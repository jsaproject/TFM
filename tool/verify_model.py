#!/usr/bin/env python3
"""Comprueba que un modelo TFLite está sano antes de embarcarlo en assets/.

Existe porque el modelo original del proyecto se publicó con la cabeza de
clasificación sin entrenar: el 70 % de sus neuronas estaban muertas, seis de
las diez clases no se predecían nunca y una imagen negra devolvía "Mariposa"
con un 100 % de confianza. Nada de eso se detecta mirando el fichero.

Uso:

    python3 tool/verify_model.py assets/model.tflite --labels assets/labels.txt
    python3 tool/verify_model.py modelo.tflite --labels labels.txt \\
        --groups tool/imagenet_animal_groups.json --images test_fotos/

El directorio de imágenes espera una subcarpeta por clase esperada:

    test_fotos/Perro/*.jpg
    test_fotos/Gato/*.jpg

Devuelve 0 si el modelo pasa todas las comprobaciones bloqueantes y 1 si no.

Requiere: pip install ai-edge-litert pillow numpy
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

try:
    from ai_edge_litert.interpreter import Interpreter
except ImportError:  # pragma: no cover
    sys.exit("Falta ai-edge-litert. Instálalo con: pip install ai-edge-litert pillow numpy")

EXTENSIONES = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}

# Normalizaciones habituales. La entrada es siempre RGB en el rango 0-255.
PREPROCESADOS = {
    "raw": lambda x: x,
    "div255": lambda x: x / 255.0,
    "pm1": lambda x: (x - 127.5) / 127.5,
    "caffe": lambda x: x[..., ::-1] - np.array([103.939, 116.779, 123.68], np.float32),
    "torch": lambda x: (x / 255.0 - np.array([0.485, 0.456, 0.406], np.float32))
    / np.array([0.229, 0.224, 0.225], np.float32),
}


class Problema(Exception):
    """Fallo bloqueante: el modelo no debe embarcarse."""


def cargar(ruta: Path) -> tuple[Interpreter, dict, dict]:
    interprete = Interpreter(model_path=str(ruta))
    interprete.allocate_tensors()
    entrada = interprete.get_input_details()[0]
    salida = interprete.get_output_details()[0]
    return interprete, entrada, salida


def describir(ruta: Path, entrada: dict, salida: dict) -> tuple[int, int]:
    """Imprime la estructura del modelo y devuelve (lado_entrada, num_clases)."""
    forma = list(entrada["shape"])
    if len(forma) != 4 or forma[3] != 3:
        raise Problema(f"Se esperaba una entrada de imagen [1,lado,lado,3] y es {forma}")
    if forma[1] != forma[2]:
        raise Problema(f"Entrada no cuadrada: {forma[1]}x{forma[2]}")

    clases = int(salida["shape"][-1])
    print(f"  fichero        {ruta.name}  ({ruta.stat().st_size / 1e6:.1f} MB)")
    print(f"  entrada        {[int(v) for v in forma]}  {entrada['dtype'].__name__}")
    print(f"  salida         {[int(v) for v in salida['shape']]}  {salida['dtype'].__name__}")
    print(f"  clases         {clases}")
    return int(forma[1]), clases


def leer_etiquetas(ruta: Path | None, clases: int) -> list[str]:
    if ruta is None:
        return [f"clase_{i}" for i in range(clases)]
    etiquetas = [ln.strip() for ln in ruta.read_text(encoding="utf-8").splitlines() if ln.strip()]
    # Muchos modelos de ImageNet reservan el índice 0 para "background".
    if len(etiquetas) not in (clases, clases - 1):
        raise Problema(
            f"{ruta.name} tiene {len(etiquetas)} etiquetas y el modelo saca {clases} clases"
        )
    if len(etiquetas) == clases - 1:
        print(f"  etiquetas      {len(etiquetas)} (+1 clase de fondo en el índice 0)")
        etiquetas = ["__fondo__", *etiquetas]
    else:
        print(f"  etiquetas      {len(etiquetas)}")
    return etiquetas


def predecir(interprete: Interpreter, entrada: dict, salida: dict, lote: np.ndarray) -> np.ndarray:
    interprete.set_tensor(entrada["index"], lote.astype(entrada["dtype"]))
    interprete.invoke()
    return interprete.get_tensor(salida["index"])[0].astype(np.float32)


def entradas_sinteticas(lado: int) -> dict[str, np.ndarray]:
    aleatorio = np.random.RandomState(0)
    sinteticas = {
        "negro": np.zeros((lado, lado, 3), np.float32),
        "blanco": np.full((lado, lado, 3), 255.0, np.float32),
        "gris": np.full((lado, lado, 3), 128.0, np.float32),
    }
    for i in range(3):
        sinteticas[f"ruido{i + 1}"] = aleatorio.uniform(0, 255, (lado, lado, 3)).astype(np.float32)
    return sinteticas


def comprobar_colapso(
    interprete: Interpreter,
    entrada: dict,
    salida: dict,
    lado: int,
    etiquetas: list[str],
    preprocesar,
) -> list[str]:
    """Una entrada sin contenido no debe producir una clase con alta confianza."""
    fallos = []
    ganadores: dict[int, list[str]] = {}
    for nombre, imagen in entradas_sinteticas(lado).items():
        prob = predecir(interprete, entrada, salida, preprocesar(imagen)[None])
        indice = int(prob.argmax())
        ganadores.setdefault(indice, []).append(nombre)
        marca = "  <-- sospechoso" if prob[indice] > 0.90 else ""
        print(f"  {nombre:8s} -> {etiquetas[indice]:20s} {prob[indice] * 100:5.1f}%{marca}")

    dominante = max(ganadores.items(), key=lambda kv: len(kv[1]))
    if len(dominante[1]) >= 5:
        fallos.append(
            f"'{etiquetas[dominante[0]]}' gana en {len(dominante[1])} de 6 entradas sin "
            "contenido: la cabeza del modelo está colapsada"
        )
    return fallos


def _tensor_de_features(ruta: Path) -> str | None:
    """Nombre del tensor que alimenta a la última capa del clasificador.

    Es el único punto donde la escasez de activaciones discrimina: las capas
    convolucionales con ReLU son escasas por naturaleza (MobileNetV2 sano pasa
    del 60 %), pero las features que ve el clasificador no deberían estarlo.
    """
    try:
        import tflite
        from tflite import BuiltinOperator
    except ImportError:
        return None

    modelo = tflite.Model.GetRootAsModel(ruta.read_bytes(), 0)
    grafo = modelo.Subgraphs(0)
    finales = (BuiltinOperator.FULLY_CONNECTED, BuiltinOperator.CONV_2D)
    densas = []
    for indice in range(grafo.OperatorsLength()):
        codigo = modelo.OperatorCodes(grafo.Operators(indice).OpcodeIndex())
        if max(codigo.BuiltinCode(), codigo.DeprecatedBuiltinCode()) in finales:
            densas.append(indice)
    if not densas:
        return None
    return grafo.Tensors(grafo.Operators(densas[-1]).InputsAsNumpy()[0]).Name().decode()


def comprobar_features_muertas(ruta: Path, entrada: dict, lado: int, preprocesar) -> list[str]:
    """Un clasificador cuyas features de entrada están casi todas a cero no aprendió."""
    nombre = _tensor_de_features(ruta)
    if nombre is None:
        print("  omitido: instala el paquete 'tflite' para analizar el grafo")
        return []

    interprete = Interpreter(model_path=str(ruta), experimental_preserve_all_tensors=True)
    interprete.allocate_tensors()
    indice_entrada = interprete.get_input_details()[0]["index"]
    indices = {d["name"]: d["index"] for d in interprete.get_tensor_details()}
    if nombre not in indices:
        print("  omitido: no se pudo leer el tensor de features")
        return []

    vivas = None
    for imagen in entradas_sinteticas(lado).values():
        interprete.set_tensor(indice_entrada, preprocesar(imagen)[None].astype(entrada["dtype"]))
        interprete.invoke()
        valor = np.abs(interprete.get_tensor(indices[nombre]).ravel())
        vivas = valor if vivas is None else np.maximum(vivas, valor)

    muertas = float((vivas == 0).mean())
    print(f"  capa           {nombre.split(';')[0][-52:]}")
    print(f"  dimensión      {vivas.size}")
    print(f"  siempre a cero {muertas * 100:.1f}%  (referencias: 12 % sano, 56 % roto)")
    # Umbral calibrado sobre solo dos modelos (MobileNetV2 sano al 12 % y el
    # ResNet50 roto del proyecto al 56 %). Si aparece un falso positivo, el
    # número de arriba es el dato a revisar antes que la conclusión.
    if muertas > 0.50:
        return [
            f"el {muertas * 100:.0f}% de las features que alimentan al clasificador están "
            "siempre a cero: la cabeza del modelo no llegó a entrenarse"
        ]
    return []


def evaluar(
    interprete: Interpreter,
    entrada: dict,
    salida: dict,
    lado: int,
    etiquetas: list[str],
    grupos: dict[str, list[int]] | None,
    directorio: Path,
    preprocesar,
    desfase: int,
) -> tuple[int, int, list[str]]:
    """Mide aciertos sobre test_fotos/<clase esperada>/*.jpg."""
    aciertos = total = 0
    lineas = []
    for carpeta in sorted(p for p in directorio.iterdir() if p.is_dir()):
        ficheros = [f for f in sorted(carpeta.iterdir()) if f.suffix.lower() in EXTENSIONES]
        if not ficheros:
            continue
        buenos = 0
        for fichero in ficheros:
            imagen = Image.open(fichero).convert("RGB").resize((lado, lado), Image.BILINEAR)
            prob = predecir(
                interprete, entrada, salida, preprocesar(np.asarray(imagen, np.float32))[None]
            )
            if grupos:
                puntos = {g: float(prob[[i + desfase for i in idx]].sum()) for g, idx in grupos.items()}
                predicho = max(puntos, key=puntos.get)
            else:
                predicho = etiquetas[int(prob.argmax())]
            buenos += predicho == carpeta.name
        aciertos += buenos
        total += len(ficheros)
        lineas.append(f"  {carpeta.name:22s} {buenos:3d}/{len(ficheros):<3d}")
    return aciertos, total, lineas


def main() -> int:
    parser = argparse.ArgumentParser(description="Verifica un modelo TFLite de clasificación.")
    parser.add_argument("modelo", type=Path)
    parser.add_argument("--labels", type=Path, help="fichero de etiquetas, una por línea")
    parser.add_argument("--groups", type=Path, help="JSON de agrupación de clases")
    parser.add_argument("--images", type=Path, help="directorio test_fotos/<clase>/*.jpg")
    parser.add_argument(
        "--preprocess", choices=sorted(PREPROCESADOS), default="pm1", help="normalización de entrada"
    )
    args = parser.parse_args()

    if not args.modelo.is_file():
        return _abortar(f"No existe {args.modelo}")

    preprocesar = PREPROCESADOS[args.preprocess]
    fallos: list[str] = []

    try:
        print("\n=== ESTRUCTURA ===")
        interprete, entrada, salida = cargar(args.modelo)
        lado, clases = describir(args.modelo, entrada, salida)
        etiquetas = leer_etiquetas(args.labels, clases)
        desfase = 0

        grupos = None
        if args.groups:
            datos = json.loads(args.groups.read_text(encoding="utf-8"))
            grupos = datos["grupos"] if "grupos" in datos else datos
            if clases not in (1000, 1001):
                raise Problema(
                    f"--groups asume un modelo de ImageNet-1k y este saca {clases} clases"
                )
            # 1001 clases = las 1000 de ImageNet más una de fondo en el índice 0.
            desfase = clases - 1000
            print(f"  grupos         {len(grupos)} (desfase de índice: {desfase})")

        print(f"\n=== ENTRADAS SIN CONTENIDO (normalización '{args.preprocess}') ===")
        fallos += comprobar_colapso(interprete, entrada, salida, lado, etiquetas, preprocesar)

        print("\n=== FEATURES DEL CLASIFICADOR ===")
        fallos += comprobar_features_muertas(args.modelo, entrada, lado, preprocesar)

        if args.images:
            if not args.images.is_dir():
                return _abortar(f"No existe el directorio {args.images}")
            print("\n=== ACIERTOS SOBRE FOTOS REALES ===")
            aciertos, total, lineas = evaluar(
                interprete, entrada, salida, lado, etiquetas, grupos, args.images,
                preprocesar, desfase,
            )
            print("\n".join(lineas))
            if total == 0:
                fallos.append(f"no hay imágenes utilizables en {args.images}")
            else:
                ratio = aciertos / total
                print(f"  {'TOTAL':22s} {aciertos:3d}/{total:<3d}  ({ratio * 100:.1f}%)")
                if ratio < 0.70:
                    fallos.append(f"solo acierta el {ratio * 100:.0f}% de las fotos de prueba")
        else:
            print("\n  (sin --images no se puede medir la precisión real)")

    except Problema as error:
        return _abortar(str(error))

    print()
    if fallos:
        print("RESULTADO: NO APTO")
        for fallo in fallos:
            print(f"  - {fallo}")
        return 1
    print("RESULTADO: APTO")
    return 0


def _abortar(mensaje: str) -> int:
    print(f"\nRESULTADO: NO APTO\n  - {mensaje}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
