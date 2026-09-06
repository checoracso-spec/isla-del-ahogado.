extends Control

## Menú principal de la isla: entrada al mundo y preferencias persistentes.

const STYLE_TOKENS = preload("res://scripts/ui/style_tokens.gd")
const SETTINGS_PANEL_SCRIPT = preload("res://scripts/ui/settings_panel.gd")

var settings_panel: PanelContainer
var menu_panel: PanelContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	SettingsManager.text_scale_changed.connect(_refresh_scale)

func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = STYLE_TOKENS.INK
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var sea_band := ColorRect.new()
	sea_band.position = Vector2(0, 0)
	sea_band.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sea_band.offset_top = -180
	sea_band.color = STYLE_TOKENS.DEEP_SEA
	sea_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sea_band)

	menu_panel = _make_panel()
	menu_panel.position = Vector2(0, 0)
	menu_panel.size = Vector2(430, 500)
	menu_panel.set_anchors_preset(Control.PRESET_CENTER)
	menu_panel.position -= menu_panel.size * 0.5
	add_child(menu_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 26)
	menu_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var title := Label.new()
	title.text = "ISLA DEL AHOGADO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", STYLE_TOKENS.RITUAL_GOLD)
	title.add_theme_font_size_override("font_size", SettingsManager.get_scaled_font_size(28))
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Una herencia maldita. Cero remordimientos."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", STYLE_TOKENS.TEXT)
	box.add_child(subtitle)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 18)
	box.add_child(spacer)
	_add_menu_button(box, "Jugar", _start_world)
	_add_menu_button(box, "Continuar", _continue_world)
	_add_menu_button(box, "Ajustes", _open_settings)
	_add_menu_button(box, "Salir", _exit_game)
	var footer := Label.new()
	footer.text = "Top-down · 32×32 · humor negro marítimo"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color", STYLE_TOKENS.CREAM)
	box.add_child(footer)

	settings_panel = SETTINGS_PANEL_SCRIPT.new()
	settings_panel.visible = false
	settings_panel.size = Vector2(430, 510)
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.position -= settings_panel.size * 0.5
	settings_panel.close_requested.connect(_close_settings)
	add_child(settings_panel)

func _add_menu_button(box: VBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 48)
	button.pressed.connect(callback)
	box.add_child(button)

func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = STYLE_TOKENS.PANEL_BG
	style.border_color = STYLE_TOKENS.PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	panel.add_theme_font_size_override("font_size", SettingsManager.get_scaled_font_size(16))
	return panel

func _start_world() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/world/world.tscn")

func _continue_world() -> void:
	_start_world()

func _open_settings() -> void:
	menu_panel.visible = false
	settings_panel.visible = true

func _close_settings() -> void:
	settings_panel.visible = false
	menu_panel.visible = true

func _exit_game() -> void:
	get_tree().quit()

func _refresh_scale(_value: float) -> void:
	if is_instance_valid(menu_panel):
		menu_panel.add_theme_font_size_override("font_size", SettingsManager.get_scaled_font_size(16))
