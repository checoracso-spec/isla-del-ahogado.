class_name Zona
extends Node2D
## Un espacio jugable: la isla, el interior de una casa, la cubierta de un barco.
##
## La idea que evita construir tres sistemas distintos. Todo lo que necesita un
## actor para vivir en algún sitio está aquí y sólo aquí:
##
##   · dónde se puede pisar        -> transitable
##   · dónde van los personajes    -> actores (ordenado por profundidad)
##   · hasta dónde llega           -> limites()
##   · por dónde se entra          -> entrada()
##
## De momento sólo heredan los interiores. El exterior (`mundo.gd`) todavía no
## es una Zona formal —expone las mismas tres cosas por su cuenta— y pasará a
## serlo cuando toque partirlo, no antes: mover eso ahora rompería el mapa sin
## ganar nada hoy.

var id: String = ""
var identidad_zona: Identidad = null
var transitable: Transitable = null
var actores: Node2D = null
var estado_guardable: Dictionary = {}

func _ready() -> void:
	if actores == null:
		actores = Node2D.new()
		actores.name = "Actores"
		actores.y_sort_enabled = true
		add_child(actores)

func limites() -> Rect2i:
	return transitable.limites() if transitable != null else Rect2i()

func montar_identidad(definicion_id: String, clave_natural: String) -> void:
	identidad_zona = Entidades.identificar("zona", definicion_id, clave_natural)
	Entidades.vincular(identidad_zona, self)

func serializar_zona() -> Dictionary:
	return {
		"id": id,
		"identidad": identidad_zona.serializar() if identidad_zona != null else {},
		"limites": {"x": limites().size.x, "y": limites().size.y},
		"estado": estado_guardable.duplicate(true),
	}

func cargar_zona(datos: Dictionary) -> void:
	estado_guardable = (datos.get("estado", {}) as Dictionary).duplicate(true)

## Dónde aparece alguien que llega sin más indicaciones.
func entrada() -> Vector2:
	var r := limites()
	return Vector2(r.position) + Vector2(r.size) * 0.5

## Mete un actor en esta zona: lo saca de donde estuviera, lo cuelga aquí y le
## cambia la transitabilidad. Es la única forma correcta de mover a alguien
## entre espacios.
func recibir(actor: Actor, en: Vector2) -> void:
	if actor == null:
		return
	if actor.get_parent() != actores:
		if actor.get_parent() != null:
			actor.reparent(actores, false)
		else:
			actores.add_child(actor)
	actor.transitable = transitable
	actor.colocar_seguro(en)

func activar() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT

func desactivar() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
