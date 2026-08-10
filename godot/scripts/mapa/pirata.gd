class_name Pirata
extends Node2D
## Un miembro de la tripulacion andando por la isla.
##
## No es decoracion: cada pirata esta asignado a un edificio y su rutina
## depende del estado real de la logistica. Si su estacion se queda sin
## material, deja de trabajar y se va a la taberna. Si es de noche, tambien.
##
## AVISO SOBRE EL ARTE: estos personajes estan DIBUJADOS POR CODIGO (ver
## `_draw`). Es un marcador de posicion deliberado: los unicos sprites de
## personaje gratuitos que encontramos son pixel art de 22 px y desentonan
## brutalmente con los edificios renderizados. Cuando haya sprites decentes,
## se cambia `_draw` por un AnimatedSprite2D y no hay que tocar nada mas.

enum Tarea { TRABAJANDO, YENDO_A_TRABAJAR, A_LA_TABERNA, PASEANDO, DURMIENDO, EN_CASA, COMIENDO }

const VELOCIDAD := 1.5              ## casillas por segundo
const ALTURA := 92.0                ## pixeles, de los pies a la coronilla

var id_personaje: String = ""
var nombre_mostrado: String = "Pirata"
var casa: Vector2i = Vector2i.ZERO          ## su puesto de trabajo
var taberna: Vector2i = Vector2i.ZERO       ## adonde va al anochecer
var horario_id: String = "tripulacion"
var horario: HorarioData = null
var color_ropa := Color("8c3b2f")
var color_panuelo := Color("c9a227")

var pos: Vector2 = Vector2.ZERO             ## en casillas, con decimales
var destino: Vector2 = Vector2.ZERO
var tarea: int = Tarea.PASEANDO
var mirando_derecha := true

var _fase := 0.0
var _espera := 0.0
var _rnd := RandomNumberGenerator.new()

func montar(p_id: String, p_nombre: String, p_casa: Vector2i, p_taberna: Vector2i,
		semilla: int, p_horario_id: String = "tripulacion") -> void:
	id_personaje = p_id
	nombre_mostrado = p_nombre
	casa = p_casa
	taberna = p_taberna
	horario_id = p_horario_id
	horario = BaseDeDatos.horario(horario_id)
	_rnd.seed = semilla
	pos = Vector2(p_casa) + Vector2(_rnd.randf_range(-1.5, 1.5), _rnd.randf_range(-1.5, 1.5))
	destino = pos
	var paleta := [
		Color("8c3b2f"), Color("3f5a6b"), Color("6b5236"),
		Color("4a5d3a"), Color("6d3f5c"), Color("2f4858"),
	]
	color_ropa = paleta[_rnd.randi() % paleta.size()]
	color_panuelo = [Color("c9a227"), Color("b23a3a"), Color("d9d2c5")][_rnd.randi() % 3]
	_actualizar_posicion()

# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if Reloj.pausado:
		return
	_pensar(delta)
	_mover(delta)
	_actualizar_posicion()
	queue_redraw()

## La rutina sale del estado real del juego, no de un temporizador ciego.
func _pensar(delta: float) -> void:
	_espera -= delta
	if _espera > 0.0:
		return
	_espera = _rnd.randf_range(1.5, 4.0)

	var hay_motin := Motin.nivel >= 80.0
	if hay_motin:
		# Se amontonan en la plaza en vez de trabajar.
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
			destino = _punto_cerca(casa, 1.8)
		_:
			tarea = Tarea.PASEANDO
			destino = _punto_cerca(taberna, 4.0)

func _mover(delta: float) -> void:
	var d := destino - pos
	var dist := d.length()
	if dist < 0.08:
		_fase = 0.0
		return
	var paso := VELOCIDAD * delta
	pos += d / dist * minf(paso, dist)
	_fase += delta * 7.0
	# En isometrico, "a la derecha" es que crezca la X de pantalla.
	var dx := d.x - d.y
	if absf(dx) > 0.01:
		mirando_derecha = dx > 0.0

func _actualizar_posicion() -> void:
	position = Iso.centro_fino(pos) + Vector2(0, Iso.MEDIO_Y)

func _punto_cerca(t: Vector2i, radio: float) -> Vector2:
	return Vector2(t) + Vector2(_rnd.randf_range(-radio, radio), _rnd.randf_range(-radio, radio))

# ---------------------------------------------------------------------------
# DIBUJO
# ---------------------------------------------------------------------------

func _draw() -> void:
	Figura.dibujar(self, {
		"andando": (destino - pos).length() > 0.08,
		"fase": _fase,
		"mirando_derecha": mirando_derecha,
		"ropa": color_ropa,
		"panuelo": color_panuelo,
		"altura": ALTURA,
	})

func estado_texto() -> String:
	match tarea:
		Tarea.TRABAJANDO: return "trabajando"
		Tarea.A_LA_TABERNA: return "en la taberna"
		Tarea.DURMIENDO: return "durmiendo"
		Tarea.EN_CASA: return "en casa"
		Tarea.COMIENDO: return "comiendo"
		Tarea.YENDO_A_TRABAJAR: return "de camino"
		_: return "sin rumbo"
