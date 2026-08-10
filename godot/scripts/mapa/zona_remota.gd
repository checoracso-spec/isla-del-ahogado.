class_name ZonaRemota
extends Zona
## Zona provisional para una ciudad o isla que aún no tiene escena artística.
##
## Sirve para validar el contrato común: límites, transitabilidad, actores y
## entrada. Cuando llegue el mapa real, se reemplaza sólo esta construcción.

const COLOR_SUELO := Color("3d5b4a")
const COLOR_SUELO_ALT := Color("4d6c52")
const COLOR_CAMINO := Color("8f6b4b")
const TransicionGlobalScript := preload("res://scripts/mapa/transicion_global.gd")
const FuenteRecursoScript := preload("res://scripts/mapa/fuente_recurso.gd")
const ParcelaCultivoScript := preload("res://scripts/mapa/parcela_cultivo.gd")
const RecolectorCultivoScript := preload("res://scripts/mapa/recolector_cultivo.gd")
const ZonaChunkScript := preload("res://scripts/nucleo/zona_chunk.gd")
const TAMANO_CHUNK := 8

var destino_id: String = ""
var ancho: int = 1
var alto: int = 1
var transiciones: Array = []
var fuentes_recurso: Array = []
var parcelas_cultivo: Array = []
var recolectores_cultivo: Array = []
var chunks: Dictionary = {} ## "x,y" -> ZonaChunk
var _centro_chunks_activo: Vector2i = Vector2i(2147483647, 2147483647)

func construir(p_destino_id: String, p_ancho: int = 16, p_alto: int = 12) -> void:
	destino_id = p_destino_id
	id = p_destino_id
	montar_identidad(p_destino_id, "zona:%s" % p_destino_id)
	ancho = maxi(4, p_ancho)
	alto = maxi(4, p_alto)
	name = "Zona_" + destino_id
	transitable = TransitableRejilla.new(ancho, alto)
	transitable.amurallar()
	# Un acceso abierto en el borde representa el puerto o camino de llegada.
	var entrada_borde := Vector2i(ancho / 2, alto - 1)
	transitable.liberar(entrada_borde)
	_montar_chunks()
	queue_redraw()

func _montar_chunks() -> void:
	for existente in chunks.values():
		if existente != null and is_instance_valid(existente):
			existente.queue_free()
	chunks.clear()
	_centro_chunks_activo = Vector2i(2147483647, 2147483647)
	var columnas := ceili(float(ancho) / TAMANO_CHUNK)
	var filas := ceili(float(alto) / TAMANO_CHUNK)
	for cy in range(filas):
		for cx in range(columnas):
			var inicio := Vector2i(cx * TAMANO_CHUNK, cy * TAMANO_CHUNK)
			var tam := Vector2i(
				mini(TAMANO_CHUNK, ancho - inicio.x),
				mini(TAMANO_CHUNK, alto - inicio.y)
			)
			var chunk = ZonaChunkScript.new()
			chunk.montar(Vector2i(cx, cy), Rect2i(inicio, tam))
			add_child(chunk)
			chunks[_clave_chunk(Vector2i(cx, cy))] = chunk

func _chunk_de_casilla(casilla: Vector2i):
	return chunks.get(_clave_chunk(chunk_de_casilla(casilla)))

func _registrar_contenido_chunk(nodo: Node, casilla: Vector2i) -> void:
	var chunk = _chunk_de_casilla(casilla)
	if chunk != null:
		chunk.registrar_contenido(nodo)

func _clave_chunk(coordenada: Vector2i) -> String:
	return "%d,%d" % [coordenada.x, coordenada.y]

func chunk_de_casilla(casilla: Vector2i) -> Vector2i:
	return Vector2i(
		floori(float(casilla.x) / TAMANO_CHUNK),
		floori(float(casilla.y) / TAMANO_CHUNK)
	)

func activar_chunk(coordenada: Vector2i, activo: bool = true) -> bool:
	var chunk = chunks.get(_clave_chunk(coordenada))
	if chunk == null:
		return false
	if activo:
		chunk.activar()
	else:
		chunk.desactivar()
	queue_redraw()
	return true

func actualizar_chunks_cerca(posicion: Vector2, radio: int = 1) -> void:
	var centro := chunk_de_casilla(Vector2i(floori(posicion.x), floori(posicion.y)))
	if centro == _centro_chunks_activo:
		return
	_centro_chunks_activo = centro
	for clave in chunks:
		var chunk = chunks[clave]
		var cerca := absi(chunk.coordenada.x - centro.x) <= radio \
			and absi(chunk.coordenada.y - centro.y) <= radio
		if cerca:
			chunk.activar()
		else:
			chunk.desactivar()
	queue_redraw()

func serializar_zona() -> Dictionary:
	var datos := super.serializar_zona()
	datos["chunks"] = {}
	for clave in chunks:
		var chunk = chunks[clave]
		datos["chunks"][clave] = chunk.serializar()
	return datos

func cargar_zona(datos: Dictionary) -> void:
	super.cargar_zona(datos)
	for clave in datos.get("chunks", {}):
		var chunk = chunks.get(str(clave))
		if chunk != null:
			chunk.cargar(datos["chunks"][clave])
	queue_redraw()

