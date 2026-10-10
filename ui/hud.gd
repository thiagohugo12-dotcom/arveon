class_name GameHUD
extends Control

const ITEM_ICON := preload("res://ui/pixel_item_icon.gd")

signal save_requested
signal dash_pressed
signal restart_pressed
signal movement_changed(value: Vector2)
signal interact_pressed
signal station_action(action: String, item: String)
signal panel_closed
signal inventory_toggled
signal map_toggled
signal character_toggled
signal skill_pressed(index: int)
signal rpg_action(action: String, id: String, expected: int)
var save_panel: SavePanel
var record_button: Button
var tower_trial: TowerTrial
var tower_action_button: Button
var transition_cover: ColorRect
var transition_active := false
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
var character_button: PixelMenuButton
var map_button: PixelMenuButton
var map_panel: PanelContainer
var expanded_map: MiniMap
var map_close: Button
var map_title: Label
var map_legend: Label
var gold_label: Label
var info_back: Panel
var mission_back: Panel
var inventory_panel: PanelContainer
var inventory_gold: Label
var inventory_list: VBoxContainer
var inventory_scroll: ScrollContainer
var inventory_close: Button
var inventory_open := false
var minimap: MiniMap
var damage_occluders: Array[Rect2] = []
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
	theme = _pixel_theme()
	info_back = Panel.new()
	info_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_back.add_theme_stylebox_override("panel", _compact_style())
	add_child(info_back)
	mission_back = Panel.new()
	mission_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_back.add_theme_stylebox_override("panel", _compact_style())
	add_child(mission_back)
	gold_label = Label.new()
	gold_label.add_theme_font_size_override("font_size", 11)
	gold_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gold_label)
	heading = Label.new()
	heading.text = "Mata · Andar 1"
	heading.add_theme_font_size_override("font_size", 11)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(heading)
	hp_label = Label.new()
	hp_label.add_theme_font_size_override("font_size", 12)
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
	minimap.size = Vector2(84, 64)
	add_child(minimap)
	inventory_button = PixelMenuButton.new()
	inventory_button.glyph = "bag"
	inventory_button.tooltip_text = "Mochila"
	inventory_button.custom_minimum_size = Vector2(44, 44)
	inventory_button.pressed.connect(func(): inventory_toggled.emit())
	add_child(inventory_button)
	character_button = PixelMenuButton.new()
	character_button.glyph = "character"
	character_button.tooltip_text = "Personagem · C"
	character_button.pressed.connect(func(): character_toggled.emit())
	add_child(character_button)
	map_button = PixelMenuButton.new()
	map_button.glyph = "map"
	map_button.tooltip_text = "Mapa · M"
	map_button.pressed.connect(func(): map_toggled.emit())
	add_child(map_button)
	map_panel = PanelContainer.new()
	map_panel.z_index = 10
	map_panel.visible = false
	map_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(map_panel)
	var map_column := VBoxContainer.new()
	map_panel.add_child(map_column)
	map_title = Label.new()
	map_title.text = "Mapa · Mata dos Primeiros Passos"
	map_title.add_theme_font_size_override("font_size", 12)
	map_column.add_child(map_title)
	expanded_map = MiniMap.new()
	expanded_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_column.add_child(expanded_map)
	map_legend = Label.new()
	map_legend.text = "● Você · Verde: acampamento\nColetas e baús: somente os descobertos"
	map_legend.add_theme_font_size_override("font_size", 11)
	map_column.add_child(map_legend)
	map_close = Button.new()
	map_close.text = "Fechar"
	map_close.custom_minimum_size.y = 44
	map_close.pressed.connect(func(): map_toggled.emit())
	map_column.add_child(map_close)
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
	var footer := HBoxContainer.new()
	inventory_column.add_child(footer)
	record_button = Button.new()
	record_button.text = "Registro"
	record_button.custom_minimum_size.y = 44
	record_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	record_button.pressed.connect(func(): save_requested.emit())
	footer.add_child(record_button)
	inventory_close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(inventory_close)
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
	for i in [3, 4]:
		actions[i].hide()
		actions[i].enabled = false
	for i in [0, 1, 2, 5]:
		actions[i].icon = ["cut", "charge", "fury", "", "", "dash"][i]
		actions[i].tooltip_text = ["Corte Circular", "Investida", "Fúria Ancestral", "", "", "Dash"][i]
		actions[i].set_caption("")
	interact_button = TouchActionButton.new()
	interact_button.title = "Interagir"
	interact_button.size = Vector2(120, 52)
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
	tower_action_button = Button.new()
	tower_action_button.custom_minimum_size.y = 44
	tower_action_button.hide()
	tower_action_button.pressed.connect(func(): station_action.emit("Retornar" if tower_trial != null and tower_trial.active() else "Entrar", ""))
	column.add_child(tower_action_button)
	station_close_button = Button.new()
	station_close_button.text = "Fechar"
	station_close_button.custom_minimum_size.y = 44
	station_close_button.pressed.connect(func(): close_station())
	column.add_child(station_close_button)
	save_panel = SavePanel.new()
	save_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(save_panel)
	rpg_panel = RPGPanel.new()
	rpg_panel.z_index = 10
	add_child(rpg_panel)
	transition_cover = ColorRect.new()
	transition_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_cover.color = Color(0.04, 0.08, 0.07, 0.0)
	transition_cover.z_index = 30
	transition_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	transition_cover.hide()
	add_child(transition_cover)
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
	var menu_x := size.x - right_inset - 140
	for i in range(3):
		var button: Button = [inventory_button, character_button, map_button][i]
		button.position = Vector2(menu_x + i * 48, margin.y)
		button.size = Vector2(44, 44)
	minimap.position = Vector2(size.x - right_inset - minimap.size.x, margin.y + 50)
	var information_width := minf(192, menu_x - margin.x - 8)
	info_back.position = margin
	info_back.size = Vector2(information_width, 74)
	heading.position = margin + Vector2(6, 2)
	heading.size = Vector2(information_width - 12, 16)
	hp_label.position = margin + Vector2(6, 18)
	hp_label.size = Vector2(information_width - 12, 18)
	gold_label.position = margin + Vector2(6, 54)
	gold_label.size = Vector2(information_width - 12, 16)
	hp_bar.position = margin + Vector2(6, 37)
	hp_bar.size = Vector2(information_width - 12, 6)
	progress_label.position = margin + Vector2(6, 42)
	progress_label.size = Vector2(information_width - 12, 16)
	var mission_width := minf(232, minimap.position.x - margin.x - 8)
	mission_back.position = margin + Vector2(0, 80)
	mission_back.size = Vector2(mission_width, 56)
	mission_label.position = mission_back.position + Vector2(6, 3)
	mission_label.size = mission_back.size - Vector2(12, 6)
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loot_label.position = Vector2(margin.x, margin.y + 140)
	loot_label.size = Vector2(minf(320, size.x - margin.x - right_inset), 42)
	map_panel.size = Vector2(minf(340, size.x - margin.x - right_inset - 12), minf(400, size.y - margin.y - bottom_inset - 12))
	map_panel.position = (size - map_panel.size) * 0.5
	save_panel.size = Vector2(minf(340, size.x - margin.x - right_inset - 12), minf(350, size.y - margin.y - bottom_inset - 12))
	save_panel.position = (size - save_panel.size) * 0.5
	inventory_panel.size = Vector2(minf(300, size.x - margin.x - right_inset - 12), minf(330, size.y - margin.y - bottom_inset - 12))
	inventory_panel.position = (size - inventory_panel.size) * 0.5
	joystick.position = Vector2(margin.x, size.y - bottom_inset - joystick.size.y)
	for slot in range(4):
		var i: int = [0, 1, 2, 5][slot]
		actions[i].position = Vector2(size.x - right_inset - 120 + (slot % 2) * 64, size.y - bottom_inset - 120 + (slot / 2) * 64)
	interact_button.position = Vector2(size.x * 0.5 - 60, size.y - bottom_inset - (185 if size.y > size.x else 67))
	station_panel.size = Vector2(minf(340, size.x - margin.x - right_inset - 12), minf(320, size.y - margin.y - bottom_inset - 12))
	station_panel.position = (size - station_panel.size) * 0.5
	rpg_panel.size = Vector2(minf(320, size.x - margin.x - right_inset - 12), minf(460, size.y - margin.y - bottom_inset - 12))
	rpg_panel.position = (size - rpg_panel.size) * 0.5
	restart.position = Vector2(size.x * 0.5 - 120, size.y * 0.5 - 24)
	restart.size = Vector2(240, 48)
	# Existing HUD appearance is unchanged. A shared list keeps world hit numbers readable.
	damage_occluders.clear()
	for panel: Control in [save_panel, info_back, mission_back, minimap, inventory_button, character_button, map_button]:
		damage_occluders.append(panel.get_global_rect())

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
	if station_panel.visible or restart.visible or rpg_panel.visible or map_panel.visible:
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
	save_panel.hide()
	close_inventory()
	close_station()
	joystick.reset()
	dash_button.enabled = false
	dash_button.queue_redraw()
	interact_button.visible = false
	restart.show()
	rpg_panel.hide()
	map_panel.hide()
	_sync_controls()

