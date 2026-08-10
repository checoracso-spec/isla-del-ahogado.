extends Node
## PROCESO B de la prueba de persistencia real.
##
## Arranca limpio —autoloads nuevos, mundo regenerado, cofre lleno otra vez—,
## carga la partida que dejó el proceso A y comprueba que todo cuadra.
##
## Lo primero que hace es verificar que EMPIEZA limpio. Sin eso, la prueba
## podría estar pasando por inercia y no por haber cargado nada.

const D := preload("res://scripts/prueba_persistencia_datos.gd")

var fallos := 0
var pruebas := 0
var mundo: Mundo

func _ready() -> void:
	print("\n=== PERSISTENCIA · PROCESO B (lee y comprueba) ===\n")
	var escena: PackedScene = load("res://escenas/mundo.tscn")
	mundo = escena.instantiate() as Mundo
	add_child(mundo)
	await get_tree().process_frame
	await get_tree().process_frame
	Reloj.pausado = true

	_comprobar("existe la partida del proceso A", Guardado.existe(D.RANURA),
		Guardado.ruta(D.RANURA))
	if not Guardado.existe(D.RANURA):
		_terminar()
		return

	# --- el proceso arranca limpio, de verdad ---
	print("Antes de cargar (debe estar todo por defecto):")
	_comprobar("la mochila empieza vacía", Bolsa.mochila.esta_vacio())
	_comprobar("el oro empieza a cero", Bolsa.oro == 0, str(Bolsa.oro))
	_comprobar("empieza fuera, no dentro", not Interiores.dentro())
	_comprobar("el día empieza en 1", Reloj.dia == 1, str(Reloj.dia))
	var puerta: Puerta = mundo.puertas[0] if not mundo.puertas.is_empty() else null
	_comprobar("el mundo regeneró sus puertas", puerta != null)
	if puerta == null:
		_terminar()
		return
	# El cofre se acaba de sembrar con 3 rones en este proceso nuevo: si tras
	# cargar sigue con 3, es que la carga no funcionó.
	print("  puerta      : %s (edificio %s)" % [puerta.identidad.instancia, puerta.edificio_instancia])

	# --- cargar ---
	print("\nCargando...")
	_comprobar("carga sin error", Guardado.cargar(D.RANURA))

	print("\nDespués de cargar:")
	_comprobar("está DENTRO de un interior", Interiores.dentro())
	_comprobar("en la planta alta guardada", Ubicacion.zona == D.ZONA_INTERIOR,
		"%s vs %s" % [Ubicacion.zona, D.ZONA_INTERIOR])
	_comprobar("se reconstruyó directamente la zona correcta",
		Interiores.activo != null
		and Interiores.activo.definicion.id == D.ZONA_INTERIOR)
	_comprobar("en la casilla guardada",
		mundo.jugador.pos_tile.distance_to(D.POS_INTERIOR) < 0.6,
		"%s vs %s" % [mundo.jugador.pos_tile, D.POS_INTERIOR])
	_comprobar("el ron está en la mochila",
		Bolsa.mochila.cantidad("ron") == D.RON_EN_MOCHILA,
		str(Bolsa.mochila.cantidad("ron")))
	_comprobar("el oro es el guardado", Bolsa.oro == D.ORO, str(Bolsa.oro))
	_comprobar("la salud es la guardada", is_equal_approx(Bolsa.salud, D.SALUD), str(Bolsa.salud))
	_comprobar("la energía es la guardada", is_equal_approx(Bolsa.energia, D.ENERGIA), str(Bolsa.energia))
	_comprobar("el día es el guardado", Reloj.dia == D.DIA, str(Reloj.dia))
	_comprobar("la hora es la guardada", is_equal_approx(Reloj.hora, D.HORA), str(Reloj.hora))

	var semillero = null
	var parcela = null
	for fuente in mundo.fuentes_recurso:
		if fuente.definicion_id == D.FUENTE_GUARDADA:
			semillero = fuente
	for candidata in mundo.parcelas_cultivo:
		if candidata.definicion_id == D.CULTIVO_GUARDADO:
			parcela = candidata
	_comprobar("la fuente agotada sigue agotada tras cargar",
		semillero != null and semillero.cantidad() == 0)
	_comprobar("la parcela sembrada conserva su etapa tras cargar",
		parcela != null and CultivosMundo.etapa(parcela.identidad.instancia) == D.ETAPA_CULTIVO_GUARDADA)

	# Bajar antes de revisar el cofre: el que vació A pertenece a la planta baja,
	# no al cofre independiente de la planta alta.
	var bajada := Interiores.activo.actores.get_node_or_null(
		"Mueble_escalera_7_3") as Interactuable
	_comprobar("la escalera existe después de reiniciar", bajada != null)
	if bajada != null:
		bajada.interactuar(mundo.jugador)
	_comprobar("puede volver a la planta baja tras cargar",
		Interiores.dentro()
		and Interiores.activo.definicion.id == puerta.interior_id,
		Ubicacion.zona)

	if Interiores.dentro() and not Interiores.activo.cofres.is_empty():
		var cofre: Cofre = Interiores.activo.cofres[0]
		_comprobar("el cofre sigue VACÍO tras reabrir el juego",
			cofre.inventario().esta_vacio(),
			"tiene %d ron" % cofre.inventario().cantidad("ron"))
		_comprobar("y es el mismo cofre de antes",
			cofre.identidad.instancia != "", cofre.identidad.instancia)

	# --- salir por la puerta correcta ---
	print("\nSaliendo:")
	var esperada := Vector2(puerta.casilla_exterior) + Vector2(0.5, 0.5)
	_comprobar("se puede salir", Interiores.salir(mundo.jugador))
	_comprobar("sale por la puerta exterior correcta",
		mundo.jugador.pos_tile.distance_to(esperada) < 1.2,
		"%s vs %s" % [mundo.jugador.pos_tile, esperada])
	_comprobar("ya está en el exterior", Ubicacion.en_exterior(), Ubicacion.zona)
	_comprobar("el ron sigue en la mochila al salir",
		Bolsa.mochila.cantidad("ron") == D.RON_EN_MOCHILA)

	Guardado.borrar(D.RANURA)
	_terminar()

func _comprobar(nombre: String, condicion: bool, detalle: String = "") -> void:
	pruebas += 1
	if condicion:
		print("  OK    %s" % nombre)
	else:
		fallos += 1
		print("  FALLO %s   %s" % [nombre, detalle])

func _terminar() -> void:
	print("\n=== %d/%d correctas ===" % [pruebas - fallos, pruebas])
	get_tree().quit(1 if fallos > 0 else 0)
