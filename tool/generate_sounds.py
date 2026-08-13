#!/usr/bin/env python3
"""Genera los tres sonidos de la app en assets/sonidos/.

Los sonidos se sintetizan aqui en lugar de descargarse para que sean
reproducibles, libres de licencia y muy pequenos (unos 20 KB cada uno).

Son tres campanillas de notas ascendentes sobre la escala de do mayor, que es
lo que un nino asocia con "bien hecho":

  acierto.wav   dos notas, cuando la foto se reconoce.
  guardado.wav  tres notas, cuando el animal entra en la coleccion.
  logro.wav     cuatro notas y mas cola, cuando se gana una medalla.

Uso:  python3 tool/generate_sounds.py
"""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 22050
AMPLITUDE = 0.62

# Frecuencias en hercios de las notas que se usan.
NOTES = {
    "do5": 523.25,
    "mi5": 659.25,
    "sol5": 783.99,
    "do6": 1046.50,
}

# (nota, comienzo en segundos, duracion en segundos) por fichero.
SOUNDS: dict[str, list[tuple[str, float, float]]] = {
    "acierto": [
        ("do5", 0.00, 0.18),
        ("sol5", 0.10, 0.28),
    ],
    "guardado": [
        ("do5", 0.00, 0.20),
        ("mi5", 0.10, 0.20),
        ("sol5", 0.20, 0.40),
    ],
    "logro": [
        ("do5", 0.00, 0.22),
        ("mi5", 0.11, 0.22),
        ("sol5", 0.22, 0.22),
        ("do6", 0.33, 0.62),
    ],
}


def _envelope(position: float, duration: float) -> float:
    """Ataque muy corto y caida exponencial: suena a campana, no a pitido."""
    attack = 0.012
    if position < attack:
        return position / attack
    return math.exp(-4.5 * (position - attack) / max(duration - attack, 1e-6))


def _render(notes: list[tuple[str, float, float]]) -> list[float]:
    total = max(start + duration for _, start, duration in notes)
    samples = [0.0] * int(total * SAMPLE_RATE)
    for name, start, duration in notes:
        frequency = NOTES[name]
        first = int(start * SAMPLE_RATE)
        for index in range(int(duration * SAMPLE_RATE)):
            position = index / SAMPLE_RATE
            angle = 2 * math.pi * frequency * position
            # El segundo armonico, flojito, le quita el punto de pitido puro.
            wave_value = math.sin(angle) + 0.22 * math.sin(2 * angle)
            samples[first + index] += wave_value * _envelope(position, duration)
    return samples


def _write(path: Path, samples: list[float]) -> None:
    peak = max((abs(sample) for sample in samples), default=1.0) or 1.0
    frames = b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, sample / peak * AMPLITUDE)) * 32767))
        for sample in samples
    )
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(frames)


def main() -> None:
    destination = Path(__file__).resolve().parent.parent / "assets" / "sonidos"
    destination.mkdir(parents=True, exist_ok=True)
    for name, notes in SOUNDS.items():
        path = destination / f"{name}.wav"
        _write(path, _render(notes))
        print(f"{path} ({path.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
