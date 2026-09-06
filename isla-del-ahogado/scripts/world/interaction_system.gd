extends Node2D

## Coordinador de interacción: detecta el objeto interactable más cercano,
## muestra su indicador y delega la acción sin conocer contenido específico.

@export var player_path: NodePath
@export var default_interaction_radius := 105.0
var player: Node2D
var current_interactable: Node2D
var generic_indicators: Dictionary = {}

func _ready() -> void:
	player = get_node_or_null(player_path) as Node2D

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	var closest: Node2D
	var closest_distance := INF
	for candidate in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(candidate) or not candidate is Node2D:
			continue
		var node := candidate as Node2D
		var radius := float(node.get_meta("interaction_radius", default_interaction_radius))
		var distance := player.global_position.distance_to(node.global_position)
		var available := distance <= radius
		_set_indicator(node, available)
		if available and distance < closest_distance:
			closest = node
			closest_distance = distance
	if current_interactable != closest and is_instance_valid(current_interactable):
		_set_indicator(current_interactable, false)
	current_interactable = closest
	if Input.is_action_just_pressed("interact") and is_instance_valid(current_interactable):
		_interact_with(current_interactable)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and is_instance_valid(current_interactable):
		_interact_with(current_interactable)

func _set_indicator(node: Node2D, available: bool) -> void:
	if node.has_method("set_interaction_available"):
		node.set_interaction_available(available)
		return
	var indicator: Label = generic_indicators.get(node)
	if not is_instance_valid(indicator):
		indicator = Label.new()
		indicator.name = "GenericInteractionIndicator"
		indicator.text = "E  Interactuar"
		indicator.position = Vector2(-44.0, -42.0)
		indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		indicator.add_theme_color_override("font_color", Color("#ffe3a6"))
		node.add_child(indicator)
		generic_indicators[node] = indicator
	indicator.visible = available

func _interact_with(node: Node2D) -> void:
	var handles_energy := bool(node.get_meta("_handles_energy", false))
	if not handles_energy:
		var cost := int(node.get_meta("energy_cost", 0))
		if cost > 0 and not player.try_spend_energy(cost):
			return
	if node.has_method("interact"):
		node.call("interact", player)
	elif node.has_signal("interacted"):
		node.emit_signal("interacted", player)
