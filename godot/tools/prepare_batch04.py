#!/usr/bin/env python3
"""Convierte los renders aprobados del Batch 04 en piezas de prueba del kit."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT = ROOT / "assets_raw" / "generated" / "batch_04_base"
DEFAULT_OUTPUT = ROOT / "assets" / "kit_validacion" / "interiores" / "arte" / "herreria_batch_04"


def crop_alpha(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    bbox = rgba.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("la imagen no tiene píxeles opacos")
    return rgba.crop(bbox)


def fit(image: Image.Image, size: tuple[int, int], padding: int = 2) -> Image.Image:
    max_width = max(1, size[0] - padding * 2)
    max_height = max(1, size[1] - padding * 2)
    scale = min(max_width / image.width, max_height / image.height)
    target = (max(1, round(image.width * scale)), max(1, round(image.height * scale)))
    return image.resize(target, Image.Resampling.NEAREST)


def save_floor(source: Path, output: Path) -> None:
    image = fit(crop_alpha(Image.open(source)), (128, 64), 1)
    canvas = Image.new("RGBA", (128, 64), (0, 0, 0, 0))
    canvas.alpha_composite(image, ((128 - image.width) // 2, (64 - image.height) // 2))
    canvas.save(output, "PNG", optimize=False)


def save_wall(source: Path, output: Path, mirror: bool = False) -> None:
    image = crop_alpha(Image.open(source))
    if mirror:
        image = ImageOps.mirror(image)
    image = fit(image, (124, 122), 0)
    canvas = Image.new("RGBA", (128, 144), (0, 0, 0, 0))
    x = (128 - image.width) // 2
    y = 128 - image.height
    canvas.alpha_composite(image, (x, y))
    canvas.save(output, "PNG", optimize=False)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    save_floor(args.input / "suelo_piedra_base_key.png", args.output / "herreria_batch04_suelo_piedra_base.png")
    save_wall(args.input / "muro_piedra_norte_key.png", args.output / "herreria_batch04_muro_norte.png")
    save_wall(args.input / "muro_piedra_norte_key.png", args.output / "herreria_batch04_muro_oeste.png", mirror=True)
    print(f"Batch 04 preparado en {args.output}")


if __name__ == "__main__":
    main()
