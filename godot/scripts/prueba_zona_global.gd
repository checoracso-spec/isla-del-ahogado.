extends Node

var correctas := 0
var fallos := 0

func _ready() -> void:
	await get_tree().process_frame
	_ejecutar()
	print("=== %d/%d comprobaciones de zona global ===" % [correctas, correctas + fallos])
	get_tree().quit(0 if fallos == 0 else 1)

func _ejecutar() -> void:
	var zona: Zona = MapaGlobal.crear_zona("portobello", 16, 12)
	_comprobar("crea Portobello desde datos", zona != null)
	if zona == null:
		return
	add_child(zona)
	zona.montar_contenido()
	_comprobar("la zona conserva su identidad", zona.id == "portobello")
	_comprobar("la zona tiene límites propios",
		zona.limites() == Rect2i(0, 0, 16, 12), str(zona.limites()))
	_comprobar("la zona tiene actores ordenados por profundidad",
		zona.actores != null and zona.actores.y_sort_enabled)
	_comprobar("la entrada cae dentro de la zona",
		zona.transitable.cabe_en(zona.entrada(), Huella.cuadrada(0.52)))
	_comprobar("la zona conserva transitabilidad común",
		zona.transitable is TransitableRejilla)
	_comprobar("Portobello monta sus recursos desde datos",
		zona.fuentes_recurso.size() == 1)
	_comprobar("Portobello no inventa cultivos",
		zona.parcelas_cultivo.is_empty())
	_comprobar("el recurso remoto tiene identidad estable",
		zona.fuentes_recurso.size() == 1
		and zona.fuentes_recurso[0].identidad != null)
	_comprobar("el recurso remoto empieza disponible",
		zona.fuentes_recurso.size() == 1
		and zona.fuentes_recurso[0].cantidad() > 0)
	var actor_contenido := Actor.new()
	actor_contenido.name = "ActorPruebaContenido"
	zona.recibir(actor_contenido, zona.entrada())
	_comprobar("recibe un Actor sin crear otro sistema", actor_contenido.get_parent() == zona.actores)
	_comprobar("el Actor usa la transitabilidad de la zona",
		actor_contenido.transitable == zona.transitable)
	_comprobar("el Actor aparece en una casilla válida",
		zona.transitable.cabe_en(actor_contenido.pos_tile, actor_contenido.huella))
	zona.desactivar()
	_comprobar("la zona puede desactivarse", not zona.visible
		and zona.process_mode == Node.PROCESS_MODE_DISABLED)
	zona.activar()
	_comprobar("la zona puede reactivarse", zona.visible
		and zona.process_mode == Node.PROCESS_MODE_INHERIT)

	var clave_recurso := ""
	if zona.fuentes_recurso.size() == 1:
		clave_recurso = str(zona.fuentes_recurso[0].identidad.instancia)
	var ceniza: ZonaRemota = MapaGlobal.crear_zona("isla_ceniza", 20, 14)
	_comprobar("Isla Ceniza declara dos fuentes y un cultivo", ceniza != null)
	if ceniza != null:
		add_child(ceniza)
		ceniza.montar_contenido()
		_comprobar("Isla Ceniza monta sus dos recursos",
			ceniza.fuentes_recurso.size() == 2)
		_comprobar("Isla Ceniza monta su cultivo de datos",
			ceniza.parcelas_cultivo.size() == 1
			and ceniza.parcelas_cultivo[0].definicion_id == "tabaco")
		ceniza.free()
	var reconstruida: ZonaRemota = MapaGlobal.crear_zona("portobello", 16, 12)
	if reconstruida != null:
		add_child(reconstruida)
		reconstruida.montar_contenido()
		_comprobar("la identidad sobrevive al remontaje de la zona",
			clave_recurso != "" and reconstruida.fuentes_recurso.size() == 1
			and str(reconstruida.fuentes_recurso[0].identidad.instancia) == clave_recurso)
		reconstruida.free()

	var actor := Actor.new()
	actor.name = "ActorPruebaZona"
	zona.recibir(actor, zona.entrada())
	_comprobar("recibe un Actor sin crear otro sistema", actor.get_parent() == zona.actores)
	_comprobar("el Actor usa la transitabilidad de la zona",
		actor.transitable == zona.transitable)
	_comprobar("el Actor aparece en una casilla válida",
		zona.transitable.cabe_en(actor.pos_tile, actor.huella))
	zona.desactivar()
	_comprobar("la zona puede desactivarse", not zona.visible
		and zona.process_mode == Node.PROCESS_MODE_DISABLED)
	zona.activar()
	_comprobar("la zona puede reactivarse", zona.visible
		and zona.process_mode == Node.PROCESS_MODE_INHERIT)
	zona.free()

func _comprobar(nombre: String, condicion: bool, detalle: String = "") -> void:
	if condicion:
		correctas += 1
		print("  OK  ", nombre)
	else:
		fallos += 1
		push_error("FALLO: %s %s" % [nombre, detalle])
