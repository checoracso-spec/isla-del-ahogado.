extends Node
## Regresión del contrato de movimiento del vertical slice.
##
## Carga el mundo real y verifica el camino que importa para MAREA-003:
## movimiento en la rejilla, bloqueo por una huella sólida y orden de
## profundidad compartido por el jugador y los edificios.

var pruebas := 0
var fallos := 0
var mundo: Mundo
var jugador: Jugador

func _ready() -> void:
	print("\n=== MAREA-003 MOVEMENT CONTRACT ===\n")
	await _cargar_mundo()
	if mundo == null or jugador == null:
		_comprobar("el mundo real crea al jugador", false)
	else:
		_comprobar("el jugador usa la transitabilidad del mundo",
			jugador.transitable == mundo.transitable)
		_comprobar("el contenedor exterior ordena por Y",
			mundo._objetos.y_sort_enabled)
		_probar_caminar()
		_probar_colision()
		_probar_profundidad()

	print("\nMAREA-003 MOVEMENT CONTRACT: %d/%d PASS" % [pruebas - fallos, pruebas])
	get_tree().quit(1 if fallos > 0 else 0)

func _comprobar(nombre: String, condicion: bool, detalle: String = "") -> void:
	pruebas += 1
	if condicion:
		print("  PASS  %s" % nombre)
	else:
		fallos += 1
		print("  FAIL  %s %s" % [nombre, detalle])

func _cargar_mundo() -> void:
	var escena: PackedScene = load("res://escenas/mundo.tscn")
	mundo = escena.instantiate() as Mundo
	add_child(mundo)
	await get_tree().process_frame
	await get_tree().process_frame
	Reloj.pausado = true
	jugador = mundo.jugador

func _buscar_par_libre() -> Array:
	for y in range(mundo.isla.alto):
		for x in range(mundo.isla.ancho - 1):
			var a := Vector2i(x, y)
			var b := Vector2i(x + 1, y)
			if mundo.transitable.puede_pisar(a) and mundo.transitable.puede_pisar(b):
				return [a, b]
	return []

func _probar_caminar() -> void:
	var par := _buscar_par_libre()
	_comprobar("existen dos casillas exteriores contiguas", not par.is_empty())
	if par.is_empty():
		return
	var origen: Vector2i = par[0]
	var destino: Vector2i = par[1]
	jugador.colocar(Vector2(origen) + Vector2(0.5, 0.5))
	var antes := jugador.pos_tile
	var dir := (Vector2(destino) - Vector2(origen)).normalized()
	for _i in 12:
		jugador.mover(dir, 0.05)
	_comprobar("camina sobre una casilla libre",
		jugador.pos_tile.distance_to(antes) > 0.1,
		"%s -> %s" % [antes, jugador.pos_tile])
	_comprobar("el movimiento conserva una huella válida",
		jugador.transitable.cabe_en(jugador.pos_tile, jugador.huella))

func _probar_colision() -> void:
	var objetivo := Vector2i(-1, -1)
	var desde := Vector2i(-1, -1)
	for clave in mundo.transitable.ocupadas.keys():
		var candidata: Vector2i = clave
		var libre := mundo.transitable.casilla_libre_cerca(candidata, 8)
		if libre != candidata:
			objetivo = candidata
			desde = libre
			break
	_comprobar("hay una huella sólida que probar", desde != Vector2i(-1, -1))
	if desde == Vector2i(-1, -1):
		return
	jugador.colocar(Vector2(desde) + Vector2(0.5, 0.5))
	var dir := (Vector2(objetivo) - Vector2(desde)).normalized()
	var atraveso := false
	for _i in 80:
		jugador.mover(dir, 0.05)
		if jugador.casilla() == objetivo:
			atraveso = true
			break
	_comprobar("no atraviesa la huella ocupada", not atraveso,
			"objetivo=%s posición=%s" % [objetivo, jugador.casilla()])

func _probar_profundidad() -> void:
	var edificio: EdificioVisual = mundo.visuales.get("taberna") as EdificioVisual
	_comprobar("existe un edificio real para probar profundidad", edificio != null)
	if edificio == null:
		return
	_comprobar("jugador y edificio comparten la capa Y-sort",
		jugador.get_parent() == mundo._objetos and edificio.get_parent() == mundo._objetos
		and jugador.z_index == 0 and edificio.z_index == 0)
	var detras := Vector2(edificio.casilla - Vector2i.ONE) + Vector2(0.5, 0.5)
	var delante := Vector2(edificio.casilla + Vector2i(edificio.lado + 1, edificio.lado + 1)) \
		+ Vector2(0.5, 0.5)
	jugador.colocar(detras)
	var y_detras := jugador.position.y < edificio.position.y
	jugador.colocar(delante)
	var y_delante := jugador.position.y > edificio.position.y
	_comprobar("el jugador queda detrás por Y en la posición trasera", y_detras)
	_comprobar("el jugador queda delante por Y en la posición frontal", y_delante)
