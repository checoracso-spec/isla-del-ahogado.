from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / "assets" / "kit_validacion" / "interiores" / "archivo_v1_pre_v3"
PROPOSAL = ROOT / "assets" / "kit_validacion" / "interiores" / "arte" / "herreria_v3"
SOURCE = ROOT / "assets" / "kit_validacion" / "interiores" / "propuestas" / "herreria_v3" / "fuente_muro_piedra_v3.png"


def clean_black(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = []
    for r, g, b, a in rgba.getdata():
        if a > 0 and r == 0 and g == 0 and b == 0:
            pixels.append((15, 15, 27, a))
        else:
            pixels.append((r, g, b, a))
    rgba.putdata(pixels)
    return rgba


def rebuild(mask_name: str, output_name: str, target_height: int, mirrored_texture: bool = False) -> None:
    mask_image = Image.open(ARCHIVE / mask_name).convert("RGBA")
    mask = mask_image.getchannel("A")
    mask = mask.resize((mask.width, target_height), Image.Resampling.NEAREST)

    texture = Image.open(SOURCE).convert("RGBA")
    texture = texture.crop(texture.getchannel("A").getbbox())
    texture = texture.resize((mask.width, target_height), Image.Resampling.NEAREST)
    # The source is a single wall face and has its own silhouette. For the
    # corner/pillar masks it must act only as an opaque stone paint layer;
    # otherwise its alpha would erase the second face of the mask.
    texture.putalpha(Image.new("L", texture.size, 255))
    if mirrored_texture:
        texture = ImageOps.mirror(texture)

    output = Image.new("RGBA", (128, 144), (0, 0, 0, 0))
    output.paste(texture, (0, 0), mask)
    clean_black(output).save(PROPOSAL / output_name)


def main() -> None:
    # The old alpha silhouettes are used only as geometric masks. No old RGB
    # pixels survive; the visible material comes from the new stone source.
    rebuild("herreria_v1_muro_norte.png", "herreria_v3_muro_norte.png", 128)
    rebuild("herreria_v1_muro_oeste.png", "herreria_v3_muro_oeste.png", 128, True)
    rebuild("herreria_v1_muro_esquina.png", "herreria_v3_muro_esquina.png", 128)
    rebuild("herreria_v1_muro_borde_pilar.png", "herreria_v3_muro_borde_pilar.png", 128)
    print("Muros V3 reconstruidos con siluetas de encaje y textura nueva.")


if __name__ == "__main__":
    main()
