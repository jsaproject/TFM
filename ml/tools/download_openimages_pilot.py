"""Construye un piloto visual a partir de cajas de Open Images verificadas."""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import re
import shutil
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

import requests
from PIL import Image, ImageDraw, ImageOps, UnidentifiedImageError

from ml.tools.download_pilot import validate_sources
from ml.tools.validate_config import ConfigError, load_yaml, validate_classes


ML_ROOT = Path(__file__).resolve().parents[1]
REPOSITORY_ROOT = ML_ROOT.parent
DEFAULT_CLASSES = ML_ROOT / "config" / "classes.yaml"
DEFAULT_CONFIG = ML_ROOT / "config" / "openimages_pilot.yaml"
DEFAULT_SOURCES = ML_ROOT / "config" / "sources.yaml"
DEFAULT_OUTPUT = ML_ROOT / "data" / "raw" / "pilot_v2"
DEFAULT_REPORTS = ML_ROOT / "reports" / "pilot_v2"
DEFAULT_CACHE = ML_ROOT / "cache" / "openimages_v7"
DEFAULT_DONOR_MANIFEST = ML_ROOT / "reports" / "pilot_v1" / "manifest.jsonl"


def validate_config(
    config: dict[str, Any], classes_document: dict[str, Any]
) -> dict[str, Any]:
    catalog = validate_classes(classes_document)
    if config.get("schema_version") != 1:
        raise ConfigError("schema_version de openimages_pilot.yaml debe ser 1.")
    if config.get("catalog_version") != catalog["catalog_version"]:
        raise ConfigError("El piloto y el catálogo usan versiones distintas.")
    target = config.get("images_per_animal")
    if not isinstance(target, int) or target < 1:
        raise ConfigError("images_per_animal debe ser un entero positivo.")

    open_images = config.get("open_images")
    mapped = config.get("open_images_classes")
    reviewed = config.get("reviewed_inaturalist")
    reviewed_photos = config.get("reviewed_inaturalist_photos")
    if not isinstance(open_images, dict) or not isinstance(mapped, dict):
        raise ConfigError("Falta la configuración de Open Images.")
    if not isinstance(reviewed, dict):
        raise ConfigError("Falta la selección manual complementaria.")
    if not isinstance(reviewed_photos, dict):
        raise ConfigError("Falta la selección por ID de iNaturalist.")
    required_urls = (
        "class_descriptions_url",
        "annotations_url",
        "image_metadata_url",
        "image_url_template",
        "required_license",
    )
    if any(
        not isinstance(open_images.get(field), str)
        or not open_images[field].startswith("https://")
        for field in required_urls
    ):
        raise ConfigError("Todas las fuentes de Open Images deben usar HTTPS.")
    flags = open_images.get("require_flags")
    if not isinstance(flags, dict) or not flags or any(value != 0 for value in flags.values()):
        raise ConfigError("Los indicadores de calidad deben exigir valor cero.")

    animal_ids = set(catalog["ordered_active_ids"]) - {catalog["fallback_id"]}
    configured_ids = set(mapped) | set(reviewed) | set(reviewed_photos)
    if configured_ids != animal_ids:
        missing = sorted(animal_ids - configured_ids)
        extras = sorted(configured_ids - animal_ids)
        raise ConfigError(
            f"Cobertura inválida; faltan={missing}, sobran={extras}."
        )
    source_counts: dict[str, int] = {}
    for class_id, class_config in mapped.items():
        if not isinstance(class_config, dict) or not isinstance(
            class_config.get("name"), str
        ):
            raise ConfigError(f"{class_id} necesita un nombre de Open Images.")
        count = class_config.get("count", target)
        excluded = class_config.get("exclude_image_ids", [])
        if not isinstance(count, int) or count < 1 or count > target:
            raise ConfigError(f"{class_id} tiene un count inválido.")
        if (
            not isinstance(excluded, list)
            or any(not isinstance(image_id, str) or not image_id for image_id in excluded)
            or len(set(excluded)) != len(excluded)
        ):
            raise ConfigError(f"{class_id} tiene exclusiones de imagen inválidas.")
        source_counts[class_id] = count
    for class_id, selection in reviewed.items():
        if (
            not isinstance(selection, list)
            or not selection
            or len(selection) > target
            or any(not isinstance(index, int) or index < 1 for index in selection)
            or len(set(selection)) != len(selection)
        ):
            raise ConfigError(f"{class_id} tiene índices manuales inválidos.")
        source_counts[class_id] = source_counts.get(class_id, 0) + len(selection)
    for class_id, selection in reviewed_photos.items():
        if (
            not isinstance(selection, list)
            or not selection
            or len(selection) > target
            or any(
                not isinstance(item, dict)
                or set(item) != {"observation_id", "photo_id"}
                or not isinstance(item["observation_id"], int)
                or item["observation_id"] < 1
                or not isinstance(item["photo_id"], int)
                or item["photo_id"] < 1
                for item in selection
            )
            or len({item["photo_id"] for item in selection}) != len(selection)
        ):
            raise ConfigError(f"{class_id} tiene fotos identificadas inválidas.")
        source_counts[class_id] = source_counts.get(class_id, 0) + len(selection)
    wrong_counts = {
        class_id: source_counts.get(class_id, 0)
        for class_id in animal_ids
        if source_counts.get(class_id, 0) != target
    }
    if wrong_counts:
        raise ConfigError(f"Cada animal necesita {target} imágenes: {wrong_counts}.")
    return {"catalog": catalog, "target": target, "source_counts": source_counts}


