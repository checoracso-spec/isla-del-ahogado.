#!/usr/bin/env python3
"""Pipeline seguro para validar y preparar assets PNG de Marea y Ceniza.

Por defecto solo lee el proyecto y escribe informes/previews en docs/assets_pipeline.
El comando normalize trabaja sobre una carpeta de entrada y otra de salida; nunca
sobrescribe assets existentes salvo que se solicite explícitamente.
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Iterable

from PIL import Image, ImageDraw


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT = PROJECT_ROOT / "assets" / "kit_validacion"
DEFAULT_MANIFEST = DEFAULT_INPUT / "manifiesto.json"
DEFAULT_OUTPUT = PROJECT_ROOT / "docs" / "assets_pipeline"
MAGENTA = (255, 0, 255)
PURE_BLACK = (0, 0, 0)
EMPTY_COLOR = (15, 15, 27)


@dataclass
class AssetResult:
    file: str
    width: int
    height: int
    mode: str
    alpha: bool
    opaque_pixels: int
    magenta_pixels: int
    black_pixels: int
    warnings: list[str]
    errors: list[str]

    @property
    def ok(self) -> bool:
        return not self.errors


def png_files(root: Path) -> Iterable[Path]:
    if not root.exists():
        return []
    return sorted(path for path in root.rglob("*.png") if path.is_file())


def read_manifest(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    return value if isinstance(value, dict) else {}


def manifest_by_file(manifest: dict[str, Any]) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    assets = manifest.get("assets", {})
    if not isinstance(assets, dict):
        return result
    for asset_id, definition in assets.items():
        if not isinstance(definition, dict):
            continue
        file_name = definition.get("archivo")
        if isinstance(file_name, str):
            result[file_name.replace("\\", "/")] = {
                "id": asset_id,
                "definition": definition,
            }
    return result


def pixel_counts(image: Image.Image) -> tuple[int, int, int, int]:
    rgba = image.convert("RGBA")
    magenta = 0
    black = 0
    opaque = 0
    partial = 0
    for red, green, blue, alpha in rgba.getdata():
        if alpha == 0:
            continue
        opaque += 1
        if alpha < 255:
            partial += 1
        if (red, green, blue) == MAGENTA:
            magenta += 1
        if (red, green, blue) == PURE_BLACK:
            black += 1
    return opaque, partial, magenta, black


def validate_image(path: Path, root: Path, definition: dict[str, Any] | None) -> AssetResult:
    relative = path.relative_to(root).as_posix()
    warnings: list[str] = []
    errors: list[str] = []
    try:
        with Image.open(path) as source:
            image = source.convert("RGBA")
            width, height = image.size
            mode = source.mode
            has_alpha = "A" in source.getbands()
            opaque, partial, magenta, black = pixel_counts(image)
    except Exception as error:  # pragma: no cover - diagnostic guard
        return AssetResult(relative, 0, 0, "?", False, 0, 0, 0, [], [f"No se pudo leer: {error}"])

    if magenta:
        errors.append(f"contiene {magenta} píxeles magenta #ff00ff visibles")
    if black:
        warnings.append(f"contiene {black} píxeles negros opacos; revisar si son contorno intencional")
    if not has_alpha:
        warnings.append("no tiene canal alfa")
    if partial and magenta:
        errors.append("hay bordes semitransparentes contaminados de magenta")

    if definition is not None:
        expected = definition.get("tam_fisico")
        if isinstance(expected, list) and len(expected) == 2:
            expected_size = (int(expected[0]), int(expected[1]))
            if (width, height) != expected_size:
                errors.append(f"tamaño {width}x{height}; manifiesto exige {expected_size[0]}x{expected_size[1]}")
        scale = definition.get("escala_pixel")
        logical = definition.get("tam_logico")
        if isinstance(scale, int) and isinstance(logical, list) and len(logical) == 2:
            if (width, height) != (logical[0] * scale, logical[1] * scale):
                errors.append("tam_fisico no coincide con tam_logico × escala_pixel")
        pivot = definition.get("pivote")
        if pivot is not None and (not isinstance(pivot, list) or len(pivot) != 2):
            errors.append("pivote inválido; debe ser [x, y]")

    return AssetResult(relative, width, height, mode, has_alpha, opaque, magenta, black, warnings, errors)


def validate_command(args: argparse.Namespace) -> int:
    root = Path(args.input).resolve()
    manifest_path = Path(args.manifest).resolve()
    manifest = read_manifest(manifest_path)
    indexed = manifest_by_file(manifest)
    results: list[AssetResult] = []
    for path in png_files(root):
        relative = path.relative_to(root).as_posix()
        entry = indexed.get(relative)
        definition = entry["definition"] if entry else None
        results.append(validate_image(path, root, definition))

    manifest_missing: list[str] = []
    available = {result.file for result in results}
    for file_name in indexed:
        if file_name not in available:
            manifest_missing.append(file_name)

    errors = sum(len(result.errors) for result in results)
    warnings = sum(len(result.warnings) for result in results)
    report = {
        "version": 1,
        "input": str(root),
        "manifest": str(manifest_path),
        "summary": {
            "files": len(results),
            "errors": errors,
            "warnings": warnings,
            "manifest_missing_files": len(manifest_missing),
        },
        "assets": [asdict(result) for result in results],
        "manifest_missing_files": manifest_missing,
    }
    output = Path(args.report).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"Assets revisados: {len(results)}")
    print(f"Errores: {errors} | Advertencias: {warnings}")
    print(f"Informe: {output}")
    for result in results:
        for message in result.errors:
            print(f"ERROR  {result.file}: {message}")
        for message in result.warnings:
            print(f"AVISO  {result.file}: {message}")
    if manifest_missing:
        print(f"AVISO  {len(manifest_missing)} entradas del manifiesto no tienen PNG en la carpeta")
    return 1 if errors or (args.strict and warnings) else 0


def normalize_rgba(source: Image.Image, remove_magenta: bool, replace_black: bool) -> Image.Image:
    image = source.convert("RGBA")
    pixels: list[tuple[int, int, int, int]] = []
    for red, green, blue, alpha in image.getdata():
        if remove_magenta and alpha > 0 and red == 255 and green == 0 and blue == 255:
            pixels.append((0, 0, 0, 0))
        elif replace_black and alpha > 0 and red == 0 and green == 0 and blue == 0:
            pixels.append((*EMPTY_COLOR, alpha))
        else:
            pixels.append((red, green, blue, alpha))
    image.putdata(pixels)
    return image


def normalize_command(args: argparse.Namespace) -> int:
    source_root = Path(args.input).resolve()
    output_root = Path(args.output).resolve()
    if source_root == output_root:
        print("ERROR: input y output deben ser carpetas distintas; no se sobrescribe el original.")
        return 2
    files = list(png_files(source_root))
    output_root.mkdir(parents=True, exist_ok=True)
    for source_path in files:
        target = output_root / source_path.relative_to(source_root)
        target.parent.mkdir(parents=True, exist_ok=True)
        with Image.open(source_path) as image:
            normalized = normalize_rgba(image, args.remove_magenta, args.replace_black)
            normalized.save(target, "PNG", optimize=False)
    print(f"Copias normalizadas: {len(files)}")
    print(f"Salida: {output_root}")
    return 0


def sheet_command(args: argparse.Namespace) -> int:
    root = Path(args.input).resolve()
    output = Path(args.output).resolve()
    files = list(png_files(root))[: args.limit]
    if not files:
        print("No se encontraron PNGs.")
        return 1
    thumb_w, thumb_h = args.cell_width, args.cell_height
    columns = max(1, args.columns)
    rows = (len(files) + columns - 1) // columns
    sheet = Image.new("RGBA", (columns * thumb_w, rows * (thumb_h + 26)), (15, 15, 27, 255))
    draw = ImageDraw.Draw(sheet)
    for index, path in enumerate(files):
        with Image.open(path) as image:
            preview = image.convert("RGBA")
            preview.thumbnail((thumb_w - 12, thumb_h - 12), Image.Resampling.NEAREST)
            x = (index % columns) * thumb_w + (thumb_w - preview.width) // 2
            y = (index // columns) * (thumb_h + 26) + (thumb_h - preview.height) // 2
            sheet.alpha_composite(preview, (x, y))
        label = path.relative_to(root).as_posix()
        draw.text(((index % columns) * thumb_w + 4, (index // columns) * (thumb_h + 26) + thumb_h + 4), label[:42], fill=(255, 243, 181, 255))
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(output, "PNG", optimize=False)
    print(f"Hoja generada: {output} ({len(files)} assets)")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Pipeline de assets de Marea y Ceniza")
    subparsers = parser.add_subparsers(dest="command", required=True)

    validate = subparsers.add_parser("validate", help="valida PNGs y el manifiesto")
    validate.add_argument("--input", default=str(DEFAULT_INPUT))
    validate.add_argument("--manifest", default=str(DEFAULT_MANIFEST))
    validate.add_argument("--report", default=str(DEFAULT_OUTPUT / "asset_report.json"))
    validate.add_argument("--strict", action="store_true", help="trata advertencias como errores")
    validate.set_defaults(function=validate_command)

    normalize = subparsers.add_parser("normalize", help="crea copias RGBA normalizadas")
    normalize.add_argument("--input", default=str(DEFAULT_INPUT))
    normalize.add_argument("--output", default=str(DEFAULT_OUTPUT / "normalized"))
    normalize.add_argument("--remove-magenta", action="store_true")
    normalize.add_argument("--replace-black", action="store_true")
    normalize.set_defaults(function=normalize_command)

    sheet = subparsers.add_parser("sheet", help="crea una hoja de contacto")
    sheet.add_argument("--input", default=str(DEFAULT_INPUT))
    sheet.add_argument("--output", default=str(DEFAULT_OUTPUT / "contact_sheet.png"))
    sheet.add_argument("--columns", type=int, default=6)
    sheet.add_argument("--limit", type=int, default=120)
    sheet.add_argument("--cell-width", type=int, default=180)
    sheet.add_argument("--cell-height", type=int, default=140)
    sheet.set_defaults(function=sheet_command)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return int(args.function(args))


if __name__ == "__main__":
    sys.exit(main())
