extends Node

var correctas := 0
var fallos := 0

func _ready() -> void:
	await get_tree().process_frame
	_ejecutar()
	print("=== %d/%d comprobaciones de mapa global ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _ejecutar() -> void:
	print("1. Destinos y rutas data-driven")
	MapaGlobal.reiniciar()
	Reloj.dia = 1
	Reloj.hora = 7.5
	_comprobar("la isla principal existe", BaseDeDatos.destino("isla_principal") != null)
	_comprobar("hay varias ubicaciones globales", MapaGlobal.destinos().size() >= 4,
		str(MapaGlobal.destinos()))
	_comprobar("hay rutas desde la isla", MapaGlobal.rutas_desde().size() == 3)
	var zona_ceniza: Zona = MapaGlobal.crear_zona("isla_ceniza", 0, 0)
	_comprobar("las dimensiones remotas vienen de BaseDeDatos",
		zona_ceniza != null and zona_ceniza.limites() == Rect2i(0, 0, 24, 16))
	if zona_ceniza != null:
		zona_ceniza.free()
	var ruta: Resource = MapaGlobal.ruta("principal_ceniza")
	_comprobar("la ruta conoce origen y destino", ruta != null
		and ruta.origen == "isla_principal" and ruta.destino == "isla_ceniza")
	_comprobar("la ruta exige una nave", ruta != null and ruta.barco_requerido == "balandra")

	print("2. Viaje persistente")
	var llegadas: Array = []
	MapaGlobal.viaje_completado.connect(func(id: String): llegadas.append(id))
	_comprobar("inicia un viaje válido", MapaGlobal.iniciar_viaje("principal_ceniza"))
	_comprobar("el viaje queda activo", MapaGlobal.viajando())
	_comprobar("el viaje asigna una instancia estable de flota",
		str(MapaGlobal.viaje_activo.get("barco_id", "")) == "balandra_001")
	_comprobar("la balandra pasa a estado mar",
		FlotaMundo.estado("balandra_001").get("estado", "") == "mar")
	_comprobar("el destino aún no cambia durante la travesía",
		MapaGlobal.ubicacion_actual == "isla_principal")
	_comprobar("rechaza un segundo viaje simultáneo",
		not MapaGlobal.iniciar_viaje("principal_portobello"))

	var serial := MapaGlobal._serializar()
	_comprobar("serializa ubicación y viaje sin nodos",
		serial.has("ubicacion_actual") and serial.has("viaje_activo"))
	MapaGlobal.reiniciar()
	MapaGlobal._cargar(serial)
	_comprobar("recupera el viaje activo", MapaGlobal.viajando())
	_comprobar("recupera el origen guardado",
		str(MapaGlobal.viaje_activo.get("origen", "")) == "isla_principal")

	print("3. Llegada y cancelación")
	Reloj.dia = 3
	Reloj.hora = 8.0
	MapaGlobal._process(0.0)
	_comprobar("llega al destino al superar la duración", llegadas.size() == 1
		and MapaGlobal.ubicacion_actual == "isla_ceniza")
	_comprobar("el viaje termina al llegar", not MapaGlobal.viajando())
	_comprobar("la balandra queda atracada en el destino",
		FlotaMundo.estado("balandra_001").get("posicion", "") == "isla_ceniza"
		and FlotaMundo.estado("balandra_001").get("estado", "") == "puerto")
	_comprobar("se puede cancelar un viaje activo", MapaGlobal.iniciar_viaje("ceniza_principal")
		and MapaGlobal.cancelar_viaje() and not MapaGlobal.viajando())
	_comprobar("cancelar devuelve la nave al puerto de salida",
		FlotaMundo.estado("balandra_001").get("posicion", "") == "isla_ceniza"
		and FlotaMundo.estado("balandra_001").get("estado", "") == "puerto")
	_comprobar("guardado reconoce la sección global",
		"mapa_global" in Guardado.secciones_activas())

func _comprobar(nombre: String, condicion: bool, detalle: String = "") -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s %s" % [nombre, detalle])
