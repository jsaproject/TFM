"""Valida inferencia y exportación ONNX de los encoders flexibles."""

from __future__ import annotations

import argparse
import json
import os
import platform
import statistics
import sys
import time
from pathlib import Path
from typing import Any, Callable

import numpy as np
import onnx
import onnxruntime as ort
import torch
import torch.nn.functional as functional
from onnxruntime.quantization import QuantType, quantize_dynamic
from torch import nn
from transformers import CLIPVisionModelWithProjection, Dinov2Model, __version__ as transformers_version

from ml.tools.validate_config import DEFAULT_CLASSES, load_yaml, validate_classes


ML_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_ARTIFACT_DIR = ML_ROOT / "artifacts" / "smoke"
DEFAULT_REPORT = ML_ROOT / "reports" / "smoke_pytorch.json"
CACHE_DIR = ML_ROOT / "cache" / "huggingface"
INPUT_SIZE = 224
MAX_SMOKE_SIZE_BYTES = 25 * 1024 * 1024


class PrototypeClassifier(nn.Module):
    """Convierte un encoder en un clasificador extensible por prototipos."""

    def __init__(self, encoder: nn.Module, embedding_size: int, output_count: int) -> None:
        super().__init__()
        self.encoder = encoder
        generator = torch.Generator().manual_seed(20260812)
        prototypes = torch.randn(output_count, embedding_size, generator=generator)
        self.register_buffer("prototypes", functional.normalize(prototypes, dim=-1))

    def encode(self, pixel_values: torch.Tensor) -> torch.Tensor:
        raise NotImplementedError

    def forward(self, pixel_values: torch.Tensor) -> torch.Tensor:
        embeddings = functional.normalize(self.encode(pixel_values), dim=-1)
        return torch.softmax(embeddings @ self.prototypes.transpose(0, 1), dim=-1)


class TinyClipClassifier(PrototypeClassifier):
    def encode(self, pixel_values: torch.Tensor) -> torch.Tensor:
        return self.encoder(pixel_values=pixel_values, return_dict=False)[0]


class DinoClassifier(PrototypeClassifier):
    def encode(self, pixel_values: torch.Tensor) -> torch.Tensor:
        return self.encoder(pixel_values=pixel_values, return_dict=False)[1]


def build_tinyclip(output_count: int) -> nn.Module:
    encoder = CLIPVisionModelWithProjection.from_pretrained(
        "wkcn/TinyCLIP-ViT-8M-16-Text-3M-YFCC15M",
        cache_dir=CACHE_DIR,
        attn_implementation="eager",
    )
    return TinyClipClassifier(encoder, encoder.config.projection_dim, output_count).eval()


def build_dinov2(output_count: int) -> nn.Module:
    encoder = Dinov2Model.from_pretrained(
        "facebook/dinov2-small",
        cache_dir=CACHE_DIR,
        attn_implementation="eager",
    )
    return DinoClassifier(encoder, encoder.config.hidden_size, output_count).eval()


BUILDERS: dict[str, Callable[[int], nn.Module]] = {
    "tinyclip_vit_8m_text_3m": build_tinyclip,
    "dinov2_small_prototypes": build_dinov2,
}


def _onnx_inference(session: ort.InferenceSession, sample: np.ndarray) -> np.ndarray:
    return session.run(None, {session.get_inputs()[0].name: sample})[0]


