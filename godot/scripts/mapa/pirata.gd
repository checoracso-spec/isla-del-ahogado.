class_name Pirata
extends Actor
## Un miembro de la tripulación andando por la isla.
##
## La rutina sigue siendo propia del pirata, pero posición, dirección, huella,
## movimiento, detalle y dibujo base vienen de Actor. Así los futuros animales
## y NPCs no necesitan una segunda implementación de colisiones.

enum Tarea { TRABAJANDO, YENDO_A_TRABAJAR, A_LA_TABERNA, PASEANDO, DURMIENDO, EN_CASA, COMIENDO }

const VELOCIDAD := 1.5
const ALTURA := 92.0
const CAPACIDAD_INVENTARIO_PERSONAL := 12.0

var id_personaje: String = ""
var nombre_mostrado: String = "Pirata"
var identidad: Identidad = null
var casa: Vector2i = Vector2i.ZERO
var trabajo: Vector2i = Vector2i.ZERO
var puesto_id: String = ""
var taberna: Vector2i = Vector2i.ZERO
var horario_id: String = "tripulacion"
var horario: HorarioData = null
var color_ropa := Color("8c3b2f")
var color_panuelo := Color("c9a227")
## Inventario propio del NPC. No es Almacen y no participa en la logistica.
var inventario_personal: Inventario
var oro_personal: int = 0
var hambre: float = 100.0
var energia_personal: float = 100.0
var moral_personal: float = 100.0

## Compatibilidad con el nombre usado por el prototipo anterior. La fuente
## de verdad sigue siendo Actor.pos_tile.
var pos: Vector2:
	get:
		return pos_tile
	set(value):
		pos_tile = value

var destino: Vector2 = Vector2.ZERO
var tarea: int = Tarea.PASEANDO

var _espera := 0.0
var _rnd := RandomNumberGenerator.new()

func _init() -> void:
	inventario_personal = Inventario.new()
	inventario_personal.capacidad = CAPACIDAD_INVENTARIO_PERSONAL

## Contrato común para que puertas, cofres y futuras interfaces puedan tratar
## al NPC como un portador sin conocer campos internos de Pirata.
func inventario() -> Inventario:
	return inventario_personal

func ajustar_necesidad(id: String, delta: float) -> float:
	match id:
		"hambre": hambre = clampf(hambre + delta, 0.0, 100.0)
		"energia": energia_personal = clampf(energia_personal + delta, 0.0, 100.0)
		"moral": moral_personal = clampf(moral_personal + delta, 0.0, 100.0)
	return necesidad(id)

func necesidad(id: String) -> float:
	match id:
		"hambre": return hambre
		"energia": return energia_personal
		"moral": return moral_personal
		_: return 0.0

## Consume un objeto del inventario personal y aplica sus efectos de datos.
## Esta ruta no toca Almacen ni Motin: las necesidades del NPC son propias.
func consumir_item_personal(id: String) -> Dictionary:
	var item: ItemData = BaseDeDatos.item(id)
	if item == null or (item.comida <= 0.0 and item.moral <= 0.0):
		return {"ok": false, "motivo": "Ese objeto no satisface necesidades personales."}
	if not inventario_personal.retirar(id, 1):
		return {"ok": false, "motivo": "El NPC no tiene ese objeto."}
	if item.comida > 0.0:
		ajustar_necesidad("hambre", item.comida)
	if item.moral > 0.0:
		ajustar_necesidad("moral", item.moral)
	_anotar_estado()
	return {"ok": true, "id": id, "comida": item.comida, "moral": item.moral}

## Atiende una necesidad usando el mejor objeto disponible en el inventario.
## La rutina decide el tipo; ItemData decide el efecto y el identificador.
func atender_necesidad_de_rutina() -> Dictionary:
	var necesidad_id := ""
	match tarea:
		Tarea.COMIENDO: necesidad_id = "hambre"
		Tarea.A_LA_TABERNA:
			var taberna := get_node_or_null("/root/TabernaManager")
			if taberna != null and taberna.has_method("servir_ronda_a"):
				var ronda: Dictionary = taberna.call("servir_ronda_a", self)
				if bool(ronda.get("ok", false)):
					return ronda
			necesidad_id = "moral"
		_: return {"ok": false, "motivo": "La tarea actual no consume."}
	var mejor_id := ""
	var mejor_efecto := 0.0
	for id in inventario_personal.ids():
		var item: ItemData = BaseDeDatos.item(str(id))
		if item == null:
			continue
		var efecto := item.comida if necesidad_id == "hambre" else item.moral
		if efecto > mejor_efecto:
			mejor_efecto = efecto
			mejor_id = str(id)
	if mejor_id == "":
		return {"ok": false, "motivo": "No hay consumibles para %s." % necesidad_id}
	return consumir_item_personal(mejor_id)

