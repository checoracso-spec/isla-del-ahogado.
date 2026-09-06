class_name PirateNpc
extends ContentInteractable

## NPC placeholder: nombre, posición fija y diálogo genérico de una línea.

@export var npc_name := "Marinero"
@export var npc_id := ""
var quest_indicator: Label

func _ready() -> void:
	display_name = npc_name
	tint = Color("#a57bc7")
	super._ready()
	quest_indicator = Label.new()
	quest_indicator.name = "QuestIndicator"
	quest_indicator.position = Vector2(-5.0, -58.0)
	quest_indicator.z_index = 30
	quest_indicator.add_theme_font_size_override("font_size", 22)
	quest_indicator.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	quest_indicator.add_theme_constant_override("shadow_offset_x", 2)
	quest_indicator.add_theme_constant_override("shadow_offset_y", 2)
	add_child(quest_indicator)
	QuestManager.quests_changed.connect(_refresh_quest_indicator)
	_refresh_quest_indicator()

func _refresh_quest_indicator() -> void:
	if not is_instance_valid(quest_indicator):
		return
	var indicator := QuestManager.get_npc_indicator(npc_id)
	quest_indicator.text = indicator
	match indicator:
		"!": quest_indicator.add_theme_color_override("font_color", Color("#ffe36e"))
		"?": quest_indicator.add_theme_color_override("font_color", Color("#8fe0ff"))
		"✓": quest_indicator.add_theme_color_override("font_color", Color("#8ee28e"))
		_: quest_indicator.add_theme_color_override("font_color", Color("#ffffff"))
