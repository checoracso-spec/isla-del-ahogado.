extends Node
## Estado persistente de las mejoras de recolección del muelle.
##
## La receta `rastrillar_marea` sigue siendo el comportamiento inicial. Cuando
## el jugador instala la red de arrastre, esta autoridad desactiva esa receta
## y monta RecolectorRecurso sobre la fuente real del mundo.

const RecolectorRecursoScript := preload("res://scripts/mapa/recolector_recurso.gd")

signal grua_activada()
signal lote_recolectado(productos: Dictionary)

const COSTE_TABLONES := 8
const COSTE_DOBLONES := 100
const INTERVALO_HORAS := 6.0

var grua_activa: bool = false
var fuente_instancia: String = ""
var _recolector = null
var _estado_recolector: Dictionary = {}
var _montado: bool = false

func _ready() -> void:
	Guardado.registrar("muelle", _serializar, _cargar)

func montar(fuentes: Array) -> void:
	_montado = true
	var fuente: FuenteRecurso = null
	for candidata in fuentes:
		if candidata != null and candidata.definicion_id == "restos_naufragio":
			fuente = candidata
			break
	if fuente == null:
		return
	if fuente_instancia == "":
		fuente_instancia = str(fuente.identidad.instancia)
	if grua_activa:
		_montar_recolector()

func activar_grua() -> bool:
	if grua_activa:
		return false
	if Almacen.disponible("tablon_tratado") < COSTE_TABLONES:
		return false
	if Almacen.disponible("doblon") < COSTE_DOBLONES:
		return false
	if not Almacen.retirar("tablon_tratado", COSTE_TABLONES):
		return false
	if not Almacen.retirar("doblon", COSTE_DOBLONES):
		Almacen.anadir("tablon_tratado", COSTE_TABLONES, "reembolso_red_muelle")
		return false
	grua_activa = true
	_montar_recolector()
	grua_activada.emit()
	return true

func ejecutar_recoleccion_ahora() -> Dictionary:
	if _recolector == null or not is_instance_valid(_recolector):
		return {"ciclos": 0, "productos": {}}
	return _recolector.ejecutar_ahora()

func estado() -> Dictionary:
	return {
		"activa": grua_activa,
		"fuente": fuente_instancia,
		"trabajadores": int(_recolector.trabajadores) if _recolector != null else 0,
	}

func _montar_recolector() -> void:
	if _recolector != null and is_instance_valid(_recolector):
		return
	if fuente_instancia == "":
		return
	_recolector = RecolectorRecursoScript.new()
	_recolector.name = "Recolector_Red_Arrastre"
	add_child(_recolector)
	_recolector.montar(fuente_instancia, "muelle_grua", 3, INTERVALO_HORAS)
	if not _estado_recolector.is_empty():
		_recolector.cargar(_estado_recolector)
	_recolector.lote_recolectado.connect(func(_r, productos):
		lote_recolectado.emit(productos))

func _serializar() -> Dictionary:
	var estado := _estado_recolector.duplicate(true)
	if _recolector != null and is_instance_valid(_recolector):
		estado = _recolector.serializar()
	return {
		"grua_activa": grua_activa,
		"fuente_instancia": fuente_instancia,
		"recolector": estado,
	}

func _cargar(datos: Dictionary) -> void:
	grua_activa = bool(datos.get("grua_activa", false))
	fuente_instancia = str(datos.get("fuente_instancia", ""))
	_estado_recolector = (datos.get("recolector", {}) as Dictionary).duplicate(true)
	if _montado and grua_activa:
		_montar_recolector()
		grua_activada.emit()

func reiniciar() -> void:
	grua_activa = false
	fuente_instancia = ""
	_estado_recolector.clear()
	if _recolector != null and is_instance_valid(_recolector):
		_recolector.queue_free()
	_recolector = null
