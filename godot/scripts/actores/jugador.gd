class_name Jugador
extends Actor
## El personaje que controlas.
##
## Sólo hace dos cosas: leer el mando y buscar qué tiene delante. Todo lo que
## pasa AL interactuar lo decide el objeto, no el jugador — por eso aquí no hay
## ni un `if es_una_puerta`. Cuando existan cofres, camas o NPCs, este archivo
## no cambia.

signal objetivo_cambiado(objetivo: Interactuable)
signal interactuo(objetivo: Interactuable)

const VELOCIDAD_ANDAR := 3.4
const VELOCIDAD_CORRER := 5.8
const COSTE_CORRER := 6.0          ## energía por segundo corriendo

var objetivo: Interactuable = null
var control_activo: bool = true

func _ready() -> void:
	velocidad = VELOCIDAD_ANDAR
	huella = Huella.cuadrada(0.52)
	# z_index se queda en 0 a propósito. Tenía 1 "para ir por delante de la
	# tripulación", y eso se salta la ordenación por profundidad: el jugador se
	# dibujaba encima de una casa aunque estuviera DETRÁS de ella. Dentro del
	# contenedor ordenado por Y manda la Y, y nada más.
	z_index = Capas.MUNDO

func actualizar(delta: float, _nivel: int) -> void:
	if not control_activo:
		estado = "idle"
		return
	_mover_con_mando(delta)
	_buscar_objetivo()
	# Deja constancia de dónde está para que el guardado la encuentre.
	# Es Ubicacion quien la guarda, no Bolsa: una lleva el dónde y otra el qué.
	Ubicacion.anotar(pos_tile, direccion)

## Interfaz común para objetos que entregan o reciben inventario.
## La mochila sigue siendo independiente de Almacen.
func inventario() -> Inventario:
	return Bolsa.mochila

func _mover_con_mando(delta: float) -> void:
	var dir := Controles.eje_movimiento_iso()
	var corriendo := Input.is_action_pressed("correr") and not Bolsa.cansado()
	velocidad = VELOCIDAD_CORRER if corriendo else VELOCIDAD_ANDAR

	var se_movio := mover(dir, delta)
	if se_movio and corriendo:
		Bolsa.ajustar_energia(-COSTE_CORRER * delta)

## Se queda con el interactuable disponible más cercano que esté a su alcance.
## Los objetos se registran solos en un grupo, así que esto funciona igual en
## la isla, dentro de una casa o en un barco.
func _buscar_objetivo() -> void:
	var mejor: Interactuable = null
	var mejor_dist := INF
	for nodo in get_tree().get_nodes_in_group(Interactuable.GRUPO):
		var i := nodo as Interactuable
		# `is_visible_in_tree` es lo que separa las zonas: al entrar en una casa
		# el exterior se oculta, y sus puertas dejan de estar al alcance aunque
		# sus casillas coincidan por número con las de dentro.
		if i == null or not i.is_inside_tree() or not i.is_visible_in_tree():
			continue
		if not i.disponible(self):
			continue
		var d := i.distancia_interaccion(pos_tile)
		if d <= i.alcance and d < mejor_dist:
			mejor = i
			mejor_dist = d
	if mejor != objetivo:
		objetivo = mejor
		objetivo_cambiado.emit(objetivo)

func _unhandled_input(evento: InputEvent) -> void:
	if not control_activo or objetivo == null:
		return
	if evento.is_action_pressed("interactuar"):
		var quien := objetivo
		quien.interactuar(self)
		interactuo.emit(quien)
		get_viewport().set_input_as_handled()

func _opciones_figura() -> Dictionary:
	var op := super()
	op["ropa"] = Color("2f4858")
	op["panuelo"] = Color("b8402f")
	op["sombrero"] = true
	op["altura"] = 98.0
	return op
