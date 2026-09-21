extends Node
## Prueba enfocada de MAREA-010: recompensa única y persistente de la taberna.

const MISION_ID := "marea_009_naufragio"
const ITEM_ID := "madera_naufragio"
const RANURA := 10

var correctas := 0
var fallos := 0
var mundo: Mundo

func _ready() -> void:
	Guardado.borrar(RANURA)
	Misiones.reiniciar()
	Bolsa.mochila.vaciar()
	Bolsa.oro = 0

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
	print("=== %d/%d comprobaciones de MAREA-010 ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _ejecutar() -> void:
	var calico := _calico()
	_comprobar("existe el NPC de taberna", calico != null)
	if calico == null:
		return
	var dialogo := calico.get_node_or_null("DialogoNpcTaberna") as DialogoNpcTaberna
	_comprobar("el NPC usa la frontera Interactuable", dialogo != null)
	if dialogo == null:
		return
	_comprobar("la misión empieza disponible", Misiones.estado(MISION_ID) == Misiones.QuestState.AVAILABLE)

	var puerta := _puerta_taberna()
	_comprobar("existe la puerta de la taberna", puerta != null)
	if puerta == null:
		return
	_comprobar("entrar conserva la frontera de interiores", Interiores.entrar(puerta, mundo.jugador))

	dialogo.interactuar(mundo.jugador)
	_comprobar("acepta el encargo", Misiones.estado(MISION_ID) == Misiones.QuestState.ACCEPTED)
	Bolsa.mochila.anadir(ITEM_ID, 2)
	_comprobar("el objetivo llega a OBJECTIVE_COMPLETE",
		Misiones.estado(MISION_ID) == Misiones.QuestState.OBJECTIVE_COMPLETE)

	var oro_antes := Bolsa.oro
	dialogo.interactuar(mundo.jugador)
	_comprobar("la entrega alcanza TURNED_IN",
		Misiones.estado(MISION_ID) == Misiones.QuestState.TURNED_IN)
	_comprobar("la entrega concede los doblones observables",
		Bolsa.oro == oro_antes + BaseDeDatos.mision(MISION_ID).recompensa_doblones)
	var oro_concedido := Bolsa.oro
	dialogo.interactuar(mundo.jugador)
	_comprobar("reinteractuar no duplica la recompensa", Bolsa.oro == oro_concedido)
	_comprobar("salir conserva el comportamiento de la taberna", Interiores.salir(mundo.jugador))
	_comprobar("el NPC vuelve al exterior", calico.get_parent() == mundo.zona_exterior.actores)

	_comprobar("guarda recompensa y estado con Guardado", Guardado.guardar(RANURA))
	Bolsa.oro = 0
	Misiones.reiniciar()
	_comprobar("limpia el estado en memoria antes de cargar",
		Bolsa.oro == 0 and Misiones.ids().is_empty())
	_comprobar("carga la partida guardada", Guardado.cargar(RANURA))
	_comprobar("restaura TURNED_IN", Misiones.estado(MISION_ID) == Misiones.QuestState.TURNED_IN)
	_comprobar("restaura los doblones", Bolsa.oro == oro_concedido)
	dialogo.interactuar(mundo.jugador)
	_comprobar("reinteractuar tras cargar no duplica la recompensa", Bolsa.oro == oro_concedido)

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
	else:
		fallos += 1
		push_error("FALLO: %s" % nombre)
