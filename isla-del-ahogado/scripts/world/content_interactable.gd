class_name ContentInteractable
extends Interactable

## Interactable visual de contenido: delega una acción concreta al ContentSystem.

@export var action_id := ""
@export var display_name := "Objeto"
@export var tint := Color("#d3a35d")
var content_root: Node

func _ready() -> void:
	interaction_prompt = "E  " + display_name
	super._ready()
	queue_redraw()

func interact(interactor: Node) -> bool:
	if not super.interact(interactor):
		return false
	content_root = get_tree().current_scene.find_child("ContentSystem", true, false)
	if is_instance_valid(content_root) and content_root.has_method("handle_action"):
		content_root.handle_action(action_id, self)
	return true

func _draw() -> void:
	draw_circle(Vector2(0.0, 12.0), 15.0, Color(0.02, 0.03, 0.04, 0.35))
	draw_rect(Rect2(-15.0, -18.0, 30.0, 30.0), tint, true)
	draw_rect(Rect2(-15.0, -18.0, 30.0, 30.0), Color("#f6e2b3"), false, 2.0)
	draw_line(Vector2(-10.0, -3.0), Vector2(10.0, 7.0), Color(0.1, 0.12, 0.13, 0.8), 3.0)

