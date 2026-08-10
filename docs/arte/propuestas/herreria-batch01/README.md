# Herrería — Batch 01

Primer lote artístico integrado el 9 de agosto de 2026 mediante la herramienta
de generación de imágenes integrada de Codex y procesamiento local a pixel art
lógico ×2.

## Contrato

| Asset | Físico | Lógico | Pivote | Huella |
|---|---:|---:|---:|---:|
| Suelo de piedra, atlas de dos celdas | 256×64 | 128×32 | — | 1×1 por celda |
| Muro norte | 128×112 | 64×56 | 64,96 | 1×1 |
| Muro oeste | 128×112 | 64×56 | 64,96 | 1×1 |
| Fragua | 192×256 | 96×128 | 96,240 | 2×1 |

## Prompts finales

- **Suelo:** dos rombos isométricos de basalto, uno base y otro desgastado,
  juntas `vacio_abismal`, salitre `plata_salitre`, luz arriba-izquierda.
- **Muro norte:** segmento modular bajo de mampostería basáltica, hollín arriba,
  salitre abajo, sin adornos únicos.
- **Muro oeste:** segmento modular bajo de caoba oscura, vigas simples, sin
  ventanas ni huecos.
- **Fragua:** media caldera naval abollada sobre huella 2×1, brasas sin llamas
  altas, núcleo `luz_palida`, metal naval oscuro.

Todos se generaron sobre chroma temporal `#ff00ff`; los PNG procesados y los
archivos integrados usan transparencia alfa. No se utiliza negro puro.

## Archivos

- `*-fuente-magenta.png`: salida original, conservada para reprocesar.
- `*-procesado.png`: versión ajustada al manifiesto.
- Los cuatro archivos activos viven en
  `godot/assets/kit_validacion/interiores/arte/herreria/`.

El suelo se procesa con `tools/procesar_atlas_suelo.ps1`; muros y objetos con
`tools/procesar_objeto_isometrico.ps1`.
