extends CanvasLayer

## Capa de controles táctiles. Se mantiene oculta en escritorio nativo.

func _ready() -> void:
	var is_touch_build := OS.has_feature("web") or OS.has_feature("mobile")
	$Overlay.visible = is_touch_build

