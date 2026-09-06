extends Node2D

## Capa superficial de los sistemas de contenido del Prompt 3.
## Cada sistema tiene un nodo visible, una interacción y una acción de prueba.

const CONTENT_SCRIPT = preload("res://scripts/world/content_interactable.gd")
const NPC_SCRIPT = preload("res://scripts/world/npc.gd")

var body_node: Node2D
var body_loot_count := 0
var body_processed := false
var body_timer: Timer
var house_state := 0
var tavern_reputation := 0
var modal: PanelContainer
var content_panel: PanelContainer
var content_toggle: Button
var status_label: Label
var panel_root: Control
var portal: Node2D
var parrot: Node2D

func _ready() -> void:
	call_deferred("_build_content")

func _build_content() -> void:
	_build_world_nodes()
	_build_content_ui()
	EconomyManager.doubloons_changed.connect(_on_doubloons_changed)
	FaithManager.faith_changed.connect(_on_faith_changed)
	AbyssManager.abyss_changed.connect(_on_abyss_changed)
	_on_abyss_changed(AbyssManager.abyss_unlocked, AbyssManager.active)
	if EconomyManager.doubloons == 0:
		EconomyManager.add_doubloons(25)
	_set_status("Hay 14 sistemas de prueba listos. Usa E cerca de los objetos o los atajos.")

func _build_world_nodes() -> void:
	_add_resource("resource_wood", "Madera", Vector2(690, 270), Color("#8d5d3d"), "madera_naufragio", "Madera de naufragio")
	_add_resource("resource_coral", "Coral", Vector2(780, 270), Color("#c86f68"), "coral_piedra", "Piedra y coral")
	_add_resource("resource_fiber", "Fibra", Vector2(870, 270), Color("#7cae69"), "fibra_vegetal", "Fibra vegetal")
	_add_resource("resource_scrap", "Chatarra", Vector2(960, 270), Color("#87949d"), "chatarra", "Chatarra")

	_add_station("station_anvil", "Yunque", Vector2(480, 260), Color("#87949d"))
	_add_station("station_still", "Alambique", Vector2(570, 260), Color("#c99558"))
	_add_station("station_apothecary", "Botica", Vector2(660, 260), Color("#8bbf91"))
	_add_station("station_tavern", "Barra", Vector2(750, 500), Color("#b87350"))

	_add_content_node("grave_1", "Parcela 1", "grave", Vector2(260, 480), Color("#667782"))
	_add_content_node("grave_2", "Parcela 2", "grave", Vector2(330, 480), Color("#667782"))
	_add_content_node("grave_3", "Parcela 3", "grave", Vector2(400, 480), Color("#667782"))
	_add_content_node("grave_4", "Parcela 4", "grave", Vector2(260, 570), Color("#667782"))
	_add_content_node("grave_5", "Parcela 5", "grave", Vector2(330, 570), Color("#667782"))
	_add_content_node("grave_6", "Parcela 6", "grave", Vector2(400, 570), Color("#667782"))

	_add_body(Vector2(400, 390))
	_add_content_node("temple", "Templo", "temple", Vector2(960, 500), Color("#695ca6"))
	_add_content_node("house", "Casa", "house", Vector2(300, 260), Color("#9b7061"))
	portal = _add_content_node("abyss_portal", "Remolino", "abyss", Vector2(1020, 390), Color("#287f88"))
	portal.visible = false
	
	_add_npc("merchant", "Mercader itinerante", Vector2(520, 590), Color("#d0a35d"))
	_add_npc("harbor_master", "Autoridad del puerto", Vector2(620, 590), Color("#6f8fc4"))
	_add_npc("rival_tavern", "Tabernero rival", Vector2(720, 590), Color("#bd6f6f"))
	_add_npc("healer", "Curandero de puerto", Vector2(820, 590), Color("#77ad83"))

	var enemy := _add_content_node("enemy_boat", "Bote rival", "combat", Vector2(940, 590), Color("#9a4c4c"))
	enemy.scale = Vector2(1.25, 1.25)
	parrot = Node2D.new()
	parrot.name = "Parrot"
	parrot.set_script(load("res://scripts/world/parrot.gd"))
	parrot.position = Vector2(610, 350)
	add_child(parrot)

	body_timer = Timer.new()
	body_timer.wait_time = 90.0
	body_timer.one_shot = false
	body_timer.timeout.connect(_spawn_body)
	add_child(body_timer)
	body_timer.start()

