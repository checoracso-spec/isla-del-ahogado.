extends Node

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
	print("=== %d/%d comprobaciones de recursos en mundo ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _ejecutar() -> void:
	_comprobar("el mundo crea una fuente costera", mundo.fuentes_recurso.size() == 1)
	if mundo.fuentes_recurso.is_empty():
		return
	var fuente = mundo.fuentes_recurso[0]
	_comprobar("la fuente está sobre terreno transitable",
		mundo.transitable.puede_pisar(fuente.casilla()))
	_comprobar("la fuente está junto al agua", _junto_a_agua(fuente.casilla()))
	_comprobar("la fuente tiene identidad estable", fuente.identidad != null
		and fuente.identidad.clave == "isla:restos_naufragio@%d,%d" % [fuente.casilla().x, fuente.casilla().y])

	Bolsa.mochila.vaciar()
	var antes: int = int(fuente.cantidad())
	var resultado: Dictionary = fuente.recolectar(mundo.jugador.inventario())
	_comprobar("el jugador puede recolectar", int(resultado.get("ciclos", 0)) == 1)
	_comprobar("la madera llega a la mochila", Bolsa.mochila.cantidad("madera_naufragio") == 2)
	_comprobar("la pólvora llega a la mochila", Bolsa.mochila.cantidad("polvora_humeda") == 1)
	_comprobar("la fuente queda agotada", antes == 1 and fuente.cantidad() == 0)

	var serial: Dictionary = RecursosMundo._serializar()
	RecursosMundo.reiniciar()
	RecursosMundo._cargar(serial)
	_comprobar("el agotamiento se conserva en datos planos", fuente.cantidad() == 0)
	_comprobar("el recurso sigue registrado tras cargar", serial.get("estados", {}).size() == 1)

func _junto_a_agua(casilla: Vector2i) -> bool:
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if mundo.isla.nivel(casilla.x + d.x, casilla.y + d.y) == GeneradorIsla.AGUA:
			return true
	return false

func _comprobar(nombre: String, condicion: bool, detalle: String = "") -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s %s" % [nombre, detalle])