def ensure_cached(session: requests.Session, url: str, path: Path) -> None:
    if path.is_file() and path.stat().st_size > 0:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".part")
    with session.get(url, stream=True, timeout=120) as response:
        response.raise_for_status()
        with temporary.open("wb") as stream:
            for chunk in response.iter_content(1024 * 1024):
                if chunk:
                    stream.write(chunk)
    temporary.replace(path)


def read_json_lines(path: Path) -> list[dict[str, Any]]:
    if not path.is_file():
        raise ConfigError(f"No existe el manifiesto donante: {path}")
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]


def select_boxes(
    config: dict[str, Any], descriptions_path: Path, annotations_path: Path
) -> dict[str, list[dict[str, Any]]]:
    mapped = config["open_images_classes"]
    names_to_ids: dict[str, str] = {}
    with descriptions_path.open("r", encoding="utf-8", newline="") as stream:
        for label_id, display_name in csv.reader(stream):
            if display_name in {value["name"] for value in mapped.values()}:
                names_to_ids[display_name] = label_id
    missing_names = sorted(
        {value["name"] for value in mapped.values()} - set(names_to_ids)
    )
    if missing_names:
        raise ConfigError(f"Open Images no contiene estas clases con cajas: {missing_names}")
    label_to_class = {
        names_to_ids[value["name"]]: class_id for class_id, value in mapped.items()
    }
    by_class_image: dict[str, dict[str, dict[str, Any]]] = defaultdict(dict)
    source = config["open_images"]
    with annotations_path.open("r", encoding="utf-8", newline="") as stream:
        for row in csv.DictReader(stream):
            class_id = label_to_class.get(row["LabelName"])
            if class_id is None:
                continue
            if any(row[field] != str(value) for field, value in source["require_flags"].items()):
                continue
            width = float(row["XMax"]) - float(row["XMin"])
            height = float(row["YMax"]) - float(row["YMin"])
            area = width * height
            threshold = float(
                mapped[class_id].get("minimum_box_area", source["minimum_box_area"])
            )
            if area < threshold:
                continue
            row["box_area"] = area
            previous = by_class_image[class_id].get(row["ImageID"])
            if previous is None or area > previous["box_area"]:
                by_class_image[class_id][row["ImageID"]] = row
    return {
        class_id: sorted(images.values(), key=lambda row: row["box_area"], reverse=True)
        for class_id, images in by_class_image.items()
    }


def load_metadata(path: Path, wanted_ids: set[str]) -> dict[str, dict[str, str]]:
    result: dict[str, dict[str, str]] = {}
    with path.open("r", encoding="utf-8", newline="") as stream:
        for row in csv.DictReader(stream):
            if row["ImageID"] in wanted_ids:
                result[row["ImageID"]] = row
    return result


def padded_crop(image: Image.Image, box: dict[str, Any], padding: float) -> Image.Image:
    width, height = image.size
    x_min, x_max = float(box["XMin"]), float(box["XMax"])
    y_min, y_max = float(box["YMin"]), float(box["YMax"])
    pad_x = (x_max - x_min) * padding
    pad_y = (y_max - y_min) * padding
    left = max(0, round((x_min - pad_x) * width))
    right = min(width, round((x_max + pad_x) * width))
    top = max(0, round((y_min - pad_y) * height))
    bottom = min(height, round((y_max + pad_y) * height))
    if right <= left or bottom <= top:
        raise ValueError("Caja vacía después de aplicar padding.")
    return image.crop((left, top, right, bottom)).convert("RGB")


