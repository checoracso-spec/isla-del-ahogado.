extends Node
## Prueba enfocada de MAREA-012: contrato data-driven y persistencia regresiva.

const MISION_ID := "marea_009_naufragio"
const RANURA := 12

var correctas := 0
var fallos := 0
var dialogo: DialogoNpcTaberna

func _ready() -> void:
	Guardado.borrar(RANURA)
	Misiones.reiniciar()
	Bolsa.mochila.vaciar()
	Bolsa.oro = 0

	var definicion := BaseDeDatos.mision(MISION_ID)
	_comprobar("carga la definición existente", definicion != null)
	if definicion == null:
		_finalizar()
		return
	_comprobar("usa un Resource tipado", definicion is MisionData)
	_comprobar("conserva el objetivo de madera",
		definicion.objetivo_item_id == "madera_naufragio"
		and definicion.objetivo_cantidad == 2)
	_comprobar("conserva la recompensa de MAREA-010", definicion.recompensa_doblones == 25)

	dialogo = DialogoNpcTaberna.new(MISION_ID, definicion)
	dialogo.name = "DialogoNpcTaberna"
	add_child(dialogo)
	await get_tree().process_frame
	_comprobar("el diálogo registra la misión desde la definición",
		Misiones.estado(MISION_ID) == Misiones.QuestState.AVAILABLE)
	dialogo.interactuar(self)
	_comprobar("la definición conserva la aceptación",
		Misiones.estado(MISION_ID) == Misiones.QuestState.ACCEPTED)
	Bolsa.mochila.anadir(definicion.objetivo_item_id, definicion.objetivo_cantidad)
	_comprobar("la definición conserva el objetivo",
		Misiones.estado(MISION_ID) == Misiones.QuestState.OBJECTIVE_COMPLETE)
	var oro_antes := Bolsa.oro
	dialogo.interactuar(self)
	_comprobar("la definición conserva la entrega", Misiones.estado(MISION_ID) == Misiones.QuestState.TURNED_IN)
	_comprobar("la recompensa sigue siendo observable",
		Bolsa.oro == oro_antes + definicion.recompensa_doblones)

	_comprobar("guarda estado con Guardado", Guardado.guardar(RANURA))
	Misiones.reiniciar()
	Bolsa.oro = 0
	_comprobar("carga estado con Guardado", Guardado.cargar(RANURA))
	_comprobar("restaura la misión entregada",
		Misiones.estado(MISION_ID) == Misiones.QuestState.TURNED_IN)
	_comprobar("reinteractuar tras cargar no duplica la recompensa",
		_reinteractuar_no_duplica(Bolsa.oro))

	_finalizar()

func _finalizar() -> void:
	Guardado.borrar(RANURA)
	print("=== %d/%d comprobaciones de MAREA-012 ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s" % nombre)

func _reinteractuar_no_duplica(oro_esperado: int) -> bool:
	dialogo.interactuar(self)
	return Bolsa.oro == oro_esperado
