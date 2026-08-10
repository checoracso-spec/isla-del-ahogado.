extends Node
const RecolectorRecursoScript := preload("res://scripts/mapa/recolector_recurso.gd")

var correctas := 0
var fallos := 0
var mundo: Mundo

func _ready() -> void:
	var escena: PackedScene = load("res://escenas/mundo.tscn")
	mundo = escena.instantiate() as Mundo
	add_child(mundo)
	await get_tree().process_frame
	await get_tree().process_frame
	Reloj.pausado = true
	_ejecutar()
	print("=== %d/%d comprobaciones de recolección automática ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _ejecutar() -> void:
	var fuente: FuenteRecurso = null
	for candidata in mundo.fuentes_recurso:
		if candidata.definicion_id == "restos_naufragio":
			fuente = candidata
			break
	_comprobar("existe una fuente para la grúa", fuente != null)
	if fuente == null:
		return

	Almacen.vaciar()
	var recolector = RecolectorRecursoScript.new()
	add_child(recolector)
	recolector.montar(str(fuente.identidad.instancia), "muelle_grua", 1, 6.0)
	var lotes: Array = []
	recolector.lote_recolectado.connect(func(_r, productos): lotes.append(productos))
	var resultado: Dictionary = recolector.ejecutar_ahora()
	_comprobar("la grúa extrae un ciclo", int(resultado.get("ciclos", 0)) == 1)
	_comprobar("la carga llega al almacén",
		Almacen.cantidad("madera_naufragio") == 2
		and Almacen.cantidad("polvora_humeda") == 1)
	_comprobar("la fuente se descuenta desde el mismo estado",
		fuente.cantidad() == 0)
	_comprobar("la recolectora emite el lote", lotes.size() == 1)

	# Un almacén con poco volumen rechaza el lote completo y no consume la
	# fuente; esta es la protección contra extracciones parciales.
	Almacen.vaciar()
	Almacen.capacidad_volumen = 1.0
	RecursosMundo._estados[fuente.identidad.instancia]["cantidad"] = 1
	var bloqueado: Dictionary = recolector.ejecutar_ahora()
	_comprobar("la grúa respeta la capacidad del almacén",
		int(bloqueado.get("ciclos", 0)) == 0
		and Almacen.cantidad("madera_naufragio") == 0
		and fuente.cantidad() == 1)
	Almacen.capacidad_volumen = 0.0

func _comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s" % nombre)
