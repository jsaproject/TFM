"""Descarga un piloto pequeño de iNaturalist con licencia y trazabilidad."""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import re
import sys
import time
from collections import defaultdict
from pathlib import Path
from typing import Any, Iterable

import imagehash
import requests
from PIL import Image, ImageDraw, ImageOps, UnidentifiedImageError
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from ml.tools.validate_config import ConfigError, load_yaml, validate_classes


ML_ROOT = Path(__file__).resolve().parents[1]
REPOSITORY_ROOT = ML_ROOT.parent
DEFAULT_CLASSES = ML_ROOT / "config" / "classes.yaml"
DEFAULT_SOURCES = ML_ROOT / "config" / "sources.yaml"
DEFAULT_OUTPUT = ML_ROOT / "data" / "raw" / "pilot"
DEFAULT_REPORTS = ML_ROOT / "reports" / "pilot"
ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
SUPPORTED_FORMATS = {"JPEG": ".jpg", "PNG": ".png", "WEBP": ".webp"}


def license_is_allowed(code: str, allowed_codes: Iterable[str]) -> bool:
    """Solo acepta el código exacto, evitando admitir variantes NC o ND."""

    return code.lower() in {allowed.lower() for allowed in allowed_codes}


def validate_sources(
    sources_document: dict[str, Any], classes_document: dict[str, Any]
) -> dict[str, Any]:
    """Comprueba que cada clase activa tiene consultas y que no hay extras."""

    catalog = validate_classes(classes_document)
    if sources_document.get("schema_version") != 1:
        raise ConfigError("schema_version de sources.yaml debe ser 1.")
    if sources_document.get("catalog_version") != catalog["catalog_version"]:
        raise ConfigError("sources.yaml y classes.yaml usan catálogos distintos.")

    policy = sources_document.get("license_policy")
    if not isinstance(policy, dict):
        raise ConfigError("sources.yaml debe declarar license_policy.")
    allowed_codes = policy.get("allowed_codes")
    license_urls = policy.get("license_urls")
    if not isinstance(allowed_codes, list) or not allowed_codes or any(
        not isinstance(code, str) or not code for code in allowed_codes
    ):
        raise ConfigError("allowed_codes debe contener códigos de licencia.")
    if not isinstance(license_urls, dict) or set(license_urls) != set(allowed_codes):
        raise ConfigError("Cada licencia admitida necesita su URL oficial.")
    if any(
        not isinstance(url, str) or not url.startswith("https://")
        for url in license_urls.values()
    ):
        raise ConfigError("Las URLs de licencia deben ser HTTPS.")

    sources = sources_document.get("sources")
    if not isinstance(sources, dict) or set(sources) != {"inaturalist"}:
        raise ConfigError("El piloto debe declarar exactamente iNaturalist.")
    source = sources["inaturalist"]
    if not isinstance(source, dict):
        raise ConfigError("inaturalist debe ser un mapa.")
    if source.get("api_url") != "https://api.inaturalist.org/v1/observations":
        raise ConfigError("El piloto solo admite la API HTTPS oficial de iNaturalist.")
    if not isinstance(source.get("user_agent"), str) or not source["user_agent"]:
        raise ConfigError("iNaturalist necesita un User-Agent descriptivo.")
    if float(source.get("api_request_delay_seconds", 0)) < 1:
        raise ConfigError("La API de iNaturalist se debe consultar como máximo una vez por segundo.")

    queries = sources_document.get("classes")
    if not isinstance(queries, dict):
        raise ConfigError("sources.yaml debe declarar consultas por clase.")
    active_ids = set(catalog["ordered_active_ids"])
    if set(queries) != active_ids:
        missing = sorted(active_ids - set(queries))
        extras = sorted(set(queries) - active_ids)
        raise ConfigError(f"Consultas desalineadas; faltan={missing}, sobran={extras}.")
    for class_id, taxa in queries.items():
        if not ID_PATTERN.fullmatch(class_id):
            raise ConfigError(f"ID de consulta no válido: {class_id}")
        if not isinstance(taxa, list) or not taxa or any(
            not isinstance(taxon, str) or not taxon.strip() for taxon in taxa
        ):
            raise ConfigError(f"{class_id} necesita al menos un taxón.")
    return {"catalog": catalog, "source": source, "policy": policy}


