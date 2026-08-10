extends Node
## AUTOLOAD: FlotaMundo
##
## Mantiene instancias de barcos como datos planos. Un barco puede cambiar de
## puerto, estar en el mar o sufrir daño sin que una ruta global tenga que
## guardar referencias a nodos de una escena.

signal barco_cambiado(instance_id: String)

var barcos: Dictionary = {}

func _ready() -> void:
	Guardado.registrar("barcos", _serializar, _cargar)
	if barcos.is_empty():
		_recrear_predeterminados()

func _recrear_predeterminados() -> void:
	barcos.clear()
	var orden := ["balandra", "bergantin", "galeon"]
	for i in orden.size():
		var definicion = BaseDeDatos.barco(orden[i])
		if definicion == null:
			continue
		var instance_id := "%s_001" % str(definicion.get("id"))
		barcos[instance_id] = {
			"instance_id": instance_id,
			"definition_id": str(definicion.get("id")),
			"nombre": str(definicion.get("nombre")),
			"propietario": "jugador",
			"estado": "puerto",
			"posicion": "isla_principal",
			"destino": "",
			"salud": int(definicion.get("salud_max")),
			"armadura": int(definicion.get("armadura")),
			"canones": 0,
			"provisiones": 50,
			"carga": {},
		}

func ids() -> Array:
	var resultado: Array = barcos.keys()
	resultado.sort()
	return resultado

func estado(instance_id: String) -> Dictionary:
	return (barcos.get(instance_id, {}) as Dictionary).duplicate(true)

func disponibles(origen: String = "") -> Array:
	var resultado: Array = []
	for instance_id in ids():
		var b: Dictionary = barcos[instance_id]
		if str(b.get("estado", "")) != "puerto":
			continue
		if origen != "" and str(b.get("posicion", "")) != origen:
			continue
		if int(b.get("salud", 0)) <= 0:
			continue
		resultado.append(instance_id)
	return resultado

func disponible_para(definicion_id: String, origen: String) -> String:
	for instance_id in disponibles(origen):
		var b: Dictionary = barcos[instance_id]
		if str(b.get("definition_id", "")) == definicion_id:
			return instance_id
	return ""

func despachar(instance_id: String, origen: String, destino: String) -> bool:
	if not barcos.has(instance_id):
		return false
	var b: Dictionary = barcos[instance_id]
	if str(b.get("estado", "")) != "puerto" \
			or str(b.get("posicion", "")) != origen \
			or int(b.get("salud", 0)) <= 0:
		return false
	b["estado"] = "mar"
	b["posicion"] = origen
	b["destino"] = destino
	barcos[instance_id] = b
	barco_cambiado.emit(instance_id)
	return true

func llegar(instance_id: String, destino: String) -> bool:
	if not barcos.has(instance_id):
		return false
	var b: Dictionary = barcos[instance_id]
	if str(b.get("estado", "")) != "mar":
		return false
	b["estado"] = "puerto"
	b["posicion"] = destino
	b["destino"] = ""
	barcos[instance_id] = b
	barco_cambiado.emit(instance_id)
	return true

func cancelar(instance_id: String, origen: String) -> bool:
	if not barcos.has(instance_id):
		return false
	var b: Dictionary = barcos[instance_id]
	if str(b.get("estado", "")) != "mar":
		return false
	b["estado"] = "puerto"
	b["posicion"] = origen
	b["destino"] = ""
	barcos[instance_id] = b
	barco_cambiado.emit(instance_id)
	return true

func reparar(instance_id: String, cantidad: int) -> int:
	if not barcos.has(instance_id):
		return 0
	var b: Dictionary = barcos[instance_id]
	var definicion = BaseDeDatos.barco(str(b.get("definition_id", "")))
	if definicion == null:
		return 0
	var antes := int(b.get("salud", 0))
	b["salud"] = mini(int(definicion.get("salud_max")), antes + maxi(0, cantidad))
	barcos[instance_id] = b
	barco_cambiado.emit(instance_id)
	return int(b["salud"]) - antes

## API mínima para futuros daños navales; todavía no existe combate que la
## invoque, pero el estado de salud ya tiene un único punto de escritura.
func aplicar_dano(instance_id: String, cantidad: int) -> int:
	if not barcos.has(instance_id):
		return 0
	var b: Dictionary = barcos[instance_id]
	var antes := int(b.get("salud", 0))
	b["salud"] = maxi(0, antes - maxi(0, cantidad))
	barcos[instance_id] = b
	barco_cambiado.emit(instance_id)
	return antes - int(b["salud"])

func _serializar() -> Dictionary:
	return {"barcos": barcos.duplicate(true)}

func _cargar(datos: Dictionary) -> void:
	var recibidos: Variant = datos.get("barcos", {})
	barcos = recibidos.duplicate(true) if recibidos is Dictionary else {}
	if barcos.is_empty():
		_recrear_predeterminados()

func reiniciar() -> void:
	_recrear_predeterminados()
