class_name GameHUD
extends Control

signal dash_pressed
signal restart_pressed
signal movement_changed(value: Vector2)
signal interact_pressed
signal station_action(action: String, item: String)
signal panel_closed
signal inventory_toggled
signal character_toggled
signal skill_pressed(index: int)
signal rpg_action(action: String, id: String, expected: int)
var rpg_panel: RPGPanel
var inventory_category := 0
var inventory_tabs: HBoxContainer
var menu_progress: GameProgress
var skill_available: Array[bool] = [true, true, true]
var scroll_touch := -1
var touch_scroll: ScrollContainer
var joystick: VirtualJoystick
var dash_button: TouchActionButton
var actions: Array[TouchActionButton] = []
var heading: Label
var hp_label: Label
var hp_bar: ProgressBar
var progress_label: Label
var mission_label: Label
var loot_label: Label
var inventory_button: Button
var inventory_panel: PanelContainer
var inventory_gold: Label
var inventory_list: VBoxContainer
var inventory_scroll: ScrollContainer
var inventory_close: Button
var inventory_open := false
var minimap: MiniMap
var restart: Button
var cooldown: float = 0.0
var notice_left := 0.0
var health_flash_left := 0.0
var previous_health := -1
var interact_button: TouchActionButton
var station_panel: PanelContainer
var station_title: Label
var station_content: VBoxContainer
var station_scroll: ScrollContainer
var station_name := ""
var station_close_button: Button
var station_page := 0
const ITEMS_PER_PAGE := 3

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading = Label.new()
	heading.text = "Mata dos Primeiros Passos"
	heading.add_theme_font_size_override("font_size", 16)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(heading)
	hp_label = Label.new()
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hp_label)
	hp_bar = ProgressBar.new()
	hp_bar.show_percentage = false
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar.add_theme_stylebox_override("fill", _health_fill(Color("#80cf88")))
	add_child(hp_bar)
	progress_label = Label.new()
	progress_label.add_theme_font_size_override("font_size", 11)
	progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(progress_label)
	mission_label = Label.new()
	mission_label.add_theme_font_size_override("font_size", 11)
	mission_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mission_label)
	loot_label = Label.new()
	loot_label.add_theme_font_size_override("font_size", 11)
	loot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(loot_label)
	minimap = MiniMap.new()
	minimap.size = Vector2(96, 80)
	add_child(minimap)
	inventory_button = Button.new()
	inventory_button.text = "Mochila"
	inventory_button.custom_minimum_size = Vector2(100, 44)
	inventory_button.pressed.connect(func(): inventory_toggled.emit())
	add_child(inventory_button)
	inventory_panel = PanelContainer.new()
	inventory_panel.z_index = 10
	inventory_panel.visible = false
	inventory_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	inventory_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(inventory_panel)
	var inventory_column := VBoxContainer.new()
	inventory_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_panel.add_child(inventory_column)
	var inventory_heading := Label.new()
	inventory_heading.text = "Mochila"
	inventory_column.add_child(inventory_heading)
	inventory_gold = Label.new()
	inventory_gold.add_theme_font_size_override("font_size", 15)
	inventory_column.add_child(inventory_gold)
	inventory_tabs = HBoxContainer.new()
	inventory_column.add_child(inventory_tabs)
	for i in range(3):
		var tab := Button.new()
		tab.text = ["Materiais", "Equip.", "Consumo"][i]
		tab.custom_minimum_size.y = 44
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_font_size_override("font_size", 12)
		tab.pressed.connect(func():
			inventory_category = i
			inventory_scroll.scroll_vertical = 0
			refresh_inventory(menu_progress)
		)
		inventory_tabs.add_child(tab)
	inventory_scroll = ScrollContainer.new()
	inventory_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_scroll.custom_minimum_size.x = 220
	inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inventory_column.add_child(inventory_scroll)
	inventory_list = VBoxContainer.new()
	inventory_list.custom_minimum_size.x = 220
	inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_scroll.add_child(inventory_list)
	inventory_close = Button.new()
	inventory_close.text = "Fechar"
	inventory_close.custom_minimum_size.y = 44
	inventory_close.pressed.connect(func(): inventory_toggled.emit())
	inventory_column.add_child(inventory_close)
	joystick = VirtualJoystick.new()
	joystick.size = Vector2(128, 128)
	joystick.direction_changed.connect(func(value: Vector2): movement_changed.emit(value))
	add_child(joystick)
	for title: String in ["Skill 1", "Skill 2", "Ultimate", "Poção", "", "Dash"]:
		var button := TouchActionButton.new()
		button.title = title + "\nEm breve" if title != "Dash" and title != "" else title
		button.enabled = title == "Dash"
		button.size = Vector2(56, 56)
		button.visible = title != ""
		add_child(button)
		actions.append(button)
		if title == "Dash":
			dash_button = button
			button.activated.connect(func(): dash_pressed.emit())
	for i in range(3):
		actions[i].enabled = true
		actions[i].activated.connect(func(): skill_pressed.emit(i))
		actions[4].visible = true
		actions[4].enabled = true
		actions[4].set_caption("Person.\nC")
		actions[4].activated.connect(func(): character_toggled.emit())
	interact_button = TouchActionButton.new()
	interact_button.title = "Interagir"
	interact_button.size = Vector2(80, 52)
	interact_button.visible = false
	interact_button.activated.connect(func(): interact_pressed.emit())
	add_child(interact_button)
	station_panel = PanelContainer.new()
	station_panel.z_index = 10
	station_panel.visible = false
	station_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	station_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(station_panel)
	var column := VBoxContainer.new()
	station_panel.add_child(column)
	station_title = Label.new()
	station_title.add_theme_font_size_override("font_size", 17)
	column.add_child(station_title)
	station_scroll = ScrollContainer.new()
	station_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	station_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(station_scroll)
	station_content = VBoxContainer.new()
	station_content.custom_minimum_size.x = 220
	station_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	station_scroll.add_child(station_content)
	station_close_button = Button.new()
	station_close_button.text = "Fechar"
	station_close_button.custom_minimum_size.y = 44
	station_close_button.pressed.connect(func(): close_station())
	column.add_child(station_close_button)
	rpg_panel = RPGPanel.new()
	rpg_panel.z_index = 10
	add_child(rpg_panel)
	rpg_panel.closed.connect(func(): character_toggled.emit())
	rpg_panel.action_requested.connect(func(action: String, id: String, expected: int): rpg_action.emit(action, id, expected))
	restart = Button.new()
	restart.z_index = 20
	restart.text = "Você caiu · Reiniciar"
	restart.visible = false
	restart.pressed.connect(func(): restart_pressed.emit())
	add_child(restart)
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if not is_instance_valid(joystick):
		return
	var margin := Vector2(12, 12)
	var bottom_inset: float = 12.0
	var right_inset: float = 12.0
	if OS.has_feature("android") or OS.has_feature("ios"):
		var safe := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		if screen.x > 0 and screen.y > 0:
			margin.x += float(safe.position.x) / screen.x * size.x
			margin.y += float(safe.position.y) / screen.y * size.y
			bottom_inset += float(screen.y - safe.end.y) / screen.y * size.y
			right_inset += float(screen.x - safe.end.x) / screen.x * size.x
	minimap.position = Vector2(size.x - right_inset - minimap.size.x, margin.y)
	var information_width := minimap.position.x - margin.x - 8.0
	heading.position = margin
	heading.size = Vector2(information_width, 44)
	hp_label.position = Vector2(margin.x, margin.y + 46)
	hp_bar.position = Vector2(margin.x, margin.y + 68)
	hp_bar.size = Vector2(minf(220, information_width), 12)
	progress_label.position = Vector2(margin.x, margin.y + 85)
	progress_label.size = Vector2(information_width, 20)
	mission_label.position = Vector2(margin.x, margin.y + 104)
	mission_label.size = Vector2(information_width, 38)
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loot_label.position = Vector2(margin.x, margin.y + 143)
	loot_label.size = Vector2(information_width, 42)
	inventory_button.position = Vector2(size.x - right_inset - 100, minimap.position.y + minimap.size.y + 6)
	inventory_panel.size = Vector2(minf(300, size.x - margin.x - right_inset - 12), minf(330, size.y - margin.y - bottom_inset - 12))
	inventory_panel.position = (size - inventory_panel.size) * 0.5
	joystick.position = Vector2(margin.x, size.y - bottom_inset - joystick.size.y)
	for i in range(actions.size()):
		actions[i].position = Vector2(size.x - right_inset - 184 + (i % 3) * 64, size.y - bottom_inset - 120 + (i / 3) * 64)
	interact_button.position = Vector2(size.x * 0.5 - 40, size.y - bottom_inset - (185 if size.y > size.x else 67))
	station_panel.size = Vector2(minf(340, size.x - margin.x - right_inset - 12), minf(320, size.y - margin.y - bottom_inset - 12))
	station_panel.position = (size - station_panel.size) * 0.5
	rpg_panel.size = Vector2(minf(320, size.x - margin.x - right_inset - 12), minf(460, size.y - margin.y - bottom_inset - 12))
	rpg_panel.position = (size - rpg_panel.size) * 0.5
	restart.position = Vector2(size.x * 0.5 - 120, size.y * 0.5 - 24)
	restart.size = Vector2(240, 48)

