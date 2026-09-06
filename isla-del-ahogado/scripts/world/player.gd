extends CharacterBody2D

## Jugador base: movimiento abstracto, energía y placeholder visual de pirata.
## No contiene todavía habilidades, combate ni reglas de sistemas específicos.

signal energy_changed(current: int, maximum: int)
signal energy_depleted

@export var move_speed := 230.0
@export var max_energy := 100
@export var map_bounds := Rect2(64.0, 64.0, 1024.0, 640.0)
var energy: int
var click_target := Vector2.ZERO
var has_click_target := false

func _ready() -> void:
	add_to_group("player")
	energy = max_energy
	queue_redraw()
	energy_changed.emit(energy, max_energy)

func _physics_process(_delta: float) -> void:
	if get_tree().paused:
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var top_down_vector := input_vector
	if top_down_vector.length_squared() > 0.001:
		has_click_target = false
		if top_down_vector.length_squared() > 1.0:
			top_down_vector = top_down_vector.normalized()
		velocity = top_down_vector * move_speed
	elif has_click_target:
		var to_target := click_target - global_position
		if to_target.length() <= 8.0:
			has_click_target = false
			velocity = Vector2.ZERO
		else:
			velocity = to_target.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	global_position.x = clampf(global_position.x, map_bounds.position.x, map_bounds.end.x)
	global_position.y = clampf(global_position.y, map_bounds.position.y, map_bounds.end.y)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		click_target = get_global_mouse_position()
		has_click_target = true

func try_spend_energy(amount: int) -> bool:
	if amount <= 0:
		return true
	if energy < amount:
		energy_depleted.emit()
		return false
	energy -= amount
	energy_changed.emit(energy, max_energy)
	return true

func restore_energy() -> void:
	energy = max_energy
	energy_changed.emit(energy, max_energy)

func _draw() -> void:
	draw_circle(Vector2(0.0, 10.0), 12.0, Color(0.03, 0.04, 0.05, 0.42))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11.0, 5.0), Vector2(11.0, 5.0), Vector2(8.0, 22.0), Vector2(-8.0, 22.0)
	]), Color("#8d3e37"))
	draw_circle(Vector2(0.0, -3.0), 8.0, Color("#d79a70"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11.0, -6.0), Vector2(11.0, -6.0), Vector2(5.0, -13.0), Vector2(-4.0, -14.0)
	]), Color("#1d222c"))
	draw_circle(Vector2(-3.0, -3.0), 1.0, Color("#211b1b"))
	draw_circle(Vector2(3.0, -3.0), 1.0, Color("#211b1b"))
