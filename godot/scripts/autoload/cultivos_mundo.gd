extends Node

## AUTOLOAD: CultivosMundo
## Estado guardable de las parcelas. El reloj es la única fuente de tiempo.

signal parcela_cambiada(instancia: String, etapa: int, lista: bool)

var _estados: Dictionary = {} ## instancia -> {definicion, sembrada, lista_en}
var _vivas: Dictionary = {}   ## instancia -> ParcelaCultivo

func _ready() -> void:
	Guardado.registrar("cultivos", _serializar, _cargar)
	Reloj.hora_cambiada.connect(_actualizar)
	Reloj.nuevo_dia.connect(func(_dia): _actualizar(int(Reloj.hora)))

func registrar(parcela) -> void:
	if parcela == null or parcela.identidad == null:
		return
	var id := str(parcela.identidad.instancia)
	_vivas[id] = parcela
	if not _estados.has(id):
		_estados[id] = {"definicion": parcela.definicion_id, "sembrada": false, "lista_en": 0.0}
	parcela.tree_exiting.connect(func(): _vivas.erase(id), CONNECT_ONE_SHOT)

func estado(instancia: String) -> Dictionary:
	return (_estados.get(instancia, {}) as Dictionary).duplicate(true)

## Consulta sin efectos para que una parcela no ofrezca cosechar si la
## mochila no puede recibir la cosecha completa.
func puede_cosechar(instancia: String, inventario: Inventario) -> bool:
	if not _estados.has(instancia) or inventario == null:
		return false
	var estado: Dictionary = _estados[instancia]
	if not bool(estado.get("sembrada", false)) or not _esta_lista(estado):
		return false
	var def: CultivoData = BaseDeDatos.cultivo(str(estado.get("definicion", "")))
	if def == null:
		return false
	for id in def.cosecha:
		if inventario.hueco_para(str(id)) < int(def.cosecha[id]):
			return false
	return true

func sembrar(instancia: String, inventario: Inventario) -> bool:
	if not _estados.has(instancia) or inventario == null:
		return false
	var estado: Dictionary = _estados[instancia]
	if bool(estado.get("sembrada", false)):
		return false
	var def: CultivoData = BaseDeDatos.cultivo(str(estado.get("definicion", "")))
	if def == null or not inventario.retirar(def.semilla, 1):
		return false
	_marcar_sembrado(instancia, estado, def)
	return true

func sembrar_en_almacen(instancia: String, origen: String = "") -> bool:
	if not _estados.has(instancia):
		return false
	var estado: Dictionary = _estados[instancia]
	if bool(estado.get("sembrada", false)):
		return false
	var def: CultivoData = BaseDeDatos.cultivo(str(estado.get("definicion", "")))
	if def == null or not Almacen.retirar(def.semilla, 1):
		return false
	_marcar_sembrado(instancia, estado, def)
	return true

func _marcar_sembrado(instancia: String, estado: Dictionary, def: CultivoData) -> void:
	estado["sembrada"] = true
	estado["lista_en"] = _hora_total() + def.horas_crecimiento
	_estados[instancia] = estado
	_emitir_cambio(instancia)

func cosechar(instancia: String, inventario: Inventario) -> Dictionary:
	if not _estados.has(instancia) or inventario == null:
		return {"ok": false, "productos": {}}
	var estado: Dictionary = _estados[instancia]
	if not puede_cosechar(instancia, inventario):
		return {"ok": false, "productos": {}}
	var def: CultivoData = BaseDeDatos.cultivo(str(estado.get("definicion", "")))
	if def == null:
		return {"ok": false, "productos": {}}
	for id in def.cosecha:
		if inventario.hueco_para(str(id)) < int(def.cosecha[id]):
			return {"ok": false, "productos": {}}
	for id in def.cosecha:
		inventario.anadir(str(id), int(def.cosecha[id]))
	estado["sembrada"] = false
	estado["lista_en"] = 0.0
	_estados[instancia] = estado
	_emitir_cambio(instancia)
	return {"ok": true, "productos": def.cosecha.duplicate(true)}

func puede_cosechar_en_almacen(instancia: String) -> bool:
	if not _estados.has(instancia) or not _esta_lista(_estados[instancia]):
		return false
	var def: CultivoData = BaseDeDatos.cultivo(str((_estados[instancia] as Dictionary).get("definicion", "")))
	if def == null:
		return false
	if Almacen.capacidad_volumen <= 0.0:
		return true
	var volumen := 0.0
	for id in def.cosecha:
		var item: ItemData = BaseDeDatos.item(str(id))
		if item == null:
			return false
		volumen += item.volumen * int(def.cosecha[id])
	return Almacen.volumen_ocupado() + volumen <= Almacen.capacidad_volumen

func cosechar_en_almacen(instancia: String, origen: String = "") -> Dictionary:
	if not _estados.has(instancia) or not puede_cosechar_en_almacen(instancia):
		return {"ok": false, "productos": {}}
	var estado: Dictionary = _estados[instancia]
	var def: CultivoData = BaseDeDatos.cultivo(str(estado.get("definicion", "")))
	if def == null:
		return {"ok": false, "productos": {}}
	var productos: Dictionary = {}
	for id in def.cosecha:
		var clave := str(id)
		var cantidad := int(def.cosecha[id])
		var aceptado := Almacen.anadir(clave, cantidad, origen)
		if aceptado != cantidad:
			for previo in productos:
				Almacen.retirar(str(previo), int(productos[previo]))
			return {"ok": false, "productos": {}}
		productos[clave] = cantidad
	estado["sembrada"] = false
	estado["lista_en"] = 0.0
	_estados[instancia] = estado
	_emitir_cambio(instancia)
	return {"ok": true, "productos": productos}

func etapa(instancia: String) -> int:
	if not _estados.has(instancia):
		return 0
	var estado: Dictionary = _estados[instancia]
	if not bool(estado.get("sembrada", false)):
		return 0
	if _esta_lista(estado):
		return 3
	var def: CultivoData = BaseDeDatos.cultivo(str(estado.get("definicion", "")))
	if def == null:
		return 1
	var restante := maxf(0.0, float(estado.get("lista_en", 0.0)) - _hora_total())
	return clampi(3 - int(ceil(restante / maxf(0.1, def.horas_crecimiento / 3.0))), 1, 2)

func _esta_lista(estado: Dictionary) -> bool:
	return float(estado.get("lista_en", 0.0)) > 0.0 and _hora_total() >= float(estado["lista_en"])

func _actualizar(_valor = 0) -> void:
	for instancia in _estados:
		_emitir_cambio(str(instancia))

func _emitir_cambio(instancia: String) -> void:
	var viva = _vivas.get(instancia)
	var lista := _estados.has(instancia) and _esta_lista(_estados[instancia])
	parcela_cambiada.emit(instancia, etapa(instancia), lista)
	if viva != null and is_instance_valid(viva):
		viva.queue_redraw()

func _hora_total() -> float:
	return float(Reloj.dia * 24) + Reloj.hora

func _serializar() -> Dictionary:
	return {"estados": _estados.duplicate(true)}

func _cargar(datos: Dictionary) -> void:
	_estados = (datos.get("estados", {}) as Dictionary).duplicate(true)
	_actualizar()

func reiniciar() -> void:
	_estados.clear()
	_vivas.clear()
