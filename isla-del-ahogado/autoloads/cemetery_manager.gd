extends Node

## Estado y calidad del cementerio de la isla.
## Se reserva aquí la coordinación de parcelas, cuerpos y reputación funeraria.

var cemetery_quality: int = 0

signal cemetery_changed(quality: int)
var graves: Array[Dictionary] = []
const MAX_GRAVES := 6

func _ready() -> void:
	for _index in range(MAX_GRAVES):
		graves.append({"occupied": false, "quality": 0})

func bury_body(quality: int = 1) -> bool:
	for index in range(graves.size()):
		if not graves[index].get("occupied", false):
			graves[index] = {"occupied": true, "quality": clampi(quality, 0, 3)}
			_recalculate()
			return true
	return false

func get_open_graves() -> int:
	var open := 0
	for grave in graves:
		if not grave.get("occupied", false):
			open += 1
	return open

func _recalculate() -> void:
	cemetery_quality = 0
	for grave in graves:
		if grave.get("occupied", false):
			cemetery_quality += int(grave.get("quality", 0))
	cemetery_changed.emit(cemetery_quality)
