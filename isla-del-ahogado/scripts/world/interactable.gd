class_name Interactable
extends Area2D

## Base genérica para cualquier objeto que pueda recibir la acción interact.
## Los objetos concretos solo necesitan heredar e implementar su resultado.

signal interacted(interactor: Node)

@export var interaction_radius := 105.0
@export var energy_cost := 4
@export var interaction_prompt := "E  Interactuar"
var interaction_indicator: Label
var nearby_interactor: Node2D
var last_interaction_msec := -1000

func _ready() -> void:
	add_to_group("interactable")
	set_meta("interaction_radius", interaction_radius)
	set_meta("energy_cost", energy_cost)
	set_meta("_handles_energy", true)
	interaction_indicator = Label.new()
	interaction_indicator.name = "InteractionIndicator"
	interaction_indicator.z_index = 20
	interaction_indicator.text = interaction_prompt
	interaction_indicator.position = Vector2(-44.0, -42.0)
	interaction_indicator.visible = false
	interaction_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interaction_indicator.add_theme_color_override("font_color", Color("#ffe3a6"))
	interaction_indicator.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	interaction_indicator.add_theme_constant_override("shadow_offset_x", 2)
	interaction_indicator.add_theme_constant_override("shadow_offset_y", 2)
	add_child(interaction_indicator)
	set_process(true)

func _process(_delta: float) -> void:
	nearby_interactor = _find_player()
	var available := is_instance_valid(nearby_interactor) and global_position.distance_to(nearby_interactor.global_position) <= interaction_radius
	set_interaction_available(available)
	if available and Input.is_action_just_pressed("interact"):
		interact(nearby_interactor)

func _find_player() -> Node2D:
	var found := get_tree().get_first_node_in_group("player") as Node2D
	if is_instance_valid(found):
		return found
	var scene := get_tree().current_scene
	if scene != null:
		return scene.find_child("Player", true, false) as Node2D
	return null

func set_interaction_available(available: bool) -> void:
	if is_instance_valid(interaction_indicator):
		interaction_indicator.visible = available

func interact(interactor: Node) -> bool:
	if is_queued_for_deletion():
		return false
	var now := Time.get_ticks_msec()
	if now - last_interaction_msec < 120:
		return false
	last_interaction_msec = now
	if interactor == null or not interactor.has_method("try_spend_energy"):
		return false
	if not interactor.try_spend_energy(energy_cost):
		return false
	interacted.emit(interactor)
	return true
