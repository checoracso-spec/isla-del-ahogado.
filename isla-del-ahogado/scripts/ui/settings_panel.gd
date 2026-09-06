class_name SettingsPanel
extends PanelContainer

## Panel reutilizable de ajustes: volumen, escala tipográfica y controles táctiles.

const STYLE_TOKENS = preload("res://scripts/ui/style_tokens.gd")

signal close_requested

var volume_slider: HSlider
var text_scale_slider: HSlider
var touch_toggle: CheckButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	SettingsManager.settings_changed.connect(_refresh_controls)
	_refresh_controls()

func _build() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = STYLE_TOKENS.PANEL_BG
	style.border_color = STYLE_TOKENS.PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", style)
	add_theme_font_size_override("font_size", SettingsManager.get_scaled_font_size(16))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var title := Label.new()
	title.text = "Ajustes"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", SettingsManager.get_scaled_font_size(23))
	box.add_child(title)
	var hint := Label.new()
	hint.text = "Las preferencias se guardan automáticamente."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", STYLE_TOKENS.CREAM)
	box.add_child(hint)

	var volume_label := Label.new()
	volume_label.text = "Volumen general"
	box.add_child(volume_label)
	volume_slider = HSlider.new()
	volume_slider.min_value = -30.0
	volume_slider.max_value = 6.0
	volume_slider.step = 1.0
	volume_slider.custom_minimum_size = Vector2(0, 30)
	volume_slider.value_changed.connect(func(value: float) -> void: SettingsManager.set_master_volume_db(value))
	box.add_child(volume_slider)

	var text_label := Label.new()
	text_label.text = "Tamaño de texto"
	box.add_child(text_label)
	text_scale_slider = HSlider.new()
	text_scale_slider.min_value = 0.85
	text_scale_slider.max_value = 1.35
	text_scale_slider.step = 0.05
	text_scale_slider.custom_minimum_size = Vector2(0, 30)
	text_scale_slider.value_changed.connect(func(value: float) -> void: SettingsManager.set_text_scale(value))
	box.add_child(text_scale_slider)

	touch_toggle = CheckButton.new()
	touch_toggle.text = "Controles táctiles siempre visibles"
	touch_toggle.toggled.connect(func(value: bool) -> void: SettingsManager.set_touch_controls_always_visible(value))
	box.add_child(touch_toggle)

	var separator := HSeparator.new()
	box.add_child(separator)
	var reset := Button.new()
	reset.text = "Restablecer ajustes"
	reset.custom_minimum_size = Vector2(0, 40)
	reset.pressed.connect(SettingsManager.reset_defaults)
	box.add_child(reset)
	var close := Button.new()
	close.text = "Volver"
	close.custom_minimum_size = Vector2(0, 44)
	close.pressed.connect(func() -> void: close_requested.emit())
	box.add_child(close)

func _refresh_controls(_ignored: Variant = null) -> void:
	if not is_instance_valid(volume_slider):
		return
	volume_slider.set_block_signals(true)
	text_scale_slider.set_block_signals(true)
	touch_toggle.set_block_signals(true)
	volume_slider.value = SettingsManager.master_volume_db
	text_scale_slider.value = SettingsManager.text_scale
	touch_toggle.button_pressed = SettingsManager.touch_controls_always_visible
	volume_slider.set_block_signals(false)
	text_scale_slider.set_block_signals(false)
	touch_toggle.set_block_signals(false)
	add_theme_font_size_override("font_size", SettingsManager.get_scaled_font_size(16))
