class_name DialogoNpcTaberna
extends Interactuable
## Diálogo mínimo del NPC de la taberna.
##
## El nodo vive como hijo del Pirata existente, por lo que conserva la
## detección [E] de Interactuable y se mueve con el NPC al entrar en la
## taberna. El estado de la misión sigue siendo propiedad de Misiones.

signal dialogo_mostrado(texto: String)

var mision_id: String = ""
var definicion: MisionData = null

func _init(p_mision_id: String = "", p_definicion: MisionData = null) -> void:
	mision_id = p_mision_id.strip_edges()
	definicion = p_definicion

func _ready() -> void:
	alcance = 1.6
	super()
	if definicion == null and not mision_id.is_empty():
		definicion = BaseDeDatos.mision(mision_id)
	# Compatibilidad con el MAREA-012 caller que construía el componente sin
	# argumentos. No fija una misión concreta: sólo usa la única definición
	# disponible mientras el contenido siga teniendo una sola misión.
	if definicion == null and mision_id.is_empty() and BaseDeDatos.misiones.size() == 1:
		definicion = BaseDeDatos.misiones.values()[0]
	if definicion == null:
		push_error("No existe la definición de misión '%s'." % mision_id)
		return
	mision_id = definicion.id
	if mision_id.is_empty():
		push_error("La definición de misión no tiene id.")
		return
	if not Misiones.ids().has(mision_id):
		Misiones.registrar(mision_id)
	if Misiones.objetivo_item(mision_id).is_empty():
		Misiones.registrar_objetivo_item(mision_id,
			definicion.objetivo_item_id, definicion.objetivo_cantidad)

func texto_accion() -> String:
	match Misiones.estado(mision_id):
		Misiones.QuestState.AVAILABLE:
			if not Misiones.puede_aceptar(mision_id):
				return "Hablar con %s · Encargo bloqueado" % _nombre_npc()
			return "Hablar con %s · Encargo" % _nombre_npc()
		Misiones.QuestState.OBJECTIVE_COMPLETE:
			return "Hablar con %s · Entregar" % _nombre_npc()
		_:
			return "Hablar con %s" % _nombre_npc()

func interactuar(_quien: Node) -> void:
	match Misiones.estado(mision_id):
		Misiones.QuestState.AVAILABLE:
			if not Misiones.puede_aceptar(mision_id):
				_dialogar(_texto_requisito())
				return
			if Misiones.aceptar(mision_id):
				_dialogar(definicion.dialogo_aceptacion)
		Misiones.QuestState.ACCEPTED:
			_dialogar(definicion.dialogo_progreso)
		Misiones.QuestState.OBJECTIVE_COMPLETE:
			if Misiones.entregar(mision_id):
				var recompensa := definicion.recompensa_doblones
				Bolsa.ingresar(recompensa)
				_dialogar(definicion.dialogo_entrega % recompensa)
		Misiones.QuestState.TURNED_IN:
			_dialogar(definicion.dialogo_completada)

## El componente es hijo del Pirata, así que su posición local no representa
## la casilla del NPC. Reutiliza la misma búsqueda de objetivos del jugador.
func distancia_interaccion(pos_tile: Vector2) -> float:
	var npc := get_parent() as Actor
	return pos_tile.distance_to(npc.pos_tile) if npc != null else super(pos_tile)

func _nombre_npc() -> String:
	var pirata := get_parent() as Pirata
	if pirata != null and not pirata.nombre_mostrado.is_empty():
		return pirata.nombre_mostrado
	if definicion != null and not definicion.npc_id.is_empty():
		var datos := BaseDeDatos.personaje(definicion.npc_id)
		if datos != null:
			return datos.nombre
	return "NPC"

func _texto_requisito() -> String:
	if definicion == null or definicion.requisito_mision_id.is_empty():
		return "Este encargo todavía no está disponible."
	var requisito: MisionData = BaseDeDatos.mision(definicion.requisito_mision_id)
	if requisito == null:
		return "Este encargo todavía no está disponible."
	var npc_requisito: PersonajeData = BaseDeDatos.personaje(requisito.npc_id)
	var nombre_requisito := npc_requisito.nombre if npc_requisito != null else "el otro tabernero"
	return "Primero completa el encargo de %s: %s." % [nombre_requisito, requisito.nombre]

func _dialogar(texto: String) -> void:
	if texto.is_empty():
		return
	dialogo_mostrado.emit("%s: %s" % [_nombre_npc(), texto])
