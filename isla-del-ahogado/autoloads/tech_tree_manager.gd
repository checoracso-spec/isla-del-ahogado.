extends Node

## Bitácora del Capitán: tecnologías, desbloqueos y progreso del árbol.
## El árbol de contenido se añadirá en una fase posterior.

var unlocked_technologies: Array[String] = []

signal tech_changed
var tech_nodes: Array[Dictionary] = []

func _ready() -> void:
	var file := FileAccess.open("res://data/tech_tree/tech_tree.json", FileAccess.READ)
	if file != null:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Array:
			for entry in parsed:
				if entry is Dictionary:
					tech_nodes.append(entry)
	if tech_nodes.is_empty():
		tech_nodes = [{"id":"navegacion_1","name":"Brújula rota","cost":1,"category":"Navegación","requires":[]}]

func is_unlocked(id: String) -> bool:
	return id in unlocked_technologies

func can_unlock(id: String) -> bool:
	for node in tech_nodes:
		if node.get("id", "") == id:
			for requirement in node.get("requires", []):
				if not is_unlocked(str(requirement)):
					return false
			return InventorySystem.count_item("pagina_bitacora") >= int(node.get("cost", 1))
	return false

func unlock(id: String) -> bool:
	if is_unlocked(id) or not can_unlock(id):
		return false
	for node in tech_nodes:
		if node.get("id", "") == id:
			if not InventorySystem.remove_item("pagina_bitacora", int(node.get("cost", 1))):
				return false
			unlocked_technologies.append(id)
			tech_changed.emit()
			return true
	return false
