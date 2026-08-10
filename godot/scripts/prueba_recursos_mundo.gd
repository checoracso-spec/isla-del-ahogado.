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
	_comprobar("la isla expone una ZonaExterior formal", mundo.zona_exterior != null)
	_comprobar("la ZonaExterior reutiliza los actores del mundo",
		mundo.zona_exterior != null and mundo.zona_exterior.actores == mundo.get_node("Objetos"))
	_comprobar("la ZonaExterior conserva los límites de la isla",
		mundo.zona_exterior != null and mundo.zona_exterior.limites() == mundo.limites_exterior())
	_comprobar("el mundo puebla fauna desde BaseDeDatos", mundo.animales.size() >= 3)
	_comprobar("los animales del mundo son actores con identidad",
		mundo.animales.all(func(a): return a is Actor and a.identidad != null))
	_comprobar("la fauna usa la transitabilidad de la isla",
		mundo.animales.all(func(a): return a.transitable == mundo.transitable))
	_comprobar("el mundo crea cuatro fuentes de recursos", mundo.fuentes_recurso.size() == 4)
	if mundo.fuentes_recurso.size() < 4:
		return

	var por_tipo := {}
	for fuente in mundo.fuentes_recurso:
		por_tipo[fuente.definicion_id] = fuente
		print("  posición %s: %s" % [fuente.definicion_id, fuente.casilla()])
		_comprobar("fuente %s sobre terreno transitable" % fuente.definicion_id,
			mundo.transitable.puede_pisar(fuente.casilla()))
	_comprobar("existe el naufragio", por_tipo.has("restos_naufragio"))
	_comprobar("existe el manglar", por_tipo.has("arbol_manglar"))
	_comprobar("existe el semillero", por_tipo.has("semillero_isla"))
	_comprobar("existe la veta", por_tipo.has("veta_azufre"))
	_comprobar("las fuentes se generan desde datos",
		BaseDeDatos.fuente("restos_naufragio").generar_en_mundo
		and BaseDeDatos.fuente("arbol_manglar").generar_en_mundo
		and BaseDeDatos.fuente("semillero_isla").generar_en_mundo
		and BaseDeDatos.fuente("veta_azufre").generar_en_mundo)
	_comprobar("las cuatro fuentes ocupan casillas distintas",
			por_tipo.size() == 4 and _casillas_distintas(por_tipo.values()))
	_comprobar("la bitácora orienta hacia los recursos",
		mundo._resumen_fuentes_exploracion().contains("Restos de Naufragio"))
	_comprobar("el HUD muestra el rastreo de la isla",
		mundo._lbl_recursos.text.contains("RASTREO DE LA ISLA")
		and mundo._lbl_recursos.text.contains("Restos de Naufragio"))
	_comprobar("el HUD muestra las parcelas con dirección",
		mundo._lbl_recursos.text.contains("Cultivos:")
		and mundo._lbl_recursos.text.contains("Cítricos"))

	var naufragio = por_tipo["restos_naufragio"]
	_comprobar("el naufragio está junto al agua", _junto_a_agua(naufragio.casilla()))
	_comprobar("el naufragio no aparece en el borde de la isla",
		naufragio.casilla().x >= 2 and naufragio.casilla().y >= 2
		and naufragio.casilla().x < Mundo.ANCHO - 2
		and naufragio.casilla().y < Mundo.ALTO - 2)
	_comprobar("el naufragio queda a distancia de exploración",
		Vector2(naufragio.casilla() - mundo.isla.centro_plaza).length() < 15.0)
	_comprobar("la identidad del naufragio es estable", naufragio.identidad != null
		and naufragio.identidad.clave == "isla:restos_naufragio@%d,%d" % [naufragio.casilla().x, naufragio.casilla().y])

	Bolsa.mochila.vaciar()
	naufragio.interactuar(mundo.jugador)
	_comprobar("el jugador recolecta el naufragio", Bolsa.mochila.cantidad("madera_naufragio") == 2)
	_comprobar("la madera del naufragio llega a la mochila", Bolsa.mochila.cantidad("madera_naufragio") == 2)
	_comprobar("la pólvora del naufragio llega a la mochila", Bolsa.mochila.cantidad("polvora_humeda") == 1)

	var arbol = por_tipo["arbol_manglar"]
	arbol.interactuar(mundo.jugador)
	_comprobar("el jugador recolecta el manglar", Bolsa.mochila.cantidad("madera_naufragio") == 5)
	_comprobar("el manglar entrega madera y carbón",
		Bolsa.mochila.cantidad("madera_naufragio") == 5 and Bolsa.mochila.cantidad("carbon") == 1)

	var veta = por_tipo["veta_azufre"]
	veta.interactuar(mundo.jugador)
	_comprobar("el jugador recolecta la veta", Bolsa.mochila.cantidad("azufre_volcanico") == 2)
	_comprobar("la veta entrega azufre", Bolsa.mochila.cantidad("azufre_volcanico") == 2)

	var semillero = por_tipo["semillero_isla"]
	semillero.interactuar(mundo.jugador)
	_comprobar("el jugador recolecta el semillero",
		Bolsa.mochila.cantidad("semilla_citrico") == 1)
	_comprobar("el semillero entrega las tres semillas",
		Bolsa.mochila.cantidad("semilla_citrico") == 1
		and Bolsa.mochila.cantidad("semilla_cana") == 1
		and Bolsa.mochila.cantidad("semilla_tabaco") == 1)

	var serial: Dictionary = RecursosMundo._serializar()
	RecursosMundo.reiniciar()
	RecursosMundo._cargar(serial)
	_comprobar("el agotamiento se conserva en datos planos", naufragio.cantidad() == 0
		and arbol.cantidad() == 2 and veta.cantidad() == 1 and semillero.cantidad() == 0)
	_comprobar("las cuatro fuentes siguen registradas tras cargar", serial.get("estados", {}).size() == 4)
	_comprobar("el rastreo deja de anunciar fuentes agotadas",
		not mundo._resumen_fuentes_exploracion().contains("Restos de Naufragio"))

func _casillas_distintas(fuentes: Array) -> bool:
	var vistas := {}
	for fuente in fuentes:
		var c: Vector2i = fuente.casilla()
		if vistas.has(c):
			return false
		vistas[c] = true
	return true

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
