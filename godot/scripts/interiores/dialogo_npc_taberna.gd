class_name DialogoNpcTaberna
extends Interactuable
## Diálogo mínimo del NPC de la taberna.
##
## El nodo vive como hijo del Pirata existente, por lo que conserva la
## detección [E] de Interactuable y se mueve con el NPC al entrar en la
## taberna. El estado de la misión sigue siendo propiedad de Misiones.

const MISION_ID := "marea_009_naufragio"

signal dialogo_mostrado(texto: String)

func _ready() -> void:
	alcance = 1.6
	super()
	var definicion := BaseDeDatos.mision(MISION_ID)
	if definicion == null:
		push_error("No existe la definición de misión '%s'." % MISION_ID)
		return
	if not Misiones.ids().has(MISION_ID):
		Misiones.registrar(MISION_ID)
	if Misiones.objetivo_item(MISION_ID).is_empty():
		Misiones.registrar_objetivo_item(MISION_ID,
			definicion.objetivo_item_id, definicion.objetivo_cantidad)

func texto_accion() -> String:
	match Misiones.estado(MISION_ID):
		Misiones.QuestState.AVAILABLE:
			return "Hablar con Calico Jack · Encargo"
		Misiones.QuestState.OBJECTIVE_COMPLETE:
			return "Hablar con Calico Jack · Entregar"
		_:
			return "Hablar con Calico Jack"

func interactuar(_quien: Node) -> void:
	match Misiones.estado(MISION_ID):
		Misiones.QuestState.AVAILABLE:
			if Misiones.aceptar(MISION_ID):
				_dialogar("Calico Jack: Trae dos maderos de naufragio y hablamos.")
		Misiones.QuestState.ACCEPTED:
			_dialogar("Calico Jack: La marea sigue trayendo madera. No tardes.")
		Misiones.QuestState.OBJECTIVE_COMPLETE:
			if Misiones.entregar(MISION_ID):
				var definicion := BaseDeDatos.mision(MISION_ID)
				var recompensa := definicion.recompensa_doblones if definicion != null else 0
				Bolsa.ingresar(recompensa)
				_dialogar("Calico Jack: Buen trabajo. Aquí tienes %d doblones." % recompensa)
		Misiones.QuestState.TURNED_IN:
			_dialogar("Calico Jack: Que corra el ron, compañero.")

## El componente es hijo del Pirata, así que su posición local no representa
## la casilla del NPC. Reutiliza la misma búsqueda de objetivos del jugador.
func distancia_interaccion(pos_tile: Vector2) -> float:
	var npc := get_parent() as Actor
	return pos_tile.distance_to(npc.pos_tile) if npc != null else super(pos_tile)

func _dialogar(texto: String) -> void:
	dialogo_mostrado.emit(texto)
