extends CanvasLayer

## Capa de controles táctiles. Se mantiene oculta en escritorio nativo.

func _ready() -> void:
	$Overlay.visible = SettingsManager.is_touch_controls_visible()
	SettingsManager.touch_visibility_changed.connect(_on_touch_visibility_changed)

func _on_touch_visibility_changed(visible: bool) -> void:
	$Overlay.visible = visible
