# Isla del Ahogado

Andamiaje de un juego de gestión y aventura con humor negro, ambientado en
una isla pirata maldita. Esta entrega contiene la base jugable top-down:
autoloads, configuración de proyecto, controles abstractos, una escena de
mundo top-down y exportación Web.

## Estado de publicación

GitHub Pages: https://checoracso-spec.github.io/isla-del-ahogado./

El workflow de GitHub Actions exporta el preset `Web` y publica `build/web` en
GitHub Pages en cada push a `main`. GitHub Pages sirve los artefactos Web con
gzip; el preset mantiene el build compatible con móviles y la compresión del
servidor queda activada en producción.

## Ejecutar localmente

1. Instala Godot 4.x.
2. Importa esta carpeta (`isla-del-ahogado/`) en el Project Manager.
3. Ejecuta el proyecto con F6/F5 o desde la línea de comandos:

```bash
godot --editor --path isla-del-ahogado
godot --headless --path isla-del-ahogado --quit
```

La escena de entrada muestra un menú principal. `Jugar` abre una cuadrícula de
prueba top-down de 32x32 con un pirata jugable y una botella de ron
recolectable. WASD mueve en ocho direcciones; el clic izquierdo
mueve/interactúa en escritorio. El joystick y
el botón táctil se muestran en Web o en dispositivos móviles; no se renderizan
en escritorio nativo.

La tecla `E` o el clic cercano interactúa, `I` abre el inventario, `J` abre el
diario de misiones, `Q` duerme y `Esc` pausa. Los ajustes permiten cambiar el
volumen, el tamaño de texto y mostrar controles táctiles en escritorio; se
guardan en la configuración del usuario. Los NPC con `!` tienen una misión
disponible; `?` indica una misión activa y `✓` una misión completada.

La dirección de arte y el balance están documentados en
[`DESIGN_ART.md`](DESIGN_ART.md) y [`BALANCE.md`](BALANCE.md).

## Secuencia de 6 prompts

- [x] Prompt 1 — estructura y andamiaje completo.
- [x] Prompt 2 — jugador, movimiento, interacción, energía, reloj e inventario.
- [x] Prompt 3 — los 14 sistemas superficiales de contenido.
- [x] Prompt 4 — diálogos, misiones y contenido narrativo.
- [x] Prompt 5 — diseño visual, UI/UX, accesibilidad y balance.
- [ ] Prompt 6 — El Abismo, pulido, pruebas y publicación final.