func set_nearby_station(name: String) -> void:
	interact_button.enabled = not name.is_empty() and not restart.visible and not station_panel.visible and not inventory_open and not rpg_panel.visible and not map_panel.visible
	interact_button.visible = interact_button.enabled
	interact_button.set_caption(("E · Guardião\nOpcional" if name == "Desafiar Guardião (opcional)" else "E · " + name) if interact_button.enabled else "Interagir")

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
	tower_action_button.hide()
	if station_name == TowerEntrance.NAME:
		station_scroll.scroll_vertical = 0
		var active := tower_trial != null and tower_trial.active()
		var cleared := active and tower_trial.phase == TowerTrial.Phase.AWAITING_GUARDIAN
		_add_description("Três hordas superadas!" if cleared else tower_trial.summary() if active else progress.ascension.summary())
		_add_description("Guardião será o desafio final." if cleared else "Abandonar reinicia a tentativa, sem penalidade." if active else "Prova de Ascensão liberada")
		_add_description("Desafio: três hordas; Guardião da Mata na próxima atualização.")
		_add_description("Se morrer, a prova recomeça da primeira horda.")
		_add_description("Ascensão ainda não concluída." if cleared else "Sem checkpoints. Fechar o jogo encerra a tentativa.")
		tower_action_button.text = "Retornar à Mata" if cleared else "Abandonar Prova" if active else "Entrar na Prova"
		tower_action_button.disabled = not active and not progress.ascension.entrance_unlocked()
		tower_action_button.show()
	elif station_name == "Ferreiro":
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
	if transition_active:
		return
	if not event is InputEventScreenTouch or not event.pressed:
		return
	if save_panel.visible:
		_touch_buttons(save_panel, event.position)
		get_viewport().set_input_as_handled()
		return
	if restart.visible:
		_activate_touch_button(restart, event.position)
		return
	if map_panel.visible:
		_activate_touch_button(map_close, event.position)
		get_viewport().set_input_as_handled()
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
	if not station_panel.visible:
		for button in [inventory_button, character_button, map_button]:
			if _activate_touch_button(button, event.position):
				return
	if not station_panel.visible:
		return
	if _activate_touch_button(tower_action_button, event.position):
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
		dash_button.set_recharge(value, 1.2)

