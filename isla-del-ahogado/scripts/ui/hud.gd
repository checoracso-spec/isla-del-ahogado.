extends CanvasLayer

## HUD unificado del prompt 2: energía, reloj, doblones, inventario, dormir y pausa.

const STYLE_TOKENS = preload("res://scripts/ui/style_tokens.gd")
const SETTINGS_PANEL_SCRIPT = preload("res://scripts/ui/settings_panel.gd")

signal sleep_requested

var root_control: Control
var stats_panel: PanelContainer
var inventory_button: Button
var sleep_button: Button
var quest_button: Button
var pause_button: Button
var energy_label: Label
var energy_bar: ProgressBar
var clock_label: Label
var doubloons_label: Label
var favor_label: Label
var inventory_panel: PanelContainer
var inventory_grid: GridContainer
var slot_buttons: Array[Button] = []
var pause_panel: PanelContainer
var quest_panel: PanelContainer
var settings_panel: PanelContainer
var quest_list: VBoxContainer
var toast_label: Label
var toast_timer: Timer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	InventorySystem.inventory_changed.connect(_refresh_inventory)
	TimeManager.time_changed.connect(_on_time_changed)
	EconomyManager.doubloons_changed.connect(_on_doubloons_changed)
	FaithManager.faith_changed.connect(_on_faith_changed)
	QuestManager.quests_changed.connect(_refresh_quest_diary)
	_refresh_inventory()
	_on_time_changed(TimeManager.day, TimeManager.minute_of_day, TimeManager.get_daylight_factor())
	_on_doubloons_changed(EconomyManager.doubloons)
	_on_faith_changed(FaithManager.sea_favor)
	_refresh_quest_diary()

