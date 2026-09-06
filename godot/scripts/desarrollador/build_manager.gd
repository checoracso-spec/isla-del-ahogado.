class_name BuildManager
extends Node2D
## PROTOTIPO — Fase 5 del Modo Desarrollador de Interiores.
##
## Cursor → tile con Iso, fantasma verde/rojo según ValidadorInterior,
## colocar/cancelar/eliminar/rotar/mover, y ahora funcionalidad real:
## los objetos colocados usan EstacionCrafteo/Cofre/Interactuable de verdad,
## exactamente como InteriorEscena monta los reales — nunca "if tipo ==
## fragua". Nodo local de comparador_herreria.tscn — no es autoload, no
## existe fuera de esta escena de prueba, no guarda nada.
##
## LIMITACIÓN CONOCIDA, documentada a propósito (no es un olvido): rotar
## cambia la huella efectiva (un 2×1 pasa a 1×2) y gira el mismo sprite con
## Node2D.rotation, pero NO existen las cuatro orientaciones de arte reales
## para estas claves todavía — el manifiesto solo declara una vista estática
## por objeto. Esto NO debe presentarse como rotación artística definitiva
## en ningún momento; es solo una señal visual + el cambio de huella real
## para validar.
##
## OTRA LIMITACIÓN, también deliberada: yunque, horno y mesa_trabajo NO
## tienen campo "interactuable" en interior_herreria_pb hoy — solo fragua y
## banco_trabajo lo tienen ("crafteo"). Colocar un yunque o un horno de
## prueba los deja tan decorativos como los reales, porque este sistema lee
## la definición TAL CUAL está en BaseDeDatos y no inventa interacción que
## no existe. Si algún día esos objetos deben ser interactivos, el cambio
## va en el dato (base_de_datos.gd), no aquí.
##
## IMPORTANTE: BaseDeDatos.interior() devuelve el MISMO Resource cacheado
## que usa la Herrería jugable real. Por eso los objetos colocados aquí
## nunca tocan interior.definicion.muebles — viven aparte, en _colocados,
## y sólo se combinan con la definición real en una COPIA, para validar.
## Por la misma razón, mover o eliminar SOLO opera sobre _colocados: los
## muebles reales de interior_herreria_pb no son ni siquiera seleccionables
## desde aquí, así que sus instance_id nunca están en riesgo.
##
## Los cofres de prueba SÍ usan Entidades.identificar()/Contenedores, igual
## que un cofre real — pero su clave natural incluye identidad.instancia de
## ESTA zona ("comparador_herreria"), que ninguna partida real puede
## producir jamás. No hace falta un espacio de nombres aparte: ya está
## aislado por construcción.
##
## Reutiliza los diccionarios ya existentes en InteriorDefinicion.muebles:
## no se crean clases PlaceableDefinition ni PlacedObject en esta fase.

const PreviewColocacionScript := preload("res://scripts/desarrollador/preview_colocacion.gd")
const EstacionCrafteoScript := preload("res://scripts/interiores/estacion_crafteo.gd")
const CofreScript := preload("res://scripts/objetos/cofre.gd")

## Orden fijo: 1-7 alternan entre estos tipos, tomados tal cual de los
## muebles ya definidos en interior_herreria_pb. Se amplió en Fase 5 para
## poder probar horno, mesa_trabajo y cofre, que pedía esta fase.
const TIPOS_DE_PRUEBA: Array[String] = [
	"yunque", "fragua", "banco_trabajo", "escalera",
	"horno", "mesa", "cofre",
]

var interior: InteriorEscena = null

var _indice_seleccion := 0
var _preview: PreviewColocacion = null
var _mueble_base: Dictionary = {}
var _ultima_casilla := Vector2i(-9999, -9999)
var _ultima_valido := false
var _rotacion_actual := 0  ## 0..3, cada paso son 90°

