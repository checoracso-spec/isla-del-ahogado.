extends Node
## AUTOLOAD: Bolsa
##
## Lo que lleva encima el jugador. Deliberadamente SEPARADO de Almacen:
##
##   Almacen = los cofres del pueblo, con su cadena de suministro, sus cuellos
##             de botella y sus 37 pruebas. No se toca.
##   Bolsa   = lo que carga una persona. Poco sitio, y se lo lleva puesto.
##
## Sacar tablones del almacén para llevártelos es un TRASVASE explícito entre
## dos inventarios, no un truco de contabilidad. Esa frontera es lo que evita
## que el juego de gestión y el juego de exploración se contaminen.

signal salud_cambiada(valor: float)
signal energia_cambiada(valor: float)
signal oro_cambiado(valor: int)
signal objetos_cambiados()
signal desmayado()

const CAPACIDAD_INICIAL := 60.0

var mochila := Inventario.new()
var oro: int = 0
var salud: float = 100.0
var salud_max: float = 100.0
var energia: float = 100.0
var energia_max: float = 100.0
var herramientas: Array[String] = []

func _ready() -> void:
	mochila.capacidad = CAPACIDAD_INICIAL
	mochila.cambiado.connect(func(_id, _n): objetos_cambiados.emit())
	Guardado.registrar("jugador", _serializar, _cargar)

# ---------------------------------------------------------------------------
# ESTADO VITAL
# ---------------------------------------------------------------------------

func ajustar_salud(delta: float) -> void:
	var antes := salud
	salud = clampf(salud + delta, 0.0, salud_max)
	if not is_equal_approx(antes, salud):
		salud_cambiada.emit(salud)
		if salud <= 0.0:
			desmayado.emit()

func ajustar_energia(delta: float) -> void:
	var antes := energia
	energia = clampf(energia + delta, 0.0, energia_max)
	if not is_equal_approx(antes, energia):
		energia_cambiada.emit(energia)

func cansado() -> bool:
	return energia < 15.0

# ---------------------------------------------------------------------------
# DINERO
# ---------------------------------------------------------------------------

func ingresar(cantidad: int) -> void:
	if cantidad <= 0:
		return
	oro += cantidad
	oro_cambiado.emit(oro)

## Todo o nada, como el resto del juego.
func pagar(cantidad: int) -> bool:
	if cantidad <= 0:
		return true
	if oro < cantidad:
		return false
	oro -= cantidad
	oro_cambiado.emit(oro)
	return true

# ---------------------------------------------------------------------------
# HERRAMIENTAS
# ---------------------------------------------------------------------------

func tiene_herramienta(id: String) -> bool:
	return id in herramientas

func equipar(id: String) -> void:
	if id not in herramientas:
		herramientas.append(id)

func equipar_desde_mochila(id: String) -> Dictionary:
	var item: ItemData = BaseDeDatos.item(id)
	if item == null or item.tipo != "herramienta":
		return {"ok": false, "motivo": "Ese objeto no es una herramienta."}
	if mochila.cantidad(id) <= 0:
		return {"ok": false, "motivo": "No tienes esa herramienta."}
	equipar(id)
	objetos_cambiados.emit()
	return {"ok": true, "motivo": "%s equipada." % item.nombre}

func consumir(id: String) -> Dictionary:
	var item: ItemData = BaseDeDatos.item(id)
	if item == null or (item.moral <= 0.0 and item.comida <= 0.0):
		return {"ok": false, "motivo": "Ese objeto no se puede consumir."}
	if not mochila.retirar(id, 1):
		return {"ok": false, "motivo": "No tienes ese objeto."}
	if item.comida > 0.0:
		ajustar_energia(item.comida)
	if item.moral > 0.0:
		Motin.aliviar(item.moral)
	objetos_cambiados.emit()
	return {"ok": true, "motivo": "%s consumido." % item.nombre,
		"energia": item.comida, "moral": item.moral}

# ---------------------------------------------------------------------------
# TRASVASE CON EL ALMACÉN
# ---------------------------------------------------------------------------
# Las dos únicas puertas entre la mochila y la logística del pueblo.
# Cualquier otra ruta sería una fuga: si algo entra o sale del almacén,
# tiene que pasar por aquí o por el propio Almacen.

func depositar_en_almacen(id: String, n: int) -> int:
	var puede := mini(n, mochila.cantidad(id))
	if puede <= 0:
		return 0
	var aceptado := Almacen.anadir(id, puede, "jugador")
	if aceptado > 0:
		mochila.retirar(id, aceptado)
	return aceptado

func retirar_del_almacen(id: String, n: int) -> int:
	var hueco := mochila.hueco_para(id)
	var puede := mini(mini(n, Almacen.disponible(id)), hueco)
	if puede <= 0:
		return 0
	if not Almacen.retirar(id, puede):
		return 0
	return mochila.anadir(id, puede)

# ---------------------------------------------------------------------------
# GUARDADO
# ---------------------------------------------------------------------------

func _serializar() -> Dictionary:
	return {
		"mochila": mochila.serializar(),
		"oro": oro,
		"salud": salud,
		"salud_max": salud_max,
		"energia": energia,
		"energia_max": energia_max,
		"herramientas": herramientas.duplicate(),
	}

func _cargar(d: Dictionary) -> void:
	mochila.cargar(d.get("mochila", {}))
	oro = int(d.get("oro", 0))
	salud_max = float(d.get("salud_max", 100.0))
	salud = float(d.get("salud", salud_max))
	energia_max = float(d.get("energia_max", 100.0))
	energia = float(d.get("energia", energia_max))
	var hs: Array[String] = []
	for h in d.get("herramientas", []):
		hs.append(str(h))
	herramientas = hs
	oro_cambiado.emit(oro)
	salud_cambiada.emit(salud)
	energia_cambiada.emit(energia)
	objetos_cambiados.emit()
