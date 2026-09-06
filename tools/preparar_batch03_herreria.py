from __future__ import annotations

import math
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
BATCH = ROOT / "assets_raw" / "generados" / "herreria_batch_03_estructura_decoracion"
OUT = BATCH / "sprites_finales"


def limpiar_chroma(imagen: Image.Image) -> Image.Image:
    rgba = imagen.convert("RGBA")
    key = rgba.getpixel((0, 0))[:3]
    pix = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, _ = pix[x, y]
            distancia = math.sqrt((r - key[0]) ** 2 + (g - key[1]) ** 2 + (b - key[2]) ** 2)
            magenta = r > 145 and b > 145 and g < 135
            if distancia <= 80 or magenta:
                pix[x, y] = (r, g, b, 0)
            elif distancia <= 125:
                pix[x, y] = (r, g, b, int(255 * (distancia - 80) / 45))
    return rgba


def visible(imagen: Image.Image) -> Image.Image:
    bbox = imagen.getchannel("A").point(lambda value: 255 if value > 8 else 0).getbbox()
    if bbox is None:
        raise RuntimeError("Celda sin contenido visible")
    return imagen.crop((max(0, bbox[0] - 8), max(0, bbox[1] - 8), min(imagen.width, bbox[2] + 8), min(imagen.height, bbox[3] + 8)))


def pixelizar(imagen: Image.Image, tamano: tuple[int, int]) -> Image.Image:
    recorte = visible(imagen)
    reducido = recorte.resize(tamano, Image.Resampling.LANCZOS)
    rgb = reducido.convert("RGB").quantize(colors=40, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    salida = Image.merge("RGBA", (*rgb.split(), reducido.getchannel("A")))
    salida = salida.resize(tamano, Image.Resampling.NEAREST)
    pix = salida.load()
    for y in range(salida.height):
        for x in range(salida.width):
            r, g, b, a = pix[x, y]
            halo = a < 255 and r > 80 and b > 40 and g < 70
            magenta = a > 0 and r > 120 and b > 120 and r > g + 50 and b > g + 40 and r + b > 300
            if halo or magenta:
                pix[x, y] = (15, 15, 27, 0)
    return salida


def celdas(ruta: Path) -> list[Image.Image]:
    base = limpiar_chroma(Image.open(ruta))
    w, h = base.width // 2, base.height // 2
    return [base.crop((0, 0, w, h)), base.crop((w, 0, w * 2, h)), base.crop((0, h, w, h * 2)), base.crop((w, h, w * 2, h * 2))]


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    # Suelo: cuatro celdas 128x64 en un atlas horizontal para poder ampliar
    # el manifiesto sin romper el atlas actual de dos celdas.
    suelo = celdas(BATCH / "suelo_piedra_4variantes.png")
    atlas = Image.new("RGBA", (512, 64), (15, 15, 27, 0))
    for i, celda in enumerate(suelo):
        atlas.alpha_composite(pixelizar(celda, (128, 64)), (i * 128, 0))
    atlas.save(OUT / "herreria_v2_suelo_atlas_4variantes.png", optimize=True)

    for fuente, nombres, tamano in (
        ("muros_piedra_4piezas.png", ("muro_norte", "muro_oeste", "muro_esquina", "muro_pilar"), (128, 112)),
        ("ventanas_muro_4variantes.png", ("ventana_norte", "ventana_oeste", "contraventana", "ventana_fuego"), (128, 112)),
        ("decoraciones_herreria_4piezas.png", ("cartel_yunque", "panel_herramientas", "saco_carbon", "farol"), (128, 128)),
    ):
        for celda, nombre in zip(celdas(BATCH / fuente), nombres):
            pixelizar(celda, tamano).save(OUT / f"herreria_v2_{nombre}.png", optimize=True)

    print(f"Generados {len(list(OUT.glob('*.png')))} assets en {OUT}")


if __name__ == "__main__":
    main()
