extends Node

var correctas := 0
var fallos := 0

func _ready() -> void:
	await get_tree().process_frame
	_ejecutar()
	print("=== %d/%d comprobaciones de zona global ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _ejecutar() -> void:
	var zona: Zona = MapaGlobal.crear_zona("portobello", 16, 12)
	_comprobar("crea Portobello desde datos", zona != null)
	if zona == null:
		return
	add_child(zona)
	_comprobar("la zona conserva su identidad", zona.id == "portobello")
	_comprobar("la zona tiene límites propios",
		zona.limites() == Rect2i(0, 0, 16, 12), str(zona.limites()))
	_comprobar("la zona tiene actores ordenados por profundidad",
		zona.actores != null and zona.actores.y_sort_enabled)
	_comprobar("la entrada cae dentro de la zona",
		zona.transitable.cabe_en(zona.entrada(), Huella.cuadrada(0.52)))
	_comprobar("la zona conserva transitabilidad común",
		zona.transitable is TransitableRejilla)

	var actor := Actor.new()
	actor.name = "ActorPruebaZona"
	zona.recibir(actor, zona.entrada())
	_comprobar("recibe un Actor sin crear otro sistema", actor.get_parent() == zona.actores)
	_comprobar("el Actor usa la transitabilidad de la zona",
		actor.transitable == zona.transitable)
	_comprobar("el Actor aparece en una casilla válida",
		zona.transitable.cabe_en(actor.pos_tile, actor.huella))
	zona.desactivar()
	_comprobar("la zona puede desactivarse", not zona.visible
		and zona.process_mode == Node.PROCESS_MODE_DISABLED)
	zona.activar()
	_comprobar("la zona puede reactivarse", zona.visible
		and zona.process_mode == Node.PROCESS_MODE_INHERIT)
	zona.free()

func _comprobar(nombre: String, condicion: bool, detalle: String = "") -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s %s" % [nombre, detalle])
