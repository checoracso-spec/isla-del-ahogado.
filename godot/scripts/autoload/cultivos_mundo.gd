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

func sembrar(instancia: String, inventario: Inventario) -> bool:
	if not _estados.has(instancia) or inventario == null:
		return false
	var estado: Dictionary = _estados[instancia]
	if bool(estado.get("sembrada", false)):
		return false
	var def: CultivoData = BaseDeDatos.cultivo(str(estado.get("definicion", "")))
	if def == null or not inventario.retirar(def.semilla, 1):
		return false
	estado["sembrada"] = true
	estado["lista_en"] = _hora_total() + def.horas_crecimiento
	_estados[instancia] = estado
	_emitir_cambio(instancia)
	return true

func cosechar(instancia: String, inventario: Inventario) -> Dictionary:
	if not _estados.has(instancia) or inventario == null:
		return {"ok": false, "productos": {}}
	var estado: Dictionary = _estados[instancia]
	if not bool(estado.get("sembrada", false)) or not _esta_lista(estado):
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