## Avanza necesidades en horas de juego. No consume recursos: la comida y el
## ron se resolveran desde servicios de edificio en un bloque posterior.
func actualizar_necesidades(horas: float) -> void:
	if horas <= 0.0:
		return
	var actividad := _actividad_de_tarea()
	for id in ["hambre", "energia", "moral"]:
		var regla = BaseDeDatos.necesidad(id)
		if regla == null:
			continue
		var valor: float = necesidad(id) + float(regla.cambio_por_hora(actividad)) * horas
		_asignar_necesidad(id, clampf(valor, 0.0, 100.0))
	_anotar_estado()

func _asignar_necesidad(id: String, valor: float) -> void:
	match id:
		"hambre": hambre = valor
		"energia": energia_personal = valor
		"moral": moral_personal = valor

func _actividad_de_tarea() -> String:
	match tarea:
		Tarea.TRABAJANDO, Tarea.YENDO_A_TRABAJAR: return "trabajar"
		Tarea.A_LA_TABERNA: return "taberna"
		Tarea.DURMIENDO: return "dormir"
		Tarea.EN_CASA: return "casa"
		Tarea.COMIENDO: return "comer"
		_: return "pasear"

func montar(p_id: String, p_nombre: String, p_casa: Vector2i, p_taberna: Vector2i,
		semilla: int, p_horario_id: String = "tripulacion",
		p_trabajo: Vector2i = Vector2i(-1, -1), p_clave: String = "",
		p_puesto_id: String = "") -> void:
	id_personaje = p_id
	nombre_mostrado = p_nombre
	var datos_personaje: PersonajeData = BaseDeDatos.personaje(p_id)
	puesto_id = p_puesto_id
	if puesto_id == "" and datos_personaje != null:
		puesto_id = datos_personaje.puesto_id
	var clave := p_clave if p_clave != "" else p_id
	if clave == "":
		clave = "marinero_%d" % semilla
	identidad = Entidades.identificar("npc", p_id if p_id != "" else "marinero", "npc:" + clave)
	Entidades.vincular(identidad, self)
	casa = p_casa
	trabajo = p_casa if p_trabajo == Vector2i(-1, -1) else p_trabajo
	taberna = p_taberna
	horario_id = p_horario_id
	horario = BaseDeDatos.horario(horario_id)
	velocidad = VELOCIDAD
	huella = Huella.cuadrada(0.56)
	detalle = Detalle.CERCA
	_rnd.seed = semilla
	pos_tile = Vector2(p_casa) + Vector2(_rnd.randf_range(-1.5, 1.5), _rnd.randf_range(-1.5, 1.5))
	destino = pos_tile
	var paleta := [
		Color("8c3b2f"), Color("3f5a6b"), Color("6b5236"),
		Color("4a5d3a"), Color("6d3f5c"), Color("2f4858"),
	]
	color_ropa = paleta[_rnd.randi() % paleta.size()]
	color_panuelo = [Color("c9a227"), Color("b23a3a"), Color("d9d2c5")][_rnd.randi() % 3]
	_aplicar_carga_inicial()
	_aplicar_posicion()
	_gestor_npcs().call("registrar", self)
	queue_redraw()

func _aplicar_carga_inicial() -> void:
	var datos: PersonajeData = BaseDeDatos.personaje(id_personaje)
	if datos == null:
		return
	inventario_personal.vaciar()
	for id in datos.inventario_inicial:
		inventario_personal.anadir(str(id), int(datos.inventario_inicial[id]))
	oro_personal = datos.oro_inicial
	for id in datos.necesidades_iniciales:
		_asignar_necesidad(str(id), clampf(float(datos.necesidades_iniciales[id]), 0.0, 100.0))

