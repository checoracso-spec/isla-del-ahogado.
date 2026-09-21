extends Node
## Smoke test de MAREA-008: interacción de mundo, objeto de misión y guardado.

const MISION_ID := "marea_008_naufragio"
const ITEM_ID := "madera_naufragio"
const RANURA := 8

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
	Guardado.borrar(RANURA)
	print("=== %d/%d comprobaciones de MAREA-008 ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _ejecutar() -> void:
	_comprobar("registra la misión", Misiones.registrar(MISION_ID))
	_comprobar("registra el objetivo de madera", Misiones.registrar_objetivo_item(
		MISION_ID, ITEM_ID, 2))
	_comprobar("el objetivo conserva su requisito",
		Misiones.objetivo_item(MISION_ID).get("item_id", "") == ITEM_ID
		and int(Misiones.objetivo_item(MISION_ID).get("cantidad", 0)) == 2)
	_comprobar("acepta la misión", Misiones.aceptar(MISION_ID))
	_comprobar("el objetivo aún no está completo", 
		Misiones.estado(MISION_ID) == Misiones.QuestState.ACCEPTED)

	var naufragio = _fuente("restos_naufragio")
	_comprobar("el mundo expone el naufragio requerido", naufragio != null)
	if naufragio == null:
		return
	_comprobar("el naufragio es interactuable", naufragio is Interactuable)
	_comprobar("la fuente ofrece una acción de recolección",
		naufragio.texto_accion() == "Recolectar Restos de Naufragio")
	naufragio.interactuar(mundo.jugador)
	_comprobar("la interacción entrega el objeto", Bolsa.mochila.cantidad(ITEM_ID) == 2)
	_comprobar("la misión reconoce el objetivo", 
		Misiones.estado(MISION_ID) == Misiones.QuestState.OBJECTIVE_COMPLETE)

	_comprobar("guarda el inventario y el objetivo", Guardado.guardar(RANURA))
	Bolsa.mochila.vaciar()
	Misiones.reiniciar()
	_comprobar("borra el estado en memoria antes de cargar",
		Bolsa.mochila.cantidad(ITEM_ID) == 0 and Misiones.ids().is_empty())
	_comprobar("carga la partida", Guardado.cargar(RANURA))
	_comprobar("restaura el objeto de misión", Bolsa.mochila.cantidad(ITEM_ID) == 2)
	_comprobar("restaura el estado del objetivo",
		Misiones.estado(MISION_ID) == Misiones.QuestState.OBJECTIVE_COMPLETE)
	_comprobar("restaura la definición del objetivo",
		Misiones.objetivo_item(MISION_ID).get("item_id", "") == ITEM_ID)

func _fuente(definicion_id: String):
	for fuente in mundo.fuentes_recurso:
		if fuente.definicion_id == definicion_id:
			return fuente
	return null

func _comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s" % nombre)
