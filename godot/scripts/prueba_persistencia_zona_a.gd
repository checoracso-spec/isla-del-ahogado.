extends Node

const MundoScript := preload("res://scripts/mundo.gd")
const D := preload("res://scripts/prueba_persistencia_datos.gd")

func _ready() -> void:
	MapaGlobal.reiniciar()
	Reloj.pausado = true
	Reloj.dia = 1
	Reloj.hora = 8.0
	var mundo: Mundo = MundoScript.new()
	add_child(mundo)
	await get_tree().process_frame
	if not MapaGlobal.iniciar_viaje("principal_ceniza"):
		printerr("A-zona: no pudo iniciar el viaje")
		get_tree().quit(1)
		return
	Reloj.dia = 4
	MapaGlobal._process(0.0)
	await get_tree().process_frame
	if mundo.zona_global_activa == null:
		printerr("A-zona: no se activo la zona remota")
		get_tree().quit(1)
		return
	var fuente_zona = null
	for candidata in mundo.zona_global_activa.fuentes_recurso:
		if candidata.definicion_id == D.FUENTE_ZONA_GUARDADA:
			fuente_zona = candidata
			break
	if fuente_zona == null:
		printerr("A-zona: no se monto la fuente remota")
		get_tree().quit(1)
		return
	Bolsa.mochila.vaciar()
	var recoleccion: Dictionary = fuente_zona.recolectar(Bolsa.mochila)
	if int(recoleccion.get("ciclos", 0)) != 1:
		printerr("A-zona: no pudo recolectar la fuente remota")
		get_tree().quit(1)
		return
	if not Guardado.guardar(D.RANURA_ZONA_GLOBAL):
		printerr("A-zona: no pudo guardar")
		get_tree().quit(1)
		return
	print("A-zona: guardado en %s, destino %s" % [
		Guardado.ruta(D.RANURA_ZONA_GLOBAL), MapaGlobal.ubicacion_actual])
	get_tree().quit(0)
