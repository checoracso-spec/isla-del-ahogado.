# Guía de dirección de arte

## Identidad

La isla se lee como un tablero top-down de pixel art: madera vieja, sal,
musgo y mar profundo. La interfaz usa paneles oscuros translúcidos con bordes
teal desgastados y texto crema. El dorado queda reservado para doblones,
rituales y acciones de progreso.

## Paleta fija

| Uso | Nombre | Hex |
| --- | --- | --- |
| Tinta y fondo de UI | Ink | `#142329` |
| Piso marino | Sea slate | `#263D46` |
| Piso alterno | Sea slate alt | `#2D4850` |
| Bordes y resaltado | Weathered teal | `#527176` |
| Madera vieja | Old wood | `#6B4A35` |
| Madera iluminada | Wood highlight | `#8A6147` |
| Musgo y naturaleza | Moss | `#526B43` |
| Mar profundo | Deep sea | `#1B3B46` |
| Abismo | Abyss dark | `#0E2933` |
| Doblones y ritual | Ritual gold | `#D6A24A` |
| Texto secundario | Cream | `#F4D38C` |
| Texto principal | Text | `#FFE4C7` |
| Peligro/interacción | Danger | `#E4A18F` |
| Éxito/completado | Success | `#9BE6AF` |

Los tokens están centralizados en `scripts/ui/style_tokens.gd`. El contraste
de texto se mantiene con texto claro sobre paneles `Ink`/`Abyss dark`; los
estados importantes también escriben su estado (`ACTIVA`, `COMPLETADA`, etc.)
y no dependen únicamente del color.

## Geometría y profundidad

- La vista es top-down y el tile de referencia es cuadrado de **32x32 px**.
- `GroundLayer` y `CharactersAndObjects` mantienen `y_sort_enabled=true`.
- Los assets futuros deben tener su origen en el centro inferior: el punto de
  apoyo toca el suelo y los objetos más bajos se dibujan delante.
- Los placeholders respetan múltiplos de 32 siempre que sea posible.

## Iconografía

Cada categoría usa una silueta simple, legible a 16–24 px y con etiqueta de
texto cuando el estado importe:

- Recursos: bloque cuadrado con una muesca o veta.
- Herramientas: diagonal sobre un bloque, con contorno claro.
- Misiones: rombo o signo `!`, `?` y `✓` según el estado.
- Sistemas/estaciones: panel redondeado con un símbolo central.
- Ritual y economía: dorado, reservado para doblones, fe y progreso.

La geometría es deliberadamente mecánica para poder reemplazar cada
placeholder por pixel art final sin cambiar tamaños, anclajes ni lógica de UI.