func set_health(current: int, maximum: int) -> void:
	hp_label.text = "HP %d / %d" % [current, maximum]
	hp_bar.max_value = maximum
	hp_bar.value = current
	if previous_health >= 0 and current != previous_health:
		health_flash_left = 0.55
		hp_bar.add_theme_stylebox_override("fill", _health_fill(Color("#e57970") if current < previous_health else Color("#85d8c0")))
	previous_health = current

func set_progress(xp: int, gold: int, kills: int, loot: String) -> void:
	progress_label.text = "XP %d  ·  Ouro %d  ·  Abates %d" % [xp, gold, kills]
	if not loot.is_empty():
		show_notice(loot)

func show_notice(message: String) -> void:
	loot_label.text = message
	loot_label.show()
	notice_left = 2.5

func _process(delta: float) -> void:
	if notice_left > 0.0:
		notice_left = maxf(0.0, notice_left - delta)
		if notice_left == 0.0:
			loot_label.hide()
	if health_flash_left > 0.0:
		health_flash_left = maxf(0.0, health_flash_left - delta)
		if health_flash_left == 0.0:
			hp_bar.add_theme_stylebox_override("fill", _health_fill(Color("#80cf88")))

func _health_fill(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	return style

func set_mission(value: String) -> void:
	mission_label.text = "◆ " + value.replace("Missão comum: ", "")

func show_inventory(progress: GameProgress) -> void:
	if station_panel.visible or restart.visible or rpg_panel.visible:
		return
	inventory_open = true
	inventory_category = 0
	inventory_panel.show()
	inventory_button.disabled = true
	interact_button.visible = false
	interact_button.enabled = false
	dash_button.enabled = false
	dash_button.queue_redraw()
	joystick.reset()
	refresh_inventory(progress)
	_sync_controls()
	_layout()

func refresh_inventory(progress: GameProgress) -> void:
	menu_progress = progress
	inventory_gold.text = "Ouro: %d" % progress.gold
	for child in inventory_list.get_children():
		inventory_list.remove_child(child)
		child.queue_free()
	if inventory_category == 1:
		for id: String in progress.equipment:
			_add_equipment(id, progress, inventory_list, true)
		return
	if inventory_category == 2:
		var empty := Label.new()
		empty.text = "Nenhum consumível nesta etapa."
		empty.add_theme_font_size_override("font_size", 12)
		inventory_list.add_child(empty)
		return
	var has_material := false
	for item: String in GameProgress.ITEMS:
		var count := int(progress.bag.get(item, 0))
		if count > 0:
			has_material = true
			var row := HBoxContainer.new()
			row.custom_minimum_size.y = 32
			inventory_list.add_child(row)
			var name := Label.new()
			name.text = item
			name.custom_minimum_size.x = 150
			name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name.autowrap_mode = TextServer.AUTOWRAP_OFF
			row.add_child(name)
			var amount := Label.new()
			amount.text = "× %d" % count
			amount.custom_minimum_size.x = 44
			amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			row.add_child(amount)
	if not has_material:
		var empty := Label.new()
		empty.text = "Nenhum material na mochila."
		empty.autowrap_mode = TextServer.AUTOWRAP_OFF
		inventory_list.add_child(empty)

func close_inventory() -> void:
	inventory_open = false
	inventory_panel.hide()
	inventory_button.disabled = false
	dash_button.enabled = not restart.visible and not station_panel.visible and not inventory_open
	dash_button.queue_redraw()
	_sync_controls()

func show_death() -> void:
	close_inventory()
	close_station()
	joystick.reset()
	dash_button.enabled = false
	dash_button.queue_redraw()
	interact_button.visible = false
	restart.show()
	rpg_panel.hide()
	_sync_controls()

func set_nearby_station(name: String) -> void:
	interact_button.enabled = not name.is_empty() and not restart.visible and not station_panel.visible and not inventory_open and not rpg_panel.visible
	interact_button.visible = interact_button.enabled
	interact_button.set_caption("E · " + name if interact_button.enabled else "Interagir")

func show_station(name: String, progress: GameProgress) -> void:
	station_name = name
	station_page = 0
	close_inventory()
	station_panel.show()
	_sync_controls()
	interact_button.enabled = false
	interact_button.visible = false
	dash_button.enabled = false
	refresh_station(progress)
	_layout()

func close_station() -> void:
	if station_panel.visible:
		station_panel.hide()
		dash_button.enabled = not restart.visible
		dash_button.queue_redraw()
		panel_closed.emit()
		_sync_controls()

func refresh_station(progress: GameProgress) -> void:
	station_title.text = station_name
	for child in station_content.get_children():
		station_content.remove_child(child)
		child.queue_free()
	if station_name == "Ferreiro":
		_add_description("Ouro %d · fabricar ou aprimorar até +3.\nMateriais usados: somente os da mochila." % progress.gold)
		for id: String in RPGRules.EQUIPMENT:
			_add_equipment(id, progress, station_content, false)
	elif station_name == "Baú":
		_add_description("Mochila/Baú · itens guardados ficam protegidos.")
		for item: String in _page_items(GameProgress.ITEMS):
			_add_row(item, "%d/%d" % [progress.bag.get(item, 0), progress.chest.get(item, 0)], "Guardar", "Retirar", int(progress.bag.get(item, 0)) > 0, int(progress.chest.get(item, 0)) > 0)
		_add_page_navigation(GameProgress.ITEMS.size(), progress)
	elif station_name == "Vendedor":
		_add_description("Ouro %d · Compra %d · Venda %d" % [progress.gold, GameProgress.BUY_PRICE, GameProgress.SELL_PRICE])
		_add_description("Coletas: venda por ouro.")
		var available_items: Array[String] = []
		for item: String in GameProgress.SELL_ITEMS:
			if int(progress.bag.get(item, 0)) > 0:
				available_items.append(item)
		available_items.sort_custom(func(a: String, b: String) -> bool:
			var a_resource := not GameProgress.TRADE_ITEMS.has(a)
			var b_resource := not GameProgress.TRADE_ITEMS.has(b)
			return a_resource and not b_resource if a_resource != b_resource else GameProgress.SELL_ITEMS.find(a) < GameProgress.SELL_ITEMS.find(b)
		)
		for item: String in GameProgress.TRADE_ITEMS:
			if not available_items.has(item):
				available_items.append(item)
		for item: String in _page_items(available_items):
			_add_row(item, "x%d" % progress.bag.get(item, 0), "Comprar", "Vender", GameProgress.TRADE_ITEMS.has(item) and progress.gold >= GameProgress.BUY_PRICE, int(progress.bag.get(item, 0)) > 0)
		_add_page_navigation(available_items.size(), progress)

func _page_items(items: Array) -> Array:
	var start := station_page * ITEMS_PER_PAGE
	return items.slice(start, mini(start + ITEMS_PER_PAGE, items.size()))

func _add_page_navigation(count: int, progress: GameProgress) -> void:
	var total := ceili(float(count) / ITEMS_PER_PAGE)
	var row := HBoxContainer.new()
	station_content.add_child(row)
	var previous := Button.new()
	previous.text = "◀"
	previous.disabled = station_page == 0
	previous.custom_minimum_size = Vector2(48, 40)
	previous.pressed.connect(func():
		station_page -= 1
		refresh_station(progress)
	)
	row.add_child(previous)
	var label := Label.new()
	label.text = "Página %d/%d" % [station_page + 1, total]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var following := Button.new()
	following.text = "▶"
	following.disabled = station_page >= total - 1
	following.custom_minimum_size = Vector2(48, 40)
	following.pressed.connect(func():
		station_page += 1
		refresh_station(progress)
	)
	row.add_child(following)

func _add_description(value: String) -> void:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", 13)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	station_content.add_child(label)

func _add_row(item: String, count: String, left: String, right: String, can_left: bool, can_right: bool) -> void:
	var buttons := HBoxContainer.new()
	station_content.add_child(buttons)
	var label := Label.new()
	label.text = item + " " + count
	label.add_theme_font_size_override("font_size", 12)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(label)
	for action: String in [left, right]:
		var button := Button.new()
		button.text = action
		button.disabled = not (can_left if action == left else can_right)
		button.add_theme_font_size_override("font_size", 12)
		button.custom_minimum_size = Vector2(76, 40)
		button.pressed.connect(func(): station_action.emit(action, item))
		buttons.add_child(button)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag and event.index == scroll_touch and is_instance_valid(touch_scroll):
		touch_scroll.scroll_vertical -= roundi(event.relative.y)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch and not event.pressed and event.index == scroll_touch:
		scroll_touch = -1
		touch_scroll = null
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventScreenTouch or not event.pressed:
		return
	if restart.visible:
		_activate_touch_button(restart, event.position)
		return
	if rpg_panel.visible:
		if _activate_touch_button(rpg_panel.close_button, event.position):
			return
		if not _touch_buttons(rpg_panel, event.position):
			_begin_scroll(rpg_panel.scroll, event)
		get_viewport().set_input_as_handled()
		return
	if inventory_open:
		if _activate_touch_button(inventory_close, event.position):
			return
		if not _touch_buttons(inventory_panel, event.position):
			_begin_scroll(inventory_scroll, event)
		get_viewport().set_input_as_handled()
		return
	if not station_panel.visible and _activate_touch_button(inventory_button, event.position):
		return
	if not station_panel.visible:
		return
	if station_name == "Ferreiro":
		if _activate_touch_button(station_close_button, event.position):
			return
		if not _touch_buttons(station_panel, event.position):
			_begin_scroll(station_scroll, event)
		get_viewport().set_input_as_handled()
		return
	if _activate_touch_button(station_close_button, event.position):
		return
	if not station_scroll.get_global_rect().has_point(event.position):
		return
	for row in station_content.get_children():
		if row.is_queued_for_deletion() or not row is HBoxContainer:
			continue
		for node in row.get_children():
			if node is Button and _activate_touch_button(node, event.position):
				return
	_begin_scroll(station_scroll, event)
	get_viewport().set_input_as_handled()

func _activate_touch_button(button: Button, position: Vector2) -> bool:
	if not button.disabled and button.is_visible_in_tree() and button.get_global_rect().has_point(position):
		button.pressed.emit()
		get_viewport().set_input_as_handled()
		return true
	return false

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1b2f27")
	style.set_border_width_all(3)
	style.border_color = Color("#d0b878")
	style.set_content_margin_all(10)
	return style

func set_dash_cooldown(value: float) -> void:
	var rounded := snappedf(value, 0.1)
	if rounded != cooldown:
		cooldown = rounded
		dash_button.set_caption("Dash" if value <= 0.0 else "Dash\n%.1fs" % value)

func _sync_controls() -> void:
	scroll_touch = -1
	touch_scroll = null
	var blocked := inventory_open or station_panel.visible or rpg_panel.visible or restart.visible
	joystick.reset()
	joystick.set_process_input(not blocked)
	for i in [0, 1, 2, 4, 5]:
		actions[i].enabled = not blocked and (i >= 3 or skill_available[i])
		actions[i].touch_index = -1
		actions[i].queue_redraw()
	if blocked:
		interact_button.enabled = false
		interact_button.hide()

func show_character(progress: GameProgress) -> void:
	if inventory_open or station_panel.visible or restart.visible:
		return
	rpg_panel.show()
	rpg_panel.refresh(progress)
	_sync_controls()
	_layout()

func close_character() -> void:
	rpg_panel.hide()
	_sync_controls()

func set_rpg_status(progress: GameProgress, player: PlayerActor) -> void:
	var lvl := progress.level()
	progress_label.text = "Nv %d · XP %d/%d · Ouro %d" % [lvl, progress.xp - RPGRules.xp_floor(lvl), RPGRules.cost_to_level(lvl), progress.gold] if lvl < RPGRules.MAX_LEVEL else "Nv 20 · Ouro %d" % progress.gold
	var names := ["Corte", "Investida", "Fúria"]
	var blocked := inventory_open or station_panel.visible or rpg_panel.visible or restart.visible
	for i in range(3):
		var left := player.skill_cooldowns[i]
		var caption: String = names[i] + ("\n%.1fs" % snappedf(left, 0.1) if left > 0.0 else "\n%d" % (i + 1))
		if i == 2 and player.fury_left > 0.0:
			caption = "Fúria\nAtiva"
		if actions[i].caption.text != caption:
			actions[i].set_caption(caption)
		var enabled := not blocked and left <= 0.0
		skill_available[i] = left <= 0.0
		if actions[i].enabled != enabled:
			actions[i].enabled = enabled
			actions[i].queue_redraw()

func _add_equipment(id: String, progress: GameProgress, destination: VBoxContainer, in_bag: bool) -> void:
	var item: Dictionary = RPGRules.EQUIPMENT[id]
	var owned := progress.equipment.has(id)
	var upgrade := int(progress.equipment.get(id, 0))
	var box := VBoxContainer.new()
	destination.add_child(box)
	var label := Label.new()
	label.text = "%s +%d · %s" % [item.name, upgrade, item.slot]
	label.add_theme_font_size_override("font_size", 13)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)
	var description := Label.new()
	var current: String = progress.equipped[item.slot]
	description.text = RPGRules.bonus_text(id, upgrade)
	if current != id:
		description.text += "\nAtual: " + (RPGRules.EQUIPMENT[current].name if current != "" else "nenhum")
		if current != "":
			description.text += "\n" + RPGRules.bonus_text(current, int(progress.equipment[current]))
	description.add_theme_font_size_override("font_size", 12)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	var button := Button.new()
	button.custom_minimum_size.y = 44
	box.add_child(button)
	if in_bag:
		button.text = "Desequipar" if current == id else "Equipar"
		button.pressed.connect(func(): rpg_action.emit("unequip" if current == id else "equip", item.slot if current == id else id, 0))
	else:
		var expected := int(progress.equipment.get(id, -1))
		var cost := RPGRules.recipe(id, owned, upgrade)
		var price := Label.new()
		price.text = "Máximo +3" if owned and upgrade >= 3 else RPGRules.cost_text(cost)
		price.add_theme_font_size_override("font_size", 12)
		price.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(price)
		box.move_child(price, 2)
		if owned and upgrade < 3:
			description.text += "\nApós melhoria: " + RPGRules.bonus_text(id, upgrade + 1)
		button.text = "Aprimorar para +%d" % (upgrade + 1) if owned else "Fabricar"
		button.disabled = not progress.can_forge(id)
		button.pressed.connect(func(): rpg_action.emit("forge", id, expected))
	box.add_child(HSeparator.new())

func _touch_buttons(node: Node, point: Vector2) -> bool:
	if node is Control and node.clip_contents and not node.get_global_rect().has_point(point):
		return false
	if node is Button:
		return _activate_touch_button(node, point)
	var children := node.get_children()
	children.reverse()
	for child in children:
		if _touch_buttons(child, point):
			return true
	return false

func _begin_scroll(scroll: ScrollContainer, event: InputEventScreenTouch) -> void:
	if scroll_touch == -1 and scroll.get_global_rect().has_point(event.position):
		scroll_touch = event.index
		touch_scroll = scroll

