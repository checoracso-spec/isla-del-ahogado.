class_name TransicionGlobal
extends Interactuable
## Punto de embarque de una zona remota.
##
## Sólo solicita el viaje al autoload de estrategia. No mueve al jugador ni
## conoce la escena que representa el destino; `Mundo` reacciona a la señal de
## llegada y decide qué zona visual activar.

signal viaje_solicitado(transicion: Node, quien: Node)

var ruta_id: String = ""
var casilla_propia: Vector2i = Vector2i.ZERO

func _ready() -> void:
	alcance = 1.8
	super()
	queue_redraw()

func texto_accion() -> String:
	var ruta: Resource = MapaGlobal.ruta(ruta_id)
	if ruta == null:
		return "Embarcar"
	var destino: Resource = BaseDeDatos.destino(str(ruta.destino))
	return "Zarpar a %s" % (destino.nombre if destino != null else ruta.destino)

func disponible(_quien: Node) -> bool:
	var ruta: Resource = MapaGlobal.ruta(ruta_id)
	return ruta != null and not MapaGlobal.viajando() \
		and str(ruta.origen) == MapaGlobal.ubicacion_actual

func interactuar(quien: Node) -> void:
	if disponible(quien):
		viaje_solicitado.emit(self, quien)

func casilla() -> Vector2i:
	return casilla_propia

func _draw() -> void:
	var centro := Vector2.ZERO
	var pts := PackedVector2Array([
		centro + Vector2(0, -Iso.MEDIO_Y * 0.55),
		centro + Vector2(Iso.MEDIO_X * 0.55, 0),
		centro + Vector2(0, Iso.MEDIO_Y * 0.55),
		centro + Vector2(-Iso.MEDIO_X * 0.55, 0),
	])
	draw_colored_polygon(pts, GlobalColors.con_alpha("oro_llama", 0.72))
	draw_polyline(pts + PackedVector2Array([pts[0]]),
		GlobalColors.get_color_seleccion(), 1.0)