func _sync_controls() -> void:
	scroll_touch = -1
	touch_scroll = null
	var blocked := transition_active or save_panel.visible or inventory_open or station_panel.visible or rpg_panel.visible or map_panel.visible or restart.visible
	for button in [inventory_button, character_button, map_button]:
		button.disabled = blocked
	joystick.reset()
	joystick.set_process_input(not blocked)
	for i in [0, 1, 2, 5]:
		actions[i].enabled = not blocked and (i >= 3 or skill_available[i])
		actions[i].touch_index = -1
		actions[i].queue_redraw()
	if blocked:
		interact_button.enabled = false
		interact_button.hide()

func show_character(progress: GameProgress) -> void:
	if inventory_open or station_panel.visible or restart.visible or map_panel.visible:
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
	progress_label.text = "Nv %d · XP %d/%d" % [lvl, progress.xp - RPGRules.xp_floor(lvl), RPGRules.cost_to_level(lvl)] if lvl < RPGRules.MAX_LEVEL else "Nv %d · Nível máximo" % RPGRules.MAX_LEVEL
	gold_label.text = "Ouro %d" % progress.gold
	character_button.notification = progress.attribute_points_available() > 0
	expanded_map.update_player(player.global_position)
	var blocked := transition_active or save_panel.visible or inventory_open or station_panel.visible or rpg_panel.visible or map_panel.visible or restart.visible
	for i in range(3):
		var left := player.skill_cooldowns[i]
		actions[i].set_recharge(left, [5.0, 8.0, 35.0][i] * player.cooldown_factor, i == 2 and player.fury_left > 0.0)
		var enabled := not blocked and left <= 0.0
		skill_available[i] = left <= 0.0
		if actions[i].enabled != enabled:
			actions[i].enabled = enabled
			actions[i].queue_redraw()

