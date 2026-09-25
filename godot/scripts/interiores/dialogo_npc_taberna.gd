class_name DialogoNpcTaberna
extends Interactuable
## Diálogo mínimo del NPC de la taberna.
##
## El nodo vive como hijo del Pirata existente, por lo que conserva la
## detección [E] de Interactuable y se mueve con el NPC al entrar en la
## taberna. El estado de la misión sigue siendo propiedad de Misiones.

signal dialogo_mostrado(texto: String)

const CENTRO_MARCADOR := Vector2(0.0, -76.0)
const FONDO_MARCADOR := Color("171b24")

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
	Misiones.estado_cambiado.connect(_al_cambiar_estado_mision)
	queue_redraw()

## El marcador es una vista derivada: nunca guarda estado propio ni altera la
## posición lógica (pies) del NPC.
func estado_marcador() -> String:
	if definicion == null or not Misiones.ids().has(mision_id):
		return "oculto"
	match Misiones.estado(mision_id):
		Misiones.QuestState.AVAILABLE:
			return "disponible" if Misiones.puede_aceptar(mision_id) else "bloqueada"
		Misiones.QuestState.OBJECTIVE_COMPLETE:
			return "entrega"
		_:
			return "oculto"

func _al_cambiar_estado_mision(_id: String, _estado: int) -> void:
	# Una misión puede desbloquear a otro NPC, por eso se refresca ante cualquier
	# transición global y no sólo cuando cambia mision_id.
	queue_redraw()

func _draw() -> void:
	var estado := estado_marcador()
	if estado == "oculto":
		return
	var acento := Color("e8bd63") if estado == "disponible" else Color("82d8c5")
	if estado == "bloqueada":
		acento = Color("aab0b8")
	draw_circle(CENTRO_MARCADOR, 10.0, FONDO_MARCADOR)
	draw_arc(CENTRO_MARCADOR, 9.0, 0.0, TAU, 32, acento, 1.5, true)
	match estado:
		"disponible":
			draw_string(ThemeDB.fallback_font, CENTRO_MARCADOR + Vector2(-3.3, 5.0),
				"!", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, acento)
		"bloqueada":
			# Candado geométrico: evita depender de glifos de fuentes externas.
			draw_arc(CENTRO_MARCADOR + Vector2(0.0, -2.0), 3.0,
				PI, TAU, 12, acento, 1.7, true)
			draw_rect(Rect2(CENTRO_MARCADOR + Vector2(-4.0, -1.0), Vector2(8.0, 7.0)),
				acento, true)
			draw_circle(CENTRO_MARCADOR + Vector2(0.0, 2.0), 0.8, FONDO_MARCADOR)
		"entrega":
			draw_line(CENTRO_MARCADOR + Vector2(-4.0, 0.0),
				CENTRO_MARCADOR + Vector2(-1.0, 3.0), acento, 2.2, true)
			draw_line(CENTRO_MARCADOR + Vector2(-1.0, 3.0),
				CENTRO_MARCADOR + Vector2(4.5, -3.0), acento, 2.2, true)

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
