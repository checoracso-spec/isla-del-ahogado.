class_name PirateNpc
extends ContentInteractable

## NPC placeholder: nombre, posición fija y diálogo genérico de una línea.

@export var npc_name := "Marinero"

func _ready() -> void:
	display_name = npc_name
	tint = Color("#a57bc7")
	super._ready()

