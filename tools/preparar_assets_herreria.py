from __future__ import annotations

import math
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
BATCH = ROOT / "assets_raw" / "generados" / "herreria_batch_02_4vistas"
OUT = BATCH / "sprites_finales"
DIRECCIONES = (("sur", 0, 0), ("este", 1, 0), ("oeste", 0, 1), ("norte", 1, 1))

# nombre_fuente, prefijo_final, tamaño físico, pivote físico
ASSETS = (
    ("yunque_4vistas.png", "mueble_herreria_yunque", (128, 112), (64, 96)),
    ("fragua_4vistas.png", "mueble_herreria_fragua", (192, 256), (96, 240)),
    ("banco_trabajo_4vistas.png", "mueble_herreria_banco_trabajo", (192, 160), (96, 144)),
    ("mesa_trabajo_4vistas.png", "mueble_herreria_mesa_trabajo", (192, 128), (96, 112)),
    ("horno_4vistas.png", "mueble_herreria_horno", (160, 256), (80, 240)),
    ("estanteria_herramientas_4vistas.png", "mueble_herreria_estanteria_herramientas", (128, 192), (64, 176)),
    ("panoplia_4vistas.png", "mueble_herreria_panoplia", (128, 144), (64, 128)),
    ("barril_carbon_4vistas.png", "mueble_herreria_deposito_carbon", (128, 112), (64, 96)),
    ("cofre_hierro_4vistas.png", "mueble_comun_cofre_hierro", (128, 144), (64, 128)),
    ("escaleras_madera_4vistas.png", "mueble_comun_escalera_madera", (160, 224), (80, 208)),
)


def limpiar_chroma(imagen: Image.Image) -> Image.Image:
    rgba = imagen.convert("RGBA")
    key = rgba.getpixel((0, 0))[:3]
    pix = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, _ = pix[x, y]
            distancia = math.sqrt(
                (r - key[0]) ** 2 + (g - key[1]) ** 2 + (b - key[2]) ** 2
            )
            magenta = r > 145 and b > 145 and g < 135
            if distancia <= 80 or magenta:
                pix[x, y] = (r, g, b, 0)
            elif distancia <= 125:
                alpha = int(255 * (distancia - 80) / 45)
                pix[x, y] = (r, g, b, alpha)
    return rgba


def recortar_visible(imagen: Image.Image) -> Image.Image:
    alpha = imagen.getchannel("A")
    bbox = alpha.point(lambda value: 255 if value > 8 else 0).getbbox()
    if bbox is None:
        raise RuntimeError("La celda no contiene un objeto visible")
    margen = 8
    x0 = max(0, bbox[0] - margen)
    y0 = max(0, bbox[1] - margen)
    x1 = min(imagen.width, bbox[2] + margen)
    y1 = min(imagen.height, bbox[3] + margen)
    return imagen.crop((x0, y0, x1, y1))


def preparar_frame(celda: Image.Image, tam_fisico: tuple[int, int], pivote: tuple[int, int]) -> Image.Image:
    visible = recortar_visible(celda)
    ancho_logico = tam_fisico[0] // 2
    alto_logico = tam_fisico[1] // 2
    pivote_logico = (pivote[0] // 2, pivote[1] // 2)
    max_ancho = max(8, ancho_logico - 6)
    max_alto = max(8, pivote_logico[1] - 2)
    factor = min(max_ancho / visible.width, max_alto / visible.height, 1.0)
    nuevo = (
        max(1, int(round(visible.width * factor))),
        max(1, int(round(visible.height * factor))),
    )
    reducido = visible.resize(nuevo, Image.Resampling.LANCZOS)
    rgb = reducido.convert("RGB").quantize(
        colors=40,
        method=Image.Quantize.MEDIANCUT,
        dither=Image.Dither.NONE,
    ).convert("RGB")
    alpha = reducido.getchannel("A")
    reducido = Image.merge("RGBA", (*rgb.split(), alpha))

    lienzo = Image.new("RGBA", (ancho_logico, alto_logico), (15, 15, 27, 0))
    x = pivote_logico[0] - reducido.width // 2
    y = pivote_logico[1] - reducido.height
    lienzo.alpha_composite(reducido, (x, y))
    salida = lienzo.resize(tam_fisico, Image.Resampling.NEAREST)
    pix = salida.load()
    for py in range(salida.height):
        for px in range(salida.width):
            r, g, b, a = pix[px, py]
            # Despill final: ningún borde rosado debe sobrevivir al chroma-key.
            es_magenta = (
                a > 0
                and r > 120
                and b > 120
                and r > g + 50
                and b > g + 40
                and r + b > 300
            )
            halo_magenta = a < 255 and r > 80 and b > 40 and g < 70
            if es_magenta or halo_magenta:
                pix[px, py] = (15, 15, 27, 0)
    return salida


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for fuente, prefijo, tam_fisico, pivote in ASSETS:
        ruta = BATCH / fuente
        if not ruta.exists():
            raise FileNotFoundError(ruta)
        base = limpiar_chroma(Image.open(ruta))
        mitad_w = base.width // 2
        mitad_h = base.height // 2
        for direccion, columna, fila in DIRECCIONES:
            celda = base.crop((columna * mitad_w, fila * mitad_h, (columna + 1) * mitad_w, (fila + 1) * mitad_h))
            salida = preparar_frame(celda, tam_fisico, pivote)
            salida.save(OUT / f"{prefijo}_{direccion}.png", optimize=True)
    print(f"Generados {len(ASSETS) * len(DIRECCIONES)} sprites en {OUT}")


if __name__ == "__main__":
    main()
