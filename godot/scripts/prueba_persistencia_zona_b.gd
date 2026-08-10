extends Node

const MundoScript := preload("res://scripts/mundo.gd")
const D := preload("res://scripts/prueba_persistencia_datos.gd")

var correctas := 0
var fallos := 0

func _ready() -> void:
	MapaGlobal.reiniciar()
	Reloj.pausado = true
	var mundo: Mundo = MundoScript.new()
	add_child(mundo)
	await get_tree().process_frame
	_comprobar("el proceso B comienza en la isla", MapaGlobal.ubicacion_actual == "isla_principal")
	_comprobar("el proceso B comienza sin zona remota", mundo.zona_global_activa == null)
	Guardado.partida_cargada.connect(func(_ranura: int): pass)
	_comprobar("la partida de zona existe", Guardado.existe(D.RANURA_ZONA_GLOBAL))
	if Guardado.existe(D.RANURA_ZONA_GLOBAL):
		Guardado.cargar(D.RANURA_ZONA_GLOBAL)
		await get_tree().process_frame
	_comprobar("carga la ubicación global", MapaGlobal.ubicacion_actual == "isla_ceniza")
	_comprobar("reconstruye la ZonaRemota", mundo.zona_global_activa != null)
	_comprobar("recoloca al jugador en la zona remota",
		mundo.zona_global_activa != null
		and mundo.jugador.get_parent() == mundo.zona_global_activa.actores)
	_comprobar("Ubicacion conserva la zona global", Ubicacion.zona == "global:isla_ceniza")
	_comprobar("la cámara usa los límites remotos",
		mundo.camara().limit_right < 3000)
	Guardado.borrar(D.RANURA_ZONA_GLOBAL)
	print("=== %d/%d comprobaciones de persistencia de zona ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s" % nombre)
