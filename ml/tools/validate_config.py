"""Valida el catálogo extensible y el registro de candidatos."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

import yaml


ML_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CLASSES = ML_ROOT / "config" / "classes.yaml"
DEFAULT_CANDIDATES = ML_ROOT / "config" / "candidates.yaml"
VALID_CATEGORIES = {"granja", "domestico", "zoo", "rechazo"}
VALID_CANDIDATE_STATUSES = {"admitted", "quarantined", "rejected"}
VALID_FREE_WEIGHTS_LICENSES = {"project_owned", "MIT", "Apache-2.0"}
MODEL_ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")


class ConfigError(ValueError):
    """Error de contrato que se puede mostrar directamente al operador."""


def load_yaml(path: Path) -> dict[str, Any]:
    """Carga un documento YAML cuyo nodo raíz debe ser un mapa."""

    try:
        with path.open("r", encoding="utf-8") as stream:
            value = yaml.safe_load(stream)
    except FileNotFoundError as error:
        raise ConfigError(f"No existe el fichero de configuración: {path}") from error
    except yaml.YAMLError as error:
        raise ConfigError(f"YAML no válido en {path}: {error}") from error

    if not isinstance(value, dict):
        raise ConfigError(f"La raíz de {path} debe ser un mapa YAML.")
    return value


def _required_map(value: Any, location: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ConfigError(f"{location} debe ser un mapa.")
    return value


def _required_list(value: Any, location: str) -> list[Any]:
    if not isinstance(value, list):
        raise ConfigError(f"{location} debe ser una lista.")
    return value


def validate_classes(document: dict[str, Any]) -> dict[str, Any]:
    """Valida y resume un catálogo sin asumir cuántas clases contiene."""

    schema_version = document.get("schema_version")
    catalog_version = document.get("catalog_version")
    fallback_id = document.get("fallback_id")
    classes = _required_list(document.get("classes"), "classes")

    if schema_version != 1:
        raise ConfigError("schema_version de classes.yaml debe ser 1.")
    if not isinstance(catalog_version, int) or catalog_version < 1:
        raise ConfigError("catalog_version debe ser un entero positivo.")
    if not isinstance(fallback_id, str) or not MODEL_ID_PATTERN.fullmatch(fallback_id):
        raise ConfigError("fallback_id debe ser un ID ASCII válido.")
    if not classes:
        raise ConfigError("El catálogo debe contener al menos una clase.")

    ids: list[str] = []
    active_ids: list[str] = []
    fallback_category: str | None = None
    for index, raw_class in enumerate(classes):
        location = f"classes[{index}]"
        item = _required_map(raw_class, location)
        class_id = item.get("id")
        display_name = item.get("display_name")
        category = item.get("category")
        active = item.get("active")

        if not isinstance(class_id, str) or not MODEL_ID_PATTERN.fullmatch(class_id):
            raise ConfigError(f"{location}.id debe ser ASCII, minúsculas y estable.")
        if class_id in ids:
            raise ConfigError(f"ID de clase duplicado: {class_id}")
        if not isinstance(display_name, str) or not display_name.strip():
            raise ConfigError(f"{location}.display_name no puede estar vacío.")
        if category not in VALID_CATEGORIES:
            raise ConfigError(f"{location}.category no es una categoría permitida.")
        if not isinstance(active, bool):
            raise ConfigError(f"{location}.active debe ser booleano.")

        for field in ("include", "exclude"):
            terms = _required_list(item.get(field), f"{location}.{field}")
            if any(not isinstance(term, str) or not term for term in terms):
                raise ConfigError(f"{location}.{field} solo admite textos no vacíos.")

        ids.append(class_id)
        if active:
            active_ids.append(class_id)
        if class_id == fallback_id:
            fallback_category = category

    if fallback_id not in active_ids:
        raise ConfigError("fallback_id debe señalar una clase activa del catálogo.")
    if fallback_category != "rechazo":
        raise ConfigError("La clase fallback debe pertenecer a la categoría rechazo.")
    if active_ids[-1] != fallback_id:
        raise ConfigError("La clase fallback debe ser la última salida activa.")

    canonical = {
        "catalog_version": catalog_version,
        "fallback_id": fallback_id,
        "ordered_active_ids": active_ids,
    }
    catalog_hash = hashlib.sha256(
        json.dumps(canonical, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    ).hexdigest()
    return {
        **canonical,
        "output_count": len(active_ids),
        "catalog_sha256": catalog_hash,
    }


def validate_candidates(document: dict[str, Any], catalog_version: int) -> dict[str, int]:
    """Valida licencias, estados y rutas de exportación de los candidatos."""

    if document.get("schema_version") != 1:
        raise ConfigError("schema_version de candidates.yaml debe ser 1.")
    if document.get("catalog_version") != catalog_version:
        raise ConfigError("candidates.yaml y classes.yaml usan catálogos distintos.")
    if document.get("selection_status") != "no_winner":
        raise ConfigError("No se puede declarar ganador antes de completar la criba.")

    candidates = _required_list(document.get("candidates"), "candidates")
    if not candidates:
        raise ConfigError("Debe existir al menos un candidato.")

    ids: set[str] = set()
    counts = {status: 0 for status in sorted(VALID_CANDIDATE_STATUSES)}
    for index, raw_candidate in enumerate(candidates):
        location = f"candidates[{index}]"
        item = _required_map(raw_candidate, location)
        candidate_id = item.get("id")
        status = item.get("status")
        production_eligible = item.get("production_eligible")
        source = _required_map(item.get("source"), f"{location}.source")
        export = _required_map(item.get("export"), f"{location}.export")

        if not isinstance(candidate_id, str) or not MODEL_ID_PATTERN.fullmatch(candidate_id):
            raise ConfigError(f"{location}.id no es válido.")
        if candidate_id in ids:
            raise ConfigError(f"ID de candidato duplicado: {candidate_id}")
        if status not in VALID_CANDIDATE_STATUSES:
            raise ConfigError(f"{location}.status no es válido.")
        if not isinstance(production_eligible, bool):
            raise ConfigError(f"{location}.production_eligible debe ser booleano.")
        if status == "admitted" and not production_eligible:
            raise ConfigError(f"{candidate_id} no puede admitirse sin elegibilidad de producto.")
        if item.get("monetary_cost") != "zero":
            raise ConfigError(f"{candidate_id} incumple el requisito de coste cero.")
        if status == "admitted" and item.get("weights_license") not in VALID_FREE_WEIGHTS_LICENSES:
            raise ConfigError(f"{candidate_id} necesita pesos propios o una licencia permisiva.")
        if status == "admitted" and export.get("target") != "tflite":
            raise ConfigError(f"{candidate_id} debe declarar una exportación móvil TFLite.")
        if not source or any(
            not isinstance(url, str) or not url.startswith("https://")
            for url in source.values()
        ):
            raise ConfigError(f"{candidate_id} debe aportar fuentes HTTPS verificables.")

        ids.add(candidate_id)
        counts[status] += 1

    if counts["admitted"] < 2:
        raise ConfigError("La criba necesita al menos dos candidatos admitidos comparables.")
    return counts


def build_report(classes_path: Path, candidates_path: Path) -> dict[str, Any]:
    """Devuelve el informe validado de ambos contratos."""

    class_report = validate_classes(load_yaml(classes_path))
    candidate_report = validate_candidates(
        load_yaml(candidates_path), class_report["catalog_version"]
    )
    return {"catalog": class_report, "candidates": candidate_report}


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Valida el catálogo extensible y las licencias de candidatos."
    )
    parser.add_argument("--classes", type=Path, default=DEFAULT_CLASSES)
    parser.add_argument("--candidates", type=Path, default=DEFAULT_CANDIDATES)
    parser.add_argument("--json", action="store_true", help="Emite el informe como JSON.")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        report = build_report(args.classes, args.candidates)
    except ConfigError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        catalog = report["catalog"]
        candidates = report["candidates"]
        print(
            "Configuración válida: "
            f"catálogo v{catalog['catalog_version']}, "
            f"{catalog['output_count']} salidas, "
            f"{candidates['admitted']} candidatos admitidos."
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
