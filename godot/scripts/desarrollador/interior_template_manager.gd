class_name InteriorTemplateManager
extends RefCounted

## Guarda y carga layouts planos del editor. No serializa nodos ni recursos vivos.

const RUTA_BASE := "res://data/desarrollador/plantillas"

static func guardar(nombre: String, datos: Dictionary) -> bool:
	var limpio := _sanitizar_nombre(nombre)
	if limpio.is_empty():
		return false
	var ruta := "%s/%s.json" % [RUTA_BASE, limpio]
	var absoluta := ProjectSettings.globalize_path(ruta)
	DirAccess.make_dir_recursive_absolute(absoluta.get_base_dir())
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	if archivo == null:
		return false
	archivo.store_string(JSON.stringify(datos, "\t"))
	archivo.close()
	return true

static func cargar(nombre: String) -> Dictionary:
	var limpio := _sanitizar_nombre(nombre)
	if limpio.is_empty():
		return {}
	var ruta := "%s/%s.json" % [RUTA_BASE, limpio]
	if not FileAccess.file_exists(ruta):
		return {}
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		return {}
	var crudo: Variant = JSON.parse_string(archivo.get_as_text())
	archivo.close()
	return crudo if crudo is Dictionary else {}

static func listar() -> Array[String]:
	var salida: Array[String] = []
	var directorio := DirAccess.open(RUTA_BASE)
	if directorio == null:
		return salida
	for nombre in directorio.get_files():
		if nombre.ends_with(".json"):
			salida.append(nombre.trim_suffix(".json"))
	salida.sort()
	return salida

static func _sanitizar_nombre(nombre: String) -> String:
	var limpio := nombre.strip_edges().to_lower()
	var permitido := "abcdefghijklmnopqrstuvwxyz0123456789_-"
	var salida := ""
	for caracter in limpio:
		if permitido.contains(caracter):
			salida += caracter
	return salida.left(48)
