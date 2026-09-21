extends Node
## Smoke test determinista de MAREA-007: estados y persistencia existente.

const MISION_ID := "marea_007_prueba"

var correctas := 0
var fallos := 0

func _ready() -> void:
	print("\n=== PRUEBAS DE ESTADO DE MISIONES ===\n")
	Misiones.reiniciar()

	_comprobar("registra una mision nueva", Misiones.registrar(MISION_ID))
	_comprobar("empieza disponible", Misiones.estado(MISION_ID) == Misiones.QuestState.AVAILABLE)
	_comprobar("no acepta una mision inexistente", not Misiones.aceptar("mision_inexistente"))
	_comprobar("no completa antes de aceptar", not Misiones.completar_objetivo(MISION_ID))
	_comprobar("acepta la mision", Misiones.aceptar(MISION_ID))
	_comprobar("queda aceptada", Misiones.estado(MISION_ID) == Misiones.QuestState.ACCEPTED)
	_comprobar("no entrega antes del objetivo", not Misiones.entregar(MISION_ID))
	_comprobar("completa el objetivo", Misiones.completar_objetivo(MISION_ID))
	_comprobar("queda objetivo completo",
		Misiones.estado(MISION_ID) == Misiones.QuestState.OBJECTIVE_COMPLETE)
	_comprobar("entrega la mision", Misiones.entregar(MISION_ID))
	_comprobar("queda entregada", Misiones.estado(MISION_ID) == Misiones.QuestState.TURNED_IN)
	_comprobar("no repite una transicion terminal", not Misiones.entregar(MISION_ID))

	_comprobar("registra su seccion en Guardado",
		Guardado.secciones_activas().has("misiones"))
	var datos_guardados := Misiones._serializar()
	Misiones.reiniciar()
	_comprobar("reiniciar elimina el estado en memoria", Misiones.ids().is_empty())
	Misiones._cargar(datos_guardados)
	_comprobar("restaura la mision guardada",
		Misiones.estado(MISION_ID) == Misiones.QuestState.TURNED_IN)

	print("=== %d/%d comprobaciones de misiones ===" % [correctas, correctas + fallos])
	get_tree().quit(1 if fallos > 0 else 0)

func _comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s" % nombre)
