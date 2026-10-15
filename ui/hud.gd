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
var boss_name: Label
var boss_bar: ProgressBar
var victory_first := false
var tower_trial: TowerTrial
var tower_action_button: Button
var travel_button: Button
var selected_floor := 1
var floor_buttons: Array[Button] = []
var transition_cover: ColorRect
var transition_active := false
var rpg_panel: RPGPanel
var inventory_category := 0
var diary_navigation: HBoxContainer
var xp_bar: ProgressBar
var menu_shade: ColorRect
var mission_toggle: Button
var mission_expanded := true
var mission_text := ""
var introduction_hud := false
var inventory_selected := ""
var inventory_compare := false
var equipment_bag: EquipmentBag
var inventory_tabs: HBoxContainer
var menu_progress: GameProgress
var skill_available: Array[bool] = [true, true, true]
var scroll_touch := -1
var inventory_touch_card: Button
var inventory_touch_origin := Vector2.ZERO
var inventory_touch_dragged := false
var touch_scroll: ScrollContainer
var joystick: VirtualJoystick
var dash_button: TouchActionButton
var actions: Array[TouchActionButton] = []
var heading: Label
var hp_label: Label
var heart_icon: DiaryHeart
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
var inventory_heading: Label
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
var first_weapon_page := 0
var first_weapon_selected := ""
var first_weapon_buttons: Dictionary = {}
var smith_tab := 0 # Loja (somente ouro) ou Forja (receitas)
var smith_shop_selected := ""
var smith_shop_buttons: Dictionary = {}
var vendor_buttons: Dictionary = {}
const FIRST_WEAPON_DESCRIPTION := "Todo aventureiro precisa de uma arma. Procure o Ferreiro no acampamento e escolha aquela que combina com seu estilo de combate."
const WEAPON_STYLES := {
	"espada":"Combate próximo e ágil, com sequências e contra-ataques.",
	"machado":"Golpes pesados, impacto e execução de alvos enfraquecidos.",
	"lanca":"Maior alcance corpo a corpo, posicionamento e controle.",
	"arco":"Ataques físicos à distância, mobilidade e marcas no alvo.",
	"cajado":"Ataques mágicos à distância, técnicas de área e barreiras."}
