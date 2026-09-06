extends Node

## Sistema global de misiones: carga quests desde JSON, sigue objetivos,
## entrega recompensas y expone señales para NPCs, HUD y sistemas de juego.

signal quest_started(quest_id: String)
signal objective_completed(quest_id: String, objective_id: String)
signal quest_completed(quest_id: String)
signal quests_changed
signal reputation_changed(value: int)

var quest_definitions: Dictionary = {}
var quest_states: Dictionary = {}
var unlocked_recipes: Array[String] = []
var tavern_reputation := 0

func _ready() -> void:
	_load_quests()

func _load_quests() -> void:
	var file := FileAccess.open("res://data/quests/quests.json", FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		return
	for entry in parsed:
		if not entry is Dictionary:
			continue
		var quest_id := str(entry.get("id", ""))
		if quest_id.is_empty():
			continue
		quest_definitions[quest_id] = entry
		quest_states[quest_id] = {"status": "no_iniciada", "objectives": {}}

func start_quest(id: String) -> bool:
	if not quest_definitions.has(id):
		return false
	var state: Dictionary = quest_states.get(id, {"status": "no_iniciada", "objectives": {}})
	if str(state.get("status", "no_iniciada")) != "no_iniciada":
		return false
	var progress: Dictionary = {}
	for objective in quest_definitions[id].get("objectives", []):
		progress[str(objective.get("id", ""))] = 0
	state["status"] = "activa"
	state["objectives"] = progress
	quest_states[id] = state
	quest_started.emit(id)
	quests_changed.emit()
	return true

func complete_objective(quest_id: String, objective_id: String, amount: int = 1) -> bool:
	if not is_quest_active(quest_id) or amount <= 0:
		return false
	var definition: Dictionary = quest_definitions.get(quest_id, {})
	var state: Dictionary = quest_states.get(quest_id, {})
	var progress: Dictionary = state.get("objectives", {})
	for objective in definition.get("objectives", []):
		if str(objective.get("id", "")) != objective_id:
			continue
		var required := maxi(1, int(objective.get("required", 1)))
		var current := int(progress.get(objective_id, 0))
		if current >= required:
			return false
		progress[objective_id] = mini(required, current + amount)
		state["objectives"] = progress
		quest_states[quest_id] = state
		objective_completed.emit(quest_id, objective_id)
		if int(progress[objective_id]) >= required:
			_try_complete_quest(quest_id)
		quests_changed.emit()
		return true
	return false

func notify_event(event_type: String, target: String, amount: int = 1) -> void:
	for quest_id in quest_definitions:
		if not is_quest_active(quest_id):
			continue
		var definition: Dictionary = quest_definitions[quest_id]
		for objective in definition.get("objectives", []):
			if str(objective.get("type", "")) == event_type and str(objective.get("target", "")) == target:
				complete_objective(quest_id, str(objective.get("id", "")), amount)

func is_quest_active(id: String) -> bool:
	return str(quest_states.get(id, {}).get("status", "")) == "activa"

func is_quest_completed(id: String) -> bool:
	return str(quest_states.get(id, {}).get("status", "")) == "completada"

func get_quest(id: String) -> Dictionary:
	return quest_definitions.get(id, {})

func get_quest_state(id: String) -> Dictionary:
	return quest_states.get(id, {"status": "no_iniciada", "objectives": {}})

func get_all_quests() -> Array:
	var result: Array = []
	for id in quest_definitions:
		result.append({"id": id, "definition": quest_definitions[id], "state": quest_states.get(id, {})})
	return result

func get_npc_quests(npc_id: String) -> Array:
	var result: Array = []
	for quest in get_all_quests():
		if str(quest.definition.get("npc", "")) == npc_id:
			result.append(quest)
	return result

func get_npc_indicator(npc_id: String) -> String:
	var has_active := false
	var has_available := false
	var has_completed := false
	for quest in get_npc_quests(npc_id):
		var status := str(quest.state.get("status", "no_iniciada"))
		if status == "activa":
			has_active = true
		elif status == "no_iniciada":
			has_available = true
		elif status == "completada":
			has_completed = true
	if has_available:
		return "!"
	if has_active:
		return "?"
	if has_completed:
		return "✓"
	return ""

func get_objective_progress(quest_id: String, objective_id: String) -> int:
	return int(quest_states.get(quest_id, {}).get("objectives", {}).get(objective_id, 0))

func is_recipe_unlocked(recipe_id: String) -> bool:
	return recipe_id in unlocked_recipes

func add_tavern_reputation(amount: int = 1) -> void:
	if amount <= 0:
		return
	tavern_reputation += amount
	reputation_changed.emit(tavern_reputation)

func _try_complete_quest(quest_id: String) -> void:
	var definition: Dictionary = quest_definitions[quest_id]
	var state: Dictionary = quest_states[quest_id]
	var progress: Dictionary = state.get("objectives", {})
	for objective in definition.get("objectives", []):
		var objective_id := str(objective.get("id", ""))
		if int(progress.get(objective_id, 0)) < maxi(1, int(objective.get("required", 1))):
			return
	state["status"] = "completada"
	quest_states[quest_id] = state
	_apply_rewards(definition.get("rewards", {}))
	quest_completed.emit(quest_id)

func _apply_rewards(rewards: Dictionary) -> void:
	var doubloons := int(rewards.get("doubloons", 0))
	if doubloons != 0:
		EconomyManager.add_doubloons(doubloons)
	var faith := int(rewards.get("faith", 0))
	if faith != 0:
		FaithManager.add_favor(faith)
	var reputation := int(rewards.get("reputation", 0))
	if reputation != 0:
		add_tavern_reputation(reputation)
	var recipe_id := str(rewards.get("unlock_recipe", ""))
	if not recipe_id.is_empty() and not is_recipe_unlocked(recipe_id):
		unlocked_recipes.append(recipe_id)
	for item_data in rewards.get("items", []):
		var item := Item.new()
		item.item_id = str(item_data.get("id", ""))
		item.item_name = str(item_data.get("name", item.item_id))
		item.max_stack = int(item_data.get("max_stack", 99))
		InventorySystem.add_item(item, int(item_data.get("quantity", 1)))
