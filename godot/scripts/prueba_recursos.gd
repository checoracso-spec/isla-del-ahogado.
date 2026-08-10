extends Node
const FuenteRecursoScript := preload("res://scripts/mapa/fuente_recurso.gd")

var correctas := 0
var fallos := 0
var fuente
var jugador: Jugador

func _ready() -> void:
	await get_tree().process_frame
	_ejecutar()
	print("=== %d/%d comprobaciones de recursos ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _ejecutar() -> void:
	print("1. Definiciones data-driven")
	var def := BaseDeDatos.fuente("restos_naufragio")
	_comprobar("la fuente existe en BaseDeDatos", def != null)
	_comprobar("la fuente tiene productos", def != null and def.productos.has("madera_naufragio"))
	_comprobar("la definición no depende de un nodo", def != null and def.tipo == "naufragio")

	RecursosMundo.reiniciar()
	Entidades.reiniciar()
	Bolsa.mochila.vaciar()
	jugador = Jugador.new()
	jugador.name = "JugadorPruebaRecursos"
	add_child(jugador)
	fuente = FuenteRecursoScript.new()
	add_child(fuente)
	_comprobar("monta una fuente con identidad estable",
		fuente.montar("restos_naufragio", "isla:restos_naufragio@4,4", Vector2i(4, 4)))
	var id_antes: String = str(fuente.identidad.instancia)
	_comprobar("la cantidad inicial viene de los datos", fuente.cantidad() == 1,
		str(fuente.cantidad()))
	_comprobar("la fuente se registra como interactuable",
		fuente.is_in_group(Interactuable.GRUPO))

	print("2. Recolección y agotamiento")
	var mochila_limitada := Inventario.new()
	mochila_limitada.capacidad = 0.01
	_comprobar("rechaza la recolección si no cabe el lote completo",
		not RecursosMundo.puede_recolectar(id_antes, mochila_limitada))
	var resultado: Dictionary = fuente.recolectar(jugador.inventario())
	_comprobar("recolecta un ciclo", int(resultado.get("ciclos", 0)) == 1)
	_comprobar("entrega madera a la mochila", Bolsa.mochila.cantidad("madera_naufragio") == 2)
	_comprobar("entrega pólvora a la mochila", Bolsa.mochila.cantidad("polvora_humeda") == 1)
	_comprobar("la fuente queda agotada", fuente.cantidad() == 0)
	_comprobar("no se puede recolectar otra vez", fuente.recolectar(jugador.inventario()).is_empty()
		or int(fuente.recolectar(jugador.inventario()).get("ciclos", 0)) == 0)

	print("3. Regeneración")
	var estado_guardado: Dictionary = RecursosMundo._serializar()
	var datos_fuente: Dictionary = estado_guardado["estados"][id_antes]
	_comprobar("guarda la próxima regeneración", float(datos_fuente["proxima"]) > 0.0)
	var hora_original := Reloj.hora
	var dia_original := Reloj.dia
	Reloj.dia = 2
	Reloj.hora = 8.0
	RecursosMundo._process(0.0)
	_comprobar("regenera al superar el tiempo", fuente.cantidad() == 1)
	Reloj.dia = dia_original
	Reloj.hora = hora_original

	print("4. Guardado plano e identidad")
	var serial := RecursosMundo._serializar()
	RecursosMundo.reiniciar()
	_comprobar("el estado se puede limpiar", RecursosMundo.cantidad(id_antes) == 0)
	RecursosMundo._cargar(serial)
	_comprobar("carga estados sin referencias a nodos",
		RecursosMundo.cantidad(id_antes) == 1)
	_comprobar("la identidad no cambia", fuente.identidad.instancia == id_antes)
	_comprobar("la sección de guardado está activa",
		"recursos_mundo" in Guardado.secciones_activas())

	fuente.queue_free()
	jugador.queue_free()

func _comprobar(nombre: String, condicion: bool, detalle: String = "") -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s %s" % [nombre, detalle])