class INaturalistClient:
    """Cliente anónimo para lotes pequeños de la API oficial."""

    def __init__(self, config: dict[str, Any], allowed_codes: list[str]) -> None:
        self.api_url = config["api_url"]
        self.image_size = config["image_size"]
        self.minimum_width = int(config["minimum_width"])
        self.minimum_height = int(config["minimum_height"])
        self.maximum_download_bytes = int(config["maximum_download_bytes"])
        self.api_delay = float(config["api_request_delay_seconds"])
        self.image_delay = float(config["image_request_delay_seconds"])
        self.allowed_codes = allowed_codes
        self.session = requests.Session()
        self.session.headers.update({"User-Agent": config["user_agent"]})
        retry = Retry(
            total=4,
            backoff_factor=2,
            status_forcelist=(429, 500, 502, 503, 504),
            allowed_methods=("GET",),
            respect_retry_after_header=True,
        )
        self.session.mount("https://", HTTPAdapter(max_retries=retry))

    def observations(self, taxon_name: str, maximum: int) -> list[dict[str, Any]]:
        response = self.session.get(
            self.api_url,
            params={
                "taxon_name": taxon_name,
                "photos": "true",
                "photo_license": ",".join(self.allowed_codes),
                "per_page": str(min(200, maximum)),
                "order_by": "votes",
                "order": "desc",
            },
            timeout=45,
        )
        response.raise_for_status()
        payload = response.json()
        time.sleep(self.api_delay)
        results = payload.get("results", [])
        if not isinstance(results, list):
            raise RuntimeError(f"Respuesta inválida para el taxón {taxon_name}.")
        return results

    def image_url(self, square_url: str) -> str:
        return re.sub(r"/(square|small|thumb)\.", f"/{self.image_size}.", square_url)

    def download(self, url: str) -> tuple[bytes, str]:
        time.sleep(self.image_delay)
        response = self.session.get(url, stream=True, timeout=45)
        response.raise_for_status()
        content_type = response.headers.get("Content-Type", "").split(";", 1)[0]
        if not content_type.startswith("image/"):
            raise ValueError(f"MIME HTTP no visual: {content_type or 'ausente'}")
        chunks: list[bytes] = []
        size = 0
        for chunk in response.iter_content(64 * 1024):
            if not chunk:
                continue
            size += len(chunk)
            if size > self.maximum_download_bytes:
                raise ValueError("La imagen supera el máximo de descarga.")
            chunks.append(chunk)
        return b"".join(chunks), content_type


def inspect_image(
    content: bytes, minimum_width: int, minimum_height: int
) -> tuple[str, int, int, str]:
    try:
        with Image.open(io.BytesIO(content)) as image:
            image.verify()
        with Image.open(io.BytesIO(content)) as image:
            image.load()
            image_format = image.format or ""
            width, height = image.size
            perceptual_hash = str(imagehash.phash(image.convert("RGB")))
    except (UnidentifiedImageError, OSError) as error:
        raise ValueError("Pillow no puede decodificar la imagen.") from error
    if image_format not in SUPPORTED_FORMATS:
        raise ValueError(f"Formato no permitido: {image_format or 'desconocido'}")
    if width < minimum_width or height < minimum_height:
        raise ValueError(f"Dimensiones insuficientes: {width}x{height}")
    return SUPPORTED_FORMATS[image_format], width, height, perceptual_hash


def photo_metadata(
    observation: dict[str, Any], allowed_codes: list[str], license_urls: dict[str, str]
) -> dict[str, Any] | None:
    photos = observation.get("photos")
    if not isinstance(photos, list):
        return None
    photo = next(
        (
            item
            for item in photos
            if isinstance(item, dict)
            and license_is_allowed(str(item.get("license_code", "")), allowed_codes)
            and isinstance(item.get("url"), str)
        ),
        None,
    )
    if photo is None:
        return None
    photo_id = photo.get("id")
    taxon = observation.get("taxon", {})
    user = observation.get("user", {})
    license_code = str(photo["license_code"]).lower()
    return {
        "source_observation_id": observation.get("id"),
        "source_observation_url": observation.get("uri"),
        "source_photo_id": photo_id,
        "source_photo_url": f"https://www.inaturalist.org/photos/{photo_id}",
        "download_url": photo["url"],
        "taxon_name": taxon.get("name") if isinstance(taxon, dict) else None,
        "taxon_preferred_name": (
            taxon.get("preferred_common_name") if isinstance(taxon, dict) else None
        ),
        "license_code": license_code,
        "license_url": license_urls[license_code],
        "attribution": photo.get("attribution", ""),
        "observer_login": user.get("login", "") if isinstance(user, dict) else "",
    }