func show_map(progress: GameProgress) -> void:
	if inventory_open or station_panel.visible or rpg_panel.visible or restart.visible:
		return
	expanded_map.progress = progress
	expanded_map.arena_bounds = minimap.arena_bounds
	map_title.text = "Mapa · Arena da Torre" if minimap.arena_bounds.has_area() else "Mapa · Mata dos Primeiros Passos"
	map_legend.text = "● Você · Dourado: portais\nSaída para a Mata ao sul" if minimap.arena_bounds.has_area() else "● Você · Verde: acampamento\nColetas e baús: somente os descobertos"
	expanded_map.player_position = minimap.player_position
	expanded_map.queue_redraw()
	map_panel.show()
	_sync_controls()
	_layout()

func close_map() -> void:
	map_panel.hide()
	_sync_controls()

func _compact_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#14271fee")
	style.set_border_width_all(1)
	style.border_color = Color("#526548")
	return style

func _pixel_theme() -> Theme:
	var result := Theme.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#203e32") if state != "pressed" else Color("#405b3b")
		style.border_color = Color("#b6b382") if state != "disabled" else Color("#526548")
		style.set_border_width_all(2)
		style.set_content_margin_all(6)
		if state == "focus":
			style.bg_color = Color.TRANSPARENT
			style.border_color = Color("#f2c26b")
		result.set_stylebox(state, "Button", style)
	result.set_color("font_color", "Label", Color("#ece4c4"))
	result.set_color("font_outline_color", "Label", Color("#112219"))
	result.set_constant("outline_size", "Label", 2)
	return result

func _add_equipment(id: String, progress: GameProgress, destination: VBoxContainer, in_bag: bool) -> void:
	var item: Dictionary = RPGRules.EQUIPMENT[id]
	var owned := progress.equipment.has(id)
	var upgrade := int(progress.equipment.get(id, 0))
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#244135")
	card_style.border_color = Color("#607951")
	card_style.set_border_width_all(1)
	card_style.set_content_margin_all(5)
	card.add_theme_stylebox_override("panel", card_style)
	destination.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	card.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	header.add_child(ITEM_ICON.new(item.slot))
	var label := Label.new()
	label.text = "%s  +%d\n%s%s" % [item.name, upgrade, item.slot.to_upper(), "  ·  EQUIPADO" if progress.equipped[item.slot] == id else ""]
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("#edcb84"))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(label)
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


func fade_transition(opaque: bool) -> void:
	transition_cover.show()
	var tween := create_tween()
	tween.tween_property(transition_cover, "color:a", 1.0 if opaque else 0.0, 0.16)
	await tween.finished
	if not opaque:
		transition_cover.hide()
