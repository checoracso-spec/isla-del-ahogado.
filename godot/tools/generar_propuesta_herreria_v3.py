from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
PROPOSAL = ROOT / "assets" / "kit_validacion" / "interiores" / "propuestas" / "herreria_v3"


def alpha_crop(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    bbox = rgba.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError(f"La imagen no tiene contenido visible: {image}")
    return rgba.crop(bbox)


def fit_on_canvas(
    source: Image.Image,
    canvas_size: tuple[int, int],
    content_size: tuple[int, int] | None = None,
    bottom_y: int | None = None,
) -> Image.Image:
    fitted = source.resize(content_size or canvas_size, Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    if bottom_y is None:
        canvas.alpha_composite(fitted)
    else:
        y = max(0, bottom_y - fitted.height)
        canvas.alpha_composite(fitted, (0, y))
    return canvas


def main() -> None:
    wall_source = alpha_crop(Image.open(PROPOSAL / "fuente_muro_piedra_v3.png"))
    floor_source = alpha_crop(Image.open(PROPOSAL / "fuente_suelo_piedra_v3.png"))
    corner_source = alpha_crop(Image.open(PROPOSAL / "limpia_esquina_piedra_v3.png"))
    pillar_source = alpha_crop(Image.open(PROPOSAL / "limpia_pilar_piedra_v3.png"))

    # The generated corner includes a sample floor for presentation. Remove it
    # before fitting the wall-only sprite, otherwise the runtime would double
    # draw the floor tile below the corner.
    corner_source = corner_source.crop((0, 0, corner_source.width, int(corner_source.height * 0.80)))

    # The game-facing canvas and pivots remain compatible with Iso and the manifest.
    floor = fit_on_canvas(floor_source, (128, 64))
    floor.save(PROPOSAL / "prototipo_suelo_piedra_v3.png")

    wall = fit_on_canvas(wall_source, (128, 144), content_size=(128, 120), bottom_y=128)
    wall.save(PROPOSAL / "prototipo_muro_norte_v3.png")
    ImageOps.mirror(wall).save(PROPOSAL / "prototipo_muro_oeste_v3.png")

    corner = fit_on_canvas(corner_source, (128, 144), content_size=(128, 120), bottom_y=128)
    corner.save(PROPOSAL / "prototipo_muro_esquina_v3.png")

    pillar = fit_on_canvas(pillar_source, (128, 144), content_size=(64, 128), bottom_y=128)
    pillar.save(PROPOSAL / "prototipo_muro_pilar_v3.png")

    print("Generados:")
    for name in (
        "prototipo_suelo_piedra_v3.png",
        "prototipo_muro_norte_v3.png",
        "prototipo_muro_oeste_v3.png",
        "prototipo_muro_esquina_v3.png",
        "prototipo_muro_pilar_v3.png",
    ):
        image = Image.open(PROPOSAL / name)
        print(name, image.size, image.mode)


if __name__ == "__main__":
    main()