func _add_resource(action: String, title: String, position: Vector2, color: Color, item_id: String, item_name: String) -> Node2D:
	var node := _add_content_node(action, title, action, position, color)
	node.set_meta("item_id", item_id)
	node.set_meta("item_name", item_name)
	return node

func _add_station(action: String, title: String, position: Vector2, color: Color) -> Node2D:
	return _add_content_node(action, title, action, position, color)

func _add_npc(action: String, title: String, position: Vector2, color: Color) -> Node2D:
	var node := NPC_SCRIPT.new()
	node.name = action
	node.npc_name = title
	node.action_id = "npc:" + action
	node.display_name = title
	node.tint = color
	node.position = position
	add_child(node)
	return node

func _add_content_node(node_name: String, title: String, action: String, position: Vector2, color: Color) -> Node2D:
	var node := CONTENT_SCRIPT.new()
	node.name = node_name
	node.display_name = title
	node.action_id = action
	node.tint = color
	node.position = position
	add_child(node)
	return node

func _add_body(position: Vector2) -> void:
	body_node = _add_content_node("WreckBody", "Saquear cuerpo", "body", position, Color("#72514f"))
	body_node.scale = Vector2(1.15, 0.7)
	body_loot_count = 0
	body_processed = false

func _spawn_body() -> void:
	if is_instance_valid(body_node):
		return
	_add_body(Vector2(380 + randi_range(-50, 50), 390 + randi_range(-20, 20)))
	_set_status("Un cuerpo de náufrago ha llegado a la orilla.")

func _build_content_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 12
	layer.name = "ContentUI"
	add_child(layer)
	panel_root = Control.new()
	panel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel_root)
	content_toggle = Button.new()
	content_toggle.position = Vector2(960, 72)
	content_toggle.size = Vector2(170, 42)
	content_toggle.pressed.connect(_toggle_content_panel)
	panel_root.add_child(content_toggle)
	content_panel = _make_panel(Vector2(930, 122), Vector2(330, 570))
	panel_root.add_child(content_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	content_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Label.new()
	title.text = "Sistemas de la isla"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 19)
	header.add_child(title)
	var hide_button := Button.new()
	hide_button.text = "Ocultar"
	hide_button.custom_minimum_size = Vector2(72, 34)
	hide_button.tooltip_text = "Esconder la pestaña de sistemas"
	hide_button.pressed.connect(_toggle_content_panel)
	header.add_child(hide_button)
	status_label = Label.new()
	status_label.text = "Listo"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 42)
	box.add_child(status_label)
	var actions := [
		["Recolectar recursos", "quick_resources"], ["Mesa de saqueo", "body"],
		["Crafteo", "craft_menu"], ["Mercader", "merchant"],
		["Taberna", "station_tavern"], ["Templo", "temple"],
		["Bitácora tecnológica", "tech"], ["Portal del Abismo", "abyss"],
		["Reparar la base", "house"], ["Encuentro de combate", "combat"],
		["Hablar con NPCs", "npc:merchant"]
	]
	for entry in actions:
		var button := Button.new()
		button.text = str(entry[0])
		button.custom_minimum_size = Vector2(0, 32)
		button.pressed.connect(handle_action.bind(str(entry[1]), null))
		box.add_child(button)
	# Keep the playfield and the touch interaction button unobstructed. The tab
	# remains available whenever the player wants to use a system shortcut.
	content_panel.visible = false
	_update_content_toggle()

func _make_panel(position: Vector2, panel_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.size = panel_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.09, 0.96)
	style.border_color = Color("#668984")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _toggle_content_panel() -> void:
	if not is_instance_valid(content_panel):
		return
	content_panel.visible = not content_panel.visible
	_update_content_toggle()

func _update_content_toggle() -> void:
	if not is_instance_valid(content_toggle) or not is_instance_valid(content_panel):
		return
	content_toggle.text = "Sistemas [ocultar]" if content_panel.visible else "Sistemas [abrir]"

