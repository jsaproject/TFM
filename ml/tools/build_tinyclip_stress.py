"""Construye el test difícil y trazable de TinyCLIP sin recopilar un dataset."""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

import requests
from PIL import Image, ImageDraw, ImageOps, UnidentifiedImageError

from ml.tools.download_openimages_pilot import load_metadata, padded_crop
from ml.tools.validate_config import ConfigError, load_yaml, validate_classes


ML_ROOT = Path(__file__).resolve().parents[1]
REPOSITORY_ROOT = ML_ROOT.parent
DEFAULT_CLASSES = ML_ROOT / "config" / "classes.yaml"
DEFAULT_CONFIG = ML_ROOT / "config" / "tinyclip_stress.yaml"
DEFAULT_OPEN_IMAGES = ML_ROOT / "config" / "openimages_pilot.yaml"
DEFAULT_PILOT_MANIFEST = ML_ROOT / "reports" / "pilot_v1" / "manifest.jsonl"
DEFAULT_OUTPUT = ML_ROOT / "data" / "raw" / "tinyclip_stress"
DEFAULT_REPORTS = ML_ROOT / "reports" / "tinyclip_stress"
DEFAULT_CACHE = ML_ROOT / "cache" / "openimages_v7"


def sha256_bytes(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


def read_json_lines(path: Path) -> list[dict[str, Any]]:
    if not path.is_file():
        raise ConfigError(f"No existe el manifiesto: {path}")
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def validate_stress_config(
    document: dict[str, Any], classes_document: dict[str, Any]
) -> dict[str, Any]:
    catalog = validate_classes(classes_document)
    if document.get("schema_version") != 1:
        raise ConfigError("schema_version de tinyclip_stress.yaml debe ser 1.")
    if document.get("catalog_version") != catalog["catalog_version"]:
        raise ConfigError("El test difícil y el catálogo usan versiones distintas.")
    if document.get("visual_review_status") not in {"pending", "passed"}:
        raise ConfigError("visual_review_status debe ser pending o passed.")
    valid_ids = set(catalog["ordered_active_ids"])
    for field in ("pilot_v1_selections", "local_images"):
        value = document.get(field)
        if not isinstance(value, dict) or not set(value).issubset(valid_ids):
            raise ConfigError(f"{field} contiene clases inválidas.")
        for class_id, selections in value.items():
            if not isinstance(selections, list) or not selections:
                raise ConfigError(f"{field}.{class_id} debe ser una lista no vacía.")
    depictions = document.get("open_images_depictions")
    if not isinstance(depictions, dict):
        raise ConfigError("Falta open_images_depictions.")
    depiction_classes = depictions.get("classes")
    count = depictions.get("images_per_class")
    minimum_area = depictions.get("minimum_box_area")
    if (
        not isinstance(depiction_classes, list)
        or not depiction_classes
        or len(set(depiction_classes)) != len(depiction_classes)
        or not set(depiction_classes).issubset(valid_ids - {catalog["fallback_id"]})
        or not isinstance(count, int)
        or count < 1
        or not isinstance(minimum_area, (int, float))
        or not 0 < float(minimum_area) <= 1
    ):
        raise ConfigError("Configuración de representaciones de Open Images inválida.")
    return {"catalog": catalog, "depictions": depictions}


def selected_pilot_rows(
    manifest: Path, selections: dict[str, list[int]]
) -> list[dict[str, Any]]:
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in read_json_lines(manifest):
        grouped[row["class_id"]].append(row)
    result: list[dict[str, Any]] = []
    for class_id, indices in selections.items():
        rows = grouped.get(class_id, [])
        for index in indices:
            if not isinstance(index, int) or index < 1 or index > len(rows):
                raise ConfigError(f"Índice {index} inválido para {class_id}.")
            source = dict(rows[index - 1])
            source["expected_class_id"] = class_id
            source["stress_group"] = (
                "unsupported_animal" if class_id == "otro" else "weak_class_photo"
            )
            result.append(source)
    return result


def selected_local_rows(selections: dict[str, list[str]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for class_id, paths in selections.items():
        for relative in paths:
            if not isinstance(relative, str):
                raise ConfigError(f"Ruta local inválida para {class_id}.")
            path = REPOSITORY_ROOT / relative
            if not path.is_file():
                raise ConfigError(f"No existe la imagen local: {relative}")
            try:
                with Image.open(path) as image:
                    image.verify()
            except (UnidentifiedImageError, OSError) as error:
                raise ConfigError(f"No se puede decodificar {relative}: {error}") from error
            rows.append(
                {
                    "expected_class_id": class_id,
                    "stress_group": (
                        "app_asset_rejection"
                        if class_id == "otro"
                        else "app_asset_supported"
                        if relative.startswith("assets/")
                        else "weak_class_photo"
                    ),
                    "source": "local_reviewed",
                    "local_path": relative.replace("\\", "/"),
                }
            )
    return rows


def select_depiction_boxes(
    descriptions_path: Path,
    annotations_path: Path,
    class_names: dict[str, str],
    minimum_area: float,
) -> dict[str, list[dict[str, Any]]]:
    wanted_names = set(class_names.values())
    label_to_class: dict[str, str] = {}
    with descriptions_path.open("r", encoding="utf-8", newline="") as stream:
        for label_id, display_name in csv.reader(stream):
            if display_name in wanted_names:
                class_id = next(
                    key for key, value in class_names.items() if value == display_name
                )
                label_to_class[label_id] = class_id
    if len(label_to_class) != len(class_names):
        raise ConfigError("Faltan clases de representación en Open Images.")

    by_class_image: dict[str, dict[str, dict[str, Any]]] = defaultdict(dict)
    with annotations_path.open("r", encoding="utf-8", newline="") as stream:
        for row in csv.DictReader(stream):
            class_id = label_to_class.get(row["LabelName"])
            if class_id is None or row["IsDepiction"] != "1":
                continue
            if any(row[field] != "0" for field in ("IsOccluded", "IsTruncated", "IsGroupOf", "IsInside")):
                continue
            area = (float(row["XMax"]) - float(row["XMin"])) * (
                float(row["YMax"]) - float(row["YMin"])
            )
            if area < minimum_area:
                continue
            candidate = dict(row)
            candidate["box_area"] = area
            previous = by_class_image[class_id].get(row["ImageID"])
            if previous is None or area > previous["box_area"]:
                by_class_image[class_id][row["ImageID"]] = candidate
    return {
        class_id: sorted(items.values(), key=lambda item: item["box_area"], reverse=True)
        for class_id, items in by_class_image.items()
    }


def download_depictions(
    session: requests.Session,
    boxes: dict[str, list[dict[str, Any]]],
    metadata: dict[str, dict[str, str]],
    class_names: dict[str, str],
    target: int,
    source_config: dict[str, Any],
    output: Path,
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    template = source_config["image_url_template"]
    required_license = source_config["required_license"]
    for class_id in class_names:
        accepted = 0
        for box in boxes.get(class_id, []):
            if accepted >= target:
                break
            image_id = box["ImageID"]
            image_metadata = metadata.get(image_id)
            if image_metadata is None or image_metadata.get("License") != required_license:
                continue
            if float(image_metadata.get("Rotation") or 0) != 0:
                continue
            url = template.format(image_id=image_id)
            try:
                response = session.get(url, timeout=45)
                response.raise_for_status()
                with Image.open(io.BytesIO(response.content)) as image:
                    image.load()
                    crop = padded_crop(image, box, 0.20)
                if min(crop.size) < 128:
                    continue
                destination = output / "depictions" / class_id / f"{image_id}.jpg"
                destination.parent.mkdir(parents=True, exist_ok=True)
                crop.save(destination, format="JPEG", quality=92, optimize=True)
                content = destination.read_bytes()
            except (requests.RequestException, UnidentifiedImageError, OSError, ValueError):
                continue
            rows.append(
                {
                    "expected_class_id": class_id,
                    "stress_group": "open_images_depiction",
                    "source": "open_images_v7",
                    "source_split": "validation",
                    "source_image_id": image_id,
                    "source_image_url": url,
                    "source_landing_url": image_metadata.get("OriginalURL", ""),
                    "license_url": image_metadata["License"],
                    "author": image_metadata.get("Author", ""),
                    "source_rotation_degrees": float(
                        image_metadata.get("Rotation") or 0
                    ),
                    "bbox": {
                        key: float(box[key]) for key in ("XMin", "XMax", "YMin", "YMax")
                    },
                    "box_area": round(float(box["box_area"]), 7),
                    "local_path": destination.relative_to(REPOSITORY_ROOT).as_posix(),
                    "sha256": sha256_bytes(content),
                }
            )
            accepted += 1
        if accepted != target:
            raise ConfigError(
                f"Open Images solo aportó {accepted}/{target} representaciones para {class_id}."
            )
    return rows


def write_contact_sheet(rows: list[dict[str, Any]], destination: Path) -> None:
    cell_width, image_height, caption_height = 240, 180, 54
    columns = 4
    sheet_rows = (len(rows) + columns - 1) // columns
    sheet = Image.new("RGB", (cell_width * columns, (image_height + caption_height) * sheet_rows), "white")
    draw = ImageDraw.Draw(sheet)
    for index, row in enumerate(rows):
        path = REPOSITORY_ROOT / row["local_path"]
        with Image.open(path) as image:
            preview = ImageOps.contain(image.convert("RGB"), (cell_width, image_height))
        left = (index % columns) * cell_width
        top = (index // columns) * (image_height + caption_height)
        sheet.paste(preview, (left + (cell_width - preview.width) // 2, top))
        draw.text((left + 5, top + image_height + 4), f"{index + 1:02d} {row['expected_class_id']}", fill="black")
        draw.text((left + 5, top + image_height + 22), row["stress_group"][:34], fill="black")
    destination.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(destination, format="JPEG", quality=90)


def build(args: argparse.Namespace) -> dict[str, Any]:
    classes_document = load_yaml(args.classes)
    document = load_yaml(args.config)
    validated = validate_stress_config(document, classes_document)
    open_images_document = load_yaml(args.open_images)
    mapped = open_images_document["open_images_classes"]
    depiction_config = validated["depictions"]
    class_names = {
        class_id: mapped[class_id]["name"] for class_id in depiction_config["classes"]
    }
    boxes = select_depiction_boxes(
        args.cache / "class-descriptions-boxable.csv",
        args.cache / "validation-annotations-bbox.csv",
        class_names,
        float(depiction_config["minimum_box_area"]),
    )
    wanted_ids = {item["ImageID"] for items in boxes.values() for item in items}
    metadata = load_metadata(
        args.cache / "validation-images-with-rotation.csv", wanted_ids
    )
    session = requests.Session()
    session.headers["User-Agent"] = "AnimalsPredictor-TinyCLIP-Stress/1.0"
    rows = selected_pilot_rows(
        args.pilot_manifest, document["pilot_v1_selections"]
    )
    rows.extend(selected_local_rows(document["local_images"]))
    rows.extend(
        download_depictions(
            session,
            boxes,
            metadata,
            class_names,
            int(depiction_config["images_per_class"]),
            open_images_document["open_images"],
            args.output,
        )
    )
    for row in rows:
        if not (REPOSITORY_ROOT / row["local_path"]).is_file():
            raise ConfigError(f"Imagen ausente: {row['local_path']}")
        row.setdefault("class_id", row["expected_class_id"])

    args.reports.mkdir(parents=True, exist_ok=True)
    (args.reports / "manifest.jsonl").write_text(
        "".join(json.dumps(row, ensure_ascii=False) + "\n" for row in rows),
        encoding="utf-8",
    )
    write_contact_sheet(rows, args.reports / "contact_sheet.jpg")
    group_counts: dict[str, int] = defaultdict(int)
    for row in rows:
        group_counts[row["stress_group"]] += 1
    summary = {
        "schema_version": 1,
        "status": (
            "human_visual_review_passed"
            if document["visual_review_status"] == "passed"
            else "pending_visual_review"
        ),
        "images": len(rows),
        "groups": dict(sorted(group_counts.items())),
        "note": "Banco pequeño para decidir integración; no es un dataset de entrenamiento.",
    }
    (args.reports / "dataset_summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return summary


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--classes", type=Path, default=DEFAULT_CLASSES)
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    parser.add_argument("--open-images", type=Path, default=DEFAULT_OPEN_IMAGES)
    parser.add_argument("--pilot-manifest", type=Path, default=DEFAULT_PILOT_MANIFEST)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--reports", type=Path, default=DEFAULT_REPORTS)
    parser.add_argument("--cache", type=Path, default=DEFAULT_CACHE)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    try:
        result = build(parse_args(argv))
    except (ConfigError, OSError, ValueError, KeyError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
