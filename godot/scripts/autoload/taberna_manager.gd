extends Node
## AUTOLOAD: TabernaManager
## Servicios manuales de la taberna. No duplica consumo ni inventarios.

signal taberna_abierta()
signal taberna_cerrada()
signal actualizado()
signal resultado(mensaje: String)

const COSTE_MARINERO := 75

var abierta := false
var estado_actual := "activa"
var marineros_contratados := 0
var _indice_rumor := 0
const RUMORES := [
	"Un mercante de la Corona llegará esta noche con acero escondido.",
	"Dicen que hay restos de naufragio al norte de la isla.",
	"La Marina ha aumentado las patrullas cerca del arrecife.",
	"Un capitán corrupto compra seda sin hacer preguntas.",
]

func _ready() -> void:
	Guardado.registrar("taberna", _serializar, _cargar)

func abrir(estado: String = "activa") -> void:
	abierta = true
	estado_actual = "activa" if estado == "abierta" else estado
	taberna_abierta.emit()
	actualizado.emit()

func cerrar() -> void:
	abierta = false
	estado_actual = "activa"
	taberna_cerrada.emit()

func servir_ronda() -> bool:
	if estado_actual == "detenida":
		resultado.emit("La taberna está cerrada hasta el amanecer.")
		return false
	if Bolsa.mochila.cantidad("raciones") < 1 or Bolsa.mochila.cantidad("ron") < 1:
		resultado.emit("Necesitas 1 ración y 1 ron en la mochila.")
		return false
	Bolsa.consumir("raciones")
	Bolsa.consumir("ron")
	Motin.aliviar(2.0)
	resultado.emit("La ronda está servida: energía y moral recuperadas.")
	actualizado.emit()
	return true

## Servicio para entidades del mundo con inventario propio, como Pirata.
## No usa Bolsa ni Almacen: la ronda consume la provisión personal del NPC.
func servir_ronda_a(entidad: Node) -> Dictionary:
	if estado_actual != "activa":
		return {"ok": false, "motivo": "La taberna no esta activa."}
	if entidad == null or not entidad.has_method("inventario") \
			or not entidad.has_method("ajustar_necesidad"):
		return {"ok": false, "motivo": "La entidad no admite servicios personales."}
	var inventario: Inventario = entidad.inventario()
	if inventario == null or not inventario.hay("raciones") or not inventario.hay("ron"):
		return {"ok": false, "motivo": "Faltan raciones o ron en el inventario personal."}
	var raciones: ItemData = BaseDeDatos.item("raciones")
	var ron: ItemData = BaseDeDatos.item("ron")
	if not inventario.retirar("raciones", 1) or not inventario.retirar("ron", 1):
		return {"ok": false, "motivo": "Las provisiones cambiaron antes de servir."}
	entidad.ajustar_necesidad("hambre", raciones.comida if raciones != null else 0.0)
	entidad.ajustar_necesidad("moral", ron.moral if ron != null else 0.0)
	return {"ok": true, "servicio": "ronda_personal", "hambre": raciones.comida if raciones != null else 0.0,
		"moral": ron.moral if ron != null else 0.0}

func contratar_marinero() -> bool:
	if estado_actual != "activa":
		resultado.emit("La contratación sólo está disponible con la taberna activa.")
		return false
	if Bolsa.oro < COSTE_MARINERO:
		resultado.emit("Necesitas %d doblones para contratar un marinero." % COSTE_MARINERO)
		return false
	if not Bolsa.pagar(COSTE_MARINERO):
		return false
	marineros_contratados += 1
	Motin.tripulacion += 1
	resultado.emit("Marinero contratado. La tripulación ahora tiene %d." % Motin.tripulacion)
	actualizado.emit()
	return true

func escuchar_rumor() -> String:
	var rumor: String = RUMORES[_indice_rumor % RUMORES.size()]
	_indice_rumor += 1
	resultado.emit(rumor)
	return rumor

func _serializar() -> Dictionary:
	return {
		"marineros_contratados": marineros_contratados,
		"tripulacion": Motin.tripulacion,
	}

func _cargar(datos: Dictionary) -> void:
	marineros_contratados = maxi(0, int(datos.get("marineros_contratados", 0)))
	Motin.tripulacion = maxi(0, int(datos.get("tripulacion", 8)))
	actualizado.emit()
