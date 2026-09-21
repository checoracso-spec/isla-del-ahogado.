extends Node
## Regresión de interacciones deterministas para la taberna del vertical slice.
##
## Usa tres objetos montados desde los datos reales y un pirata creado por
## Mundo. La prueba no depende de clics ni de temporizadores: invoca el mismo
## contrato que usa Jugador al interactuar.

var pruebas := 0
var fallos := 0
var mundo: Mundo
var jugador: Jugador

func _ready() -> void:
	print("\n=== MAREA-005 INTERACTION CONTRACT ===\n")
	await _cargar_mundo()
	if mundo == null or jugador == null:
		_comprobar("el mundo real crea al jugador", false)
	else:
		_probar_tres_objetos_y_un_npc()

	print("\nMAREA-005 INTERACTION CONTRACT: %d/%d PASS" % [pruebas - fallos, pruebas])
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

func _entrar_taberna() -> bool:
	for puerta: Puerta in mundo.puertas:
		if puerta.edificio_definicion == "taberna":
			mundo.recibir_jugador(jugador,
				Vector2(puerta.casilla_exterior) + Vector2(0.5, 0.5))
			return Interiores.entrar(puerta, jugador)
	return false

func _probar_tres_objetos_y_un_npc() -> void:
	_comprobar("entra en la taberna real", _entrar_taberna())
	if not Interiores.dentro():
		return

	# Objeto 1: mostrador de taberna — abre el servicio real.
	var puesto := Interiores.activo.actores.get_node_or_null(
		"Mueble_puesto_taberna_4_2") as PuestoTaberna
	_comprobar("existe el mostrador de taberna", puesto != null)
	if puesto != null:
		puesto.interactuar(jugador)
	_comprobar("el mostrador abre el servicio", TabernaManager.abierta)

	# Objeto 2: cofre — emite su señal y conserva su inventario persistente.
	var cofre: Cofre = Interiores.activo.cofres[0] \
		if not Interiores.activo.cofres.is_empty() else null
	var cofre_respondio := [false]
	if cofre != null:
		cofre.abierto.connect(func(_cofre: Cofre): cofre_respondio[0] = true)
		var contenido_antes := cofre.inventario().cantidad("ron")
		cofre.interactuar(jugador)
		_comprobar("el cofre existe y responde", cofre_respondio[0])
		_comprobar("el cofre no duplica su contenido al abrir",
			cofre.inventario().cantidad("ron") == contenido_antes)
	else:
		_comprobar("el cofre existe y responde", false)
		_comprobar("el cofre no duplica su contenido al abrir", false)

	# Objeto 3: puerta de salida — usa el gestor de interiores, no un atajo.
	var salida := Interiores.activo.puerta_salida
	_comprobar("existe la puerta de salida", salida != null)
	_comprobar("la puerta anuncia Salir",
		salida != null and salida.texto_accion() == "Salir")

	# NPC real: el servicio personal consume sus provisiones y modifica sus
	# necesidades, sin tocar Bolsa ni Almacen.
	var npc: Pirata = mundo.piratas[0] if not mundo.piratas.is_empty() else null
	_comprobar("existe un NPC real de la tripulación", npc != null)
	if npc != null:
		var raciones_antes := npc.inventario().cantidad("raciones")
		var ron_antes := npc.inventario().cantidad("ron")
		npc.inventario().anadir("raciones", 1)
		npc.inventario().anadir("ron", 1)
		npc.hambre = 20.0
		npc.moral_personal = 20.0
		npc.tarea = Pirata.Tarea.A_LA_TABERNA
		TabernaManager.abrir("activa")
		var resultado := npc.atender_necesidad_de_rutina()
		_comprobar("el NPC recibe una ronda personal", bool(resultado.get("ok", false)))
		_comprobar("la interacción consume sus provisiones",
			npc.inventario().cantidad("raciones") == raciones_antes
			and npc.inventario().cantidad("ron") == ron_antes)
		_comprobar("la interacción mejora sus necesidades",
			npc.hambre > 20.0 and npc.moral_personal > 20.0)

	if salida != null:
		salida.interactuar(jugador)
	_comprobar("la puerta de salida completa el retorno", not Interiores.dentro())
	TabernaManager.cerrar()
