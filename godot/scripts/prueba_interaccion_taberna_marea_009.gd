extends Node
## Smoke test de MAREA-009: NPC de taberna, aceptación y entrega.

const MISION_ID := "marea_009_naufragio"
const ITEM_ID := "madera_naufragio"
const RANURA := 9

var correctas := 0
var fallos := 0
var mundo: Mundo

func _ready() -> void:
	Guardado.borrar(RANURA)
	Misiones.reiniciar()
	Bolsa.mochila.vaciar()

	var escena: PackedScene = load("res://escenas/mundo.tscn")
	mundo = escena.instantiate() as Mundo
	add_child(mundo)
	await get_tree().process_frame
	await get_tree().process_frame
	Reloj.pausado = true
	_ejecutar()
	if Interiores.dentro():
		Interiores.salir(mundo.jugador)
	Guardado.borrar(RANURA)
	print("=== %d/%d comprobaciones de MAREA-009 ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _ejecutar() -> void:
	var calico := _calico()
	_comprobar("existe el NPC de taberna", calico != null)
	if calico == null:
		return
	var dialogo := calico.get_node_or_null("DialogoNpcTaberna") as DialogoNpcTaberna
	_comprobar("Calico Jack usa la frontera Interactuable", dialogo != null)
	if dialogo == null:
		return
	_comprobar("la misión empieza disponible", Misiones.estado(MISION_ID) == Misiones.QuestState.AVAILABLE)
	_comprobar("el NPC ofrece el encargo", dialogo.texto_accion().contains("Encargo"))

	var puerta := _puerta_taberna()
	_comprobar("existe la puerta de la taberna", puerta != null)
	if puerta == null:
		return
	_comprobar("entrar conserva la frontera de interiores", Interiores.entrar(puerta, mundo.jugador))
	_comprobar("el mismo NPC entra en la taberna",
		calico.get_parent() == Interiores.activo.actores)

	dialogo.interactuar(mundo.jugador)
	_comprobar("acepta el encargo mediante interacción",
		Misiones.estado(MISION_ID) == Misiones.QuestState.ACCEPTED)
	_comprobar("la interacción registra el objetivo existente",
		Misiones.objetivo_item(MISION_ID).get("item_id", "") == ITEM_ID)

	Bolsa.mochila.anadir(ITEM_ID, 2)
	_comprobar("el objetivo llega a OBJECTIVE_COMPLETE",
		Misiones.estado(MISION_ID) == Misiones.QuestState.OBJECTIVE_COMPLETE)
	_comprobar("el mismo NPC cambia a opción de entrega",
		dialogo.texto_accion().contains("Entregar"))
	dialogo.interactuar(mundo.jugador)
	_comprobar("la interacción entrega la misión",
		Misiones.estado(MISION_ID) == Misiones.QuestState.TURNED_IN)
	_comprobar("el NPC queda sin entrega repetible",
		not dialogo.texto_accion().contains("Entregar"))

	_comprobar("salir conserva el comportamiento de la taberna", Interiores.salir(mundo.jugador))
	_comprobar("el NPC vuelve al exterior", calico.get_parent() == mundo.zona_exterior.actores)

func _calico() -> Pirata:
	for npc: Pirata in mundo.piratas:
		if npc.id_personaje == "calico_jack":
			return npc
	return null

func _puerta_taberna() -> Puerta:
	for puerta: Puerta in mundo.puertas:
		if puerta.edificio_definicion == "taberna" \
				and puerta.sentido == Puerta.Sentido.ENTRAR:
			return puerta
	return null

func _comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s" % nombre)
