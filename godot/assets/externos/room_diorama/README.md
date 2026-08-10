# Biblioteca externa: Isometric Pixel-Art Room Diorama Tileset

Fuente original: https://announcerua.itch.io/isometric-pixel-art-room-diorama-tileset
Autor indicado en la página: Devs In Exile Studio.

El pack se distribuye en la página como un asset pack gratuito y contiene 67
dioramas isométricos de interiores y edificios. Se conserva aquí como arte
externo opcional; los sistemas del juego no dependen de estos PNG.

## Estado de integración

- Importado sin sobrescribir `assets/tiles`, `assets/edificios` ni `assets/kit_validacion`.
- Las imágenes originales son de 302×256 píxeles.
- Todavía no forman parte del manifiesto principal porque el mundo usa una
  rejilla lógica de 128×64 y cada pieza necesita un pivote y una huella
  declarados antes de entrar en una escena jugable.
- El siguiente paso artístico será seleccionar una imagen de herrería,
  taberna o almacén, medir su anclaje y montarla como `asset_exterior` o como
  referencia visual, sin acoplarla a la lógica.

La primera selección es la clave `herreria_ref`, que apunta a
`isometricroomtileset (60).png`. Se puede ver con
`res://escenas/galeria_diorama.tscn`; la ruta está aislada en
`scripts/autoload/dioramas_externos.gd`.

Además, el catálogo descubre automáticamente los 67 PNG como `pack_01` a
`pack_67`, ordenados por nombre de archivo. Estas claves sirven para galerías
y futuras revisiones artísticas; no se registran todavía como piezas
jugables de 128×64.

La galería monta la imagen mediante `scripts/visual/diorama_preview.gd`.
Ese componente recibe una clave del catálogo y aplica el filtro Nearest,
pero no crea colisiones, transitabilidad ni estado de guardado.

Para comparar el arte con el interior que realmente usa el juego, ejecutar
`res://escenas/comparador_herreria.tscn`. La escena monta ambos lados sin
modificar `mundo.tscn`.

No modificar los nombres originales hasta completar esa validación.
