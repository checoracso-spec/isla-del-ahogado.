extends Node

## Diálogos ramificados: carga árboles JSON, navega opciones y dispara
## acciones de QuestManager desde una conversación.

signal dialogue_started(dialogue_id: String)
signal node_changed(node: Dictionary)
signal dialogue_closed

var dialogues: Dictionary = {}
var active_dialogue_id := ""
var current_node_id := ""

func _ready() -> void:
	_load_dialogues()

func _load_dialogues() -> void:
	var file := FileAccess.open("res://data/dialogues/npc_dialogues.json", FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		return
	for entry in parsed:
		if entry is Dictionary and not str(entry.get("id", "")).is_empty():
			dialogues[str(entry.id)] = entry

func start_dialogue(dialogue_id: String) -> bool:
	if not dialogues.has(dialogue_id):
		return false
	active_dialogue_id = dialogue_id
	current_node_id = str(dialogues[dialogue_id].get("start", "root"))
	dialogue_started.emit(dialogue_id)
	node_changed.emit(get_current_node())
	return true

func get_current_node() -> Dictionary:
	if active_dialogue_id.is_empty() or not dialogues.has(active_dialogue_id):
		return {}
	var nodes: Dictionary = dialogues[active_dialogue_id].get("nodes", {})
	return nodes.get(current_node_id, {})

func choose_option(index: int) -> bool:
	var node := get_current_node()
	var options: Array = node.get("options", [])
	if index < 0 or index >= options.size():
		return false
	var option: Dictionary = options[index]
	_run_action(option.get("action", {}))
	var next_id := str(option.get("next", "close"))
	if next_id.is_empty() or next_id == "close":
		close_dialogue()
		return true
	current_node_id = next_id
	node_changed.emit(get_current_node())
	return true

func close_dialogue() -> void:
	if active_dialogue_id.is_empty():
		return
	active_dialogue_id = ""
	current_node_id = ""
	dialogue_closed.emit()

func _run_action(action_data) -> void:
	if not action_data is Dictionary:
		return
	match str(action_data.get("type", "")):
		"start_quest": QuestManager.start_quest(str(action_data.get("quest_id", "")))
		"complete_objective": QuestManager.complete_objective(str(action_data.get("quest_id", "")), str(action_data.get("objective_id", "")), int(action_data.get("amount", 1)))