func aplicar_estado(datos: Dictionary) -> void:
	var inventario_datos: Variant = datos.get("inventario", {})
	if inventario_datos is Dictionary:
		inventario_personal.cargar(inventario_datos)
	oro_personal = int(datos.get("oro_personal", oro_personal))
	var necesidades_datos: Variant = datos.get("necesidades", {})
	if necesidades_datos is Dictionary:
		hambre = clampf(float(necesidades_datos.get("hambre", hambre)), 0.0, 100.0)
		energia_personal = clampf(float(necesidades_datos.get("energia", energia_personal)), 0.0, 100.0)
		moral_personal = clampf(float(necesidades_datos.get("moral", moral_personal)), 0.0, 100.0)
	var p: Variant = datos.get("pos_tile", {})
	if p is Dictionary:
		pos_tile = Vector2(float(p.get("x", pos_tile.x)), float(p.get("y", pos_tile.y)))
	var d: Variant = datos.get("direccion", {})
	if d is Dictionary:
		direccion = Vector2(float(d.get("x", direccion.x)), float(d.get("y", direccion.y)))
	var objetivo: Variant = datos.get("destino", {})
	if objetivo is Dictionary:
		destino = Vector2(float(objetivo.get("x", pos_tile.x)), float(objetivo.get("y", pos_tile.y)))
	tarea = int(datos.get("tarea", tarea))
	estado = str(datos.get("estado", estado))
	puesto_id = str(datos.get("puesto_id", puesto_id))
	_aplicar_posicion()
	queue_redraw()

func serializar() -> Dictionary:
	return {
		"definicion": id_personaje,
		"pos_tile": {"x": pos_tile.x, "y": pos_tile.y},
		"direccion": {"x": direccion.x, "y": direccion.y},
		"destino": {"x": destino.x, "y": destino.y},
		"tarea": tarea,
		"estado": estado,
		"puesto_id": puesto_id,
		"inventario": inventario_personal.serializar(),
		"oro_personal": oro_personal,
		"necesidades": {
			"hambre": hambre,
			"energia": energia_personal,
			"moral": moral_personal,
		},
	}

## La rutina sale del estado real del juego, no de un temporizador ciego.
func actualizar(delta: float, _nivel: int) -> void:
	if not Reloj.pausado:
		actualizar_necesidades((24.0 / Reloj.DURACION_DIA_SEG) * delta * Reloj.velocidad)
	_pensar(delta)
	var distancia := destino - pos_tile
	if distancia.length() <= 0.08:
		estado = "idle"
		_anotar_estado()
		return
	# Actor resuelve la colisión y actualiza dirección/posición. Si un edificio
	# bloquea la línea directa, el pirata no atraviesa la estructura.
	mover(distancia, delta)
	_anotar_estado()

func _pensar(delta: float) -> void:
	_espera -= delta
	if _espera > 0.0:
		return
	_espera = _rnd.randf_range(1.5, 4.0)

	var hay_motin := Motin.nivel >= 80.0
	if hay_motin:
		tarea = Tarea.PASEANDO
		destino = Vector2(casa) + Vector2(_rnd.randf_range(-6, 6), _rnd.randf_range(-6, 6))
		return

	var actividad: String = horario.actividad_en(Reloj.hora) if horario != null else "trabajar"
	match actividad:
		"dormir":
			tarea = Tarea.DURMIENDO
			destino = _punto_cerca(casa, 1.0)
		"casa":
			tarea = Tarea.EN_CASA
			destino = _punto_cerca(casa, 1.2)
		"comer":
			tarea = Tarea.COMIENDO
			destino = _punto_cerca(taberna, 2.5)
		"taberna":
			tarea = Tarea.A_LA_TABERNA
			destino = _punto_cerca(taberna, 2.5)
		"trabajar":
			tarea = Tarea.TRABAJANDO
			destino = _punto_cerca(trabajo, 1.8)
		_:
			tarea = Tarea.PASEANDO
			destino = _punto_cerca(taberna, 4.0)
	atender_necesidad_de_rutina()

func _punto_cerca(t: Vector2i, radio: float) -> Vector2:
	return Vector2(t) + Vector2(_rnd.randf_range(-radio, radio), _rnd.randf_range(-radio, radio))

func _anotar_estado() -> void:
	var gestor := _gestor_npcs()
	if gestor != null:
		gestor.call("anotar", self)

func _gestor_npcs() -> Node:
	return get_node_or_null("/root/NpcsMundo")

func _opciones_figura() -> Dictionary:
	var op := super()
	op["ropa"] = color_ropa
	op["panuelo"] = color_panuelo
	op["altura"] = ALTURA
	op["sombrero"] = true
	return op

func estado_texto() -> String:
	match tarea:
		Tarea.TRABAJANDO: return "trabajando"
		Tarea.A_LA_TABERNA: return "en la taberna"
		Tarea.DURMIENDO: return "durmiendo"
		Tarea.EN_CASA: return "en casa"
		Tarea.COMIENDO: return "comiendo"
		Tarea.YENDO_A_TRABAJAR: return "de camino"
		_: return "sin rumbo"