func _set_status(text: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = text
	var hud := get_tree().current_scene.get_node_or_null("HUD")
	if is_instance_valid(hud) and hud.has_method("show_toast"):
		hud.show_toast(text)

func _toast_action(text: String, event_name := "") -> void:
	_set_status(text)
	if is_instance_valid(parrot) and not event_name.is_empty() and parrot.has_method("comment"):
		parrot.comment(event_name)

func handle_action(action: String, _source: Node2D) -> void:
	match action:
		"resource_wood", "resource_coral", "resource_fiber", "resource_scrap":
			_collect_resource(_source, action)
		"body": _open_body_menu()
		"grave": _toast_action("Parcela disponible: entierra aquí desde la mesa de saqueo.")
		"station_anvil": _open_crafting("Yunque")
		"station_still": _open_crafting("Alambique")
		"station_apothecary": _open_crafting("Botica")
		"station_tavern": _open_tavern()
		"temple": _open_temple()
		"house": _repair_house()
		"abyss": _open_abyss()
		"combat": _open_combat()
		"merchant", "npc:merchant": _open_merchant()
		"npc:harbor_master": _show_dialogue("Autoridad del puerto", "Hola, viajero. El mar está cobrando peaje.")
		"npc:rival_tavern": _show_dialogue("Tabernero rival", "Mi ron tiene menos arena que el tuyo.")
		"npc:healer": _show_dialogue("Curandero de puerto", "Descansa antes de que te conviertas en ingrediente.")
		"quick_resources": _quick_resources()
		"craft_menu": _open_crafting("Yunque")
		"tech": _open_tech_tree()

func _collect_resource(source: Node2D, action: String) -> void:
	if not is_instance_valid(source):
		return
	var amount := 2 if FaithManager.get_resource_multiplier() > 1.0 else 1
	var item_id := str(source.get_meta("item_id", "madera_naufragio"))
	var item_name := str(source.get_meta("item_name", "Recurso"))
	InventorySystem.add_item(_item(item_id, item_name), amount)
	_toast_action("Recolectaste %s x%d." % [item_name, amount])
	source.queue_free()

func _quick_resources() -> void:
	InventorySystem.add_item(_item("madera_naufragio", "Madera de naufragio"), 2)
	InventorySystem.add_item(_item("coral_piedra", "Piedra y coral"), 2)
	InventorySystem.add_item(_item("fibra_vegetal", "Fibra vegetal"), 2)
	InventorySystem.add_item(_item("chatarra", "Chatarra"), 2)
	InventorySystem.add_item(_item("hacha", "Hacha"), 1)
	_toast_action("Recursos de prueba añadidos. Tienes un hacha básica.")

func _open_body_menu() -> void:
	if not is_instance_valid(body_node) or body_processed:
		_toast_action("No hay un cuerpo pendiente en la orilla.")
		return
	_show_modal("Mesa de saqueo", [
		["Objeto personal (+página)", Callable(self, "_loot_body").bind("personal")],
		["Materia prima (+chatarra)", Callable(self, "_loot_body").bind("material")],
		["Nada", Callable(self, "_loot_body").bind("nothing")]
	])

func _loot_body(kind: String) -> void:
	if body_loot_count >= 2:
		_offer_body_finish()
		return
	body_loot_count += 1
	if kind == "personal":
		InventorySystem.add_item(_item("pagina_bitacora", "Página de bitácora"), 1)
		_toast_action("Encontraste una página de bitácora.", "loot")
	elif kind == "material":
		InventorySystem.add_item(_item("chatarra", "Chatarra"), 2)
		_toast_action("Rescataste chatarra útil.", "loot")
	else:
		_toast_action("El cadáver no tenía nada. Ni dignidad.", "loot")
	if body_loot_count >= 2:
		_offer_body_finish()

func _offer_body_finish() -> void:
	_show_modal("Destino del náufrago", [
		["Enterrar en el cementerio", Callable(self, "_bury_body")],
		["Desechar al mar", Callable(self, "_discard_body")]
	])

func _bury_body() -> void:
	if CemeteryManager.bury_body(2 if body_loot_count >= 2 else 1):
		body_processed = true
		if is_instance_valid(body_node): body_node.queue_free()
		_toast_action("Cuerpo enterrado. Favor del mar: %d." % CemeteryManager.cemetery_quality, "bury")
	else:
		_toast_action("No quedan parcelas libres.")

func _discard_body() -> void:
	body_processed = true
	if is_instance_valid(body_node): body_node.queue_free()
	_toast_action("El mar se queda con el cuerpo. Qué práctico.", "bury")

func _open_crafting(station: String) -> void:
	var recipes: Array = []
	match station:
		"Yunque": recipes = [["Cuchillo oxidado (madera + chatarra)", {"madera_naufragio": 1, "chatarra": 1}, "cuchillo", "Cuchillo oxidado"]]
		"Alambique": recipes = [["Ron oscuro (fibra + coral)", {"fibra_vegetal": 1, "coral_piedra": 1}, "botella_ron", "Botella de ron"]]
		"Botica": recipes = [["Cataplasma (fibra + coral)", {"fibra_vegetal": 1, "coral_piedra": 1}, "cataplasma", "Cataplasma"]]
	var options: Array = []
	for recipe in recipes:
		options.append([recipe[0], Callable(self, "_craft").bind(recipe[1], recipe[2], recipe[3])])
	_show_modal("%s · recetas" % station, options)

func _craft(costs: Dictionary, result_id: String, result_name: String) -> void:
	for item_id in costs:
		if InventorySystem.count_item(item_id) < int(costs[item_id]):
			_toast_action("Faltan materiales para %s." % result_name)
			return
	for item_id in costs:
		InventorySystem.remove_item(item_id, int(costs[item_id]))
	InventorySystem.add_item(_item(result_id, result_name), 1)
	_toast_action("Fabricaste %s." % result_name, "craft")

func _open_tavern() -> void:
	_show_modal("Barra de taberna", [["Servir grog (ron + fibra)", Callable(self, "_serve_grog")]])

func _serve_grog() -> void:
	if InventorySystem.count_item("botella_ron") < 1 or InventorySystem.count_item("fibra_vegetal") < 1:
		_toast_action("Necesitas una botella de ron y fibra.")
		return
	InventorySystem.remove_item("botella_ron", 1)
	InventorySystem.remove_item("fibra_vegetal", 1)
	tavern_reputation += 1
	EconomyManager.add_doubloons(6)
	_toast_action("Grog servido. Reputación de taberna: %d." % tavern_reputation, "craft")

func _open_merchant() -> void:
	_show_modal("Mercader itinerante · %d doblones" % EconomyManager.doubloons, [
		["Comprar página de bitácora · 8", Callable(self, "_buy_page")],
		["Comprar ron · 4", Callable(self, "_buy_rum")],
		["Vender madera · 3", Callable(self, "_sell_wood")]
	])

func _buy_page() -> void:
	if EconomyManager.buy(_item("pagina_bitacora", "Página de bitácora"), 1, 8): _toast_action("Compraste una página de bitácora.")
	else: _toast_action("No puedes pagar o no tienes espacio.")

func _buy_rum() -> void:
	if EconomyManager.buy(_item("botella_ron", "Botella de ron"), 1, 4): _toast_action("Compraste ron.")
	else: _toast_action("No puedes pagar o no tienes espacio.")

func _sell_wood() -> void:
	if EconomyManager.sell("madera_naufragio", 1, 3): _toast_action("Vendiste madera por 3 doblones.")
	else: _toast_action("No tienes madera para vender.")

func _open_temple() -> void:
	_show_modal("Templo del Dios Ahogado · favor %d" % FaithManager.sea_favor, [
		["Donar 5 doblones", Callable(self, "_donate").bind(5)],
		["Donar 10 doblones", Callable(self, "_donate").bind(10)],
		["Activar bendición (+10% recursos)", Callable(self, "_bless")]
	])

func _donate(amount: int) -> void:
	if FaithManager.donate(amount): _toast_action("Donación aceptada. Favor: %d." % FaithManager.sea_favor, "donate")
	else: _toast_action("No tienes suficientes doblones.")

func _bless() -> void:
	if FaithManager.activate_blessing(): _toast_action("El mar te bendice durante un día.", "donate")
	else: _toast_action("Necesitas 10 de favor del mar.")

func _open_tech_tree() -> void:
	var options: Array = []
	for node in TechTreeManager.tech_nodes:
		var unlocked := TechTreeManager.is_unlocked(str(node.id))
		var text := "%s · %s" % [str(node.category), str(node.name)]
		if unlocked: text += " · DESBLOQUEADO"
		else: text += " · página x%d" % int(node.cost)
		options.append([text, Callable(self, "_unlock_tech").bind(str(node.id))])
	_show_modal("Bitácora del Capitán", options)

func _unlock_tech(id: String) -> void:
	if TechTreeManager.unlock(id): _toast_action("Tecnología desbloqueada: %s." % id)
	else: _toast_action("Faltan páginas o requisitos para esa tecnología.")

func _open_abyss() -> void:
	AbyssManager.check_unlock()
	if not AbyssManager.abyss_unlocked:
		_toast_action("El remolino exige 10 de favor del mar.")
		return
	AbyssManager.enter()
	_show_modal("El Abismo", [["Recolectar perla abisal", Callable(self, "_collect_abyss_resource")], ["Regresar a la isla", Callable(self, "_leave_abyss")]])
	_toast_action("El Abismo te recibe con un tinte verdeazul.")

func _collect_abyss_resource() -> void:
	InventorySystem.add_item(_item("perla_abisal", "Perla abisal"), 1)
	_toast_action("Recolectaste una perla abisal.")

func _leave_abyss() -> void:
	AbyssManager.exit()
	_toast_action("Has regresado a la isla.")

func _on_abyss_changed(unlocked: bool, active: bool) -> void:
	if is_instance_valid(portal): portal.visible = unlocked
	var world := get_tree().current_scene
	if world != null and world.has_node("AbyssOverlay/AbyssTint"):
		world.get_node("AbyssOverlay/AbyssTint").color = Color(0.03, 0.22, 0.25, 0.32 if active else 0.0)

func _repair_house() -> void:
	if house_state >= 2:
		_toast_action("La casa ya está mejorada.")
		return
	var cost := 25 if house_state == 0 else 50
	if not EconomyManager.spend_doubloons(cost):
		_toast_action("Necesitas %d doblones." % cost)
		return
	house_state += 1
	_toast_action("Casa %s: %s." % [house_state, "reparada" if house_state == 1 else "mejorada"])

func _open_combat() -> void:
	_show_modal("¡Bote pirata rival!", [["Golpear y abordar", Callable(self, "_combat_win")], ["Huir", Callable(self, "_combat_lose")]])

func _combat_win() -> void:
	EconomyManager.add_doubloons(10)
	_toast_action("Ganaste el duelo naval y tomaste 10 doblones.", "combat")

func _combat_lose() -> void:
	if is_instance_valid(GameManager.player) and GameManager.player.has_method("try_spend_energy"):
		GameManager.player.try_spend_energy(10)
	_toast_action("El bote rival te golpeó. Pierdes energía.", "combat")

func _show_dialogue(who: String, line: String) -> void:
	_show_modal(who, [[line, Callable(self, "_close_modal")]])

func _show_modal(title_text: String, options: Array) -> void:
	_close_modal()
	modal = _make_panel(Vector2(390, 170), Vector2(500, 390))
	panel_root.add_child(modal)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	modal.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	for option in options:
		var button := Button.new()
		button.text = str(option[0])
		button.custom_minimum_size = Vector2(0, 42)
		button.pressed.connect(_run_modal_callback.bind(option[1]))
		box.add_child(button)
	var close := Button.new()
	close.text = "Cerrar"
	close.pressed.connect(_close_modal)
	box.add_child(close)

func _run_modal_callback(callback: Callable) -> void:
	_close_modal()
	callback.call()

func _close_modal() -> void:
	if is_instance_valid(modal):
		modal.queue_free()
	modal = null

func _on_doubloons_changed(amount: int) -> void:
	_set_status("Doblones: %d · Favor: %d · Cementerio: %d" % [amount, FaithManager.sea_favor, CemeteryManager.cemetery_quality])

func _on_faith_changed(value: int) -> void:
	_set_status("Favor del mar: %d · Abismo: %s" % [value, "abierto" if AbyssManager.abyss_unlocked else "cerrado"])

func _item(item_id: String, item_name: String, max_stack := 99) -> Item:
	var item := Item.new()
	item.item_id = item_id
	item.item_name = item_name
	item.max_stack = max_stack
	return item
