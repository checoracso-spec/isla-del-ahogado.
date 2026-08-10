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

var id_personaje: String = ""
var nombre_mostrado: String = "Pirata"
var identidad: Identidad = null
var casa: Vector2i = Vector2i.ZERO
var trabajo: Vector2i = Vector2i.ZERO
var taberna: Vector2i = Vector2i.ZERO
var horario_id: String = "tripulacion"
var horario: HorarioData = null
var color_ropa := Color("8c3b2f")
var color_panuelo := Color("c9a227")

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

func montar(p_id: String, p_nombre: String, p_casa: Vector2i, p_taberna: Vector2i,
		semilla: int, p_horario_id: String = "tripulacion",
		p_trabajo: Vector2i = Vector2i(-1, -1), p_clave: String = "") -> void:
	id_personaje = p_id
	nombre_mostrado = p_nombre
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
	_aplicar_posicion()
	_gestor_npcs().call("registrar", self)
	queue_redraw()

func aplicar_estado(datos: Dictionary) -> void:
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
	}

## La rutina sale del estado real del juego, no de un temporizador ciego.
func actualizar(delta: float, _nivel: int) -> void:
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
