# Paleta maestra — Marea y Ceniza

Fuente externa del contrato implementado por el Autoload `GlobalColors`.
Los PNG pueden reemplazarse sin modificar la lógica, pero todo color generado
por código, UI o parámetros enviados a shaders debe partir de esta tabla.

## Reglas

- Luz global desde arriba-izquierda: `Vector2(-1, -1)`.
- `#ff00ff` se reserva al chroma-key temporal. Nunca se renderiza en el juego.
- Nunca se renderiza negro puro `#000000`.
- El vacío, contornos y sombras máximas usan `#0f0f1b`.
- Selección usa un borde blanco de 1 píxel.
- El blanco puro queda reservado para selección, no para fuego ni salitre.
- Los archivos finales usan transparencia alfa; no conservan el fondo chroma.

## Colores

| Nombre | Hex |
|---|---|
| vacio_abismal | `#0f0f1b` |
| azul_noche | `#162038` |
| gris_oscuro | `#252536` |
| marron_profundo | `#291814` |
| gris_base | `#3d3d52` |
| gris_claro | `#5e5e73` |
| acero_gris | `#8b8b9e` |
| plata_salitre | `#c2c2d1` |
| madera_oscura | `#42241c` |
| madera_base | `#663b2a` |
| madera_clara | `#8f5c3b` |
| arena_madera | `#c48d5f` |
| rojo_sangre | `#4a1528` |
| rojo_calido | `#822633` |
| rojo_brillante | `#bd403a` |
| naranja_fuego | `#e87a41` |
| oro_llama | `#f5c051` |
| luz_palida | `#fff3b5` |
| blanco_puro | `#ffffff` |
| oceano_sombra | `#264063` |
| azul_base | `#3a6b8f` |
| cian_magico | `#5cb2b5` |
| espuma_marina | `#98e0d5` |
| verde_abisal | `#183028` |
| verde_base | `#2c543b` |
| verde_claro | `#4a804d` |
| verde_brillo | `#82b06b` |
| verde_toxico | `#a8ca58` |
| piel_sombra | `#593e47` |
| piel_oscura | `#8c5d62` |
| piel_base | `#c98a82` |
| piel_brillo | `#ebb3a4` |

## Reservas de interfaz

| Uso | Color |
|---|---|
| Salud | rojo_brillante `#bd403a` |
| Estamina | verde_claro `#4a804d` |
| Energía alternativa / rareza | cian_magico `#5cb2b5` |
| Interacción | oro_llama `#f5c051` |
| Peligro | naranja_fuego `#e87a41` |
| Estado alterado / veneno | verde_toxico `#a8ca58` |
| Selección | blanco_puro `#ffffff`, borde de 1 px |
