class_name ZonaRemota
extends Zona
## Zona provisional para una ciudad o isla que aún no tiene escena artística.
##
## Sirve para validar el contrato común: límites, transitabilidad, actores y
## entrada. Cuando llegue el mapa real, se reemplaza sólo esta construcción.

const COLOR_SUELO := Color("3d5b4a")
const COLOR_SUELO_ALT := Color("4d6c52")
const COLOR_CAMINO := Color("8f6b4b")
const TransicionGlobalScript := preload("res://scripts/mapa/transicion_global.gd")

var destino_id: String = ""
var ancho: int = 1
var alto: int = 1
var transiciones: Array = []

func construir(p_destino_id: String, p_ancho: int = 16, p_alto: int = 12) -> void:
	destino_id = p_destino_id
	id = p_destino_id
	ancho = maxi(4, p_ancho)
	alto = maxi(4, p_alto)
	name = "Zona_" + destino_id
	transitable = TransitableRejilla.new(ancho, alto)
	transitable.amurallar()
	# Un acceso abierto en el borde representa el puerto o camino de llegada.
	var entrada_borde := Vector2i(ancho / 2, alto - 1)
	transitable.liberar(entrada_borde)
	queue_redraw()

func entrada() -> Vector2:
	return Vector2(ancho / 2, alto - 2) + Vector2(0.5, 0.5)

## Añade un único punto de embarque para una ruta data-driven. El destino
## remoto puede tener una ruta de regreso o una conexión posterior sin que la
## zona necesite conocer la escena que la contiene.
func montar_transicion(ruta_id: String) -> Node:
	if actores == null:
		actores = Node2D.new()
		actores.name = "Actores"
		actores.y_sort_enabled = true
		add_child(actores)
	var ruta: Resource = MapaGlobal.ruta(ruta_id)
	if ruta == null:
		return null
	var t: Node = TransicionGlobalScript.new()
	t.name = "Embarque_" + ruta_id
	t.ruta_id = ruta_id
	t.casilla_propia = Vector2i(ancho / 2, alto - 2)
	t.position = Iso.centro_v(t.casilla_propia)
	actores.add_child(t)
	transiciones.append(t)
	return t

func _draw() -> void:
	for y in range(alto):
		for x in range(ancho):
			var centro := Iso.centro(x, y)
			var color := COLOR_SUELO if (x + y) % 2 == 0 else COLOR_SUELO_ALT
			if x == ancho / 2 or y == alto / 2:
				color = COLOR_CAMINO
			draw_colored_polygon(PackedVector2Array([
				centro + Vector2(0, -Iso.MEDIO_Y),
				centro + Vector2(Iso.MEDIO_X, 0),
				centro + Vector2(0, Iso.MEDIO_Y),
				centro + Vector2(-Iso.MEDIO_X, 0),
			]), color)
