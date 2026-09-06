# Editor de interiores

El editor se ejecuta con `res://escenas/prueba_editor_layout.tscn`. Es una
herramienta de desarrollo: modifica el layout JSON del interior de prueba y
no altera `Iso`, `Almacen`, inventarios ni la definición compartida de la
base de datos.

## Flujo recomendado

1. Edita primero en modo `BASE`: suelos, muros, bordes y tamaño de la sala.
2. Usa `VALIDAR BASE → EDITAR OBJETOS` cuando el perímetro esté correcto.
3. En modo `OBJETOS`, coloca muebles, estaciones y transiciones.
4. Pulsa `VALIDAR` antes de guardar.
5. Guarda con `Ctrl+S`. El guardado anterior queda automáticamente en
   `interior_herreria_pb_layout.json.bak`.

## Controles

| Control | Acción |
|---|---|
| Clic izquierdo | Seleccionar, arrastrar o confirmar una colocación |
| Clic derecho | Marco de selección múltiple; en colocación, región de copias |
| Rueda | Zoom de la sala o de la referencia según el panel bajo el cursor |
| Botón central | Desplazar la sala o la referencia |
| Flechas | Mover 1 píxel |
| `Alt` + flechas | Mover media baldosa |
| `Shift` + flechas | Mover 8 píxeles |
| `Ctrl` + flechas | Mover una baldosa |
| `R` / `F` | Espejo horizontal / vertical |
| `I` / `K` | Mostrar calibrador / restaurar calibración |
| `N` | Ciclar ajuste: libre, píxel, subrejilla 2×2, media baldosa, baldosa |
| `Ctrl+C/V` | Copiar / pegar selección |
| `Ctrl+D` | Duplicar selección con separación segura |
| `Ctrl+Shift+H/V` | Alinear selección en X / Y |
| `Ctrl+Shift+S/O` | Guardar / cargar plantilla del interior |
| `Ctrl+S/O` | Guardar / cargar layout |
| `Ctrl+Z/Y` | Deshacer / rehacer |
| `Delete` | Ocultar los elementos editables seleccionados |
| `F5` | Vista limpia |
| `B` | Activar o salir del modo de colocación |

## Protección contra errores

- `BLOQUEAR BASE` impide mover, borrar o reemplazar suelos y muros.
- `BLOQUEAR OBJETOS` protege muebles y transiciones.
- Reemplazar un asset reutiliza el nodo existente; no crea stacking.
- Ocultar y restaurar conserva la identidad y la posición del elemento.
- `REST. BAK` recupera el último layout guardado antes del guardado actual.
- El validador marca fuera de sala, solapes de huella y transiciones sin
  destino; también marca muros separados de su ancla isométrica. Los
  problemas se dibujan en rojo sobre la escena.

## Assets y escalabilidad

La paleta se filtra escribiendo parte del nombre o de la clave del asset.
Las categorías separan muros, suelos, mobiliario y puertas/escaleras. La
selección de un asset desde la paleta lo deja listo para arrastrar a la sala;
la creación sigue siendo data-driven y usa el manifiesto existente.

Las plantillas son JSON planos en `res://data/desarrollador/plantillas`.
Guardan tamaño, assets, calibraciones, alturas, visibilidad y transiciones,
pero nunca referencias a nodos. Esto permite crear una sala aprobada y
reutilizarla como punto de partida para otro edificio sin duplicar sistemas.

Los valores de calibración, altura visual de muro, espejo, tamaño de sala,
transiciones y visibilidad se serializan en el layout. La huella lógica sigue
siendo independiente del tamaño del sprite, para que un asset grande no cree
una barrera invisible mayor que su colisión real.