def download_open_images(
    session: requests.Session,
    config: dict[str, Any],
    boxes: dict[str, list[dict[str, Any]]],
    metadata: dict[str, dict[str, str]],
    output: Path,
    target: int,
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    source = config["open_images"]
    used_images: set[str] = set()
    for class_id, class_config in config["open_images_classes"].items():
        class_target = int(class_config.get("count", target))
        excluded_image_ids = set(class_config.get("exclude_image_ids", []))
        accepted = 0
        for box in boxes.get(class_id, []):
            if accepted >= class_target:
                break
            image_id = box["ImageID"]
            image_metadata = metadata.get(image_id)
            if (
                image_id in excluded_image_ids
                or image_id in used_images
                or image_metadata is None
            ):
                continue
            if image_metadata.get("License") != source["required_license"]:
                continue
            url = source["image_url_template"].format(image_id=image_id)
            try:
                response = session.get(url, timeout=45)
                response.raise_for_status()
                with Image.open(io.BytesIO(response.content)) as image:
                    image.load()
                    crop = padded_crop(image, box, float(source["crop_padding_ratio"]))
                minimum_crop_side = int(
                    class_config.get(
                        "minimum_crop_side", source["minimum_crop_side"]
                    )
                )
                if min(crop.size) < minimum_crop_side:
                    continue
            except (requests.RequestException, UnidentifiedImageError, OSError, ValueError):
                continue
            class_directory = output / class_id
            class_directory.mkdir(parents=True, exist_ok=True)
            local_path = class_directory / f"openimages_{image_id}.jpg"
            crop.save(local_path, format="JPEG", quality=92, optimize=True)
            content = local_path.read_bytes()
            sha256 = hashlib.sha256(content).hexdigest()
            rows.append(
                {
                    "class_id": class_id,
                    "source": "open_images_v7",
                    "source_split": source["split"],
                    "source_image_id": image_id,
                    "source_image_url": url,
                    "source_landing_url": image_metadata.get("OriginalLandingURL", ""),
                    "license_url": image_metadata["License"],
                    "author": image_metadata.get("Author", ""),
                    "author_profile_url": image_metadata.get("AuthorProfileURL", ""),
                    "bbox": {
                        key: float(box[key]) for key in ("XMin", "XMax", "YMin", "YMax")
                    },
                    "box_area": round(float(box["box_area"]), 7),
                    "local_path": local_path.resolve().relative_to(REPOSITORY_ROOT).as_posix(),
                    "width": crop.width,
                    "height": crop.height,
                    "sha256": sha256,
                    "review_decision": "pending",
                }
            )
            used_images.add(image_id)
            accepted += 1
        print(f"{class_id}: {accepted}/{class_target} Open Images", flush=True)
        if accepted != class_target:
            raise ConfigError(
                f"{class_id} no alcanza {class_target} recortes válidos."
            )
    return rows


def copy_reviewed_donors(
    config: dict[str, Any], donor_manifest: Path, output: Path
) -> list[dict[str, Any]]:
    donor_rows = read_json_lines(donor_manifest)
    rows: list[dict[str, Any]] = []
    for class_id, indexes in config["reviewed_inaturalist"].items():
        candidates = [row for row in donor_rows if row.get("class_id") == class_id]
        for index in indexes:
            if index > len(candidates):
                raise ConfigError(f"Índice {index} inexistente para {class_id}.")
            donor = candidates[index - 1]
            source_path = REPOSITORY_ROOT / Path(donor["local_path"])
            if not source_path.is_file():
                raise ConfigError(f"No existe la imagen donante: {source_path}")
            class_directory = output / class_id
            class_directory.mkdir(parents=True, exist_ok=True)
            destination = class_directory / f"inaturalist_{donor['source_photo_id']}{source_path.suffix}"
            shutil.copy2(source_path, destination)
            with Image.open(destination) as image:
                image.verify()
            copied = dict(donor)
            copied.update(
                {
                    "local_path": destination.resolve()
                    .relative_to(REPOSITORY_ROOT)
                    .as_posix(),
                    "selection": "manual_visual_review",
                    "review_decision": "accepted",
                }
            )
            rows.append(copied)
        print(f"{class_id}: {len(indexes)}/{len(indexes)} selección manual", flush=True)
    return rows


def download_reviewed_photos(
    session: requests.Session,
    config: dict[str, Any],
    sources_document: dict[str, Any],
    output: Path,
) -> list[dict[str, Any]]:
    source = sources_document["sources"]["inaturalist"]
    policy = sources_document["license_policy"]
    allowed_codes = set(policy["allowed_codes"])
    rows: list[dict[str, Any]] = []
    for class_id, selections in config["reviewed_inaturalist_photos"].items():
        for selection in selections:
            observation_id = selection["observation_id"]
            photo_id = selection["photo_id"]
            response = session.get(f"{source['api_url']}/{observation_id}", timeout=45)
            response.raise_for_status()
            results = response.json().get("results", [])
            observation = next(
                (item for item in results if item.get("id") == observation_id), None
            )
            if observation is None:
                raise ConfigError(f"Observación inexistente: {observation_id}.")
            photo = next(
                (item for item in observation.get("photos", []) if item.get("id") == photo_id),
                None,
            )
            if photo is None:
                raise ConfigError(
                    f"La foto {photo_id} no pertenece a la observación {observation_id}."
                )
            license_code = str(photo.get("license_code", "")).lower()
            if license_code not in allowed_codes:
                raise ConfigError(f"Licencia no admitida en la foto {photo_id}.")
            square_url = photo.get("url")
            if not isinstance(square_url, str) or not square_url.startswith("https://"):
                raise ConfigError(f"URL inválida en la foto {photo_id}.")
            image_url = re.sub(r"/(square|small|thumb)\.", "/medium.", square_url)
            image_response = session.get(image_url, timeout=45)
            image_response.raise_for_status()
            if len(image_response.content) > int(source["maximum_download_bytes"]):
                raise ConfigError(f"La foto {photo_id} supera el tamaño permitido.")
            try:
                with Image.open(io.BytesIO(image_response.content)) as image:
                    image.load()
                    converted = image.convert("RGB")
            except (UnidentifiedImageError, OSError) as error:
                raise ConfigError(f"La foto {photo_id} no es decodificable.") from error
            if (
                converted.width < int(source["minimum_width"])
                or converted.height < int(source["minimum_height"])
            ):
                raise ConfigError(f"La foto {photo_id} no tiene resolución suficiente.")
            class_directory = output / class_id
            class_directory.mkdir(parents=True, exist_ok=True)
            destination = class_directory / f"inaturalist_{photo_id}.jpg"
            converted.save(destination, format="JPEG", quality=92, optimize=True)
            content = destination.read_bytes()
            taxon = observation.get("taxon", {})
            user = observation.get("user", {})
            rows.append(
                {
                    "class_id": class_id,
                    "source": "inaturalist",
                    "source_observation_id": observation_id,
                    "source_observation_url": observation.get("uri", ""),
                    "source_photo_id": photo_id,
                    "source_photo_url": f"https://www.inaturalist.org/photos/{photo_id}",
                    "download_url": image_url,
                    "taxon_name": taxon.get("name", "") if isinstance(taxon, dict) else "",
                    "license_code": license_code,
                    "license_url": policy["license_urls"][license_code],
                    "attribution": photo.get("attribution", ""),
                    "observer_login": user.get("login", "") if isinstance(user, dict) else "",
                    "local_path": destination.resolve()
                    .relative_to(REPOSITORY_ROOT)
                    .as_posix(),
                    "width": converted.width,
                    "height": converted.height,
                    "sha256": hashlib.sha256(content).hexdigest(),
                    "selection": "manual_visual_review_by_id",
                    "review_decision": "accepted",
                }
            )
        print(
            f"{class_id}: {len(selections)}/{len(selections)} selección por ID",
            flush=True,
        )
    return rows


def write_contact_sheet(class_id: str, rows: list[dict[str, Any]], path: Path) -> None:
    cell_width, image_height, label_height = 240, 180, 48
    sheet = Image.new("RGB", (len(rows) * cell_width, image_height + label_height), "white")
    draw = ImageDraw.Draw(sheet)
    for index, row in enumerate(rows):
        with Image.open(REPOSITORY_ROOT / Path(row["local_path"])) as image:
            preview = ImageOps.contain(image.convert("RGB"), (cell_width, image_height))
        x = index * cell_width
        sheet.paste(preview, (x + (cell_width - preview.width) // 2, 0))
        draw.text((x + 6, image_height + 4), f"{index + 1:02d} {class_id}", fill="black")
        draw.text((x + 6, image_height + 22), row["source"], fill="black")
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path, format="JPEG", quality=90)


def build_pilot(args: argparse.Namespace) -> dict[str, Any]:
    classes_document = load_yaml(args.classes)
    config = load_yaml(args.config)
    sources_document = load_yaml(args.sources)
    validated = validate_config(config, classes_document)
    validate_sources(sources_document, classes_document)
    if args.dry_run:
        return {
            "dry_run": True,
            "target_total": validated["target"]
            * (validated["catalog"]["output_count"] - 1),
            "open_images_classes": len(config["open_images_classes"]),
            "manual_classes": len(
                set(config["reviewed_inaturalist"])
                | set(config["reviewed_inaturalist_photos"])
            ),
        }

    session = requests.Session()
    session.headers.update({"User-Agent": "AnimalsPredictorML/1.0 Open Images pilot"})
    descriptions = args.cache / "class-descriptions-boxable.csv"
    annotations = args.cache / "validation-annotations-bbox.csv"
    image_metadata = args.cache / "validation-images-with-rotation.csv"
    source = config["open_images"]
    for url, path in (
        (source["class_descriptions_url"], descriptions),
        (source["annotations_url"], annotations),
        (source["image_metadata_url"], image_metadata),
    ):
        ensure_cached(session, url, path)
    boxes = select_boxes(config, descriptions, annotations)
    wanted_ids = {box["ImageID"] for candidates in boxes.values() for box in candidates}
    metadata = load_metadata(image_metadata, wanted_ids)
    args.output.mkdir(parents=True, exist_ok=True)
    args.reports.mkdir(parents=True, exist_ok=True)
    rows = download_open_images(
        session, config, boxes, metadata, args.output, validated["target"]
    )
    rows.extend(copy_reviewed_donors(config, args.donor_manifest, args.output))
    rows.extend(download_reviewed_photos(session, config, sources_document, args.output))
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        grouped[row["class_id"]].append(row)
    expected_ids = set(validated["catalog"]["ordered_active_ids"]) - {
        validated["catalog"]["fallback_id"]
    }
    wrong_counts = {
        class_id: len(grouped[class_id])
        for class_id in expected_ids
        if len(grouped[class_id]) != validated["target"]
    }
    if wrong_counts or len(rows) != len(expected_ids) * validated["target"]:
        raise ConfigError(f"Conteo final inválido: {wrong_counts}")
    for class_id in validated["catalog"]["ordered_active_ids"]:
        if class_id == validated["catalog"]["fallback_id"]:
            continue
        write_contact_sheet(
            class_id,
            grouped[class_id],
            args.reports / "contact_sheets" / f"{class_id}.jpg",
        )
    manifest = args.reports / "manifest.jsonl"
    with manifest.open("w", encoding="utf-8", newline="\n") as stream:
        for row in rows:
            stream.write(json.dumps(row, ensure_ascii=False) + "\n")
    summary = {
        "schema_version": 1,
        "catalog_version": validated["catalog"]["catalog_version"],
        "catalog_sha256": validated["catalog"]["catalog_sha256"],
        "status": "pending_human_review",
        "downloaded_total": len(rows),
        "images_per_animal": validated["target"],
        "open_images_count": sum(row["source"] == "open_images_v7" for row in rows),
        "manually_selected_count": sum(
            row["source"] == "inaturalist" for row in rows
        ),
        "classes": {class_id: len(grouped[class_id]) for class_id in sorted(expected_ids)},
    }
    (args.reports / "summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return summary


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--classes", type=Path, default=DEFAULT_CLASSES)
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    parser.add_argument("--sources", type=Path, default=DEFAULT_SOURCES)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--reports", type=Path, default=DEFAULT_REPORTS)
    parser.add_argument("--cache", type=Path, default=DEFAULT_CACHE)
    parser.add_argument("--donor-manifest", type=Path, default=DEFAULT_DONOR_MANIFEST)
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    try:
        report = build_pilot(parse_args(argv))
    except (ConfigError, requests.RequestException, OSError, csv.Error) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
