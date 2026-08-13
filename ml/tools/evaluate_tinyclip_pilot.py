"""Evalúa TinyCLIP cero-shot sobre el piloto revisado, sin entrenamiento."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import sys
import time
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

from ml.tools.validate_config import ConfigError, load_yaml, validate_classes


ML_ROOT = Path(__file__).resolve().parents[1]
REPOSITORY_ROOT = ML_ROOT.parent
DEFAULT_CLASSES = ML_ROOT / "config" / "classes.yaml"
DEFAULT_PROMPTS = ML_ROOT / "config" / "tinyclip_prompts.yaml"
DEFAULT_MANIFEST = ML_ROOT / "reports" / "pilot_v4" / "manifest.jsonl"
DEFAULT_PILOT_SUMMARY = ML_ROOT / "reports" / "pilot_v4" / "summary.json"
DEFAULT_REPORTS = ML_ROOT / "reports" / "tinyclip_pilot"
DEFAULT_CACHE = ML_ROOT / "cache" / "huggingface"


def _non_empty_strings(value: Any) -> bool:
    return (
        isinstance(value, list)
        and bool(value)
        and all(isinstance(item, str) and item.strip() for item in value)
        and len(set(value)) == len(value)
    )


def validate_prompt_config(
    document: dict[str, Any], classes_document: dict[str, Any]
) -> dict[str, Any]:
    catalog = validate_classes(classes_document)
    if document.get("schema_version") != 1:
        raise ConfigError("schema_version de tinyclip_prompts.yaml debe ser 1.")
    if document.get("catalog_version") != catalog["catalog_version"]:
        raise ConfigError("Los prompts y el catálogo usan versiones distintas.")
    model = document.get("model")
    if (
        not isinstance(model, dict)
        or not isinstance(model.get("id"), str)
        or not model["id"].strip()
        or not isinstance(model.get("revision"), str)
        or len(model["revision"]) != 40
    ):
        raise ConfigError("TinyCLIP necesita modelo y revisión exactos.")
    templates = document.get("templates")
    if not _non_empty_strings(templates) or any(
        template.count("{subject}") != 1 for template in templates
    ):
        raise ConfigError("Cada plantilla debe contener exactamente {subject}.")
    configured = document.get("classes")
    if not isinstance(configured, dict):
        raise ConfigError("tinyclip_prompts.yaml debe declarar classes.")
    expected_ids = set(catalog["ordered_active_ids"])
    if set(configured) != expected_ids:
        missing = sorted(expected_ids - set(configured))
        extras = sorted(set(configured) - expected_ids)
        raise ConfigError(f"Prompts desalineados; faltan={missing}, sobran={extras}.")
    expanded: dict[str, list[str]] = {}
    for class_id in catalog["ordered_active_ids"]:
        entry = configured[class_id]
        if not isinstance(entry, dict):
            raise ConfigError(f"Configuración inválida para {class_id}.")
        subjects = entry.get("subjects")
        prompts = entry.get("prompts")
        if subjects is not None and not _non_empty_strings(subjects):
            raise ConfigError(f"Subjects inválidos para {class_id}.")
        if prompts is not None and not _non_empty_strings(prompts):
            raise ConfigError(f"Prompts inválidos para {class_id}.")
        class_prompts: list[str] = []
        if subjects:
            class_prompts.extend(
                template.format(subject=subject)
                for subject in subjects
                for template in templates
            )
        if prompts:
            class_prompts.extend(prompts)
        if not class_prompts or len(set(class_prompts)) != len(class_prompts):
            raise ConfigError(f"{class_id} necesita prompts únicos.")
        expanded[class_id] = class_prompts
    return {"catalog": catalog, "model": model, "prompts": expanded}


def read_pilot_rows(
    manifest: Path, summary_path: Path, valid_class_ids: set[str], fallback_id: str
) -> list[dict[str, Any]]:
    if not manifest.is_file() or not summary_path.is_file():
        raise ConfigError("No existe el piloto_v4 completo.")
    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    if summary.get("status") != "human_review_passed":
        raise ConfigError("El piloto debe superar la revisión humana antes de evaluarlo.")
    rows = [
        json.loads(line)
        for line in manifest.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]
    if not rows:
        raise ConfigError("El manifiesto del piloto está vacío.")
    counts = Counter(row.get("class_id") for row in rows)
    expected_animals = valid_class_ids - {fallback_id}
    if set(counts) != expected_animals or len(set(counts.values())) != 1:
        raise ConfigError(f"El piloto no está balanceado: {dict(sorted(counts.items()))}.")
    for row in rows:
        local_path = row.get("local_path")
        if not isinstance(local_path, str) or not (REPOSITORY_ROOT / local_path).is_file():
            raise ConfigError(f"Imagen ausente en el piloto: {local_path}.")
    return rows


def read_stress_rows(
    manifest: Path, summary_path: Path, valid_class_ids: set[str]
) -> list[dict[str, Any]]:
    if not manifest.is_file() or not summary_path.is_file():
        raise ConfigError("No existe el test difícil completo.")
    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    if summary.get("status") != "human_visual_review_passed":
        raise ConfigError("El test difícil debe superar la revisión visual.")
    rows = [
        json.loads(line)
        for line in manifest.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]
    if not rows:
        raise ConfigError("El manifiesto del test difícil está vacío.")
    for row in rows:
        class_id = row.get("expected_class_id", row.get("class_id"))
        local_path = row.get("local_path")
        if class_id not in valid_class_ids:
            raise ConfigError(f"Clase esperada inválida: {class_id}.")
        if not isinstance(local_path, str) or not (REPOSITORY_ROOT / local_path).is_file():
            raise ConfigError(f"Imagen ausente en el test difícil: {local_path}.")
        row["class_id"] = class_id
        if not isinstance(row.get("stress_group"), str):
            raise ConfigError(f"Imagen sin grupo de estrés: {local_path}.")
    return rows


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def cached_model_path(cache: Path, model_id: str, revision: str) -> Path:
    repository = "models--" + model_id.replace("/", "--")
    path = cache / repository / "snapshots" / revision / "model.safetensors"
    if not path.is_file():
        raise ConfigError(
            "No están descargados los pesos de TinyCLIP; ejecuta con --allow-download."
        )
    return path


def evaluate(args: argparse.Namespace) -> dict[str, Any]:
    import numpy as np
    import torch
    import torch.nn.functional as functional
    from PIL import Image, UnidentifiedImageError
    from transformers import CLIPModel, CLIPProcessor
    from transformers.utils import logging as transformers_logging

    def feature_tensor(output: Any) -> torch.Tensor:
        """Admite la salida tensorial de Transformers 4 y la tipada de v5."""

        if isinstance(output, torch.Tensor):
            return output
        pooled = getattr(output, "pooler_output", None)
        if isinstance(pooled, torch.Tensor):
            return pooled
        raise RuntimeError("Transformers devolvió embeddings en un formato inesperado.")

    transformers_logging.set_verbosity_error()
    classes_document = load_yaml(args.classes)
    prompt_document = load_yaml(args.prompts)
    validated = validate_prompt_config(prompt_document, classes_document)
    catalog = validated["catalog"]
    model_config = validated["model"]
    if args.model_id is not None:
        model_config = {"id": args.model_id, "revision": args.model_revision}
    class_ids = catalog["ordered_active_ids"]
    fallback_id = catalog["fallback_id"]
    if args.dataset_kind == "pilot":
        rows = read_pilot_rows(
            args.manifest, args.dataset_summary, set(class_ids), fallback_id
        )
        evaluation_scope = "pilot_v4_human_reviewed_photos"
    else:
        rows = read_stress_rows(args.manifest, args.dataset_summary, set(class_ids))
        evaluation_scope = "tinyclip_stress_human_reviewed"
    if args.dry_run:
        return {
            "dry_run": True,
            "model_id": model_config["id"],
            "revision": model_config["revision"],
            "images": len(rows),
            "labels": len(class_ids),
            "prompts": sum(len(items) for items in validated["prompts"].values()),
        }

    os.environ.setdefault("HF_HOME", str(args.cache.resolve()))
    os.environ.setdefault("HF_HUB_DISABLE_PROGRESS_BARS", "1")
    torch.manual_seed(20260812)
    torch.set_num_threads(args.threads)
    started = time.perf_counter()
    load_options = {
        "cache_dir": args.cache,
        "revision": model_config["revision"],
        "local_files_only": not args.allow_download,
    }
    processor = CLIPProcessor.from_pretrained(model_config["id"], **load_options)
    model = CLIPModel.from_pretrained(model_config["id"], **load_options).eval()

    all_prompts: list[str] = []
    prompt_ranges: dict[str, tuple[int, int]] = {}
    for class_id in class_ids:
        first = len(all_prompts)
        all_prompts.extend(validated["prompts"][class_id])
        prompt_ranges[class_id] = (first, len(all_prompts))
    text_inputs = processor(text=all_prompts, return_tensors="pt", padding=True)
    with torch.inference_mode():
        text_features = functional.normalize(
            feature_tensor(model.get_text_features(**text_inputs)), dim=-1
        )
        prototypes = []
        for class_id in class_ids:
            first, last = prompt_ranges[class_id]
            prototype = text_features[first:last].mean(dim=0)
            prototypes.append(functional.normalize(prototype, dim=0))
        class_prototypes = torch.stack(prototypes)

    fallback_index = class_ids.index(fallback_id)
    animal_indices = [index for index in range(len(class_ids)) if index != fallback_index]
    predictions: list[dict[str, Any]] = []
    failures: list[str] = []
    for offset in range(0, len(rows), args.batch_size):
        batch_rows = rows[offset : offset + args.batch_size]
        images = []
        valid_rows = []
        for row in batch_rows:
            path = REPOSITORY_ROOT / row["local_path"]
            try:
                with Image.open(path) as image:
                    images.append(image.convert("RGB"))
                valid_rows.append(row)
            except (UnidentifiedImageError, OSError):
                failures.append(row["local_path"])
        if not images:
            continue
        image_inputs = processor(images=images, return_tensors="pt")
        with torch.inference_mode():
            image_features = functional.normalize(
                feature_tensor(
                    model.get_image_features(pixel_values=image_inputs["pixel_values"])
                ),
                dim=-1,
            )
            similarities = image_features @ class_prototypes.T
            logits = model.logit_scale.exp() * similarities
            probabilities = torch.softmax(logits, dim=-1).cpu().numpy()
            animal_logits = logits[:, animal_indices]
            animal_predictions = animal_logits.argmax(dim=-1).cpu().numpy()
            animal_similarities = similarities[:, animal_indices]
        for row, scores, similarity_scores, animal_similarity_scores, animal_prediction in zip(
            valid_rows,
            probabilities,
            similarities.cpu().numpy(),
            animal_similarities.cpu().numpy(),
            animal_predictions,
            strict=True,
        ):
            order = np.argsort(scores)[::-1]
            predicted_id = class_ids[int(order[0])]
            animal_predicted_id = class_ids[animal_indices[int(animal_prediction)]]
            animal_similarity_order = np.argsort(animal_similarity_scores)[::-1]
            top_animal_index = int(animal_similarity_order[0])
            second_animal_index = int(animal_similarity_order[1])
            top3 = [
                {"class_id": class_ids[int(index)], "score": round(float(scores[index]), 6)}
                for index in order[:3]
            ]
            predictions.append(
                {
                    "expected_class_id": row["class_id"],
                    "predicted_class_id": predicted_id,
                    "animal_only_predicted_class_id": animal_predicted_id,
                    "correct": predicted_id == row["class_id"],
                    "animal_only_correct": animal_predicted_id == row["class_id"],
                    "score": round(float(scores[order[0]]), 6),
                    "margin": round(float(scores[order[0]] - scores[order[1]]), 6),
                    "top_animal_score": round(
                        float(scores[animal_indices[top_animal_index]]), 6
                    ),
                    "fallback_score": round(float(scores[fallback_index]), 6),
                    "top_animal_similarity": round(
                        float(animal_similarity_scores[top_animal_index]), 6
                    ),
                    "fallback_similarity": round(
                        float(similarity_scores[fallback_index]), 6
                    ),
                    "animal_similarity_margin": round(
                        float(
                            animal_similarity_scores[top_animal_index]
                            - animal_similarity_scores[second_animal_index]
                        ),
                        6,
                    ),
                    "top3": top3,
                    "local_path": row["local_path"],
                    "stress_group": row.get("stress_group", "pilot_photo"),
                }
            )
        print(f"Procesadas {min(offset + args.batch_size, len(rows))}/{len(rows)}", flush=True)
    if failures:
        raise ConfigError(f"No se pudieron decodificar estas imágenes: {failures}.")
    if len(predictions) != len(rows):
        raise ConfigError("La evaluación no produjo una predicción por imagen.")

    per_class: dict[str, dict[str, Any]] = {}
    confusion: dict[str, Counter[str]] = defaultdict(Counter)
    for class_id in class_ids:
        if class_id == fallback_id:
            continue
        items = [item for item in predictions if item["expected_class_id"] == class_id]
        if not items:
            continue
        correct = sum(item["correct"] for item in items)
        animal_correct = sum(item["animal_only_correct"] for item in items)
        per_class[class_id] = {
            "images": len(items),
            "correct": correct,
            "accuracy": round(correct / len(items), 4),
            "animal_only_accuracy": round(animal_correct / len(items), 4),
        }
        for item in items:
            confusion[class_id][item["predicted_class_id"]] += 1

    args.reports.mkdir(parents=True, exist_ok=True)
    prediction_fields = [
        "expected_class_id",
        "predicted_class_id",
        "animal_only_predicted_class_id",
        "correct",
        "animal_only_correct",
        "score",
        "margin",
        "top_animal_score",
        "fallback_score",
        "top_animal_similarity",
        "fallback_similarity",
        "animal_similarity_margin",
        "top3",
        "local_path",
        "stress_group",
    ]
    with (args.reports / "predictions.csv").open(
        "w", encoding="utf-8", newline=""
    ) as stream:
        writer = csv.DictWriter(stream, fieldnames=prediction_fields)
        writer.writeheader()
        for item in predictions:
            serialized = dict(item)
            serialized["top3"] = json.dumps(item["top3"], ensure_ascii=False)
            writer.writerow(serialized)
    with (args.reports / "confusion_matrix.csv").open(
        "w", encoding="utf-8", newline=""
    ) as stream:
        writer = csv.writer(stream)
        writer.writerow(["expected_class_id", *class_ids])
        for expected_id in class_ids:
            if expected_id != fallback_id:
                writer.writerow(
                    [expected_id, *(confusion[expected_id][label] for label in class_ids)]
                )

    weights_path = cached_model_path(
        args.cache, model_config["id"], model_config["revision"]
    )
    correct = sum(item["correct"] for item in predictions)
    animal_correct = sum(item["animal_only_correct"] for item in predictions)
    per_group: dict[str, dict[str, Any]] = {}
    for group in sorted({item["stress_group"] for item in predictions}):
        items = [item for item in predictions if item["stress_group"] == group]
        per_group[group] = {
            "images": len(items),
            "correct": sum(item["correct"] for item in items),
            "accuracy": round(sum(item["correct"] for item in items) / len(items), 4),
        }
    summary = {
        "schema_version": 1,
        "status": "completed_not_production_validation",
        "evaluation_scope": evaluation_scope,
        "catalog_version": catalog["catalog_version"],
        "catalog_sha256": catalog["catalog_sha256"],
        "model_id": model_config["id"],
        "model_revision": model_config["revision"],
        "weights_sha256": sha256_file(weights_path),
        "weights_bytes": weights_path.stat().st_size,
        "images": len(predictions),
        "catalog_labels": len(class_ids),
        "accuracy_with_fallback": round(correct / len(predictions), 4),
        "accuracy_animals_only": round(animal_correct / len(predictions), 4),
        "fallback_predictions": sum(
            item["predicted_class_id"] == fallback_id for item in predictions
        ),
        "elapsed_seconds": round(time.perf_counter() - started, 3),
        "cpu_threads": args.threads,
        "note": "Los scores cero-shot no son confianza calibrada; este piloto no sustituye un test independiente.",
        "per_class": per_class,
        "per_group": per_group,
    }
    (args.reports / "summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return summary


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--classes", type=Path, default=DEFAULT_CLASSES)
    parser.add_argument("--prompts", type=Path, default=DEFAULT_PROMPTS)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument(
        "--dataset-kind", choices=("pilot", "stress"), default="pilot"
    )
    parser.add_argument("--dataset-summary", type=Path, default=DEFAULT_PILOT_SUMMARY)
    parser.add_argument("--reports", type=Path, default=DEFAULT_REPORTS)
    parser.add_argument("--cache", type=Path, default=DEFAULT_CACHE)
    parser.add_argument("--batch-size", type=int, default=8)
    parser.add_argument("--threads", type=int, default=4)
    parser.add_argument("--allow-download", action="store_true")
    parser.add_argument("--model-id")
    parser.add_argument("--model-revision")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv)
    if args.batch_size < 1 or args.threads < 1:
        parser.error("batch-size y threads deben ser positivos.")
    if (args.model_id is None) != (args.model_revision is None):
        parser.error("model-id y model-revision deben indicarse juntos.")
    if args.model_revision is not None and len(args.model_revision) != 40:
        parser.error("model-revision debe ser un hash de 40 caracteres.")
    return args


def main(argv: list[str] | None = None) -> int:
    try:
        result = evaluate(parse_args(argv))
    except (
        ConfigError,
        OSError,
        ValueError,
        RuntimeError,
        json.JSONDecodeError,
    ) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
