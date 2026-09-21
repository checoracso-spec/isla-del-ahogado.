extends Node
## Regresión del tramo exterior → taberna → exterior del vertical slice.
##
## Usa la puerta, el gestor de interiores y el jugador reales. No fabrica una
## sala de prueba: la taberna se monta desde BaseDeDatos y conserva el retorno
## exterior declarado por la puerta.

var pruebas := 0
var fallos := 0
var mundo: Mundo
var jugador: Jugador
var puerta: Puerta

func _ready() -> void:
	print("\n=== MAREA-004 TAVERN PORTAL CONTRACT ===\n")
	await _cargar_mundo()
	if mundo == null or jugador == null:
		_comprobar("el mundo real crea el jugador", false)
	else:
		puerta = _puerta_taberna()
		_comprobar("existe la puerta real de la taberna", puerta != null)
		if puerta != null:
			_probar_entrada_y_recorrido()

	print("\nMAREA-004 TAVERN PORTAL CONTRACT: %d/%d PASS" % [pruebas - fallos, pruebas])
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

func _puerta_taberna() -> Puerta:
	for candidata: Puerta in mundo.puertas:
		if candidata.edificio_definicion == "taberna":
			return candidata
	return null

func _probar_entrada_y_recorrido() -> void:
	var retorno_esperado := Vector2(puerta.casilla_exterior) + Vector2(0.5, 0.5)
	mundo.recibir_jugador(jugador, retorno_esperado)
	var mochila_antes := jugador.inventario().cantidad("ron")
	jugador.inventario().anadir("ron", 2)
	mochila_antes = jugador.inventario().cantidad("ron")
	var oro_antes := Bolsa.oro
	Bolsa.oro = 237
	var dia_antes := Reloj.dia

	_comprobar("la puerta apunta al interior de taberna",
		puerta.interior_id == "interior_taberna_pb", puerta.interior_id)
	_comprobar("la puerta es interactuable", puerta.is_in_group(Interactuable.GRUPO))
	_comprobar("entrar activa la taberna real", Interiores.entrar(puerta, jugador))
	_comprobar("el interior activo es el de la taberna",
		Interiores.dentro()
		and Interiores.activo.definicion.id == "interior_taberna_pb")
	_comprobar("el exterior queda oculto", not mundo._objetos.visible)
	_comprobar("el jugador cambia a la rejilla interior",
		jugador.get_parent() == Interiores.activo.actores
		and jugador.transitable == Interiores.activo.transitable)
	_comprobar("aparece en la entrada válida",
		jugador.pos_tile.distance_to(Interiores.activo.entrada()) < 0.6)

	var puntos := [Vector2i(3, 6), Vector2i(3, 5), Vector2i(4, 5)]
	var recorridos := 0
	for punto: Vector2i in puntos:
		if not Interiores.activo.transitable.cabe_en(
			Vector2(punto) + Vector2(0.5, 0.5), jugador.huella):
			continue
		var antes := jugador.pos_tile
		for _i in 40:
			if jugador.ir_hacia(Vector2(punto) + Vector2(0.5, 0.5), 0.05):
				break
		var llego := jugador.pos_tile.distance_to(Vector2(punto) + Vector2(0.5, 0.5)) < 0.7
		_comprobar("recorre un punto interior %s" % punto, llego,
			"%s -> %s" % [antes, jugador.pos_tile])
		if llego:
			recorridos += 1
	_comprobar("recorre tres puntos de la taberna", recorridos == 3,
			"recorridos=%d" % recorridos)

	var salio := Interiores.salir(jugador)
	_comprobar("sale por la puerta de la taberna", salio)
	_comprobar("el gestor vuelve al exterior", not Interiores.dentro()
		and Ubicacion.en_exterior())
	_comprobar("el exterior vuelve a encenderse", mundo._objetos.visible)
	_comprobar("el jugador vuelve al contenedor exterior",
		jugador.get_parent() == mundo._objetos)
	_comprobar("recupera la posición de la puerta",
		jugador.pos_tile.distance_to(retorno_esperado) < 0.6,
		"%s vs %s" % [jugador.pos_tile, retorno_esperado])
	_comprobar("conserva el inventario mínimo", jugador.inventario().cantidad("ron") == mochila_antes)
	_comprobar("conserva el oro", Bolsa.oro == 237)
	_comprobar("conserva el día", Reloj.dia == dia_antes)

	# Restaurar sólo el estado sintético del benchmark antes de terminar.
	Bolsa.oro = oro_antes