const ITEMS_PER_PAGE := 3

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = _pixel_theme()
	menu_shade = ColorRect.new()
	menu_shade.color = Color(0.09,0.12,0.08,0.63)
	menu_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_shade.z_index = 9
	menu_shade.hide()
	add_child(menu_shade)
	info_back = Panel.new()
	info_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_back.add_theme_stylebox_override("panel",DiaryTheme.box(Color.TRANSPARENT,Color.TRANSPARENT,0,0))
	add_child(info_back)
	mission_back = Panel.new()
	mission_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_back.add_theme_stylebox_override("panel", DiaryTheme.piece("paper",0))
	add_child(mission_back)
	gold_label = Label.new()
	gold_label.add_theme_font_size_override("font_size", 11)
	gold_label.add_theme_color_override("font_color",Color("#ffd67c"))
	gold_label.add_theme_color_override("font_outline_color",Color("#35291d"))
	gold_label.add_theme_constant_override("outline_size",3)
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
	hp_label.add_theme_color_override("font_color",Color("#fff0ce"))
	hp_label.add_theme_color_override("font_outline_color",Color("#35291d"))
	hp_label.add_theme_constant_override("outline_size",3)
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hp_label)
	heart_icon = DiaryHeart.new()
	add_child(heart_icon)
	hp_bar = ProgressBar.new()
	hp_bar.show_percentage = false
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar.add_theme_stylebox_override("fill", _health_fill(Color("#80cf88")))
	add_child(hp_bar)
	xp_bar = ProgressBar.new()
	xp_bar.show_percentage = false
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_bar.add_theme_stylebox_override("fill",DiaryTheme.box(Color("#dca947"),Color("#dca947"),0,0))
	add_child(xp_bar)
	progress_label = Label.new()
	progress_label.add_theme_font_size_override("font_size", 11)
	progress_label.add_theme_color_override("font_color",Color("#fff0ce"))
	progress_label.add_theme_color_override("font_outline_color",Color("#35291d"))
	progress_label.add_theme_constant_override("outline_size",3)
	progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(progress_label)
	mission_label = Label.new()
	mission_label.add_theme_font_size_override("font_size", 11)
	mission_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mission_label)
	mission_toggle = Button.new()
	mission_toggle.text = "−"
	mission_toggle.tooltip_text = "Recolher / expandir missões"
	mission_toggle.pressed.connect(func():
		mission_expanded = not mission_expanded
		_render_mission()
		_layout()
	)
	add_child(mission_toggle)
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
	inventory_column.add_theme_constant_override("separation",4)
	inventory_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_panel.add_child(inventory_column)
	inventory_heading = Label.new()
	inventory_heading.text = "Diário do Explorador"
	inventory_heading.add_theme_font_override("font",DiaryTheme.heading_font())
	inventory_heading.add_theme_font_size_override("font_size",18)
	var book_header := HBoxContainer.new()
	inventory_column.add_child(book_header)
	inventory_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	book_header.add_child(inventory_heading)
	inventory_gold = Label.new()
	inventory_gold.add_theme_font_size_override("font_size", 15)
	var coin := DiaryHeart.new()
	coin.glyph = "coin"
	coin.tint = Color("#edb53e")
	coin.custom_minimum_size = Vector2(16,16)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	book_header.add_child(coin)
	book_header.add_child(inventory_gold)
	diary_navigation = HBoxContainer.new()
	inventory_column.add_child(diary_navigation)
	for i in range(3):
		var link := DiaryTab.new()
		link.glyph = ["bag","book","fury"][i]
		link.text = ["Mochila","Proficiências","Habilidades"][i]
		link.add_theme_font_size_override("font_size",11)
		link.custom_minimum_size.y = 44
		link.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		DiaryTheme.select(link,i == 0)
		link.pressed.connect(func(): _open_diary(i))
		diary_navigation.add_child(link)
	inventory_tabs = HBoxContainer.new()
	inventory_column.add_child(inventory_tabs)
	for i in range(3):
		var tab := DiaryTab.new()
		tab.glyph = ["charge","character","potion"][i]
		tab.text = ["Materiais", "Equipamentos", "Consumo"][i]
		tab.custom_minimum_size.y = 44
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_font_size_override("font_size", 12)
		tab.pressed.connect(func():
			inventory_category = i
			inventory_selected = ""
			inventory_compare = false
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
	for title: String in ["Skill 1", "Skill 2", "Skill 3", "Poção", "", "Dash"]:
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
	actions[3].show()
	actions[3].icon = "potion"
	actions[3].title = "Poção"
	actions[3].tooltip_text = "Poções ainda não disponíveis"
	actions[3].set_caption("")
	for i in [0, 1, 2, 5]:
		actions[i].icon = ["cut", "charge", "fury", "", "", "dash"][i]
		actions[i].tooltip_text = ["Skill 1", "Skill 2", "Skill 3", "", "", "Dash"][i]
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
	station_title.add_theme_font_size_override("font_size",17)
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
	travel_button = Button.new()
	travel_button.custom_minimum_size.y = 44
	travel_button.hide()
	travel_button.pressed.connect(func(): station_action.emit("Viajar", str(selected_floor)))
	column.add_child(travel_button)
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
	rpg_panel.bag_requested.connect(func(): _open_diary(0))
	rpg_panel.action_requested.connect(func(action: String, id: String, expected: int): rpg_action.emit(action, id, expected))
	restart = Button.new()
	restart.z_index = 20
	restart.text = "Você caiu · Reiniciar"
	restart.visible = false
	restart.pressed.connect(func(): restart_pressed.emit())
	add_child(restart)
	boss_name = Label.new()
	boss_name.add_theme_font_size_override("font_size", 12)
	boss_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_name.hide()
	add_child(boss_name)
	boss_bar = ProgressBar.new()
	boss_bar.show_percentage = false
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar.add_theme_stylebox_override("fill", _health_fill(Color("#b4d584")))
	boss_bar.hide()
	add_child(boss_bar)
	resized.connect(_layout)
	# Wrapped labels settle their minimum height after the first layout pass.
	# Refit the modal then, including when rotating or changing diary pages.
	rpg_panel.minimum_size_changed.connect(func(): _layout.call_deferred())
	inventory_panel.minimum_size_changed.connect(func(): _layout.call_deferred())
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
	info_back.size = Vector2(information_width, 72)
	heading.position = margin + Vector2(6, 2)
	heading.hide()
	heading.size = Vector2(information_width - 12, 16)
	heart_icon.position = margin + Vector2(6,5)
	heart_icon.size = Vector2(24,24)
	hp_label.position = margin + Vector2(34, 3)
	hp_label.size = Vector2(information_width - 40, 18)
	gold_label.position = margin + Vector2(6, 51)
	gold_label.size = Vector2(information_width - 12, 16)
	hp_bar.position = margin + Vector2(34, 23)
	hp_bar.size = Vector2(information_width - 40, 8)
	progress_label.position = margin + Vector2(6, 32)
	progress_label.size = Vector2(information_width - 12, 16)
	xp_bar.position = margin + Vector2(6,48)
	xp_bar.size = Vector2(information_width-12,4)
	var mission_width := minf(232, minimap.position.x - margin.x - 8)
	mission_back.position = margin + Vector2(0, 86)
	mission_back.size = Vector2(mission_width,86 if introduction_hud and mission_expanded else 56 if mission_expanded or boss_name.visible else 44)
	# Landscape places the two readable panels in one top strip, leaving the
	# workshop visible below. Portrait retains its separate, full-width rows.
	if size.x >= 600 and size.x > size.y:
		mission_back.position = margin + Vector2(information_width+8,0)
		mission_back.size.x = minf(232,menu_x-mission_back.position.x-8)
		mission_width = mission_back.size.x
	mission_label.position = mission_back.position + Vector2(6, 3)
	mission_label.size = mission_back.size - Vector2(12, 6)
	mission_label.size.x -= 38
	mission_toggle.position = mission_back.position + Vector2(mission_back.size.x-44,0)
	mission_toggle.size = Vector2(44,44)
	mission_toggle.visible = not boss_name.visible
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boss_name.position = mission_label.position
	boss_name.size = Vector2(mission_width - 12, 30)
	boss_bar.position = mission_back.position + Vector2(6, 38)
	boss_bar.size = Vector2(mission_width - 12, 7)
	loot_label.position = Vector2(margin.x, margin.y + 146)
	if size.x >= 600 and size.x > size.y:
		loot_label.position.y = margin.y+80
	if introduction_hud:
		loot_label.position.y = maxf(loot_label.position.y,mission_back.position.y+mission_back.size.y+6)
	loot_label.size = Vector2(minf(320, size.x - margin.x - right_inset), 42)
	map_panel.size = Vector2(minf(340, size.x - margin.x - right_inset - 12), minf(400, size.y - margin.y - bottom_inset - 12))
	map_panel.position = (size - map_panel.size) * 0.5
	save_panel.size = Vector2(minf(340, size.x - margin.x - right_inset - 12), minf(350, size.y - margin.y - bottom_inset - 12))
	save_panel.position = (size - save_panel.size) * 0.5
	# Large landscape displays use their real pixel budget for the diary, while
	# world/camera scale and minimum physical touch size remain unchanged.
	var diary_scale := 1.0
	var window_size := get_window().size
	if window_size.x >= 900 and window_size.y >= 500 and size.x > size.y and is_equal_approx(size.x,get_viewport_rect().size.x):
		diary_scale = minf(1.0,size.x/float(window_size.x))
	inventory_panel.scale = Vector2.ONE*diary_scale
	rpg_panel.scale = Vector2.ONE*diary_scale
	inventory_panel.size = Vector2(minf(820, (size.x - margin.x - right_inset - 12)/diary_scale), minf(650, (size.y - margin.y - bottom_inset - 12)/diary_scale))
	inventory_panel.position = (size - inventory_panel.size*diary_scale) * 0.5
	DiaryArt.skin(inventory_panel)
	inventory_heading.add_theme_font_size_override("font_size",30 if inventory_panel.size.x >= 600 and inventory_panel.size.y >= 420 else 23)
	inventory_gold.add_theme_font_size_override("font_size",17 if inventory_panel.size.x >= 600 else 13)
	for link: Button in diary_navigation.get_children():
		link.add_theme_font_size_override("font_size",20 if inventory_panel.size.x >= 600 else 15)
	for link: Button in inventory_tabs.get_children():
		link.add_theme_font_size_override("font_size",18 if inventory_panel.size.x >= 600 else 14)
	joystick.position = Vector2(margin.x, size.y - bottom_inset - joystick.size.y)
	for slot in range(4):
		var i: int = [5, 0, 1, 2][slot]
		actions[i].position = Vector2(size.x - right_inset - 120 + (slot % 2) * 64, size.y - bottom_inset - 120 + (slot / 2) * 64)
	actions[3].position = Vector2(size.x-right_inset-56,size.y-bottom_inset-184)
	interact_button.position = Vector2(size.x * 0.5 - 60, size.y - bottom_inset - (185 if size.y > size.x else 67))
	var service := station_name in ["Ferreiro","Vendedor"]
	station_title.add_theme_font_size_override("font_size",24 if service else 17)
	if service: station_title.add_theme_font_override("font",DiaryTheme.heading_font())
	else: station_title.remove_theme_font_override("font")
	station_panel.size = Vector2(minf(560 if service else 340, size.x - margin.x - right_inset - 12), minf(620 if service else 320, size.y - margin.y - bottom_inset - 12))
	station_panel.add_theme_stylebox_override("panel",DiaryTheme.piece("frame",16) if service else _panel_style())
	station_panel.position = (size - station_panel.size) * 0.5
	rpg_panel.size = Vector2(minf(640, (size.x - margin.x - right_inset - 12)/diary_scale), minf(650, (size.y - margin.y - bottom_inset - 12)/diary_scale))
	rpg_panel.position = (size - rpg_panel.size*diary_scale) * 0.5
	DiaryArt.skin(rpg_panel)
	restart.position = Vector2(size.x * 0.5 - 120, size.y * 0.5 - 24)
	restart.size = Vector2(240, 48)
	# Existing HUD appearance is unchanged. A shared list keeps world hit numbers readable.
	damage_occluders.clear()
	for panel: Control in [save_panel, info_back, mission_back, minimap, inventory_button, character_button, map_button]:
		damage_occluders.append(panel.get_global_rect())

func set_health(current: int, maximum: int) -> void:
	hp_label.text = "%d / %d" % [current, maximum]
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
	mission_text = value.replace("Missão comum: ", "")
	_render_mission()

func _render_mission() -> void:
	mission_label.text = mission_text if mission_expanded else mission_text.get_slice("\n",0)
	mission_toggle.text = "−" if mission_expanded else "+"

func show_inventory(progress: GameProgress) -> void:
	if station_panel.visible or restart.visible or rpg_panel.visible or map_panel.visible:
		return
	inventory_open = true
	inventory_category = 1
	inventory_selected = ""
	inventory_compare = false
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
	inventory_gold.text = str(progress.gold)
	for i in range(inventory_tabs.get_child_count()): DiaryTheme.select(inventory_tabs.get_child(i),i == inventory_category)
	if progress.ascension.forest_seal:
		inventory_gold.tooltip_text = "Selo da Mata · %d andares" % progress.ascension.unlocked_floors.size()
		inventory_gold.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for child in inventory_list.get_children():
		inventory_list.remove_child(child)
		child.queue_free()
	equipment_bag = null
	if inventory_category == 1:
		equipment_bag = EquipmentBag.new(progress,inventory_selected,inventory_compare)
		inventory_list.add_child(equipment_bag)
		equipment_bag.selected.connect(func(id: String):
			inventory_selected = id
			inventory_compare = false
			inventory_scroll.scroll_vertical = 0
			refresh_inventory(progress)
		)
		equipment_bag.action_requested.connect(func(action: String, id: String): rpg_action.emit(action,id,0))
		equipment_bag.compare_requested.connect(func():
			inventory_compare = not inventory_compare
			refresh_inventory(progress)
		)
		if not inventory_selected.is_empty():
			_focus_equipment_detail.call_deferred()
		return
	if inventory_category == 2:
		var empty := Label.new()
		empty.text = "Nenhum consumível nesta etapa."
		empty.add_theme_font_size_override("font_size", 12)
		inventory_list.add_child(empty)
		return
	var material_grid := GridContainer.new()
	material_grid.columns = 3
	material_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_list.add_child(material_grid)
	var has_material := false
	for item: String in GameProgress.ITEMS:
		var count := int(progress.bag.get(item, 0))
		if count > 0:
			has_material = true
			var tile := PanelContainer.new()
			tile.name = item
			tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tile.add_theme_stylebox_override("panel",DiaryTheme.piece("slot",6))
			material_grid.add_child(tile)
			var row := VBoxContainer.new()
			row.custom_minimum_size = Vector2(62,86)
			tile.add_child(row)
			var icon := PixelItemIcon.new(item)
			icon.framed = false
			icon.custom_minimum_size = Vector2(48,48)
			icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			row.add_child(icon)
			var name := Label.new()
			name.text = item
			name.name = "ItemName"
			name.add_theme_font_size_override("font_size",11)
			name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row.add_child(name)
			var amount := Label.new()
			amount.text = "× %d" % count
			amount.name = "Quantity"
			amount.custom_minimum_size.x = 44
			amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	selected_floor = progress.ascension.current_floor
	station_page = 0
	first_weapon_page = 0
	first_weapon_selected = ""
	smith_tab = 0
	smith_shop_selected = ""
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
	first_weapon_buttons.clear()
	smith_shop_buttons.clear()
	vendor_buttons.clear()
	for child in station_content.get_children():
		station_content.remove_child(child)
		child.queue_free()
	tower_action_button.hide()
	travel_button.hide()
	floor_buttons.clear()
	if station_name == TowerEntrance.NAME:
		station_scroll.scroll_vertical = 0
		var active := tower_trial != null and tower_trial.active()
		var cleared := active and tower_trial.phase == TowerTrial.Phase.VICTORY
		_add_description("Vitória · Guardião da Mata!" if cleared else tower_trial.summary() if active else "Andar %d · Torre: %d/50 criaturas" % [selected_floor, progress.ascension.defeats[str(selected_floor)]])
		_add_description("Ascensão do Andar %d concluída%s" % [progress.ascension.current_floor, " · Selo da Mata" if progress.ascension.current_floor == 1 else ""] if cleared else "Abandonar reinicia a tentativa, sem penalidade." if active else "Prova concluída" if progress.ascension.completed_trials[str(selected_floor)] else "Prova de Ascensão liberada" if progress.ascension.entrance_unlocked(selected_floor) else "Prova bloqueada: derrote 50 criaturas neste andar.")
		_add_description("+%d XP · +%d ouro" % [FloorConfig.reward(AscensionProgress.GUARDIAN_XP, progress.ascension.current_floor), FloorConfig.reward(AscensionProgress.GUARDIAN_GOLD, progress.ascension.current_floor)] if cleared and victory_first else "Recompensas únicas já recebidas." if cleared else "Desafio: três hordas e Guardião da Mata.")
		_add_description(("Campanha inicial conquistada! Cinco andares superados." if progress.ascension.current_floor == 5 else "Andar %d desbloqueado · viaje pela Torre na Mata." % (progress.ascension.current_floor + 1)) if cleared else "Se morrer, a prova recomeça da primeira horda.")
		_add_description("Retorne à Mata em segurança." if cleared else "Sem checkpoints. Fechar o jogo encerra a tentativa.")
		tower_action_button.text = "Retornar à Mata" if cleared else "Abandonar Prova" if active else "Entrar na Prova"
		tower_action_button.disabled = not active and not progress.ascension.entrance_unlocked()
		tower_action_button.show()
		if not active:
			for id in range(1,6):
				var button := Button.new()
				button.custom_minimum_size.y = 44
				button.text = "Andar %d · %s%s" % [id, "Atual" if id == progress.ascension.current_floor else "Disponível" if progress.ascension.can_travel(id) else "Bloqueado", " ✓" if id == selected_floor else ""]
				button.pressed.connect(func(): selected_floor = id; refresh_station(progress))
				station_content.add_child(button)
				floor_buttons.append(button)
			station_title.text = "Torre · Andar %d" % progress.ascension.current_floor
			travel_button.text = "Viajar ao Andar %d" % selected_floor
			travel_button.disabled = selected_floor == progress.ascension.current_floor or not progress.ascension.can_travel(selected_floor)
			travel_button.show()
	elif station_name == "Ferreiro":
		if progress.introduction_active():
			_first_weapon_interface(progress)
			return
		_smith_tabs(progress)
		if smith_tab == 0:
			_smith_shop(progress)
		else:
			_add_description("Seu ouro: %d · materiais da mochila\nFabrique equipamentos ou melhore até +3." % progress.gold)
			for id: String in RPGRules.EQUIPMENT:
				_add_equipment(id, progress, station_content, false)
	elif station_name == "Baú":
		_add_description("Mochila/Baú · itens guardados ficam protegidos.")
		for item: String in _page_items(GameProgress.ITEMS):
			_add_row(item, "%d/%d" % [progress.bag.get(item, 0), progress.chest.get(item, 0)], "Guardar", "Retirar", int(progress.bag.get(item, 0)) > 0, int(progress.chest.get(item, 0)) > 0)
		_add_page_navigation(GameProgress.ITEMS.size(), progress)
	elif station_name == "Vendedor":
		_add_description("Seu ouro: %d" % progress.gold)
		var available_items: Array[String] = []
		for item: String in GameProgress.SELL_ITEMS:
			if int(progress.bag.get(item,0)) > 0: available_items.append(item)
		available_items.sort_custom(func(a: String, b: String) -> bool:
			var resource_a := not GameProgress.TRADE_ITEMS.has(a)
			var resource_b := not GameProgress.TRADE_ITEMS.has(b)
			return resource_a and not resource_b if resource_a != resource_b else GameProgress.SELL_ITEMS.find(a) < GameProgress.SELL_ITEMS.find(b))
		for item: String in GameProgress.TRADE_ITEMS:
			if not available_items.has(item): available_items.append(item)
		for item: String in _page_items(available_items): _vendor_item(item,progress)
		_add_page_navigation(available_items.size(),progress)

func _page_items(items: Array) -> Array:
	var start := station_page * ITEMS_PER_PAGE
	return items.slice(start, mini(start + ITEMS_PER_PAGE, items.size()))

func _add_page_navigation(count: int, progress: GameProgress) -> void:
	var total := ceili(float(count) / ITEMS_PER_PAGE)
	var row := HBoxContainer.new()
	station_content.add_child(row)
	var previous := Button.new()
	previous.text = "Anterior" if station_name == "Vendedor" else "◀"
	previous.disabled = station_page == 0
	previous.custom_minimum_size = Vector2(70,44) if station_name == "Vendedor" else Vector2(48,40)
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
	following.text = "Próxima" if station_name == "Vendedor" else "▶"
	following.disabled = station_page >= total - 1
	following.custom_minimum_size = Vector2(70,44) if station_name == "Vendedor" else Vector2(48,40)
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
		if event.position.distance_to(inventory_touch_origin) > 8.0:
			inventory_touch_dragged = true
		touch_scroll.scroll_vertical -= roundi(event.relative.y)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch and not event.pressed and event.index == scroll_touch:
		var tapped_card := inventory_touch_card
		var activate: bool = not inventory_touch_dragged and is_instance_valid(tapped_card) and event.position.distance_to(inventory_touch_origin) <= 8.0
		inventory_touch_card = null
		scroll_touch = -1
		touch_scroll = null
		if activate:
			tapped_card.pressed.emit()
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
		if rpg_panel.scroll.get_global_rect().has_point(event.position):
			_defer_menu_touch(rpg_panel.content,rpg_panel.scroll,event)
			return
		if not _touch_buttons(rpg_panel, event.position):
			_begin_scroll(rpg_panel.scroll, event)
		get_viewport().set_input_as_handled()
		return
	if inventory_open:
		if _activate_touch_button(inventory_close, event.position):
			return
		# Delay card activation until release so a swipe can scroll over the cards.
		if inventory_category == 1 and inventory_scroll.get_global_rect().has_point(event.position):
			inventory_touch_card = null
			inventory_touch_origin = event.position
			inventory_touch_dragged = false
			for card: Button in equipment_bag.cards.values():
				if card.get_global_rect().has_point(event.position):
					inventory_touch_card = card
					break
			if inventory_touch_card != null:
				_begin_scroll(inventory_scroll,event)
				get_viewport().set_input_as_handled()
				return
		if not _touch_buttons(inventory_panel, event.position):
			_begin_scroll(inventory_scroll, event)
		get_viewport().set_input_as_handled()
		return
	if not station_panel.visible:
		for button in [inventory_button, character_button, map_button, mission_toggle]:
			if _activate_touch_button(button, event.position):
				return
	if not station_panel.visible:
		return
	if _activate_touch_button(travel_button, event.position) or _activate_touch_button(tower_action_button, event.position):
		return
	if station_name == TowerEntrance.NAME:
		if _activate_touch_button(station_close_button, event.position):
			return
		if station_scroll.get_global_rect().has_point(event.position) and not _touch_buttons(station_content, event.position):
			_begin_scroll(station_scroll, event)
		get_viewport().set_input_as_handled()
		return
	if station_name in ["Ferreiro","Vendedor"]:
		if _activate_touch_button(station_close_button,event.position): return
		if station_scroll.get_global_rect().has_point(event.position):
			_defer_menu_touch(station_content,station_scroll,event)
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

func _button_under(node: Node, point: Vector2) -> Button:
	if node is Control and node.clip_contents and not node.get_global_rect().has_point(point): return null
	if node is Button:
		return node if not node.disabled and node.is_visible_in_tree() and node.get_global_rect().has_point(point) else null
	var children := node.get_children()
	children.reverse()
	for child: Node in children:
		var button := _button_under(child,point)
		if button != null: return button
	return null

func _defer_menu_touch(content: Control, scroll: ScrollContainer, event: InputEventScreenTouch) -> void:
	inventory_touch_card = _button_under(content,event.position)
	inventory_touch_origin = event.position
	inventory_touch_dragged = false
	_begin_scroll(scroll,event)
	get_viewport().set_input_as_handled()

func _activate_touch_button(button: Button, position: Vector2) -> bool:
	if not button.disabled and button.is_visible_in_tree() and button.get_global_rect().has_point(position):
		button.pressed.emit()
		get_viewport().set_input_as_handled()
		return true
	return false

func _panel_style() -> StyleBoxFlat:
	return DiaryTheme.box(DiaryTheme.PAPER,DiaryTheme.WOOD,12,3)

func set_dash_cooldown(value: float) -> void:
	var rounded := snappedf(value, 0.1)
	if rounded != cooldown:
		cooldown = rounded
		dash_button.set_recharge(value, 1.2)

func _sync_controls() -> void:
	inventory_touch_card = null
	inventory_touch_dragged = false
	scroll_touch = -1
	touch_scroll = null
	var blocked := transition_active or save_panel.visible or inventory_open or station_panel.visible or rpg_panel.visible or map_panel.visible or restart.visible
	menu_shade.visible = blocked and not transition_active and not restart.visible
	for button in [inventory_button, character_button, map_button]:
		button.disabled = blocked
	mission_toggle.disabled = blocked
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
	if introduction_hud != progress.introduction_active():
		introduction_hud = progress.introduction_active()
		_layout()
	rpg_panel.allow_respec = SafeCamp.in_clearance(player.global_position) and not minimap.arena_bounds.has_area()
	var lvl := progress.level()
	progress_label.text = "Nv %d · XP %d/%d" % [lvl, progress.xp - RPGRules.xp_floor(lvl), RPGRules.cost_to_level(lvl)] if lvl < RPGRules.MAX_LEVEL else "Nv %d · Nível máximo" % RPGRules.MAX_LEVEL
	gold_label.text = "Ouro %d" % progress.gold
	xp_bar.max_value = RPGRules.cost_to_level(lvl)
	xp_bar.value = progress.xp-RPGRules.xp_floor(lvl)
	var mastery_available := false
	for category: String in ArsenalRules.CATEGORIES:
		if progress.talents.mastery_points(category) > 0: mastery_available = true
	character_button.notification = progress.attribute_points_available() > 0 or progress.skill_points() > 0 or mastery_available
	expanded_map.update_player(player.global_position)
	var blocked := transition_active or save_panel.visible or inventory_open or station_panel.visible or rpg_panel.visible or map_panel.visible or restart.visible
	player._sync_skill_cooldowns()
	var category := progress.active_category()
	for i in range(3):
		var rule := AbilityRules.skill1(progress.equipped.Arma) if i == 0 else AbilityRules.active_skill(category,progress.abilities.loadouts[category].skills[i-1]) if not category.is_empty() else {}
		var ultimate: bool = not rule.is_empty() and not category.is_empty() and rule.id == AbilityRules.CATEGORIES[category].ultimate.id
		actions[i].legend = "Ultimate" if ultimate else "Skill %d" % (i+1)
		actions[i].tooltip_text = rule.get("name","Slot vazio")
		actions[i].icon = "fury" if ultimate else category if i == 0 and not category.is_empty() else "charge"
		actions[i].charge_fraction = float(progress.abilities.charge[category])/100.0 if ultimate else -1.0
		var left := player.skill_cooldowns[i]
		if ultimate:
			left = progress.abilities.global_ultimate_cooldown if progress.abilities.last_ultimate_category != category else 0.0
		actions[i].set_recharge(left,float(rule.get("cooldown",10.0)),ultimate and actions[i].charge_fraction >= 1.0)
		if ultimate and left <= 0: actions[i].set_caption("%d%%" % progress.abilities.charge[category])
		elif rule.is_empty(): actions[i].set_caption("—")
		var enabled := not blocked and player.skill_ready(i)
		skill_available[i] = player.skill_ready(i)
		if actions[i].enabled != enabled:
			actions[i].enabled = enabled
			actions[i].queue_redraw()

func show_map(progress: GameProgress) -> void:
	if inventory_open or station_panel.visible or rpg_panel.visible or restart.visible:
		return
	expanded_map.progress = progress
	expanded_map.arena_bounds = minimap.arena_bounds
	map_title.text = "Mapa · Arena da Torre" if minimap.arena_bounds.has_area() else "Mapa · Mata · Andar %d" % progress.ascension.current_floor
	map_legend.text = "● Você · Dourado: portais\nSaída para a Mata ao sul" if minimap.arena_bounds.has_area() else "● Você · Verde: acampamento\nColetas e baús: somente os descobertos"
	expanded_map.player_position = minimap.player_position
	expanded_map.queue_redraw()
	map_panel.show()
	_sync_controls()
	_layout()

func close_map() -> void:
	map_panel.hide()
	_sync_controls()

func _compact_style() -> StyleBoxTexture:
	return DiaryTheme.piece("wood",0)

func _focus_equipment_detail() -> void:
	if not inventory_open or equipment_bag == null or equipment_bag.detail_panel == null: return
	await get_tree().process_frame
	if not is_instance_valid(equipment_bag) or equipment_bag.detail_panel == null: return
	inventory_scroll.ensure_control_visible(equipment_bag.detail_panel)

func _pixel_theme() -> Theme:
	return DiaryTheme.create()

func _open_diary(page: int) -> void:
	if page == 0 and inventory_open: return
	if inventory_open: inventory_toggled.emit()
	if rpg_panel.visible: character_toggled.emit()
	if page == 0:
		inventory_toggled.emit()
	else:
		rpg_panel.tab = 2 if page == 1 else 1
		character_toggled.emit()

func _add_equipment(id: String, progress: GameProgress, destination: VBoxContainer, in_bag: bool) -> void:
	var item: Dictionary = RPGRules.EQUIPMENT[id]
	var owned := progress.equipment.has(id)
	var upgrade := int(progress.equipment.get(id, 0))
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#e6d1a3")
	card_style.border_color = Color("#b99863")
	card_style.set_border_width_all(1)
	card_style.set_content_margin_all(5)
	card.add_theme_stylebox_override("panel", card_style)
	destination.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	card.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	header.add_child(ITEM_ICON.new(ArsenalRules.metadata(id).icon))
	var label := Label.new()
	label.text = "%s  +%d\n%s%s" % [item.name, upgrade, item.slot.to_upper(), "  ·  EQUIPADO" if progress.equipped[item.slot] == id else ""]
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", DiaryTheme.GREEN)
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

func _smith_tabs(progress: GameProgress) -> void:
	var tabs := HBoxContainer.new()
	station_content.add_child(tabs)
	for index in range(2):
		var tab := Button.new()
		tab.text = "Comprar armas" if index == 0 else "Fabricar / melhorar"
		tab.add_theme_font_size_override("font_size",14)
		tab.custom_minimum_size.y = 44
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		DiaryTheme.select(tab,smith_tab == index)
		tab.pressed.connect(func():
			smith_tab = index
			smith_shop_selected = ""
			station_scroll.scroll_vertical = 0
			refresh_station(progress))
		tabs.add_child(tab)

func _smith_shop(progress: GameProgress) -> void:
	if not smith_shop_selected.is_empty():
		if not ArsenalRules.CATEGORIES.has(smith_shop_selected):
			smith_shop_selected = ""
			return
		var chosen: String = smith_shop_selected
		var cost := GameProgress.starter_weapon_price(chosen)
		_add_description("Comprar %s por %d ouro?\nSerá equipada · Saldo restante: %d ouro." % [RPGRules.EQUIPMENT[chosen].name,cost,progress.gold-cost])
		var stats := ArsenalRules.effective(progress,chosen)
		_add_description("%s\nDano %d · alcance %.0f px\n%.2f ataques/s" % [WEAPON_STYLES[chosen],stats.damage,stats.reach,1.0/stats.interval])
		var confirm := Button.new()
		confirm.text = "Confirmar · %d ouro" % cost
		confirm.custom_minimum_size.y = 48
		confirm.disabled = not progress.can_buy_starter_weapon(chosen)
		confirm.pressed.connect(func(): station_action.emit("buy_starter",chosen))
		station_content.add_child(confirm)
		smith_shop_buttons["confirm"] = confirm
		_focus_station_action.call_deferred(confirm)
		var cancel := Button.new()
		cancel.text = "Voltar às armas"
		cancel.custom_minimum_size.y = 48
		cancel.pressed.connect(func():
			smith_shop_selected = ""
			refresh_station(progress))
		station_content.add_child(cancel)
		smith_shop_buttons["back"] = cancel
		return
	_add_description("Seu ouro: %d · compra sem materiais" % progress.gold)
	for id: String in ArsenalRules.CATEGORIES:
		_smith_shop_weapon(id,progress)

func _focus_station_action(button: Button) -> void:
	await get_tree().process_frame
	if is_instance_valid(button) and station_panel.visible:
		station_scroll.ensure_control_visible(button)

func _smith_shop_weapon(id: String, progress: GameProgress) -> void:
	var price := GameProgress.starter_weapon_price(id)
	var owned := progress.equipment.has(id)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",DiaryTheme.box(DiaryTheme.PAPER,Color("#bea16a"),6,1))
	station_content.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",3)
	card.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	header.add_child(ITEM_ICON.new(id))
	var title := DiaryTheme.label("%s · %s" % [RPGRules.EQUIPMENT[id].name,TalentRules.CLASSES[id]],13)
	header.add_child(title)
	var button := Button.new()
	button.custom_minimum_size.y = 44
	button.text = "Equipada" if progress.equipped.Arma == id else "Já está na mochila" if owned else "Faltam %d ouro" % (price-progress.gold) if progress.gold < price else "Comprar · %d ouro" % price
	button.disabled = owned or not progress.can_buy_starter_weapon(id)
	button.pressed.connect(func():
		smith_shop_selected = id
		station_scroll.scroll_vertical = 0
		refresh_station(progress))
	box.add_child(button)
	smith_shop_buttons[id] = button

func _vendor_item(item: String, progress: GameProgress) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",DiaryTheme.box(DiaryTheme.PAPER,Color("#bea16a"),6,1))
	station_content.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",3)
	card.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	header.add_child(ITEM_ICON.new(item))
	header.add_child(DiaryTheme.label("%s · na mochila: %d" % [item,progress.bag.get(item,0)],13))
	var actions := HBoxContainer.new()
	box.add_child(actions)
	for action: String in ["Comprar","Vender"]:
		if action == "Comprar" and not GameProgress.TRADE_ITEMS.has(item): continue
		var button := Button.new()
		button.name = action+item
		button.text = "%s 1 · %d ouro" % [action,GameProgress.BUY_PRICE if action == "Comprar" else GameProgress.SELL_PRICE]
		button.custom_minimum_size.y = 44
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",13)
		button.disabled = progress.gold < GameProgress.BUY_PRICE if action == "Comprar" else int(progress.bag.get(item,0)) <= 0
		button.pressed.connect(func(): station_action.emit(action,item))
		actions.add_child(button)
		vendor_buttons[action+":"+item] = button

func _first_weapon_button(key: String, caption: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 48
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	station_content.add_child(button)
	first_weapon_buttons[key] = button
	return button

func _first_weapon_interface(progress: GameProgress) -> void:
	station_title.text = "O Primeiro Passo"
	if first_weapon_page == 0:
		_add_description(FIRST_WEAPON_DESCRIPTION)
		_add_description("Escolha uma arma gratuita. Você poderá fabricar as outras depois.\nSem XP, ouro ou equipamentos extras.")
		_first_weapon_button("open","Escolher primeira arma",func():
			first_weapon_page = 1
			station_scroll.scroll_vertical = 0
			refresh_station(progress))
		return
	if first_weapon_page == 2 and ArsenalRules.CATEGORIES.has(first_weapon_selected):
		_add_description("Você deseja começar sua jornada com %s?" % RPGRules.EQUIPMENT[first_weapon_selected].name)
		_add_description("A arma será equipada automaticamente. A escolha gratuita é única; outras categorias continuarão disponíveis no Ferreiro.")
		var confirm := _first_weapon_button("confirm","Confirmar",func(): station_action.emit("first_weapon",first_weapon_selected))
		confirm.disabled = progress.save_blocked
		_first_weapon_button("back","Voltar",func():
			first_weapon_page = 1
			refresh_station(progress))
		return
	_add_description("Compare as cinco opções. Role para ver todas antes de escolher.")
	for id: String in ArsenalRules.CATEGORIES:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel",DiaryTheme.box(DiaryTheme.PAPER,DiaryTheme.WOOD,6,1))
		station_content.add_child(card)
		var box := VBoxContainer.new()
		card.add_child(box)
		var header := HBoxContainer.new()
		box.add_child(header)
		header.add_child(ITEM_ICON.new(id))
		var name_label := DiaryTheme.label(RPGRules.EQUIPMENT[id].name + "\n" + TalentRules.CLASSES[id],16)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(name_label)
		var values := ArsenalRules.effective(progress,id)
		var details := DiaryTheme.label("Dano básico %d · Alcance %.0f px\nVelocidade %.2f ataques/s · intervalo %.2f s\n%s" % [values.damage,values.reach,1.0/values.interval,values.interval,WEAPON_STYLES[id]],14)
		box.add_child(details)
		var button := Button.new()
		button.text = "Escolher " + ArsenalRules.category_name(id)
		button.custom_minimum_size.y = 48
		button.pressed.connect(func():
			first_weapon_selected = id
			first_weapon_page = 2
			station_scroll.scroll_vertical = 0
			refresh_station(progress))
		box.add_child(button)
		first_weapon_buttons[id] = button
	_first_weapon_button("back","Voltar",func():
		first_weapon_page = 0
		station_scroll.scroll_vertical = 0
		refresh_station(progress))

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

func set_boss(boss: TowerGuardian) -> void:
	var active := is_instance_valid(boss)
	var changed := boss_name.visible != active
	boss_name.visible = active
	boss_bar.visible = active
	mission_label.visible = not active
	mission_toggle.visible = not active
	if changed: _layout()
	if active:
		boss_name.text = "Guardião da Mata · Fase %d\nHP %d/%d" % [2 if boss.health.current * 2 <= boss.health.maximum else 1, boss.health.current, boss.health.maximum]
		boss_bar.max_value = boss.health.maximum
		boss_bar.value = boss.health.current

