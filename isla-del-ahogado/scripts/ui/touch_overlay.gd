extends Control

## Controles táctiles mínimos: joystick virtual e interacción.
## Solo se muestran en Web o en dispositivos móviles; emiten acciones abstractas.

const JOYSTICK_RADIUS := 72.0
const BUTTON_RADIUS := 58.0
var joystick_active := false
var interaction_active := false
var joystick_vector := Vector2.ZERO

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _draw() -> void:
	var joystick_center := _joystick_center()
	var button_center := _button_center()
	draw_circle(joystick_center, JOYSTICK_RADIUS, Color(0.05, 0.08, 0.10, 0.72))
	draw_arc(joystick_center, JOYSTICK_RADIUS, 0.0, TAU, 48, Color("#a7c6bf"), 3.0)
	draw_circle(joystick_center + joystick_vector * 30.0, 28.0, Color(0.36, 0.62, 0.59, 0.9))
	draw_circle(button_center, BUTTON_RADIUS, Color(0.25, 0.12, 0.14, 0.85))
	draw_arc(button_center, BUTTON_RADIUS, 0.0, TAU, 48, Color("#e4a18f"), 3.0)
	draw_string(ThemeDB.fallback_font, button_center - Vector2(24.0, -8.0), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#ffe4c7"))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_update_touch(event.position)
		else:
			_release_all_actions()
		accept_event()
	elif event is InputEventScreenDrag:
		_update_touch(event.position)
		accept_event()

func _update_touch(position: Vector2) -> void:
	var joystick_center := _joystick_center()
	var button_center := _button_center()
	var joystick_offset := position - joystick_center
	if joystick_offset.length() <= JOYSTICK_RADIUS * 1.35:
		joystick_active = true
		joystick_vector = joystick_offset.limit_length(JOYSTICK_RADIUS) / JOYSTICK_RADIUS
		_set_movement_actions(joystick_vector)
	elif position.distance_to(button_center) <= BUTTON_RADIUS * 1.35:
		interaction_active = true
		Input.action_press("interact")
	queue_redraw()

func _joystick_center() -> Vector2:
	return Vector2(110.0, size.y - 110.0)

func _button_center() -> Vector2:
	return Vector2(size.x - 112.0, size.y - 110.0)

func _set_movement_actions(vector: Vector2) -> void:
	Input.action_press("move_left", absf(vector.x)) if vector.x < 0.0 else Input.action_release("move_left")
	Input.action_press("move_right", absf(vector.x)) if vector.x > 0.0 else Input.action_release("move_right")
	Input.action_press("move_up", absf(vector.y)) if vector.y < 0.0 else Input.action_release("move_up")
	Input.action_press("move_down", absf(vector.y)) if vector.y > 0.0 else Input.action_release("move_down")

func _release_all_actions() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "interact"]:
		Input.action_release(action)
	joystick_active = false
	interaction_active = false
	joystick_vector = Vector2.ZERO
	queue_redraw()
