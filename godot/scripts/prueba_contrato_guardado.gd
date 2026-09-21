extends Node
## Gate de guardado/carga para MAREA_VERTICAL_SLICE_V1.
##
## Usa ranuras privadas del banco de pruebas (997/998) y las borra siempre al
## terminar. Nunca toca una ranura de usuario ni depende de un archivo previo.

const RANURA_FLUJO := 997
const RANURA_CORRUPTA := 998

var pruebas := 0
var fallos := 0
var mundo: Mundo
var jugador: Jugador
var puerta: Puerta

func _ready() -> void:
	print("\n=== MAREA-006 SAVE/LOAD CONTRACT ===\n")
	Guardado.borrar(RANURA_FLUJO)
	Guardado.borrar(RANURA_CORRUPTA)
	await _cargar_mundo()
	if mundo == null or jugador == null:
		_comprobar("el mundo real crea el jugador", false)
	else:
		_probar_archivo_ausente()
		_probar_flujo_completo()
		_probar_archivo_corrupto()

	Guardado.borrar(RANURA_FLUJO)
	Guardado.borrar(RANURA_CORRUPTA)
	print("\nMAREA-006 SAVE/LOAD CONTRACT: %d/%d PASS" % [pruebas - fallos, pruebas])
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

func _buscar_puerta_taberna() -> Puerta:
	for candidata: Puerta in mundo.puertas:
		if candidata.edificio_definicion == "taberna":
			return candidata
	return null

func _probar_archivo_ausente() -> void:
	Guardado.borrar(RANURA_CORRUPTA)
	_comprobar("una ranura ausente no existe", not Guardado.existe(RANURA_CORRUPTA))
	_comprobar("cargar una ranura ausente falla limpiamente",
		not Guardado.cargar(RANURA_CORRUPTA))

func _probar_flujo_completo() -> void:
	puerta = _buscar_puerta_taberna()
	_comprobar("existe la puerta de taberna para el flujo", puerta != null)
	if puerta == null:
		return

	var fuera := Vector2(puerta.casilla_exterior) + Vector2(0.5, 0.5)
	mundo.recibir_jugador(jugador, fuera)
	_comprobar("entra antes de guardar", Interiores.entrar(puerta, jugador))
	if not Interiores.dentro():
		return

	var posicion_guardada := Vector2(3.5, 5.5)
	jugador.colocar(posicion_guardada)
	Ubicacion.anotar(jugador.pos_tile, jugador.direccion)
	Bolsa.oro = 321
	Reloj.dia = 7
	Reloj.hora = 14.5
	_comprobar("guarda el recorrido dentro de la taberna",
		Guardado.guardar(RANURA_FLUJO))
	_comprobar("el archivo de guardado existe", Guardado.existe(RANURA_FLUJO))

	var contenido := FileAccess.get_file_as_string(Guardado.ruta(RANURA_FLUJO))
	var documento: Variant = JSON.parse_string(contenido)
	var secciones: Dictionary = documento.get("secciones", {}) \
		if documento is Dictionary else {}
	_comprobar("el schema declara la versión actual",
		documento is Dictionary and int(documento.get("version", 0)) == 1)
	_comprobar("el schema contiene jugador, reloj y taberna",
		secciones.has("jugador") and secciones.has("reloj")
		and secciones.has("taberna"))

	_comprobar("sale para simular el cierre de sesión", Interiores.salir(jugador))
	Bolsa.oro = 0
	Reloj.dia = 1
	Reloj.hora = 6.0
	_comprobar("carga el archivo válido", Guardado.cargar(RANURA_FLUJO))
	_comprobar("reabre la taberna guardada",
		Interiores.dentro() and Ubicacion.zona == "interior_taberna_pb")
	_comprobar("restaura la posición interior",
		jugador.pos_tile.distance_to(posicion_guardada) < 0.6,
		"%s vs %s" % [jugador.pos_tile, posicion_guardada])
	_comprobar("restaura el oro", Bolsa.oro == 321, str(Bolsa.oro))
	_comprobar("restaura día y hora", Reloj.dia == 7 and is_equal_approx(Reloj.hora, 14.5),
		"día=%d hora=%.2f" % [Reloj.dia, Reloj.hora])
	_comprobar("puede salir después de cargar", Interiores.salir(jugador))

func _probar_archivo_corrupto() -> void:
	var f := FileAccess.open(Guardado.ruta(RANURA_CORRUPTA), FileAccess.WRITE)
	if f != null:
		# JSON válido, pero con raíz inválida para el schema de una partida.
		f.store_string("[]")
		f.close()
	_comprobar("el archivo corrupto existe", Guardado.existe(RANURA_CORRUPTA))
	_comprobar("cargar un archivo corrupto falla limpiamente",
		not Guardado.cargar(RANURA_CORRUPTA))
