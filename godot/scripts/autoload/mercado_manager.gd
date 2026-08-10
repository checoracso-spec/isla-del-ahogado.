extends Node
## AUTOLOAD: MercadoManager
## Comercio manual mínimo. El stock del comerciante es independiente de Almacen.

signal mercado_abierto()
signal mercado_cerrado()
signal actualizado()
signal operacion_realizada(mensaje: String)

const STOCK_INICIAL := {
	"ron": 12,
	"raciones": 20,
	"carbon": 10,
	"madera_naufragio": 20,
	"aceite_imperial": 4,
	"acero_imperial": 3,
}

var stock := Inventario.new()
var demanda: Dictionary = {} ## id -> indice relativo; 1.0 = normal
var abierto := false
var _inicializado := false

func _ready() -> void:
	Guardado.registrar("mercado", _serializar, _cargar)
	_inicializar_stock()

func _inicializar_stock() -> void:
	if _inicializado:
		return
	for id in STOCK_INICIAL:
		stock.anadir(id, int(STOCK_INICIAL[id]))
		demanda[id] = float(demanda.get(id, 1.0))
	_inicializado = true

func abrir() -> void:
	abierto = true
	mercado_abierto.emit()
	actualizado.emit()

func cerrar() -> void:
	abierto = false
	mercado_cerrado.emit()

func indice_oferta(id: String) -> float:
	var objetivo := maxi(1, int(STOCK_INICIAL.get(id, 1)))
	return float(stock.cantidad(id)) / float(objetivo)

func multiplicador_oferta(id: String) -> float:
	var oferta := indice_oferta(id)
	var evento := EventosMundo.multiplicador_oferta(id)
	if oferta <= 0.25:
		return 1.50 * evento
	if oferta <= 0.50:
		return 1.25 * evento
	if oferta >= 1.50:
		return 0.75 * evento
	if oferta >= 1.25:
		return 0.90 * evento
	return evento

func indice_demanda(id: String) -> float:
	return clampf(float(demanda.get(id, 1.0)), 0.5, 1.5)

func multiplicador_demanda(id: String) -> float:
	return 1.0 + (indice_demanda(id) - 1.0) * 0.5

func registrar_demanda(id: String, variacion: float) -> void:
	demanda[id] = clampf(indice_demanda(id) + variacion, 0.5, 1.5)
	actualizado.emit()

func reiniciar_demanda() -> void:
	demanda.clear()
	for id in STOCK_INICIAL:
		demanda[id] = 1.0

func precio_compra(id: String) -> int:
	var item: ItemData = BaseDeDatos.item(id)
	var base := float(item.valor_base if item else 1) * 1.25
	return maxi(1, int(ceil(base * multiplicador_oferta(id) * multiplicador_demanda(id))))

func precio_venta(id: String) -> int:
	var item: ItemData = BaseDeDatos.item(id)
	var base := float(item.valor_base if item else 1) * 0.75
	return maxi(1, int(floor(base * Plantel.factor("precio_venta")
		* multiplicador_oferta(id) * multiplicador_demanda(id))))

func comprar(id: String, cantidad: int = 1) -> bool:
	if cantidad <= 0 or stock.cantidad(id) < cantidad:
		operacion_realizada.emit("El mercado no tiene suficiente mercancía.")
		return false
	var total := precio_compra(id) * cantidad
	if Bolsa.oro < total:
		operacion_realizada.emit("No tienes suficientes doblones.")
		return false
	if Bolsa.mochila.hueco_para(id) < cantidad:
		operacion_realizada.emit("La mochila no tiene espacio.")
		return false
	if not Bolsa.pagar(total):
		return false
	var movido := stock.transferir_a(Bolsa.mochila, id, cantidad)
	if movido != cantidad:
		Bolsa.ingresar(total)
		operacion_realizada.emit("La compra no pudo completarse.")
		return false
	registrar_demanda(id, 0.08 * cantidad)
	operacion_realizada.emit("Compraste %d × %s por %d doblones." % [cantidad, BaseDeDatos.nombre_item(id), total])
	actualizado.emit()
	return true

func vender(id: String, cantidad: int = 1) -> bool:
	if cantidad <= 0 or Bolsa.mochila.cantidad(id) < cantidad:
		operacion_realizada.emit("No tienes esa mercancía.")
		return false
	var total := precio_venta(id) * cantidad
	var movido := Bolsa.mochila.transferir_a(stock, id, cantidad)
	if movido != cantidad:
		operacion_realizada.emit("El mercado no puede aceptar esa mercancía.")
		return false
	registrar_demanda(id, -0.06 * cantidad)
	Bolsa.ingresar(total)
	operacion_realizada.emit("Vendiste %d × %s por %d doblones." % [cantidad, BaseDeDatos.nombre_item(id), total])
	actualizado.emit()
	return true

func lista_stock() -> Array:
	return stock.lista()

func _serializar() -> Dictionary:
	return {"stock": stock.serializar(), "demanda": demanda.duplicate(true),
		"inicializado": _inicializado}

func _cargar(datos: Dictionary) -> void:
	stock.cargar(datos.get("stock", {}))
	demanda = (datos.get("demanda", {}) as Dictionary).duplicate(true)
	if demanda.is_empty():
		reiniciar_demanda()
	_inicializado = bool(datos.get("inicializado", true))
	actualizado.emit()