def write_contact_sheet(
    class_id: str, rows: list[dict[str, Any]], destination: Path
) -> None:
    columns, cell_width, image_height, label_height = 5, 240, 180, 64
    row_count = max(1, (len(rows) + columns - 1) // columns)
    sheet = Image.new(
        "RGB", (columns * cell_width, row_count * (image_height + label_height)), "white"
    )
    draw = ImageDraw.Draw(sheet)
    for index, row in enumerate(rows):
        local_path = REPOSITORY_ROOT / Path(row["local_path"])
        with Image.open(local_path) as source:
            preview = ImageOps.contain(source.convert("RGB"), (cell_width, image_height))
        x = (index % columns) * cell_width
        y = (index // columns) * (image_height + label_height)
        sheet.paste(preview, (x + (cell_width - preview.width) // 2, y))
        taxon = str(row["taxon_name"] or "taxón desconocido")
        if len(taxon) > 31:
            taxon = taxon[:28] + "..."
        draw.text((x + 6, y + image_height + 4), f"{index + 1:02d} {class_id}", fill="black")
        draw.text((x + 6, y + image_height + 22), taxon, fill="black")
        draw.text((x + 6, y + image_height + 40), row["license_code"], fill="black")
    destination.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(destination, format="JPEG", quality=88)


def download_pilot(args: argparse.Namespace) -> dict[str, Any]:
    classes_document = load_yaml(args.classes)
    sources_document = load_yaml(args.sources)
    validated = validate_sources(sources_document, classes_document)
    catalog = validated["catalog"]
    source = validated["source"]
    policy = validated["policy"]
    queries = sources_document["classes"]
    fallback_id = catalog["fallback_id"]
    targets = {
        class_id: args.fallback_count if class_id == fallback_id else args.max_per_class
        for class_id in catalog["ordered_active_ids"]
    }
    if args.dry_run:
        return {
            "dry_run": True,
            "catalog_version": catalog["catalog_version"],
            "catalog_sha256": catalog["catalog_sha256"],
            "source": "inaturalist_api",
            "classes": [
                {"id": class_id, "target": targets[class_id], "taxa": queries[class_id]}
                for class_id in catalog["ordered_active_ids"]
            ],
            "total_target": sum(targets.values()),
        }

    args.output.mkdir(parents=True, exist_ok=True)
    args.reports.mkdir(parents=True, exist_ok=True)
    client = INaturalistClient(source, policy["allowed_codes"])
    manifest_path = args.reports / "manifest.jsonl"
    rows: list[dict[str, Any]] = []
    if manifest_path.exists():
        for line in manifest_path.read_text(encoding="utf-8").splitlines():
            row = json.loads(line)
            local_path = REPOSITORY_ROOT / Path(row.get("local_path", ""))
            if (
                row.get("catalog_sha256") == catalog["catalog_sha256"]
                and row.get("class_id") in targets
                and local_path.is_file()
            ):
                rows.append(row)
    seen_sha256 = {str(row["sha256"]) for row in rows}
    seen_observations = {
        int(row["source_observation_id"])
        for row in rows
        if isinstance(row.get("source_observation_id"), int)
    }
    rejection_counts: dict[str, int] = defaultdict(int)

    for class_id in catalog["ordered_active_ids"]:
        target = targets[class_id]
        accepted = [row for row in rows if row["class_id"] == class_id]
        taxa = queries[class_id]
        per_taxon = max(1, (target + len(taxa) - 1) // len(taxa))
        for taxon_name in taxa:
            taxon_target = min(target - len(accepted), per_taxon)
            if taxon_target <= 0:
                break
            observations = client.observations(taxon_name, args.candidate_limit)
            accepted_for_taxon = 0
            for observation in observations:
                if accepted_for_taxon >= taxon_target:
                    break
                observation_id = observation.get("id")
                if not isinstance(observation_id, int) or observation_id in seen_observations:
                    rejection_counts["duplicate_observation"] += 1
                    continue
                metadata = photo_metadata(
                    observation, policy["allowed_codes"], policy["license_urls"]
                )
                if metadata is None:
                    rejection_counts["photo_metadata_or_license"] += 1
                    continue
                download_url = client.image_url(metadata["download_url"])
                try:
                    content, content_type = client.download(download_url)
                    extension, width, height, perceptual_hash = inspect_image(
                        content, client.minimum_width, client.minimum_height
                    )
                except (requests.RequestException, ValueError) as error:
                    rejection_counts[type(error).__name__] += 1
                    continue
                sha256 = hashlib.sha256(content).hexdigest()
                if sha256 in seen_sha256:
                    rejection_counts["duplicate_sha256"] += 1
                    continue
                seen_sha256.add(sha256)
                seen_observations.add(observation_id)
                directory = args.output / "inaturalist" / class_id
                directory.mkdir(parents=True, exist_ok=True)
                local_path = directory / f"{sha256[:20]}{extension}"
                local_path.write_bytes(content)
                relative_path = local_path.resolve().relative_to(REPOSITORY_ROOT).as_posix()
                row: dict[str, Any] = {
                    "catalog_version": catalog["catalog_version"],
                    "catalog_sha256": catalog["catalog_sha256"],
                    "class_id": class_id,
                    "source": "inaturalist",
                    "query_taxon": taxon_name,
                    **metadata,
                    "download_url": download_url,
                    "http_content_type": content_type,
                    "sha256": sha256,
                    "phash": perceptual_hash,
                    "width": width,
                    "height": height,
                    "bytes": len(content),
                    "local_path": relative_path,
                    "review_decision": "pending",
                    "review_reason": "",
                }
                rows.append(row)
                accepted.append(row)
                accepted_for_taxon += 1
        print(f"{class_id}: {len(accepted)}/{target} candidatos válidos", flush=True)
        if len(accepted) < target:
            rejection_counts["target_not_reached"] += target - len(accepted)
        write_contact_sheet(
            class_id, accepted, args.reports / "contact_sheets" / f"{class_id}.jpg"
        )

    with manifest_path.open("w", encoding="utf-8", newline="\n") as stream:
        for row in rows:
            stream.write(json.dumps(row, ensure_ascii=False) + "\n")
    review_path = args.reports / "review.csv"
    review_fields = [
        "class_id",
        "query_taxon",
        "taxon_name",
        "source_photo_url",
        "sha256",
        "local_path",
        "review_decision",
        "review_reason",
    ]
    with review_path.open("w", encoding="utf-8-sig", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=review_fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)
    counts = {class_id: 0 for class_id in catalog["ordered_active_ids"]}
    for row in rows:
        counts[row["class_id"]] += 1
    summary = {
        "schema_version": 1,
        "catalog_version": catalog["catalog_version"],
        "catalog_sha256": catalog["catalog_sha256"],
        "source": "inaturalist_api",
        "monetary_cost": "zero",
        "status": "pending_human_review",
        "targets": targets,
        "downloaded": counts,
        "downloaded_total": len(rows),
        "rejections": dict(sorted(rejection_counts.items())),
        "manifest": manifest_path.resolve().relative_to(REPOSITORY_ROOT).as_posix(),
        "review": review_path.resolve().relative_to(REPOSITORY_ROOT).as_posix(),
    }
    (args.reports / "summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return summary


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Descarga un piloto trazable mediante la API de iNaturalist."
    )
    parser.add_argument("--classes", type=Path, default=DEFAULT_CLASSES)
    parser.add_argument("--sources", type=Path, default=DEFAULT_SOURCES)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--reports", type=Path, default=DEFAULT_REPORTS)
    parser.add_argument("--max-per-class", type=int, default=10)
    parser.add_argument("--fallback-count", type=int, default=30)
    parser.add_argument("--candidate-limit", type=int, default=80)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv)
    if args.max_per_class < 1 or args.fallback_count < 1 or args.candidate_limit < 1:
        parser.error("Los límites deben ser enteros positivos.")
    return args


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        report = download_pilot(args)
    except (ConfigError, requests.RequestException, RuntimeError, OSError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
