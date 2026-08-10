class_name FuenteRecurso
extends Interactuable
const FuenteRecursoDataScript := preload("res://scripts/datos/fuente_recurso_data.gd")
## Una fuente física del mundo: restos, árbol, veta o futura parcela.
##
## La instancia sólo contiene identidad y presentación. La cantidad viva la
## administra RecursosMundo, para que el nodo pueda desaparecer y reaparecer
## sin perder el estado.

signal recolectado(fuente: Node, ciclos: int, productos: Dictionary)

var definicion_id: String = ""
var identidad: Identidad = null
var casilla_pos: Vector2i = Vector2i.ZERO

func montar(p_definicion_id: String, clave_natural: String, casilla: Vector2i) -> bool:
	var def := BaseDeDatos.fuente(p_definicion_id)
	if def == null:
		push_warning("FuenteRecurso: definición inexistente '%s'" % p_definicion_id)
		return false
	definicion_id = p_definicion_id
	casilla_pos = casilla
	identidad = Entidades.identificar("recurso", definicion_id, clave_natural)
	Entidades.vincular(identidad, self)
	name = "Recurso_%s_%s" % [definicion_id, identidad.instancia]
	position = Iso.centro_v(casilla)
	RecursosMundo.registrar(self)
	queue_redraw()
	return true

func definicion() -> Resource:
	return BaseDeDatos.fuente(definicion_id)

func cantidad() -> int:
	return RecursosMundo.cantidad(identidad.instancia if identidad != null else "")

func disponible(_quien: Node) -> bool:
	return cantidad() > 0

func texto_accion() -> String:
	var def := definicion()
	if cantidad() <= 0:
		return "Agotado"
	return "Recolectar %s" % (def.nombre if def != null else definicion_id)

func interactuar(quien: Node) -> void:
	if quien == null or not quien.has_method("inventario"):
		return
	var destino: Inventario = quien.inventario()
	var resultado := recolectar(destino)
	if int(resultado.get("ciclos", 0)) > 0:
		recolectado.emit(self, int(resultado["ciclos"]), resultado["productos"])

## Punto de entrada común para jugadores, NPCs y animales recolectores.
func recolectar(destino: Inventario, ciclos: int = 1) -> Dictionary:
	if identidad == null or destino == null:
		return {"ciclos": 0, "productos": {}}
	return RecursosMundo.recolectar(identidad.instancia, destino, ciclos)

func casilla() -> Vector2i:
	return casilla_pos

func _draw() -> void:
	var color := Color("8f5c3b") if cantidad() > 0 else Color("3d3d52")
	draw_circle(Vector2(0, -10), 9.0, color)
	draw_line(Vector2(-8, 0), Vector2(8, 0), Color("c48d5f"), 2.0)
