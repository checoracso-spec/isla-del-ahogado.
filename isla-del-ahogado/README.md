# Isla del Ahogado

Andamiaje de un juego de gestión y aventura con humor negro, ambientado en
una isla pirata maldita. Esta entrega contiene la base jugable top-down:
autoloads, configuración de proyecto, controles abstractos, una escena de
mundo top-down y exportación Web.

## Estado de publicación

GitHub Pages: pendiente de publicar desde el repositorio remoto. Cuando el
repositorio tenga un nombre y usuario de GitHub, el enlace será:
`https://<usuario>.github.io/<repositorio>/`

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

La escena inicial muestra una cuadrícula de prueba top-down de 32x32 con un
pirata jugable y una botella de ron recolectable. WASD mueve en ocho
direcciones; el clic izquierdo mueve/interactúa en escritorio. El joystick y
el botón táctil se muestran en Web o en dispositivos móviles; no se renderizan
en escritorio nativo.

La tecla `E` o el clic cercano interactúa, `I` abre el inventario, `Q` duerme y
`Esc` pausa. Interactuar con la botella consume energía y la añade al
inventario. Dormir restaura la energía y avanza al día siguiente.

## Secuencia de 6 prompts

- [x] Prompt 1 — estructura y andamiaje completo.
- [x] Prompt 2 — jugador, movimiento, interacción, energía, reloj e inventario.
- [ ] Prompt 3 — estaciones, inventario y economía.
- [ ] Prompt 4 — diálogos, misiones y contenido narrativo.
- [ ] Prompt 5 — cementerio, fe, tecnología y taberna.
- [ ] Prompt 6 — El Abismo, pulido, pruebas y publicación final.