func _build_ui() -> void:
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_theme_font_size_override("font_size", SettingsManager.get_scaled_font_size(16))
	add_child(root_control)

	stats_panel = _make_panel(Vector2(20.0, 20.0), Vector2(380.0, 108.0))
	root_control.add_child(stats_panel)
	var stats_margin := MarginContainer.new()
	stats_margin.add_theme_constant_override("margin_left", 14)
	stats_margin.add_theme_constant_override("margin_top", 10)
	stats_margin.add_theme_constant_override("margin_right", 14)
	stats_margin.add_theme_constant_override("margin_bottom", 10)
	stats_panel.add_child(stats_margin)
	var stats_box := VBoxContainer.new()
	stats_margin.add_child(stats_box)
	var top_line := HBoxContainer.new()
	stats_box.add_child(top_line)
	clock_label = Label.new()
	clock_label.text = "Día 1 · 08:00"
	top_line.add_child(clock_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_line.add_child(spacer)
	doubloons_label = Label.new()
	doubloons_label.text = "Doblones: 0"
	top_line.add_child(doubloons_label)
	favor_label = Label.new()
	favor_label.text = "Favor: 0"
	stats_box.add_child(favor_label)
	energy_label = Label.new()
	energy_label.text = "Energía 100/100"
	stats_box.add_child(energy_label)
	energy_bar = ProgressBar.new()
	energy_bar.max_value = 100
	energy_bar.value = 100
	energy_bar.show_percentage = false
	energy_bar.custom_minimum_size = Vector2(0.0, 18.0)
	stats_box.add_child(energy_bar)

	inventory_button = _create_button("Inventario [I]", Vector2(20.0, 142.0), Vector2(160.0, 44.0), _toggle_inventory)
	sleep_button = _create_button("Dormir [Q]", Vector2(190.0, 142.0), Vector2(140.0, 44.0), _request_sleep)
	quest_button = _create_button("Misiones [J]", Vector2(16.0, 188.0), Vector2(160.0, 40.0), _toggle_quest_diary)
	pause_button = _create_button("Pausa [Esc]", Vector2(1140.0, 20.0), Vector2(120.0, 44.0), _toggle_pause, true)

	_build_inventory_panel()
	_build_pause_panel()
	_build_quest_panel()
	settings_panel = SETTINGS_PANEL_SCRIPT.new()
	settings_panel.visible = false
	settings_panel.close_requested.connect(_close_settings)
	root_control.add_child(settings_panel)
	SettingsManager.text_scale_changed.connect(_on_text_scale_changed)
	_layout_responsive()

	toast_label = Label.new()
	toast_label.position = Vector2(390.0, 650.0)
	toast_label.size = Vector2(500.0, 40.0)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_color", Color("#ffe3a6"))
	toast_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	toast_label.add_theme_constant_override("shadow_offset_x", 2)
	toast_label.add_theme_constant_override("shadow_offset_y", 2)
	root_control.add_child(toast_label)
	toast_timer = Timer.new()
	toast_timer.one_shot = true
	toast_timer.wait_time = 2.4
	toast_timer.timeout.connect(func() -> void: toast_label.text = "")
	add_child(toast_timer)
	_layout_responsive()

func _build_inventory_panel() -> void:
	inventory_panel = _make_panel(Vector2(360.0, 120.0), Vector2(560.0, 430.0))
	inventory_panel.visible = false
	root_control.add_child(inventory_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	inventory_panel.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)
	var title := Label.new()
	title.text = "Inventario · 20 espacios"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	inventory_grid = GridContainer.new()
	inventory_grid.columns = 5
	inventory_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(inventory_grid)
	for index in range(InventorySystem.SLOT_COUNT):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(58.0, 70.0)
		slot.text = "%02d\nVacío" % (index + 1)
		slot.disabled = true
		inventory_grid.add_child(slot)
		slot_buttons.append(slot)

func _build_pause_panel() -> void:
	pause_panel = _make_panel(Vector2(470.0, 210.0), Vector2(340.0, 280.0))
	pause_panel.visible = false
	root_control.add_child(pause_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	pause_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var title := Label.new()
	title.text = "Pausa"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var resume := Button.new()
	resume.text = "Reanudar"
	resume.custom_minimum_size = Vector2(0.0, 44.0)
	resume.pressed.connect(_resume_game)
	box.add_child(resume)
	var settings := Button.new()
	settings.text = "Ajustes"
	settings.custom_minimum_size = Vector2(0.0, 44.0)
	settings.pressed.connect(_toggle_settings)
	box.add_child(settings)
	var exit := Button.new()
	exit.text = "Salir"
	exit.custom_minimum_size = Vector2(0.0, 44.0)
	exit.pressed.connect(_exit_game)
	box.add_child(exit)

func _build_quest_panel() -> void:
	quest_panel = _make_panel(Vector2(300.0, 120.0), Vector2(680.0, 500.0))
	quest_panel.visible = false
	root_control.add_child(quest_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	quest_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Label.new()
	title.text = "Diario de misiones"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	header.add_child(title)
	var close := Button.new()
	close.text = "Cerrar"
	close.pressed.connect(_toggle_quest_diary)
	header.add_child(close)
	quest_list = VBoxContainer.new()
	quest_list.add_theme_constant_override("separation", 7)
	quest_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(quest_list)

func _refresh_quest_diary() -> void:
	if not is_instance_valid(quest_list):
		return
	for child in quest_list.get_children():
		child.queue_free()
	var visible_count := 0
	for quest in QuestManager.get_all_quests():
		var definition: Dictionary = quest.get("definition", {})
		var state: Dictionary = quest.get("state", {})
		var status := str(state.get("status", "no_iniciada"))
		if status == "no_iniciada":
			continue
		visible_count += 1
		var card := Label.new()
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var status_text := "ACTIVA" if status == "activa" else "COMPLETADA"
		var card_text := "%s · %s\n%s\n" % [status_text, str(definition.get("title", quest.get("id", "Misión"))), str(definition.get("description", ""))]
		var progress: Dictionary = state.get("objectives", {})
		for objective in definition.get("objectives", []):
			var objective_id := str(objective.get("id", ""))
			card_text += "  • %s (%d/%d)\n" % [str(objective.get("description", "Objetivo")), int(progress.get(objective_id, 0)), int(objective.get("required", 1))]
		card_text += "Recompensa: %s" % _quest_reward_text(definition.get("rewards", {}))
		card.text = card_text
		card.custom_minimum_size = Vector2(0, 72)
		card.add_theme_color_override("font_color", Color("#9be6af") if status == "completada" else Color("#ffe3a6"))
		quest_list.add_child(card)
	if visible_count == 0:
		var empty_label := Label.new()
		empty_label.text = "No tienes misiones activas. Habla con los NPC que tienen un signo !."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		quest_list.add_child(empty_label)

func _quest_reward_text(rewards: Dictionary) -> String:
	var parts: Array[String] = []
	if int(rewards.get("doubloons", 0)) > 0:
		parts.append("%d doblones" % int(rewards.doubloons))
	if int(rewards.get("faith", 0)) > 0:
		parts.append("%d favor" % int(rewards.faith))
	if int(rewards.get("reputation", 0)) > 0:
		parts.append("+%d reputación" % int(rewards.reputation))
	if not str(rewards.get("unlock_recipe", "")).is_empty():
		parts.append("receta nueva")
	for item in rewards.get("items", []):
		parts.append("%s x%d" % [str(item.get("name", item.get("id", "ítem"))), int(item.get("quantity", 1))])
	return ", ".join(parts) if not parts.is_empty() else "ninguna"

func _make_panel(position: Vector2, panel_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.size = panel_size
	var style := StyleBoxFlat.new()
	style.bg_color = STYLE_TOKENS.PANEL_BG
	style.border_color = STYLE_TOKENS.PANEL_BORDER
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _notification(what: int) -> void:
	if what == Control.NOTIFICATION_RESIZED and is_instance_valid(root_control):
		_layout_responsive()

func _layout_responsive() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var viewport_width := viewport_size.x
	var viewport_height := viewport_size.y
	if is_instance_valid(stats_panel):
		stats_panel.position = Vector2(16.0, 16.0)
		stats_panel.size = Vector2(minf(380.0, maxf(280.0, viewport_width - 32.0)), 108.0)
	if is_instance_valid(inventory_button):
		inventory_button.position = Vector2(16.0, 136.0)
		inventory_button.size = Vector2(minf(160.0, maxf(120.0, (viewport_width - 48.0) * 0.5)), 44.0)
	if is_instance_valid(sleep_button):
		sleep_button.position = Vector2(inventory_button.position.x + inventory_button.size.x + 12.0, 136.0)
		sleep_button.size = Vector2(minf(140.0, maxf(112.0, viewport_width - sleep_button.position.x - 16.0)), 44.0)
	if is_instance_valid(quest_button):
		quest_button.position = Vector2(16.0, 188.0)
		quest_button.size = Vector2(minf(160.0, maxf(120.0, viewport_width - 32.0)), 40.0)
	if is_instance_valid(pause_button):
		pause_button.position = Vector2(maxf(16.0, viewport_width - 136.0), 16.0)
		pause_button.size = Vector2(minf(120.0, viewport_width - 32.0), 44.0)
	if is_instance_valid(inventory_panel):
		inventory_panel.position = Vector2(12.0, maxf(112.0, (viewport_height - 430.0) * 0.5))
		inventory_panel.size = Vector2(maxf(240.0, viewport_width - 24.0), minf(430.0, maxf(260.0, viewport_height - 140.0)))
	if is_instance_valid(pause_panel):
		pause_panel.position = Vector2(maxf(12.0, (viewport_width - 340.0) * 0.5), maxf(110.0, (viewport_height - 280.0) * 0.5))
		pause_panel.size = Vector2(minf(340.0, viewport_width - 24.0), minf(280.0, viewport_height - 120.0))
	if is_instance_valid(quest_panel):
		quest_panel.position = Vector2(maxf(12.0, (viewport_width - 680.0) * 0.5), maxf(104.0, (viewport_height - 500.0) * 0.5))
		quest_panel.size = Vector2(minf(680.0, viewport_width - 24.0), minf(500.0, maxf(300.0, viewport_height - 120.0)))
	if is_instance_valid(settings_panel):
		settings_panel.position = Vector2(maxf(12.0, (viewport_width - 430.0) * 0.5), maxf(82.0, (viewport_height - 510.0) * 0.5))
		settings_panel.size = Vector2(minf(430.0, viewport_width - 24.0), minf(510.0, maxf(430.0, viewport_height - 90.0)))
	if is_instance_valid(toast_label):
		toast_label.position = Vector2(16.0, maxf(120.0, viewport_height - 70.0))
		toast_label.size = Vector2(maxf(0.0, viewport_width - 32.0), 40.0)

func _create_button(text: String, position: Vector2, button_size: Vector2, callback: Callable, right_anchored := false) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = button_size
	if right_anchored:
		button.position = Vector2(1140.0, 20.0)
	button.pressed.connect(callback)
	root_control.add_child(button)
	return button

func _refresh_inventory() -> void:
	if slot_buttons.is_empty():
		return
	for index in range(slot_buttons.size()):
		var slot := InventorySystem.get_slot(index)
		var item: Item = slot.get("item") as Item
		if item == null:
			slot_buttons[index].text = "%02d\nVacío" % (index + 1)
			slot_buttons[index].tooltip_text = "Espacio vacío"
		else:
			var quantity := int(slot.get("quantity", 0))
			slot_buttons[index].text = "%s\nx%d" % [item.item_name, quantity]
			slot_buttons[index].tooltip_text = item.item_id

func update_energy(current: int, maximum: int) -> void:
	if not is_instance_valid(energy_bar):
		return
	energy_bar.max_value = maximum
	energy_bar.value = current
	energy_label.text = "Energía %d/%d" % [current, maximum]

func _on_time_changed(day: int, minute_of_day: int, _daylight: float) -> void:
	if is_instance_valid(clock_label):
		clock_label.text = "Día %d · %02d:%02d" % [day, int(minute_of_day / 60), minute_of_day % 60]

func _on_doubloons_changed(amount: int) -> void:
	if is_instance_valid(doubloons_label):
		doubloons_label.text = "Doblones: %d" % amount

func _on_faith_changed(amount: int) -> void:
	if is_instance_valid(favor_label):
		favor_label.text = "Favor del mar: %d" % amount

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_inventory"):
		_toggle_inventory()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_quests"):
		_toggle_quest_diary()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _toggle_inventory() -> void:
	inventory_panel.visible = not inventory_panel.visible

func _toggle_quest_diary() -> void:
	if not is_instance_valid(quest_panel):
		return
	quest_panel.visible = not quest_panel.visible
	if quest_panel.visible:
		_refresh_quest_diary()

func _request_sleep() -> void:
	sleep_requested.emit()

func _toggle_pause() -> void:
	var should_pause := not get_tree().paused
	get_tree().paused = should_pause
	pause_panel.visible = should_pause
	if not should_pause:
		settings_panel.visible = false

func _resume_game() -> void:
	get_tree().paused = false
	pause_panel.visible = false
	settings_panel.visible = false

func _exit_game() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible
	if settings_panel.visible:
		pause_panel.visible = true

func _close_settings() -> void:
	settings_panel.visible = false

func _on_text_scale_changed(value: float) -> void:
	if is_instance_valid(root_control):
		root_control.add_theme_font_size_override("font_size", SettingsManager.get_scaled_font_size(16))

func show_toast(message: String) -> void:
	toast_label.text = message
	toast_timer.start()
