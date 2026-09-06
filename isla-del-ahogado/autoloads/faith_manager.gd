extends Node

## Favor del mar y relación con el Templo del Dios Ahogado.
## Las donaciones y consecuencias narrativas llegarán más adelante.

var sea_favor: int = 0

signal faith_changed(value: int)
var blessing_until_day := 0

func donate(amount: int) -> bool:
	if amount <= 0 or not EconomyManager.spend_doubloons(amount):
		return false
	add_favor(amount)
	return true

func add_favor(amount: int) -> void:
	if amount == 0:
		return
	sea_favor = maxi(0, sea_favor + amount)
	faith_changed.emit(sea_favor)
	AbyssManager.check_unlock()

func can_activate_blessing() -> bool:
	return sea_favor >= 10

func activate_blessing() -> bool:
	if not can_activate_blessing():
		return false
	blessing_until_day = TimeManager.day + 1
	return true

func get_resource_multiplier() -> float:
	return 1.1 if blessing_until_day > 0 and TimeManager.day <= blessing_until_day else 1.0
