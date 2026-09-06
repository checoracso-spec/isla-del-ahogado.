extends Node

## Preferencias persistentes de accesibilidad y presentación, separadas del guardado de partida.

const CONFIG_PATH := "user://isla_del_ahogado_settings.cfg"
const SECTION := "preferences"
const DEFAULT_VOLUME_DB := 0.0
const DEFAULT_TEXT_SCALE := 1.0
const DEFAULT_TOUCH_ALWAYS_VISIBLE := false

signal settings_changed
signal text_scale_changed(value: float)
signal touch_visibility_changed(visible: bool)

var master_volume_db: float = DEFAULT_VOLUME_DB
var text_scale: float = DEFAULT_TEXT_SCALE
var touch_controls_always_visible: bool = DEFAULT_TOUCH_ALWAYS_VISIBLE

func _ready() -> void:
	_load()
	_apply_audio()

func _load() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	master_volume_db = float(config.get_value(SECTION, "master_volume_db", DEFAULT_VOLUME_DB))
	text_scale = clampf(float(config.get_value(SECTION, "text_scale", DEFAULT_TEXT_SCALE)), 0.85, 1.35)
	touch_controls_always_visible = bool(config.get_value(SECTION, "touch_controls_always_visible", DEFAULT_TOUCH_ALWAYS_VISIBLE))

func _save() -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION, "master_volume_db", master_volume_db)
	config.set_value(SECTION, "text_scale", text_scale)
	config.set_value(SECTION, "touch_controls_always_visible", touch_controls_always_visible)
	config.save(CONFIG_PATH)

func set_master_volume_db(value: float) -> void:
	master_volume_db = clampf(value, -30.0, 6.0)
	_apply_audio()
	_save_and_emit()

func set_text_scale(value: float) -> void:
	text_scale = clampf(value, 0.85, 1.35)
	_save_and_emit()
	text_scale_changed.emit(text_scale)

func set_touch_controls_always_visible(value: bool) -> void:
	touch_controls_always_visible = value
	_save_and_emit()
	touch_visibility_changed.emit(is_touch_controls_visible())

func is_touch_controls_visible() -> bool:
	return OS.has_feature("web") or OS.has_feature("mobile") or touch_controls_always_visible

func get_scaled_font_size(base_size: int) -> int:
	return maxi(11, int(round(float(base_size) * text_scale)))

func reset_defaults() -> void:
	master_volume_db = DEFAULT_VOLUME_DB
	text_scale = DEFAULT_TEXT_SCALE
	touch_controls_always_visible = DEFAULT_TOUCH_ALWAYS_VISIBLE
	_apply_audio()
	_save_and_emit()
	text_scale_changed.emit(text_scale)
	touch_visibility_changed.emit(is_touch_controls_visible())

func _apply_audio() -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, master_volume_db)

func _save_and_emit() -> void:
	_save()
	settings_changed.emit()
