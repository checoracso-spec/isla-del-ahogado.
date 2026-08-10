extends Node

const MundoScript := preload("res://scripts/mundo.gd")

var correctas := 0
var fallos := 0
var mundo: Mundo

func _ready() -> void:
	await get_tree().process_frame
	await _ejecutar()
	print("=== %d/%d comprobaciones de viaje jugable ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _ejecutar() -> void:
	MapaGlobal.reiniciar()
	Reloj.pausado = true
	Reloj.dia = 1
	Reloj.hora = 8.0
	mundo = MundoScript.new()
	mundo.name = "MundoPruebaViaje"
	add_child(mundo)
	await get_tree().process_frame
	_comprobar("el mundo inicia en la isla", mundo.zona_global_activa == null
		and MapaGlobal.ubicacion_actual == "isla_principal")

	_comprobar("inicia un viaje desde la isla",
		MapaGlobal.iniciar_viaje("principal_ceniza"))
	Reloj.dia = 4
	MapaGlobal._process(0.0)
	await get_tree().process_frame
	_comprobar("la llegada activa una Zona remota", mundo.zona_global_activa != null)
	_comprobar("el jugador entra en la zona remota",
		mundo.zona_global_activa != null
		and mundo.jugador.get_parent() == mundo.zona_global_activa.actores)
	_comprobar("la zona remota conserva el destino global",
		MapaGlobal.ubicacion_actual == "isla_ceniza"
		and Ubicacion.zona == "global:isla_ceniza")
	_comprobar("la llegada monta los recursos del destino",
		mundo.zona_global_activa != null
		and mundo.zona_global_activa.fuentes_recurso.size() == 2)
	_comprobar("la llegada monta los cultivos del destino",
		mundo.zona_global_activa != null
		and mundo.zona_global_activa.parcelas_cultivo.size() == 1
		and mundo.zona_global_activa.parcelas_cultivo[0].definicion_id == "tabaco")
	_comprobar("el HUD identifica el rastreo de la zona",
		mundo._lbl_recursos.text.contains("RASTREO DE LA ZONA"))
	_comprobar("la zona remota crea un embarque de regreso",
		mundo.zona_global_activa.get("transiciones").size() == 1)

	var embarque: Node = mundo.zona_global_activa.get("transiciones")[0]
	_comprobar("el embarque conoce la ruta de regreso",
		str(embarque.get("ruta_id")) == "ceniza_principal")
	embarque.interactuar(mundo.jugador)
	_comprobar("el embarque inicia el viaje de vuelta", MapaGlobal.viajando())
	Reloj.dia = 7
	MapaGlobal._process(0.0)
	await get_tree().process_frame
	_comprobar("la llegada a casa desactiva la zona remota",
		mundo.zona_global_activa == null
		and MapaGlobal.ubicacion_actual == "isla_principal")
	_comprobar("el jugador vuelve al exterior de la isla",
		mundo.jugador.get_parent() == mundo.get_node("Objetos")
		and Ubicacion.en_exterior())
	_comprobar("la cámara recupera los límites exteriores",
		mundo.camara().limit_right > 3000)

	mundo.free()
	MapaGlobal.reiniciar()

func _comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s" % nombre)
