extends Node
const FuenteRecursoScript := preload("res://scripts/mapa/fuente_recurso.gd")
## AUTOLOAD: RecursosMundo
##
## Registro de estado de las fuentes recolectables. Los nodos son temporales;
## este diccionario es la autoridad guardable de cantidades y regeneración.

signal fuente_cambiada(instancia: String, cantidad: int)

var _estados: Dictionary = {}       ## instancia -> {definicion, cantidad, proxima}
var _vivas: Dictionary = {}        ## instancia -> nodo FuenteRecurso

func _ready() -> void:
	Guardado.registrar("recursos_mundo", _serializar, _cargar)

func registrar(fuente) -> void:
	if fuente == null or fuente.identidad == null:
		return
	var id: String = str(fuente.identidad.instancia)
	_vivas[id] = fuente
	if not _estados.has(id):
		var def: FuenteRecursoData = fuente.definicion()
		_estados[id] = {
			"definicion": fuente.definicion_id,
			"cantidad": def.ciclos_maximos if def != null else 0,
			"proxima": 0.0,
		}
	fuente.tree_exiting.connect(func(): _vivas.erase(id), CONNECT_ONE_SHOT)

func cantidad(instancia: String) -> int:
	return int((_estados.get(instancia, {}) as Dictionary).get("cantidad", 0))

func recolectar(instancia: String, destino: Inventario, ciclos: int = 1) -> Dictionary:
	if not _estados.has(instancia) or destino == null:
		return {"ciclos": 0, "productos": {}}
	var estado: Dictionary = _estados[instancia]
	var def: FuenteRecursoData = BaseDeDatos.fuente(str(estado.get("definicion", "")))
	if def == null:
		return {"ciclos": 0, "productos": {}}
	var posibles := mini(maxi(0, ciclos), int(estado.get("cantidad", 0)))
	if posibles <= 0:
		return {"ciclos": 0, "productos": {}}
	# La recolección es por ciclos completos: no desaparece un nodo si el
	# inventario no puede aceptar todos sus productos.
	for item_id in def.productos:
		var por_ciclo := int(def.productos[item_id])
		if por_ciclo <= 0:
			continue
		var ciclos_por_capacidad := int(floor(float(destino.hueco_para(str(item_id))) / por_ciclo))
		posibles = mini(posibles, ciclos_por_capacidad)
	if posibles <= 0:
		return {"ciclos": 0, "productos": {}}

	var productos: Dictionary = {}
	for item_id in def.productos:
		var total := int(def.productos[item_id]) * posibles
		destino.anadir(str(item_id), total)
		productos[str(item_id)] = total
	estado["cantidad"] = int(estado.get("cantidad", 0)) - posibles
	if int(estado["cantidad"]) <= 0 and def.regeneracion_horas > 0.0:
		estado["proxima"] = _hora_total() + def.regeneracion_horas
	_estados[instancia] = estado
	fuente_cambiada.emit(instancia, int(estado["cantidad"]))
	var viva = _vivas.get(instancia)
	if viva != null and is_instance_valid(viva):
		viva.queue_redraw()
	return {"ciclos": posibles, "productos": productos}

func _process(_delta: float) -> void:
	var ahora := _hora_total()
	for instancia in _estados:
		var estado: Dictionary = _estados[instancia]
		var proxima := float(estado.get("proxima", 0.0))
		if proxima <= 0.0 or ahora < proxima:
			continue
		var def: FuenteRecursoData = BaseDeDatos.fuente(str(estado.get("definicion", "")))
		if def == null:
			continue
		estado["cantidad"] = def.ciclos_maximos
		estado["proxima"] = 0.0
		_estados[instancia] = estado
		fuente_cambiada.emit(str(instancia), def.ciclos_maximos)
		var viva = _vivas.get(instancia)
		if viva != null and is_instance_valid(viva):
			viva.queue_redraw()

func _hora_total() -> float:
	return float(Reloj.dia * 24) + Reloj.hora

func _serializar() -> Dictionary:
	return {"estados": _estados.duplicate(true)}

func _cargar(datos: Dictionary) -> void:
	_estados = (datos.get("estados", {}) as Dictionary).duplicate(true)
	for id in _vivas:
		var viva = _vivas[id]
		if viva != null and is_instance_valid(viva):
			viva.queue_redraw()

func reiniciar() -> void:
	_estados.clear()
	_vivas.clear()
