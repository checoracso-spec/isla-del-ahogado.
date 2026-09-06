extends Node2D

## Mundo de prueba del prompt 2: cuadrícula top-down, jugador, recolectable,
## interacción, ciclo de luz y conexión con el HUD.

const TILE_SIZE := Vector2(32.0, 32.0)
const GRID_SIZE := Vector2i(32, 20)
const WORLD_CENTER := Vector2(576.0, 384.0)
const FLOOR_COLOR := Color("#263d46")
const FLOOR_ALT_COLOR := Color("#2d4850")
const EDGE_COLOR := Color("#527176")

@onready var player := $CharactersAndObjects/Player
@onready var hud := $HUD
@onready var day_night_tint := $DayNightOverlay/Tint

func _ready() -> void:
	GameManager.world_scene = self
	GameManager.player = player
	player.energy_changed.connect(hud.update_energy)
	player.energy_depleted.connect(func() -> void: hud.show_toast("No tienes energía suficiente."))
	hud.sleep_requested.connect(_sleep)
	TimeManager.time_changed.connect(_on_time_changed)
	_on_time_changed(TimeManager.day, TimeManager.minute_of_day, TimeManager.get_daylight_factor())
	queue_redraw()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("sleep") and not get_tree().paused:
		_sleep()

func _sleep() -> void:
	if get_tree().paused:
		return
	TimeManager.advance_to_next_day()
	player.restore_energy()
	hud.show_toast("Has dormido. Comienza el día %d." % TimeManager.day)

func _on_time_changed(_day: int, _minute_of_day: int, daylight: float) -> void:
	if not is_instance_valid(day_night_tint):
		return
	var night_strength := 1.0 - daylight
	day_night_tint.color = Color(0.08, 0.13, 0.32, 0.36 * night_strength)

func _draw() -> void:
	var grid_center := Vector2((GRID_SIZE.x - 1) * 0.5, (GRID_SIZE.y - 1) * 0.5)
	for y in range(GRID_SIZE.y):
		for x in range(GRID_SIZE.x):
			var local_x := float(x) - grid_center.x
			var local_y := float(y) - grid_center.y
			var center := WORLD_CENTER + Vector2(local_x * TILE_SIZE.x, local_y * TILE_SIZE.y)
			var tile_rect := Rect2(center - TILE_SIZE * 0.5, TILE_SIZE)
			var color := FLOOR_ALT_COLOR if (x + y) % 2 == 0 else FLOOR_COLOR
			draw_rect(tile_rect, color, true)
			draw_rect(tile_rect, EDGE_COLOR, false, 1.0)
