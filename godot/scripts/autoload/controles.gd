extends Node
## AUTOLOAD: Controles
##
## Registra las acciones de entrada por código en vez de a mano en
## project.godot. Ese archivo guarda cada tecla como un objeto serializado
## larguísimo; un carácter mal puesto y el proyecto no abre. Aquí se lee, se
## cambia y se añade un mando sin miedo.

## Las flechas están deliberadamente LIBRES. Antes movían al jugador y a la
## cámara a la vez, y como el reenganche de la cámara mira `eje_movimiento()`,
## intentar mover la vista con ellas devolvía la cámara al personaje.
## Quedan reservadas para el modo de cámara libre, cuando exista.
const ACCIONES := {
	"mover_arriba":    [KEY_W],
	"mover_abajo":     [KEY_S],
	"mover_izquierda": [KEY_A],
	"mover_derecha":   [KEY_D],
	"interactuar":     [KEY_E, KEY_ENTER],
	"correr":          [KEY_SHIFT],
	"pausa":           [KEY_SPACE],
	"inventario":      [KEY_I, KEY_TAB],
	"guardar_rapido":  [KEY_F5],
	"cargar_rapido":   [KEY_F9],
}

func _ready() -> void:
	for accion in ACCIONES:
		if not InputMap.has_action(accion):
			InputMap.add_action(accion)
		for codigo in ACCIONES[accion]:
			var ev := InputEventKey.new()
			ev.physical_keycode = codigo
			InputMap.action_add_event(accion, ev)

## Vector de movimiento en coordenadas de PANTALLA (-1..1 en cada eje).
func eje_movimiento() -> Vector2:
	return Input.get_vector("mover_izquierda", "mover_derecha",
		"mover_arriba", "mover_abajo")

## El mismo vector, ya traducido a casillas isométricas.
## Pulsar "arriba" tiene que alejarte en diagonal, no subir en la rejilla.
func eje_movimiento_iso() -> Vector2:
	var e := eje_movimiento()
	if e == Vector2.ZERO:
		return Vector2.ZERO
	return Vector2(e.y + e.x * 0.5, e.y - e.x * 0.5).normalized()