def export_and_measure(
    candidate_id: str,
    builder: Callable[[int], nn.Module],
    output_count: int,
    artifact_dir: Path,
) -> dict[str, Any]:
    torch.manual_seed(20260812)
    torch.set_num_threads(4)
    model = builder(output_count)
    sample = torch.randn(1, 3, INPUT_SIZE, INPUT_SIZE)
    with torch.inference_mode():
        reference = model(sample).cpu().numpy()
    if reference.shape != (1, output_count):
        raise RuntimeError(f"Salida PyTorch inesperada: {reference.shape}")

    artifact_dir.mkdir(parents=True, exist_ok=True)
    onnx_path = artifact_dir / f"{candidate_id}.onnx"
    quantized_path = artifact_dir / f"{candidate_id}.int8.onnx"
    with torch.inference_mode():
        torch.onnx.export(
            model,
            (sample,),
            onnx_path,
            input_names=["image"],
            output_names=["catalog_probabilities"],
            opset_version=18,
            dynamo=False,
        )
    onnx.checker.check_model(onnx.load(onnx_path))

    session = ort.InferenceSession(str(onnx_path), providers=["CPUExecutionProvider"])
    sample_numpy = sample.numpy()
    onnx_output = _onnx_inference(session, sample_numpy)
    if not np.allclose(reference, onnx_output, atol=1e-4, rtol=1e-4):
        difference = float(np.max(np.abs(reference - onnx_output)))
        raise RuntimeError(f"ONNX no conserva la salida; diferencia máxima {difference}.")

    quantize_dynamic(
        onnx_path,
        quantized_path,
        op_types_to_quantize=["MatMul", "Gemm"],
        weight_type=QuantType.QInt8,
    )
    quantized_session = ort.InferenceSession(
        str(quantized_path), providers=["CPUExecutionProvider"]
    )
    quantized_output = _onnx_inference(quantized_session, sample_numpy)
    cosine = float(
        np.sum(reference * quantized_output)
        / (np.linalg.norm(reference) * np.linalg.norm(quantized_output))
    )
    if not np.isfinite(quantized_output).all() or cosine < 0.999:
        raise RuntimeError(f"La cuantización degrada demasiado la salida: coseno {cosine}.")

    for _ in range(4):
        _onnx_inference(quantized_session, sample_numpy)
    durations_ms: list[float] = []
    for _ in range(20):
        started = time.perf_counter()
        _onnx_inference(quantized_session, sample_numpy)
        durations_ms.append((time.perf_counter() - started) * 1000.0)

    size_bytes = quantized_path.stat().st_size
    return {
        "candidate_id": candidate_id,
        "status": "passed_onnx" if size_bytes <= MAX_SMOKE_SIZE_BYTES else "failed_size_gate",
        "parameters": sum(parameter.numel() for parameter in model.parameters()),
        "float_onnx_size_mib": round(onnx_path.stat().st_size / (1024 * 1024), 3),
        "quantized_onnx_artifact": str(quantized_path.relative_to(ML_ROOT)).replace("\\", "/"),
        "quantized_onnx_size_bytes": size_bytes,
        "quantized_onnx_size_mib": round(size_bytes / (1024 * 1024), 3),
        "input_shape": list(sample_numpy.shape),
        "output_shape": list(quantized_output.shape),
        "quantized_output_cosine": round(cosine, 7),
        "desktop_cpu_threads": 4,
        "desktop_latency_median_ms": round(statistics.median(durations_ms), 3),
        "desktop_latency_p95_ms": round(float(np.percentile(durations_ms, 95)), 3),
        "tflite_status": "pending_linux_conversion",
        "note": "ONNX es una prueba intermedia; el candidato no pasa la puerta móvil hasta producir y ejecutar TFLite.",
    }


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Smoke test PyTorch, ONNX, cuantización e inferencia de encoders flexibles."
    )
    parser.add_argument("--candidate", choices=["all", *BUILDERS], default="all")
    parser.add_argument("--classes", type=Path, default=DEFAULT_CLASSES)
    parser.add_argument("--artifact-dir", type=Path, default=DEFAULT_ARTIFACT_DIR)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    os.environ.setdefault("HF_HOME", str(CACHE_DIR))
    catalog = validate_classes(load_yaml(args.classes))
    selected = BUILDERS if args.candidate == "all" else {args.candidate: BUILDERS[args.candidate]}
    report: dict[str, Any] = {
        "schema_version": 1,
        "catalog_version": catalog["catalog_version"],
        "catalog_sha256": catalog["catalog_sha256"],
        "output_count": catalog["output_count"],
        "platform": platform.platform(),
        "pytorch_version": torch.__version__,
        "transformers_version": transformers_version,
        "litert_torch_windows_install": "failed_no_litert_converter_win_amd64_wheel",
        "results": [],
    }
    exit_code = 0
    for candidate_id, builder in selected.items():
        print(f"Probando {candidate_id}...", flush=True)
        try:
            result = export_and_measure(
                candidate_id, builder, catalog["output_count"], args.artifact_dir
            )
            if result["status"] == "failed_size_gate":
                exit_code = 2
        except Exception as error:  # Registra el candidato fallido y permite probar el siguiente.
            result = {
                "candidate_id": candidate_id,
                "status": "failed_onnx",
                "error": f"{type(error).__name__}: {error}",
            }
            exit_code = 2
        report["results"].append(result)
        print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)

    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
