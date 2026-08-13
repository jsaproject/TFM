"""Exporta TinyCLIP como clasificador de animales en ONNX float32.

El grafo resultante recibe una imagen preprocesada y devuelve la similitud
coseno contra los prototipos de texto del catálogo. No aplica softmax ni
umbrales: esa decisión pertenece a la aplicación, que necesita la similitud
cruda para rechazar resultados dudosos.

Los prototipos se calculan aquí a partir de `tinyclip_prompts.yaml`, de modo
que ampliar el catálogo no exige reentrenar: basta con añadir textos y volver a
ejecutar este script.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

import torch
from torch import Tensor
from torch.nn import functional as functional

from ml.tools.evaluate_tinyclip_pilot import load_yaml, validate_prompt_config


ML_ROOT = Path(__file__).resolve().parents[1]
REPOSITORY_ROOT = ML_ROOT.parent
DEFAULT_CLASSES = ML_ROOT / "config" / "classes.yaml"
DEFAULT_PROMPTS = ML_ROOT / "config" / "tinyclip_prompts.yaml"
DEFAULT_CACHE = ML_ROOT / "cache" / "huggingface"
DEFAULT_OUTPUT = ML_ROOT / "artifacts" / "classifier"

INPUT_SIZE = 224
OPSET = 18
IMAGE_MEAN = [0.48145466, 0.4578275, 0.40821073]
IMAGE_STD = [0.26862954, 0.26130258, 0.27577711]


class TinyClipAnimalClassifier(torch.nn.Module):
    """Rama visual de TinyCLIP seguida de la comparación con los prototipos."""

    def __init__(self, clip: Any, prototypes: Tensor) -> None:
        super().__init__()
        self.vision_model = clip.vision_model
        self.visual_projection = clip.visual_projection
        self.register_buffer("prototypes", prototypes)

    def forward(self, image: Tensor) -> Tensor:
        pooled = self.vision_model(pixel_values=image).pooler_output
        features = self.visual_projection(pooled)
        features = features / features.norm(p=2, dim=-1, keepdim=True).clamp_min(1e-12)
        return features @ self.prototypes


def sha256_of(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_prototypes(
    model: Any,
    processor: Any,
    prompts: dict[str, list[str]],
    class_ids: list[str],
) -> Tensor:
    """Media normalizada de los embeddings de texto de cada clase."""

    ordered: list[str] = []
    ranges: dict[str, tuple[int, int]] = {}
    for class_id in class_ids:
        first = len(ordered)
        ordered.extend(prompts[class_id])
        ranges[class_id] = (first, len(ordered))
    inputs = processor(text=ordered, return_tensors="pt", padding=True)
    with torch.inference_mode():
        features = functional.normalize(
            model.get_text_features(**inputs).pooler_output, dim=-1
        )
        prototypes = [
            functional.normalize(features[ranges[c][0] : ranges[c][1]].mean(dim=0), dim=0)
            for c in class_ids
        ]
    return torch.stack(prototypes).t().contiguous()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--classes", type=Path, default=DEFAULT_CLASSES)
    parser.add_argument("--prompts", type=Path, default=DEFAULT_PROMPTS)
    parser.add_argument("--cache", type=Path, default=DEFAULT_CACHE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--name", default="tinyclip_39m_classifier")
    parser.add_argument("--model-id", default="wkcn/TinyCLIP-ViT-39M-16-Text-19M-YFCC15M")
    parser.add_argument(
        "--model-revision", default="07a4b0bc751cb64fecd2b661c048c1dd98d69444"
    )
    parser.add_argument("--minimum-similarity", type=float, required=True)
    parser.add_argument("--minimum-margin", type=float, default=0.0)
    parser.add_argument("--layout", default="NCHW_RGB")
    parser.add_argument("--allow-download", action="store_true")
    args = parser.parse_args()

    import os

    os.environ.setdefault("HF_HOME", str(args.cache.resolve()))
    from transformers import CLIPModel, CLIPProcessor
    from transformers.utils import logging as transformers_logging

    transformers_logging.set_verbosity_error()

    classes_document = load_yaml(args.classes)
    validated = validate_prompt_config(load_yaml(args.prompts), classes_document)
    catalog = validated["catalog"]
    fallback_id = catalog["fallback_id"]
    class_ids = [c for c in catalog["ordered_active_ids"] if c != fallback_id]
    display_by_id = {
        entry["id"]: entry["display_name"] for entry in classes_document["classes"]
    }

    load_options = {
        "cache_dir": args.cache,
        "revision": args.model_revision,
        "local_files_only": not args.allow_download,
    }
    processor = CLIPProcessor.from_pretrained(args.model_id, **load_options)
    model = CLIPModel.from_pretrained(args.model_id, **load_options).eval()

    prototypes = build_prototypes(model, processor, validated["prompts"], class_ids)
    classifier = TinyClipAnimalClassifier(model, prototypes).eval()

    args.output.mkdir(parents=True, exist_ok=True)
    onnx_path = args.output / f"{args.name}.onnx"
    dummy = torch.zeros(1, 3, INPUT_SIZE, INPUT_SIZE)
    with torch.inference_mode():
        torch.onnx.export(
            classifier,
            (dummy,),
            str(onnx_path),
            input_names=["image"],
            output_names=["animal_similarities"],
            opset_version=OPSET,
            dynamo=False,
        )

    weights_path = (
        args.cache
        / f"models--{args.model_id.replace('/', '--')}"
        / "snapshots"
        / args.model_revision
        / "model.safetensors"
    )
    with torch.inference_mode():
        logit_scale = float(model.logit_scale.exp())

    metadata = {
        "schema_version": 1,
        "model_id": args.model_id,
        "model_revision": args.model_revision,
        "weights_sha256": sha256_of(weights_path),
        "catalog_version": classes_document["catalog_version"],
        "catalog_sha256": hashlib.sha256(args.classes.read_bytes()).hexdigest(),
        "class_ids": class_ids,
        "display_names": [display_by_id[c] for c in class_ids],
        "fallback_id": fallback_id,
        "input": {
            # TFLite consume NHWC; el grafo ONNX exportado aquí es NCHW.
            "shape": (
                [1, INPUT_SIZE, INPUT_SIZE, 3]
                if args.layout == "NHWC_RGB"
                else [1, 3, INPUT_SIZE, INPUT_SIZE]
            ),
            "layout": args.layout,
            "resize": "shortest_edge_224_then_center_crop_224",
            "resample": "bicubic",
            "scale": "pixel_divided_by_255",
            "mean": IMAGE_MEAN,
            "std": IMAGE_STD,
        },
        "output": {
            "shape": [1, len(class_ids)],
            "value": "cosine_similarity",
            "softmax_logit_scale": logit_scale,
        },
        "rejection": {
            "minimum_similarity": args.minimum_similarity,
            "minimum_margin": args.minimum_margin,
        },
    }
    metadata_path = args.output / f"{args.name}.metadata.json"
    metadata_path.write_text(
        json.dumps(metadata, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )

    print(f"ONNX     : {onnx_path} ({onnx_path.stat().st_size} bytes)")
    print(f"SHA-256  : {sha256_of(onnx_path)}")
    print(f"clases   : {len(class_ids)} | logit_scale = {logit_scale:.7f}")
    print(f"metadatos: {metadata_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