## Objetos colocados esta sesión. Cada entrada:
## {"id": int, "nodo": Node2D, "datos": Dictionary}.
## Nunca se escribe en interior.definicion.muebles — ver nota de cabecera.
var _colocados: Array[Dictionary] = []
var _siguiente_id := 1

## Movimiento en curso, o {} si no se está moviendo nada.
var _moviendo: Dictionary = {}

func _ready() -> void:
	_preview = PreviewColocacionScript.new()
	# Se cuelga de la propia sala, no de BuildManager: así hereda su
	# desplazamiento (interior.position) igual que cualquier mueble real, sin
	# tener que duplicar esa cuenta aquí.
	if interior != null:
		interior.add_child(_preview)
	else:
		add_child(_preview)
	_seleccionar(0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _seleccionar(0)
			KEY_2: _seleccionar(1)
			KEY_3: _seleccionar(2)
			KEY_4: _seleccionar(3)
			KEY_5: _seleccionar(4)
			KEY_6: _seleccionar(5)
			KEY_7: _seleccionar(6)
			KEY_R: _rotar()
			KEY_ESCAPE: _cancelar()
			KEY_DELETE: _eliminar_actual()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_clic_izquierdo()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_clic_derecho()

func _process(_delta: float) -> void:
	if interior == null or interior.definicion == null or _mueble_base.is_empty():
		return
	var casilla := _casilla_bajo_cursor()
	if casilla == _ultima_casilla:
		return
	_actualizar_preview(casilla)

func _actualizar_preview(casilla: Vector2i) -> void:
	_ultima_casilla = casilla
	var huella := _huella_efectiva()
	var candidato := _candidato_en(casilla)
	_ultima_valido = _es_valido(candidato, _id_excluido())
	_preview.actualizar(casilla, huella, _ultima_valido)

func _candidato_en(casilla: Vector2i) -> Dictionary:
	var candidato := _mueble_base.duplicate(true)
	candidato["casilla"] = casilla
	candidato["huella"] = _huella_efectiva()
	return candidato

## Mientras se mueve un objeto, ese mismo objeto no debe contar como
## "ocupado" al validar su propia nueva posición.
func _id_excluido() -> int:
	return int(_moviendo.get("id", -1)) if not _moviendo.is_empty() else -1

func _clic_izquierdo() -> void:
	if not _moviendo.is_empty():
		_confirmar_movimiento()
	else:
		_colocar_actual()

## Clic derecho es sensible al contexto: si el cursor está sobre un objeto
## de esta sesión y no hay nada más en curso, lo recoge para moverlo. Si no,
## se comporta como "cancelar".
func _clic_derecho() -> void:
	if not _moviendo.is_empty():
		_cancelar()
		return
	var casilla := _casilla_bajo_cursor()
	var entrada := _buscar_colocado_en(casilla)
	if entrada.is_empty():
		_cancelar()
		return
	_iniciar_movimiento(entrada)

func _seleccionar(indice: int) -> void:
	if not _moviendo.is_empty():
		_cancelar_movimiento()
	_indice_seleccion = indice
	_rotacion_actual = 0
	var tipo := TIPOS_DE_PRUEBA[_indice_seleccion]
	_mueble_base = _buscar_mueble_por_tipo(tipo)
	_ultima_casilla = Vector2i(-9999, -9999)
	if not _mueble_base.is_empty():
		_preview.configurar(_mueble_base)
	print("[BuildManager] seleccionado: %s" % tipo)

func _cancelar() -> void:
	if not _moviendo.is_empty():
		_cancelar_movimiento()
		return
	_mueble_base = {}
	_preview.visible = false
	print("[BuildManager] cancelado")

func _rotar() -> void:
	if _mueble_base.is_empty():
		return
	_rotacion_actual = (_rotacion_actual + 1) % 4
	_preview.rotation = _rotacion_actual * (PI / 2.0)
	_ultima_casilla = Vector2i(-9999, -9999)  ## fuerza refrescar la validación
	print("[BuildManager] rotación: %d°" % (_rotacion_actual * 90))

func _huella_efectiva() -> Vector2i:
	var base := _huella_de(_mueble_base)
	if _rotacion_actual % 2 == 1:
		return Vector2i(base.y, base.x)
	return base

func _colocar_actual() -> void:
	if _mueble_base.is_empty():
		return
	var casilla := _casilla_bajo_cursor()
	var candidato := _candidato_en(casilla)
	if not _es_valido(candidato, -1):
		print("[BuildManager] posición inválida, no se coloca en %s" % casilla)
		return
	candidato["id_sesion"] = _siguiente_id
	candidato["_rotacion"] = _rotacion_actual
	var nodo := _montar_funcionalidad(candidato)
	if nodo == null:
		return
	_colocados.append({"id": _siguiente_id, "nodo": nodo, "datos": candidato})
	print("[BuildManager] colocado %s en %s (id %d)" % [candidato.get("tipo", "?"), casilla, _siguiente_id])
	_siguiente_id += 1
	_ultima_casilla = Vector2i(-9999, -9999)  ## el candidato ahora cuenta como ocupado

## El corazón de la Fase 5: monta un nodo funcional de verdad a partir del
## diccionario, con la MISMA lógica data-driven que usa
## InteriorEscena._montar_muebles_visual()/_montar_cofres() — nunca por
## nombre de tipo, salvo la distinción cofre/mueble normal que la propia
## arquitectura del juego ya hace (Cofre es una clase aparte con su propio
## camino de montaje en el juego real, no una invención de esta fase).
func _montar_funcionalidad(candidato: Dictionary) -> Node2D:
	if str(candidato.get("tipo", "")) == "cofre":
		return _montar_cofre_de_prueba(candidato)
	return _montar_mueble_interactivo(candidato)

func _montar_mueble_interactivo(candidato: Dictionary) -> Node2D:
	var clave := str(candidato.get("asset", ""))
	if clave == "" or not Assets.existe(clave):
		return null
	var interactuable_tipo := str(candidato.get("interactuable", ""))
	var soporte: Node2D
	match interactuable_tipo:
		"crafteo": soporte = EstacionCrafteoScript.new()
		_: soporte = Node2D.new()
	if soporte is Interactuable:
		var est := soporte as Interactuable
		if soporte.has_method("set_estacion_id"):
			soporte.set_estacion_id(str(candidato.get("estacion_id", "")))
		if soporte.has_method("set_accion"):
			soporte.set_accion(str(candidato.get("accion", "Fabricar")))
		if soporte.has_method("set_horario_id"):
			soporte.set_horario_id(str(candidato.get("horario_id", "")))
		if soporte.has_method("set_actividades_productivas"):
			soporte.set_actividades_productivas(candidato.get("actividades_productivas", ["trabajar"]))
		if soporte.has_method("set_actividades_preparacion"):
			soporte.set_actividades_preparacion(candidato.get("actividades_preparacion", []))
		est.establecer_casillas_interaccion([])  ## respaldo: su propia casilla
	soporte.position = _punto_anclaje(candidato["casilla"], _huella_efectiva())
	soporte.rotation = _rotacion_actual * (PI / 2.0)
	var sprite := Assets.sprite(clave)
	sprite.modulate = Color(1, 1, 1, 0.9)  ## distingue lo de prueba del arte definitivo
	soporte.add_child(sprite)
	interior.add_child(soporte)
	return soporte

## Cofre de prueba: usa Entidades + Contenedores exactamente como un cofre
## real (mismo Cofre.gd, mismo inventario_de()) — su clave natural incluye
## la identidad de ESTA zona de prueba, así que nunca puede coincidir con un
## cofre de una partida real. Se puede eliminar sin tocar cofres reales
## porque nunca comparten identidad ni nodo.
func _montar_cofre_de_prueba(candidato: Dictionary) -> Node2D:
	if interior == null or interior.identidad == null:
		return null
	var casilla: Vector2i = candidato["casilla"]
	var definicion_cofre := str(candidato.get("definicion", "cofre_oxidado"))
	var c := CofreScript.new()
	c.name = "CofrePrueba_%d_%d" % [casilla.x, casilla.y]
	c.identidad = Entidades.identificar("objeto", definicion_cofre,
		"cofre_prueba:%s@%d,%d,%d" % [interior.identidad.instancia, casilla.x, casilla.y, _siguiente_id])
	c.contenido_inicial = (candidato.get("contenido", {}) as Dictionary).duplicate()
	c.asset_cerrado = str(candidato.get("asset_cerrado", ""))
	c.asset_abierto = str(candidato.get("asset_abierto", ""))
	c.zona_id = interior.identidad.instancia
	c.casilla_interior = casilla
	c.position = _punto_anclaje(casilla, _huella_efectiva())
	interior.add_child(c)
	Entidades.vincular(c.identidad, c)
	return c

## Recoge un objeto ya colocado: lo oculta (no lo destruye ni le toca su
## estado interno — sigue siendo el mismo EstacionCrafteo/Cofre con el mismo
## estacion_id/identidad), y arma el fantasma para previsualizar el destino.
func _iniciar_movimiento(entrada: Dictionary) -> void:
	_moviendo = entrada
	var datos: Dictionary = entrada["datos"]
	(entrada["nodo"] as Node2D).visible = false
	_mueble_base = datos.duplicate(true)
	_mueble_base.erase("id_sesion")
	_rotacion_actual = int(datos.get("_rotacion", 0))
	_preview.configurar(_mueble_base)
	_preview.rotation = _rotacion_actual * (PI / 2.0)
	_ultima_casilla = Vector2i(-9999, -9999)
	print("[BuildManager] moviendo id %d (%s)" % [int(entrada["id"]), datos.get("tipo", "?")])

## Reposiciona el MISMO nodo (nunca lo recrea): station_id, identidad,
## capa visual y pivote quedan exactamente como estaban, solo cambia dónde
## se dibuja y desde dónde se puede usar.
func _confirmar_movimiento() -> void:
	if _moviendo.is_empty():
		return
	var casilla := _casilla_bajo_cursor()
	var candidato := _candidato_en(casilla)
	if not _es_valido(candidato, _id_excluido()):
		print("[BuildManager] destino inválido, sigue moviéndose")
		return
	var nodo: Node2D = _moviendo["nodo"]
	var datos: Dictionary = _moviendo["datos"]
	datos["casilla"] = casilla
	datos["huella"] = _huella_efectiva()
	datos["_rotacion"] = _rotacion_actual
	nodo.position = _punto_anclaje(casilla, _huella_efectiva())
	nodo.rotation = _rotacion_actual * (PI / 2.0)
	if nodo is Cofre:
		(nodo as Cofre).casilla_interior = casilla
	elif nodo is Interactuable:
		(nodo as Interactuable).establecer_casillas_interaccion([])
	nodo.visible = true
	print("[BuildManager] movido id %d a %s" % [int(_moviendo["id"]), casilla])
	_moviendo = {}
	_mueble_base = {}
	_preview.visible = false

func _cancelar_movimiento() -> void:
	if _moviendo.is_empty():
		return
	(_moviendo["nodo"] as Node2D).visible = true
	print("[BuildManager] movimiento cancelado, id %d vuelve a su sitio" % int(_moviendo["id"]))
	_moviendo = {}
	_mueble_base = {}
	_preview.visible = false

## Elimina el objeto que se está moviendo (si hay uno en curso) o, si no,
## el que esté bajo el cursor. Sólo toca _colocados — los muebles y cofres
## reales de interior_herreria_pb no son alcanzables desde aquí.
func _eliminar_actual() -> void:
	if not _moviendo.is_empty():
		var nodo: Node2D = _moviendo["nodo"]
		var id: int = _moviendo["id"]
		_liberar_nodo(nodo)
		for i in range(_colocados.size() - 1, -1, -1):
			if int(_colocados[i]["id"]) == id:
				_colocados.remove_at(i)
				break
		print("[BuildManager] eliminado (estaba en movimiento) id %d" % id)
		_moviendo = {}
		_mueble_base = {}
		_preview.visible = false
		return
	var casilla := _casilla_bajo_cursor()
	for i in range(_colocados.size() - 1, -1, -1):
		var entrada: Dictionary = _colocados[i]
		var datos: Dictionary = entrada["datos"]
		if _ocupa(datos, casilla):
			_liberar_nodo(entrada["nodo"])
			_colocados.remove_at(i)
			print("[BuildManager] eliminado objeto de prueba en %s" % casilla)
			_ultima_casilla = Vector2i(-9999, -9999)
			return

func _liberar_nodo(nodo: Node2D) -> void:
	nodo.queue_free()

func _buscar_colocado_en(casilla: Vector2i) -> Dictionary:
	for entrada in _colocados:
		if _ocupa(entrada["datos"], casilla):
			return entrada
	return {}

func _ocupa(mueble: Dictionary, casilla: Vector2i) -> bool:
	var origen: Vector2i = mueble.get("casilla", Vector2i.ZERO)
	var huella: Vector2i = mueble.get("huella", Vector2i.ONE)
	return casilla.x >= origen.x and casilla.y >= origen.y \
		and casilla.x < origen.x + huella.x and casilla.y < origen.y + huella.y

## Toma la definición TAL CUAL de interior_herreria_pb — mismo asset, misma
## huella, mismo "solido", mismo "interactuable"/"estacion_id" si los tiene.
## No se inventan valores nuevos.
func _buscar_mueble_por_tipo(tipo: String) -> Dictionary:
	if interior == null or interior.definicion == null:
		return {}
	for m in interior.definicion.muebles:
		var mueble: Dictionary = m
		if str(mueble.get("tipo", "")) == tipo:
			return mueble.duplicate(true)
	return {}

func _huella_de(mueble: Dictionary) -> Vector2i:
	var h: Variant = mueble.get("huella", Vector2i.ONE)
	return h if h is Vector2i else Vector2i.ONE

## Mismo espacio que usa InteriorEscena para colocar a sus hijos: la sala
## vive desplazada por interior.position dentro de comparador_herreria.
func _casilla_bajo_cursor() -> Vector2i:
	var local := interior.to_local(get_global_mouse_position())
	return Iso.a_tile(local)

## Misma fórmula que InteriorEscena._punto_anclaje(): huella 1×1 usa el
## centro de la casilla, huellas más grandes anclan por la esquina de apoyo.
func _punto_anclaje(origen: Vector2i, huella: Vector2i) -> Vector2:
	if huella == Vector2i.ONE:
		return Iso.centro_v(origen)
	var apoyo := origen + huella - Vector2i.ONE
	return Iso.apoyo(apoyo.x, apoyo.y)

## Reutiliza el validador genérico entero en vez de reescribir solape,
## límites y accesibilidad a mano: se añade el candidato (y todo lo ya
## colocado esta sesión, salvo el objeto que se esté moviendo) a una COPIA
## de la definición real y se pide un veredicto completo. La definición
## real (BaseDeDatos.interior(...)) nunca se toca.
func _es_valido(candidato: Dictionary, id_excluido: int) -> bool:
	var copia := interior.definicion.duplicate()
	copia.muebles = interior.definicion.muebles.duplicate(true)
	for entrada in _colocados:
		if int(entrada["id"]) == id_excluido:
			continue
		copia.muebles.append((entrada["datos"] as Dictionary).duplicate(true))
	copia.muebles.append(candidato)
	var problemas := ValidadorInterior.validar(copia)
	return problemas.is_empty()
