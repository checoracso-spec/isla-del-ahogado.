extends Node
const EventoMundoDataScript := preload("res://scripts/datos/evento_mundo_data.gd")
## AUTOLOAD: EventosMundo
##
## Registro temporal y guardable de sucesos globales. Un evento sólo declara
## datos y duración; los sistemas consumidores deciden qué significa cada
## modificador. Así una tormenta no necesita conocer la escena del puerto.

signal evento_iniciado(id: String)
signal evento_terminado(id: String)
signal eventos_cambiados()

var _activos: Dictionary = {} ## id -> {iniciado, termina}

func _ready() -> void:
	Guardado.registrar("eventos", _serializar, _cargar)

func iniciar(id: String, duracion_horas: float = 0.0) -> bool:
	var def = BaseDeDatos.evento(id)
	if def == null or _activos.has(id):
		return false
	var duracion: float = float(def.duracion_horas) if duracion_horas <= 0.0 else maxf(0.1, duracion_horas)
	_activos[id] = {
		"iniciado": _hora_total(),
		"termina": _hora_total() + duracion,
	}
	evento_iniciado.emit(id)
	eventos_cambiados.emit()
	return true

func terminar(id: String) -> bool:
	if not _activos.has(id):
		return false
	_activos.erase(id)
	evento_terminado.emit(id)
	eventos_cambiados.emit()
	return true

func activo(id: String) -> bool:
	_actualizar_expirados()
	return _activos.has(id)

func activos() -> Array[String]:
	_actualizar_expirados()
	var ids: Array[String] = []
	for id in _activos:
		ids.append(str(id))
	ids.sort()
	return ids

func estado(id: String) -> Dictionary:
	_actualizar_expirados()
	return (_activos.get(id, {}) as Dictionary).duplicate(true)

## Multiplicador acumulado para el precio por oferta de un artículo.
func multiplicador_oferta(item_id: String) -> float:
	_actualizar_expirados()
	var resultado := 1.0
	for id in _activos:
		var def = BaseDeDatos.evento(str(id))
		if def == null:
			continue
		if def.multiplicadores_oferta.has(item_id):
			resultado *= maxf(0.1, float(def.multiplicadores_oferta[item_id]))
	return resultado

## Multiplicador de disponibilidad para una definición de fuente. Es distinto
## del precio: una marea puede traer más restos y, a la vez, abaratar su venta.
func multiplicador_recurso(definicion_id: String) -> float:
	_actualizar_expirados()
	var resultado := 1.0
	for id in _activos:
		var def = BaseDeDatos.evento(str(id))
		if def == null:
			continue
		if def.multiplicadores_recursos.has(definicion_id):
			resultado *= maxf(0.1, float(def.multiplicadores_recursos[definicion_id]))
	return resultado

func riesgo_viaje(riesgo_base: float) -> float:
	_actualizar_expirados()
	var resultado := riesgo_base
	for id in _activos:
		var def = BaseDeDatos.evento(str(id))
		if def != null:
			resultado *= def.multiplicador_riesgo_viaje
	return clampf(resultado, 0.0, 1.0)

func reiniciar() -> void:
	_activos.clear()
	eventos_cambiados.emit()

func _process(_delta: float) -> void:
	_actualizar_expirados()

func _actualizar_expirados() -> void:
	var ahora := _hora_total()
	var vencidos: Array[String] = []
	for id in _activos:
		if ahora >= float((_activos[id] as Dictionary).get("termina", ahora + 1.0)):
			vencidos.append(str(id))
	for id in vencidos:
		terminar(id)

func _hora_total() -> float:
	return float(Reloj.dia * 24) + Reloj.hora

func _serializar() -> Dictionary:
	return {"activos": _activos.duplicate(true)}

func _cargar(datos: Dictionary) -> void:
	_activos = (datos.get("activos", {}) as Dictionary).duplicate(true)
	_actualizar_expirados()
	eventos_cambiados.emit()
