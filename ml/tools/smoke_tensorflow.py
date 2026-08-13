"""Construye, convierte y ejecuta candidatos TensorFlow sin entrenarlos."""

from __future__ import annotations

import argparse
import json
import os
import statistics
import sys
import time
from pathlib import Path
from typing import Any, Callable

import keras
import keras_hub
import numpy as np
import tensorflow as tf

from ml.tools.validate_config import DEFAULT_CLASSES, load_yaml, validate_classes


ML_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_ARTIFACT_DIR = ML_ROOT / "artifacts" / "smoke"
DEFAULT_REPORT = ML_ROOT / "reports" / "smoke_tensorflow.json"
INPUT_SIZE = 224
MAX_SMOKE_SIZE_BYTES = 25 * 1024 * 1024


def _classifier_head(inputs: keras.KerasTensor, features: keras.KerasTensor, output_count: int) -> keras.Model:
    pooled = keras.layers.GlobalAveragePooling2D(name="global_average_pool")(features)
    outputs = keras.layers.Dense(output_count, activation="softmax", name="catalog_probabilities")(pooled)
    return keras.Model(inputs, outputs)


def build_mobilenet_v3_small(output_count: int) -> keras.Model:
    inputs = keras.Input((INPUT_SIZE, INPUT_SIZE, 3), dtype="float32", name="image")
    normalized = keras.layers.Rescaling(1.0 / 127.5, offset=-1.0, name="normalize")(inputs)
    backbone = keras.applications.MobileNetV3Small(
        input_shape=(INPUT_SIZE, INPUT_SIZE, 3),
        include_top=False,
        include_preprocessing=False,
        weights=None,
        minimalistic=False,
    )
    return _classifier_head(inputs, backbone(normalized), output_count)


def build_efficientnet_lite0(output_count: int) -> keras.Model:
    inputs = keras.Input((INPUT_SIZE, INPUT_SIZE, 3), dtype="float32", name="image")
    normalized = keras.layers.Rescaling(1.0 / 127.5, offset=-1.0, name="normalize")(inputs)
    backbone = keras_hub.models.EfficientNetBackbone.from_preset(
        "efficientnet_lite0_ra_imagenet",
        load_weights=False,
    )
    return _classifier_head(inputs, backbone(normalized), output_count)


BUILDERS: dict[str, Callable[[int], keras.Model]] = {
    "mnv3_small_project_weights": build_mobilenet_v3_small,
    "efficientnet_lite0_project_weights": build_efficientnet_lite0,
}


def _random_input(detail: dict[str, Any], seed: int = 20260812) -> np.ndarray:
    rng = np.random.default_rng(seed)
    shape = tuple(int(value) for value in detail["shape"])
    dtype = detail["dtype"]
    if np.issubdtype(dtype, np.integer):
        limits = np.iinfo(dtype)
        return rng.integers(limits.min, limits.max, size=shape, dtype=dtype)
    return rng.uniform(0.0, 255.0, size=shape).astype(dtype)


def convert_and_measure(
    candidate_id: str,
    builder: Callable[[int], keras.Model],
    output_count: int,
    artifact_dir: Path,
) -> dict[str, Any]:
    tf.keras.backend.clear_session()
    tf.random.set_seed(20260812)
    model = builder(output_count)

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_bytes = converter.convert()

    artifact_dir.mkdir(parents=True, exist_ok=True)
    artifact_path = artifact_dir / f"{candidate_id}.tflite"
    artifact_path.write_bytes(tflite_bytes)

    interpreter = tf.lite.Interpreter(model_content=tflite_bytes, num_threads=4)
    interpreter.allocate_tensors()
    input_detail = interpreter.get_input_details()[0]
    output_detail = interpreter.get_output_details()[0]
    sample = _random_input(input_detail)

    interpreter.set_tensor(input_detail["index"], sample)
    interpreter.invoke()
    for _ in range(4):
        interpreter.set_tensor(input_detail["index"], sample)
        interpreter.invoke()

    durations_ms: list[float] = []
    for _ in range(20):
        started = time.perf_counter()
        interpreter.set_tensor(input_detail["index"], sample)
        interpreter.invoke()
        durations_ms.append((time.perf_counter() - started) * 1000.0)

    output = interpreter.get_tensor(output_detail["index"])
    if output.shape[-1] != output_count:
        raise RuntimeError(
            f"{candidate_id}: salida {output.shape[-1]}, esperada {output_count}."
        )
    if not np.isfinite(output).all():
        raise RuntimeError(f"{candidate_id}: la inferencia contiene valores no finitos.")

    size_bytes = len(tflite_bytes)
    return {
        "candidate_id": candidate_id,
        "status": "passed" if size_bytes <= MAX_SMOKE_SIZE_BYTES else "failed_size_gate",
        "parameters": model.count_params(),
        "artifact": str(artifact_path.relative_to(ML_ROOT)).replace("\\", "/"),
        "size_bytes": size_bytes,
        "size_mib": round(size_bytes / (1024 * 1024), 3),
        "input_shape": input_detail["shape"].tolist(),
        "input_dtype": np.dtype(input_detail["dtype"]).name,
        "output_shape": output_detail["shape"].tolist(),
        "output_dtype": np.dtype(output_detail["dtype"]).name,
        "desktop_cpu_threads": 4,
        "desktop_latency_median_ms": round(statistics.median(durations_ms), 3),
        "desktop_latency_p95_ms": round(float(np.percentile(durations_ms, 95)), 3),
        "note": "La latencia de escritorio solo valida ejecución; no sustituye la medición release en móvil.",
    }


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Smoke test de construcción, conversión TFLite e inferencia TensorFlow."
    )
    parser.add_argument(
        "--candidate",
        choices=["all", *BUILDERS],
        default="all",
        help="Candidato que se probará.",
    )
    parser.add_argument("--classes", type=Path, default=DEFAULT_CLASSES)
    parser.add_argument("--artifact-dir", type=Path, default=DEFAULT_ARTIFACT_DIR)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    os.environ.setdefault("KAGGLEHUB_CACHE", str(ML_ROOT / "cache" / "kagglehub"))
    catalog = validate_classes(load_yaml(args.classes))
    selected = BUILDERS if args.candidate == "all" else {args.candidate: BUILDERS[args.candidate]}

    report: dict[str, Any] = {
        "schema_version": 1,
        "catalog_version": catalog["catalog_version"],
        "catalog_sha256": catalog["catalog_sha256"],
        "output_count": catalog["output_count"],
        "tensorflow_version": tf.__version__,
        "keras_version": keras.__version__,
        "keras_hub_version": keras_hub.__version__,
        "results": [],
    }
    exit_code = 0
    for candidate_id, builder in selected.items():
        print(f"Probando {candidate_id}...", flush=True)
        try:
            result = convert_and_measure(
                candidate_id,
                builder,
                catalog["output_count"],
                args.artifact_dir,
            )
            if result["status"] != "passed":
                exit_code = 2
        except Exception as error:  # Se registra el fallo y se continúa con el siguiente candidato.
            result = {
                "candidate_id": candidate_id,
                "status": "failed_conversion",
                "error": f"{type(error).__name__}: {error}",
            }
            exit_code = 2
        report["results"].append(result)
        print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)

    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
