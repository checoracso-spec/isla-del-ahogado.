from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
DESTINATION = ROOT / "assets" / "kit_validacion" / "interiores" / "arte" / "herreria_batch_04_v2_neutro"

SOURCES = (
    (ROOT / "assets" / "kit_validacion" / "interiores" / "arte" / "herreria_batch_04" / "herreria_batch04_muro_norte.png", "herreria_batch04_v2_muro_norte.png"),
    (ROOT / "assets" / "kit_validacion" / "interiores" / "arte" / "herreria_batch_04" / "herreria_batch04_muro_oeste.png", "herreria_batch04_v2_muro_oeste.png"),
    (ROOT / "assets" / "kit_validacion" / "interiores" / "arte" / "herreria_batch_04" / "herreria_batch04_suelo_piedra_base.png", "herreria_batch04_v2_suelo_piedra_base.png"),
    (ROOT / "assets" / "kit_validacion" / "interiores" / "arte" / "herreria_v3" / "herreria_v3_muro_esquina.png", "herreria_batch04_v2_muro_esquina.png"),
    (ROOT / "assets" / "kit_validacion" / "interiores" / "arte" / "herreria_v3" / "herreria_v3_muro_borde_pilar.png", "herreria_batch04_v2_muro_borde_pilar.png"),
)


def neutralize(pixel: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    r, g, b, a = pixel
    if a == 0:
        return pixel

    # Reduce chroma while preserving every luminance/value variation of the
    # original pixel. The tiny blue-gray bias removes baked yellow lighting
    # without repainting silhouettes, edges, or texture structure.
    luminance = 0.299 * r + 0.587 * g + 0.114 * b
    neutral_r = luminance * 0.96
    neutral_g = luminance * 0.985
    neutral_b = min(255.0, luminance * 1.035)
    # Keep only a very small amount of the source chroma. This makes the
    # three pieces read as one neutral stone family rather than warm variants.
    saturation = 0.08
    nr = neutral_r + (r - neutral_r) * saturation
    ng = neutral_g + (g - neutral_g) * saturation
    nb = neutral_b + (b - neutral_b) * saturation

    # Warm pixels are desaturated more aggressively so beige/yellow highlights
    # become cool natural stone instead of remaining gold.
    warmth = max(0.0, min(1.0, ((r + g) * 0.5 - b) / 100.0))
    nr = nr * (1.0 - 0.18 * warmth) + luminance * 0.93 * (0.18 * warmth)
    ng = ng * (1.0 - 0.18 * warmth) + luminance * 0.97 * (0.18 * warmth)
    nb = nb * (1.0 - 0.18 * warmth) + luminance * 1.03 * (0.18 * warmth)

    return (int(max(0, min(255, round(nr)))),
            int(max(0, min(255, round(ng)))),
            int(max(0, min(255, round(nb)))),
            a)


def main() -> None:
    DESTINATION.mkdir(parents=True, exist_ok=True)
    for source_path, output_name in SOURCES:
        output_path = DESTINATION / output_name
        with Image.open(source_path).convert("RGBA") as source:
            pixels = [neutralize(pixel) for pixel in source.getdata()]
            result = Image.new("RGBA", source.size)
            result.putdata(pixels)
            result.save(output_path)
            print(f"{output_path.name}: {source.size[0]}x{source.size[1]}")

if __name__ == "__main__":
    main()
