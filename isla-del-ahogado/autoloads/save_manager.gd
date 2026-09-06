extends Node

## Guardado y carga de estado en JSON dentro de user://.
## Mantiene una API mínima para que los sistemas puedan conectarse después.

const SAVE_PATH := "user://isla_del_ahogado_save.json"

func save_game(state: Dictionary = {}) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(state, "\t"))
	return true

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

