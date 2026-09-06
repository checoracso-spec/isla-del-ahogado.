extends Node

## Estado de El Abismo: acceso, progresión y datos de expedición.
## El área se implementará después del andamiaje.

var abyss_unlocked: bool = false

signal abyss_changed(unlocked: bool, active: bool)
var active := false
const FAITH_THRESHOLD := 10

func check_unlock() -> void:
	if not abyss_unlocked and FaithManager.sea_favor >= FAITH_THRESHOLD:
		abyss_unlocked = true
		abyss_changed.emit(abyss_unlocked, active)

func enter() -> bool:
	check_unlock()
	if not abyss_unlocked:
		return false
	active = true
	abyss_changed.emit(abyss_unlocked, active)
	return true

func exit() -> void:
	active = false
	abyss_changed.emit(abyss_unlocked, active)
