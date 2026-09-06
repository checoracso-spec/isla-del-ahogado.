extends Node

## Calendario de la partida: día, hora, ciclo día/noche y avance temporal.
## El mundo avanza lentamente para que el cambio de luz sea visible durante la prueba.

signal time_changed(day: int, minute_of_day: int, daylight: float)
signal day_changed(day: int)

var day: int = 1
var minute_of_day: int = 8 * 60
@export var game_minutes_per_real_second: float = 2.0
var _minute_accumulator := 0.0

func _ready() -> void:
	time_changed.emit(day, minute_of_day, get_daylight_factor())

func _process(delta: float) -> void:
	_minute_accumulator += delta * game_minutes_per_real_second
	if _minute_accumulator < 1.0:
		return
	var minutes_to_advance := int(_minute_accumulator)
	_minute_accumulator -= minutes_to_advance
	advance_minutes(minutes_to_advance)

func advance_minutes(amount: int) -> void:
	if amount <= 0:
		return
	minute_of_day += amount
	while minute_of_day >= 24 * 60:
		minute_of_day -= 24 * 60
		day += 1
		day_changed.emit(day)
	time_changed.emit(day, minute_of_day, get_daylight_factor())

func advance_to_next_day() -> void:
	day += 1
	minute_of_day = 8 * 60
	_minute_accumulator = 0.0
	day_changed.emit(day)
	time_changed.emit(day, minute_of_day, get_daylight_factor())

func get_daylight_factor() -> float:
	const sunrise := 6.0 * 60.0
	const sunset := 20.0 * 60.0
	if minute_of_day <= sunrise or minute_of_day >= sunset:
		return 0.0
	var progress := (float(minute_of_day) - sunrise) / (sunset - sunrise)
	return sin(progress * PI)

func get_time_text() -> String:
	return "%02d:%02d" % [int(minute_of_day / 60), minute_of_day % 60]
