class_name ValidadorInterior
extends RefCounted
## Reglas de integridad para cualquier interior descrito por datos.
##
## No construye nodos ni corrige silenciosamente. Devuelve problemas legibles
## para que pruebas, herramientas de contenido y futuros mods puedan rechazar
## una habitación inválida antes de que el jugador quede atrapado.

const CAPAS_VALIDAS := ["suelo", "pared", "mundo", "efectos"]
const DIRECCIONES := [Vector2i(1, 0), Vector2i(-1, 0),
	Vector2i(0, 1), Vector2i(0, -1)]

static func validar(def: InteriorDefinicion) -> PackedStringArray:
	var problemas := PackedStringArray()
	if def == null:
		problemas.append("definición nula")
		return problemas
	if def.ancho < 3 or def.alto < 3:
		problemas.append("%s: tamaño menor que 3×3" % def.id)
		return problemas

	var ocupadas := {}
	var muebles_solidos: Array[Dictionary] = []
	for indice in def.muebles.size():
		var mueble: Dictionary = def.muebles[indice]
		_validar_capa_y_assets(def, mueble, indice, problemas)
		if not bool(mueble.get("solido", true)):
			continue
		muebles_solidos.append(mueble)
		var origen := _casilla(mueble)
		var huella := _huella(mueble)
		for dy in huella.y:
			for dx in huella.x:
				var celda := origen + Vector2i(dx, dy)
				if not _es_interior(def, celda):
					problemas.append("%s: mueble %d ocupa fuera del interior %s"
						% [def.id, indice, celda])
					continue
				if ocupadas.has(celda):
					problemas.append("%s: muebles %s y %d se solapan en %s"
						% [def.id, ocupadas[celda], indice, celda])
				else:
					ocupadas[celda] = indice

	for indice in def.muebles.size():
		var mueble: Dictionary = def.muebles[indice]
		if bool(mueble.get("solido", true)):
			continue
		var origen := _casilla(mueble)
		var huella := _huella(mueble)
		for dy in huella.y:
			for dx in huella.x:
				var celda := origen + Vector2i(dx, dy)
				if not _es_posicion_visual_valida(def, mueble, celda):
					problemas.append("%s: mueble no sólido %d ocupa fuera del interior %s"
						% [def.id, indice, celda])
					continue
				if ocupadas.has(celda):
					problemas.append("%s: mueble no sólido %d se solapa con mueble %s en %s"
						% [def.id, indice, ocupadas[celda], celda])

	var entrada := def.entrada_valida()
	if ocupadas.has(entrada):
		problemas.append("%s: la entrada %s está ocupada" % [def.id, entrada])
	for indice in def.muebles.size():
		var mueble: Dictionary = def.muebles[indice]
		if not bool(mueble.get("solido", true)) and _ocupa(mueble, entrada):
			problemas.append("%s: mueble no sólido %d ocupa la entrada %s"
				% [def.id, indice, entrada])

	_validar_accesibilidad(def, entrada, ocupadas, problemas)
	_validar_adyacencias(def, muebles_solidos, ocupadas, problemas)
	return problemas

static func _validar_capa_y_assets(def: InteriorDefinicion, mueble: Dictionary,
		indice: int, problemas: PackedStringArray) -> void:
	var capa := str(mueble.get("capa_visual", "mundo"))
	if capa not in CAPAS_VALIDAS:
		problemas.append("%s: mueble %d usa capa_visual '%s' inválida"
			% [def.id, indice, capa])
	if bool(mueble.get("solido", true)) and capa != "mundo":
		problemas.append("%s: mueble sólido %d debe usar capa_visual 'mundo'"
			% [def.id, indice])
	for campo in ["asset", "asset_cerrado", "asset_abierto"]:
		var clave := str(mueble.get(campo, ""))
		if clave != "" and not Assets.existe(clave):
			problemas.append("%s: mueble %d referencia asset inexistente '%s'"
				% [def.id, indice, clave])
	if str(mueble.get("tipo", "")) == "cofre":
		var definicion := str(mueble.get("definicion", "cofre_oxidado"))
		if BaseDeDatos.item(definicion) == null:
			problemas.append("%s: cofre %d usa definición inexistente '%s'"
				% [def.id, indice, definicion])

static func _validar_accesibilidad(def: InteriorDefinicion, entrada: Vector2i,
		ocupadas: Dictionary, problemas: PackedStringArray) -> void:
	if ocupadas.has(entrada):
		return
	var visitadas := {entrada: true}
	var cola: Array[Vector2i] = [entrada]
	var cursor := 0
	while cursor < cola.size():
		var actual := cola[cursor]
		cursor += 1
		for direccion in DIRECCIONES:
			var vecina: Vector2i = actual + direccion
			if _es_interior(def, vecina) and not ocupadas.has(vecina) \
					and not visitadas.has(vecina):
				visitadas[vecina] = true
				cola.append(vecina)
	var libres := (def.ancho - 2) * (def.alto - 2) - ocupadas.size()
	if visitadas.size() != libres:
		problemas.append("%s: sólo %d de %d casillas libres son accesibles"
			% [def.id, visitadas.size(), libres])

static func _validar_adyacencias(def: InteriorDefinicion,
		muebles: Array[Dictionary], ocupadas: Dictionary,
		problemas: PackedStringArray) -> void:
	for indice in muebles.size():
		var mueble: Dictionary = muebles[indice]
		var origen: Vector2i = _casilla(mueble)
		var huella: Vector2i = _huella(mueble)
		var accesible := false
		for dy in huella.y:
			for dx in huella.x:
				var celda: Vector2i = origen + Vector2i(dx, dy)
				for direccion: Vector2i in DIRECCIONES:
					var vecina: Vector2i = celda + direccion
					if _es_interior(def, vecina) and not ocupadas.has(vecina):
						accesible = true
						break
				if accesible:
					break
			if accesible:
				break
		if not accesible:
			problemas.append("%s: mueble sólido en %s no tiene acceso adyacente"
				% [def.id, origen])

static func _casilla(mueble: Dictionary) -> Vector2i:
	var valor: Variant = mueble.get("casilla", Vector2i.ZERO)
	return valor if valor is Vector2i else Vector2i.ZERO

static func _huella(mueble: Dictionary) -> Vector2i:
	var valor: Variant = mueble.get("huella", Vector2i.ONE)
	if valor is Vector2i:
		return Vector2i(maxi(1, valor.x), maxi(1, valor.y))
	return Vector2i.ONE

static func _es_interior(def: InteriorDefinicion, celda: Vector2i) -> bool:
	return celda.x >= 1 and celda.y >= 1 \
		and celda.x < def.ancho - 1 and celda.y < def.alto - 1

static func _es_posicion_visual_valida(def: InteriorDefinicion,
		mueble: Dictionary, celda: Vector2i) -> bool:
	if str(mueble.get("capa_visual", "mundo")) == "pared":
		return (celda.x == 0 and celda.y >= 1 and celda.y < def.alto - 1) \
			or (celda.y == 0 and celda.x >= 1 and celda.x < def.ancho - 1)
	return _es_interior(def, celda)

static func _ocupa(mueble: Dictionary, celda: Vector2i) -> bool:
	var origen := _casilla(mueble)
	var huella := _huella(mueble)
	return celda.x >= origen.x and celda.y >= origen.y \
		and celda.x < origen.x + huella.x and celda.y < origen.y + huella.y
