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
	EventosMundo.eventos_cambiados.connect(_ajustar_por_eventos)

func registrar(fuente) -> void:
	if fuente == null or fuente.identidad == null:
		return
	var id: String = str(fuente.identidad.instancia)
	_vivas[id] = fuente
	if not _estados.has(id):
		var def: FuenteRecursoData = fuente.definicion()
		_estados[id] = {
			"definicion": fuente.definicion_id,
			"cantidad": _capacidad_fuente(def) if def != null else 0,
			"proxima": 0.0,
		}
	fuente.tree_exiting.connect(func(): _vivas.erase(id), CONNECT_ONE_SHOT)

func cantidad(instancia: String) -> int:
	return int((_estados.get(instancia, {}) as Dictionary).get("cantidad", 0))

## Consulta sin efectos para que una fuente no ofrezca una acción imposible.
func puede_recolectar(instancia: String, destino: Inventario, ciclos: int = 1) -> bool:
	return _ciclos_posibles(instancia, destino, ciclos) > 0

func recolectar(instancia: String, destino: Inventario, ciclos: int = 1) -> Dictionary:
	if not _estados.has(instancia) or destino == null:
		return {"ciclos": 0, "productos": {}}
	var estado: Dictionary = _estados[instancia]
	var def: FuenteRecursoData = BaseDeDatos.fuente(str(estado.get("definicion", "")))
	if def == null:
		return {"ciclos": 0, "productos": {}}
	var posibles := _ciclos_posibles(instancia, destino, ciclos)
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

func _ciclos_posibles(instancia: String, destino: Inventario, ciclos: int) -> int:
	if not _estados.has(instancia) or destino == null:
		return 0
	var estado: Dictionary = _estados[instancia]
	var def: FuenteRecursoData = BaseDeDatos.fuente(str(estado.get("definicion", "")))
	if def == null:
		return 0
	var posibles := mini(maxi(0, ciclos), int(estado.get("cantidad", 0)))
	for item_id in def.productos:
		var por_ciclo := int(def.productos[item_id])
		if por_ciclo <= 0:
			continue
		var ciclos_por_capacidad := int(floor(float(destino.hueco_para(str(item_id))) / por_ciclo))
		posibles = mini(posibles, ciclos_por_capacidad)
	return maxi(0, posibles)

## Recolección automática para estaciones del mundo, como la grúa del muelle.
## Usa la API pública de Almacen como destino logístico, pero no mezcla ese
## estado con Inventario ni modifica las reglas del almacén.
func recolectar_en_almacen(instancia: String, ciclos: int = 1,
		origen: String = "") -> Dictionary:
	if not _estados.has(instancia):
		return {"ciclos": 0, "productos": {}}
	var estado: Dictionary = _estados[instancia]
	var def: FuenteRecursoData = BaseDeDatos.fuente(str(estado.get("definicion", "")))
	if def == null:
		return {"ciclos": 0, "productos": {}}
	var posibles := mini(maxi(0, ciclos), int(estado.get("cantidad", 0)))
	if posibles <= 0:
		return {"ciclos": 0, "productos": {}}

	# El lote completo debe caber antes de tocar el almacén. Así una grúa no
	# deja una extracción a medias si el puerto está lleno.
	if Almacen.capacidad_volumen > 0.0:
		var hueco := Almacen.capacidad_volumen - Almacen.volumen_ocupado()
		var volumen_lote := 0.0
		for item_id in def.productos:
			var item: ItemData = BaseDeDatos.item(str(item_id))
			if item != null:
				volumen_lote += item.volumen * int(def.productos[item_id])
		if volumen_lote > 0.0:
			posibles = mini(posibles, int(floor(hueco / volumen_lote)))
	if posibles <= 0:
		return {"ciclos": 0, "productos": {}}

	var productos: Dictionary = {}
	for item_id in def.productos:
		var total := int(def.productos[item_id]) * posibles
		var aceptado := Almacen.anadir(str(item_id), total, origen)
		if aceptado != total:
			# La comprobación previa evita este camino en condiciones normales.
			# Si el destino cambió entre medias, no consumimos la fuente.
			for previo in productos:
				Almacen.retirar(str(previo), int(productos[previo]))
			return {"ciclos": 0, "productos": {}}
		productos[str(item_id)] = total

	_estado_recolectado(instancia, posibles, def)
	return {"ciclos": posibles, "productos": productos}

func _estado_recolectado(instancia: String, ciclos: int, def: FuenteRecursoData) -> void:
	var estado: Dictionary = _estados[instancia]
	estado["cantidad"] = int(estado.get("cantidad", 0)) - ciclos
	if int(estado["cantidad"]) <= 0 and def.regeneracion_horas > 0.0:
		estado["proxima"] = _hora_total() + def.regeneracion_horas
	_estados[instancia] = estado
	fuente_cambiada.emit(instancia, int(estado["cantidad"]))
	var viva = _vivas.get(instancia)
	if viva != null and is_instance_valid(viva):
		viva.queue_redraw()

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
		estado["cantidad"] = _capacidad_fuente(def)
		estado["proxima"] = 0.0
		_estados[instancia] = estado
		fuente_cambiada.emit(str(instancia), int(estado["cantidad"]))
		var viva = _vivas.get(instancia)
		if viva != null and is_instance_valid(viva):
			viva.queue_redraw()

func _hora_total() -> float:
	return float(Reloj.dia * 24) + Reloj.hora

func _serializar() -> Dictionary:
	return {"estados": _estados.duplicate(true)}

func _cargar(datos: Dictionary) -> void:
	_estados = (datos.get("estados", {}) as Dictionary).duplicate(true)
	_ajustar_por_eventos()
	for id in _vivas:
		var viva = _vivas[id]
		if viva != null and is_instance_valid(viva):
			viva.queue_redraw()

func reiniciar() -> void:
	_estados.clear()
	_vivas.clear()

func _capacidad_fuente(def: FuenteRecursoData) -> int:
	if def == null:
		return 0
	var multiplicador := EventosMundo.multiplicador_recurso(def.id)
	return maxi(0, ceili(float(def.ciclos_maximos) * multiplicador))

func _ajustar_por_eventos() -> void:
	for instancia in _estados:
		var estado: Dictionary = _estados[instancia]
		var def: FuenteRecursoData = BaseDeDatos.fuente(
			str(estado.get("definicion", "")))
		if def == null:
			continue
		var multiplicador := EventosMundo.multiplicador_recurso(def.id)
		if multiplicador <= 1.0:
			continue
		var capacidad := maxi(0, ceili(float(def.ciclos_maximos) * multiplicador))
		# Una nueva marea trae restos inmediatamente. Al terminar el evento no
		# confiscamos el excedente: sólo las regeneraciones usan la capacidad base.
		if capacidad > int(estado.get("cantidad", 0)):
			estado["cantidad"] = capacidad
			estado["proxima"] = 0.0
			_estados[instancia] = estado
			fuente_cambiada.emit(str(instancia), capacidad)
			var viva = _vivas.get(instancia)
			if viva != null and is_instance_valid(viva):
				viva.queue_redraw()