## Monta el contenido recolectable declarado por el destino. Los nodos son
## representaciones temporales; RecursosMundo y CultivosMundo conservan el
## estado real y las identidades naturales mantienen la persistencia.
func montar_contenido() -> void:
	if actores == null:
		return
	for fuente in fuentes_recurso:
		if fuente != null and is_instance_valid(fuente):
			fuente.queue_free()
	for parcela in parcelas_cultivo:
		if parcela != null and is_instance_valid(parcela):
			parcela.queue_free()
	for recolector in recolectores_cultivo:
		if recolector != null and is_instance_valid(recolector):
			recolector.queue_free()
	for chunk in chunks.values():
		if chunk != null and is_instance_valid(chunk):
			chunk.limpiar_contenido()
	fuentes_recurso.clear()
	parcelas_cultivo.clear()
	recolectores_cultivo.clear()
	var destino: Resource = BaseDeDatos.destino(destino_id)
	if destino == null:
		return
	var usadas: Array = []
	for i in destino.fuentes.size():
		var casilla := _casilla_contenido(i, usadas)
		if casilla.x < 0:
			continue
		var fuente = FuenteRecursoScript.new()
		fuente.name = "Recurso_%s_%d" % [str(destino.fuentes[i]), i]
		actores.add_child(fuente)
		var clave := "zona:%s:recurso:%s@%d,%d" % [destino_id,
			str(destino.fuentes[i]), casilla.x, casilla.y]
		if fuente.montar(str(destino.fuentes[i]), clave, casilla):
			fuentes_recurso.append(fuente)
			_registrar_contenido_chunk(fuente, casilla)
			usadas.append(casilla)
		else:
			fuente.queue_free()
	for i in destino.cultivos.size():
		var casilla := _casilla_contenido(20 + i, usadas)
		if casilla.x < 0:
			continue
		var parcela = ParcelaCultivoScript.new()
		parcela.name = "Parcela_%s_%d" % [str(destino.cultivos[i]), i]
		actores.add_child(parcela)
		var clave := "zona:%s:parcela:%s@%d,%d" % [destino_id,
			str(destino.cultivos[i]), casilla.x, casilla.y]
		if parcela.montar(str(destino.cultivos[i]), clave, casilla):
			parcelas_cultivo.append(parcela)
			_registrar_contenido_chunk(parcela, casilla)
			_montar_automatizador_cultivo(parcela)
			usadas.append(casilla)
		else:
			parcela.queue_free()
	queue_redraw()

func _montar_automatizador_cultivo(parcela: ParcelaCultivo) -> void:
	var def := parcela.definicion()
	if def == null or def.automatizador_edificio == "" or def.automatizador_trabajadores <= 0:
		return
	var recolector = RecolectorCultivoScript.new()
	recolector.name = "RecolectorCultivo_" + parcela.definicion_id
	actores.add_child(recolector)
	recolector.montar(parcela.identidad.instancia, def.automatizador_edificio,
		def.automatizador_trabajadores, def.automatizador_horario_id)
	recolectores_cultivo.append(recolector)
	_registrar_contenido_chunk(recolector, parcela.casilla())

func _casilla_contenido(semilla: int, usadas: Array) -> Vector2i:
	var margen := 2
	var ancho_util := maxi(1, ancho - margen * 2 - 1)
	var alto_util := maxi(1, alto - margen * 2 - 2)
	for intento in 12:
		var x := margen + ((semilla * 5 + intento * 3) % ancho_util)
		var y := margen + ((semilla * 3 + intento * 2) % alto_util)
		var casilla := Vector2i(x, y)
		if casilla in usadas:
			continue
		if transitable.cabe_en(Vector2(casilla) + Vector2(0.5, 0.5), Huella.cuadrada(0.52)):
			return casilla
	return Vector2i(-1, -1)

func entrada() -> Vector2:
	return Vector2(ancho / 2, alto - 2) + Vector2(0.5, 0.5)

## Añade un único punto de embarque para una ruta data-driven. El destino
## remoto puede tener una ruta de regreso o una conexión posterior sin que la
## zona necesite conocer la escena que la contiene.
func montar_transicion(ruta_id: String) -> Node:
	if actores == null:
		actores = Node2D.new()
		actores.name = "Actores"
		actores.y_sort_enabled = true
		add_child(actores)
	var ruta: Resource = MapaGlobal.ruta(ruta_id)
	if ruta == null:
		return null
	var t: Node = TransicionGlobalScript.new()
	t.name = "Embarque_" + ruta_id
	t.ruta_id = ruta_id
	t.casilla_propia = Vector2i(ancho / 2, alto - 2)
	t.position = Iso.centro_v(t.casilla_propia)
	actores.add_child(t)
	transiciones.append(t)
	return t

func _draw() -> void:
	for y in range(alto):
		for x in range(ancho):
			var chunk = chunks.get(_clave_chunk(chunk_de_casilla(Vector2i(x, y))))
			if chunk != null and not chunk.activo:
				continue
			var centro := Iso.centro(x, y)
			var color := COLOR_SUELO if (x + y) % 2 == 0 else COLOR_SUELO_ALT
			if x == ancho / 2 or y == alto / 2:
				color = COLOR_CAMINO
			draw_colored_polygon(PackedVector2Array([
				centro + Vector2(0, -Iso.MEDIO_Y),
				centro + Vector2(Iso.MEDIO_X, 0),
				centro + Vector2(0, Iso.MEDIO_Y),
				centro + Vector2(-Iso.MEDIO_X, 0),
			]), color)
