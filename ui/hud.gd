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
var damage_flash: ColorRect
var mission_toggle: Button
var mission_expanded := true
var mission_text := ""
var mission_hint := ""
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
var mission_prefix: Label
var mission_hint_label: Label
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
const MissionBannerScene = preload("res://ui/mission_banner.gd")
var mission_back: Control
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
var death_panel: Panel
var death_shade: ColorRect
var death_scroll: ScrollContainer
var death_body: VBoxContainer
var death_details: VBoxContainer
var death_details_button: Button
var death_details_open := false
var death_result: Dictionary = {}
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
var smith_instance_selected := ""
var smith_craft_category := "espada"
var smith_craft_rarity := "comum"
var smith_use_seal := false
var smith_shop_selected := ""
var smith_shop_buttons: Dictionary = {}
var smith_action_buttons: Dictionary = {}
var smith_pick_buttons: Dictionary = {}
var station_tab_host: HBoxContainer
var station_intro := false
var vendor_buttons: Dictionary = {}
var vendor_tab := 0
var vendor_tabs: Array[Button] = []
var smith_confirm := false
var smith_shop_expanded := false
var smith_bonus_expanded := false
var smith_grid: GridContainer
var station_wallet: Label
var station_header_close: Button
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
	damage_flash = ColorRect.new()
	damage_flash.color = Color("#d6534a",0.0)
	damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_flash.z_index = 5
	damage_flash.hide()
	add_child(damage_flash)
	info_back = Panel.new()
	info_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_back.add_theme_stylebox_override("panel",DiaryTheme.box(Color.TRANSPARENT,Color.TRANSPARENT,0,0))
	add_child(info_back)
	mission_back = MissionBannerScene.new()
	mission_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	mission_label.add_theme_color_override("font_color",Color("#fff5d2"))
	mission_label.add_theme_color_override("font_outline_color",Color("#14231d"))
	mission_label.add_theme_constant_override("outline_size",2)
	mission_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mission_label)
	mission_prefix = Label.new()
	mission_prefix.text = "MISSÃO ATUAL"
	mission_prefix.add_theme_font_size_override("font_size",9)
	mission_prefix.add_theme_color_override("font_color",Color("#ffd67c"))
	mission_prefix.add_theme_color_override("font_outline_color",Color("#14231d"))
	mission_prefix.add_theme_constant_override("outline_size",2)
	mission_prefix.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mission_prefix)
	mission_hint_label = Label.new()
	mission_hint_label.add_theme_font_size_override("font_size",9)
	mission_hint_label.add_theme_color_override("font_color",Color("#e6c779"))
	mission_hint_label.add_theme_color_override("font_outline_color",Color("#14231d"))
	mission_hint_label.add_theme_constant_override("outline_size",2)
	mission_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mission_hint_label)
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
	loot_label.add_theme_color_override("font_outline_color", Color("#302b21"))
	loot_label.add_theme_constant_override("outline_size", 3)
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
	character_button.tooltip_text = "Ficha do personagem · C"
	character_button.pressed.connect(func():
		rpg_panel.tab = 3
		character_toggled.emit()
	)
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
	for i in range(2):
		var link := DiaryTab.new()
		link.glyph = ["bag","fury"][i]
		link.text = ["Mochila","Evolução"][i]
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
	actions[4].activated.connect(func(): skill_pressed.emit(3))
	for i in [3, 4]:
		actions[i].hide()
		actions[i].enabled = false
	actions[3].show()
	actions[3].icon = "potion"
	actions[3].title = "Poção"
	actions[3].tooltip_text = "Poções ainda não disponíveis"
	actions[3].set_caption("")
	actions[4].icon = "fury"
	actions[4].title = "Ultimate"
	actions[4].tooltip_text = "Ultimate"
	actions[4].set_caption("")
	for i in [0, 1, 2, 5]:
		actions[i].icon = ["cut", "charge", "fury", "", "", "dash"][i]
		actions[i].tooltip_text = ["Skill 1", "Skill 2", "Skill 3", "", "", "Dash"][i]
		actions[i].set_caption("")
	interact_button = TouchActionButton.new()
	interact_button.title = "Interagir"
	interact_button.size = Vector2(96, 44)
	interact_button.visible = false
	interact_button.activated.connect(func():
		dismiss_interaction()
		interact_pressed.emit()
	)
	add_child(interact_button)
	interact_button.caption.add_theme_font_size_override("font_size",11)
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
	var header := HBoxContainer.new()
	column.add_child(header)
	station_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(station_title)
	station_wallet = DiaryTheme.label("",13)
	station_wallet.size_flags_horizontal = Control.SIZE_SHRINK_END
	station_wallet.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.add_child(station_wallet)
	station_header_close = Button.new()
	station_header_close.text = "×"
	station_header_close.custom_minimum_size = Vector2(44,44)
	station_header_close.pressed.connect(close_station)
	header.add_child(station_header_close)
	station_tab_host = HBoxContainer.new()
	station_tab_host.add_theme_constant_override("separation",4)
	station_tab_host.visible = false
	column.add_child(station_tab_host)
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
	death_panel = Panel.new()
	death_panel.z_index = 20
	death_panel.visible = false
	death_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	death_panel.clip_contents = true
	death_panel.add_theme_stylebox_override("panel",DefeatArt.plate("frame",0))
	death_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	death_shade = ColorRect.new()
	death_shade.color = Color(0.17,0.03,0.03,0.66)
	death_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	death_shade.z_index = 19
	death_shade.hide()
	add_child(death_shade)
	add_child(death_panel)
	var death_column := VBoxContainer.new()
	death_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_column.offset_left = 10
	death_column.offset_top = 6
	death_column.offset_right = -10
	death_column.offset_bottom = -10
	death_column.add_theme_constant_override("separation",4)
	death_panel.add_child(death_column)
	death_column.add_child(DefeatView.title())
	death_scroll = ScrollContainer.new()
	death_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	death_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	death_column.add_child(death_scroll)
	death_body = VBoxContainer.new()
	death_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	death_body.add_theme_constant_override("separation",4)
	death_scroll.add_child(death_body)
	var return_button := Button.new()
	return_button.text = "Voltar ao acampamento"
	return_button.custom_minimum_size.y = 54
	DefeatView.style_button(return_button,"button","home",22)
	return_button.pressed.connect(func(): restart_pressed.emit())
	death_column.add_child(return_button)
	death_details_button = Button.new()
	death_details_button.text = "Ver detalhes"
	death_details_button.custom_minimum_size = Vector2(190,44)
	death_details_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	DefeatView.style_button(death_details_button,"ghost","scroll",18)
	death_details_button.pressed.connect(func(): death_details_open = not death_details_open; death_details.visible = death_details_open; death_details_button.text = "Ocultar detalhes" if death_details_open else "Ver detalhes")
	death_details_button.pressed.connect(func(): call_deferred("_qa_ui_state","death"))
	death_column.add_child(death_details_button)
	boss_name = Label.new()
	boss_name.add_theme_font_size_override("font_size", 12)
	boss_name.add_theme_color_override("font_color", Color("#fff0c3"))
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
	call_deferred("_qa_ui_state","hud")

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
	if not inventory_button.visible:
		character_button.position = Vector2(menu_x, margin.y)
		map_button.position = Vector2(menu_x + 48, margin.y)
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
	var mission_width := minf(220, minimap.position.x - margin.x - 8)
	mission_back.position = margin + Vector2(0, 86)
	var mission_has_hint := not mission_hint.is_empty() and not boss_name.visible
	mission_back.size = Vector2(mission_width,58 if boss_name.visible else 48 if mission_has_hint else 34)
	# Landscape places the two readable panels in one top strip, leaving the
	# workshop visible below. Portrait retains its separate, full-width rows.
	if size.x >= 600 and size.x > size.y:
		mission_back.position = margin + Vector2(information_width+8,0)
		mission_back.size.x = minf(220,menu_x-mission_back.position.x-8)
		mission_width = mission_back.size.x
	if mission_has_hint:
		mission_prefix.position = mission_back.position + Vector2(38, 5)
		mission_prefix.size = Vector2(mission_width-47, 11)
		mission_label.position = mission_back.position + Vector2(38, 17)
		mission_label.size = Vector2(mission_width-47, 15)
		mission_hint_label.position = mission_back.position + Vector2(38, 33)
		mission_hint_label.size = Vector2(mission_width-47, 12)
	else:
		mission_prefix.position = mission_back.position + Vector2(38, 3)
		mission_prefix.size = Vector2(mission_width-47, 11)
		mission_label.position = mission_back.position + Vector2(38, 15)
		mission_label.size = Vector2(mission_width-47, 15)
		mission_hint_label.position = Vector2(-1000,-1000)
		mission_hint_label.size = Vector2.ZERO
	mission_toggle.position = mission_back.position + Vector2(mission_back.size.x-44,0)
	mission_toggle.size = Vector2(44,44)
	mission_toggle.visible = false
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boss_name.position = mission_back.position + Vector2(10, 4)
	boss_name.size = Vector2(mission_width - 12, 30)
	boss_bar.position = mission_back.position + Vector2(10, 43)
	boss_bar.size = Vector2(mission_width - 20, 7)
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
	# The character diary keeps its physical size in landscape. The older
	# inventory grid retains its compatibility scale because its fixed card grid
	# is still measured in that coordinate space.
	var diary_scale := 1.0
	var inventory_scale := 1.0
	var window_size := get_window().size
	if window_size.x >= 900 and window_size.y >= 500 and size.x > size.y and is_equal_approx(size.x,get_viewport_rect().size.x):
		inventory_scale = minf(1.0,size.x/float(window_size.x))
	inventory_panel.scale = Vector2.ONE*inventory_scale
	rpg_panel.scale = Vector2.ONE*diary_scale
	var landscape := size.x > size.y
	inventory_panel.size = Vector2(minf(820, (size.x - margin.x - right_inset - 12)/inventory_scale), minf(650, (size.y - margin.y - bottom_inset - 12)/inventory_scale))
	inventory_panel.position = (size - inventory_panel.size*inventory_scale) * 0.5
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
	actions[4].position = Vector2(size.x-right_inset-120,size.y-bottom_inset-184)
	interact_button.position = Vector2(size.x * 0.5 - interact_button.size.x * 0.5, size.y - bottom_inset - (177 if size.y > size.x else 59))
	var service := station_name in ["Ferreiro","Vendedor"]
	station_title.add_theme_font_size_override("font_size",24 if service else 17)
	if service: station_title.add_theme_font_override("font",DiaryTheme.heading_font())
	else: station_title.remove_theme_font_override("font")
	station_panel.size = Vector2(minf(720 if landscape and service else 560 if service else 460 if landscape else 340, size.x - margin.x - right_inset - 12), minf(780 if service else 320, size.y - margin.y - bottom_inset - 12))
	station_panel.add_theme_stylebox_override("panel",DiaryTheme.piece("frame",22) if service else _panel_style())
	station_panel.position = (size - station_panel.size) * 0.5
	_apply_station_look()
	rpg_panel.size = Vector2(minf(820 if landscape else 640, (size.x - margin.x - right_inset - 12)/diary_scale), minf(780, (size.y - margin.y - bottom_inset - 12)/diary_scale))
	rpg_panel.position = (size - rpg_panel.size*diary_scale) * 0.5
	DiaryArt.skin(rpg_panel)
	death_panel.size = Vector2(minf(520,size.x-16),minf(784,size.y-16))
	death_panel.position = (size-death_panel.size)*0.5
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
		if current < previous_health:
			damage_flash.color.a = 0.20
			damage_flash.show()
	previous_health = current

func set_progress(xp: int, gold: int, kills: int, loot: String) -> void:
	progress_label.text = "XP %d  ·  Ouro %d  ·  Abates %d" % [xp, gold, kills]
	if not loot.is_empty():
		show_notice(loot)

func show_notice(message: String, tint: Color = Color("#fff0ce")) -> void:
	loot_label.text = message
	loot_label.add_theme_color_override("font_color", tint)
	loot_label.show()
	notice_left = 2.5

func _process(delta: float) -> void:
	if notice_left > 0.0:
		notice_left = maxf(0.0, notice_left - delta)
		if notice_left == 0.0:
			loot_label.hide()
	if health_flash_left > 0.0:
		health_flash_left = maxf(0.0, health_flash_left - delta)
		if damage_flash.visible:
			damage_flash.color.a = 0.20 * health_flash_left / 0.55
		if health_flash_left == 0.0:
			hp_bar.add_theme_stylebox_override("fill", _health_fill(Color("#80cf88")))
			damage_flash.hide()

func _health_fill(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	return style

func set_mission(value: String) -> void:
	var lines := value.replace("Missão comum: ", "").split("\n", false)
	mission_text = lines[0] if not lines.is_empty() else ""
	mission_hint = ""
	if lines.size() > 1 and lines[0] == "O Primeiro Passo":
		mission_text = "Escolha sua primeira arma"
		mission_hint = "Fale com o Ferreiro."
	_render_mission()
	_layout()

func _render_mission() -> void:
	mission_label.text = mission_text if mission_expanded else mission_text.get_slice("\n",0)
	mission_hint_label.text = mission_hint
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
	var material_items := GameProgress.ITEMS.duplicate()
	for owned: String in progress.bag:
		if not material_items.has(owned): material_items.append(owned)
	for item: String in material_items:
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
			var material_meta := EquipmentEconomy.split_key(item)
			var icon := PixelItemIcon.new(material_meta.item,Color(ArsenalRules.RARITIES[material_meta.rarity].color))
			icon.framed = false
			icon.custom_minimum_size = Vector2(48,48)
			icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			row.add_child(icon)
			var name := Label.new()
			name.text = material_meta.item + (" · "+ArsenalRules.RARITIES[material_meta.rarity].name if EquipmentEconomy.MATERIALS.has(material_meta.item) else "")
			if EquipmentEconomy.MATERIALS.has(material_meta.item): name.add_theme_color_override("font_color",Color(ArsenalRules.RARITIES[material_meta.rarity].color).darkened(0.45))
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

func show_death(result: Dictionary = {}) -> void:
	death_result = result.duplicate(true)
	save_panel.hide()
	close_inventory()
	close_station()
	joystick.reset()
	dash_button.enabled = false
	dash_button.queue_redraw()
	interact_button.visible = false
	restart.hide()
	death_panel.show()
	death_details_open = false
	death_details_button.text = "Ver detalhes"
	for child in death_body.get_children():
		death_body.remove_child(child)
		child.queue_free()
	death_shade.show()
	death_body.add_child(DefeatView.enemy_card(str(result.get("enemy","Inimigo não identificado"))))
	death_body.add_child(DefeatView.section("bag","PERDAS DESTA DERROTA"))
	death_body.add_child(DefeatView.losses(result))
	death_body.add_child(DefeatView.section("swords","EQUIPAMENTOS"))
	death_body.add_child(DefeatView.equipment(result))
	death_body.add_child(DefeatView.section("home","RETORNO"))
	death_body.add_child(DefeatView.return_card(int(result.get("floor",1))))
	death_details = VBoxContainer.new()
	death_details.visible = false
	death_body.add_child(death_details)
	death_details.add_child(DefeatView.section("scroll","DETALHES DA DERROTA"))
	death_details.add_child(_death_label("Resultado registrado pelo sistema de morte. Valores zero indicam que não houve perda de ouro ou XP.",13))
	death_scroll.scroll_vertical = 0
	rpg_panel.hide()
	map_panel.hide()
	_layout()
	_sync_controls()
	call_deferred("_qa_ui_state","death")

func _death_section(value: String) -> Control:
	var label := DiaryTheme.label(value,14)
	label.add_theme_color_override("font_color",DiaryTheme.GREEN)
	return label

func _death_label(value: String, font_size: int, centered: bool = false) -> Label:
	var label := DiaryTheme.label(value,font_size)
	if centered: label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func set_nearby_station(name: String) -> void:
	interact_button.enabled = not name.is_empty() and not restart.visible and not station_panel.visible and not inventory_open and not rpg_panel.visible and not map_panel.visible
	interact_button.visible = interact_button.enabled
	interact_button.set_caption(("E · Guardião\nOpcional" if name == "Desafiar Guardião (opcional)" else "E · " + name) if interact_button.enabled else "Interagir")
	if interact_button.visible: call_deferred("_qa_ui_state","hud")

func dismiss_interaction() -> void:
	interact_button.enabled = false
	interact_button.hide()

func show_station(name: String, progress: GameProgress) -> void:
	station_name = name
	station_scroll.scroll_vertical = 0
	selected_floor = progress.ascension.current_floor
	station_page = 0
	first_weapon_page = 0
	first_weapon_selected = ""
	smith_tab = 0
	smith_shop_expanded = false
	smith_bonus_expanded = false
	smith_confirm = false
	vendor_tab = 0
	smith_shop_selected = ""
	close_inventory()
	station_panel.show()
	_sync_controls()
	interact_button.enabled = false
	interact_button.visible = false
	dash_button.enabled = false
	refresh_station(progress)
	_layout()
	call_deferred("_qa_ui_state","blacksmith")

func close_station() -> void:
	if station_panel.visible:
		station_panel.hide()
		dash_button.enabled = not restart.visible
		dash_button.queue_redraw()
		panel_closed.emit()
		_sync_controls()
		call_deferred("_qa_ui_state","hud")

func refresh_station(progress: GameProgress) -> void:
	station_title.text = station_name
	station_wallet.text = "%d ouro" % progress.gold
	station_wallet.visible = station_name in ["Ferreiro","Vendedor"]
	station_header_close.visible = station_wallet.visible
	smith_grid = null
	vendor_tabs.clear()
	smith_action_buttons.clear()
	smith_pick_buttons.clear()
	station_intro = station_name == "Ferreiro" and progress.introduction_active()
	_apply_station_look()
	first_weapon_buttons.clear()
	station_content.add_theme_constant_override("separation",4 if station_name in ["Ferreiro","Vendedor"] else 8)
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
		var guardian_name := FloorConfig.tower_guardian_name(progress.ascension.current_floor)
		var return_name := FloorConfig.tower_return_name(progress.ascension.current_floor)
		_add_description("Vitória · %s!" % guardian_name if cleared else tower_trial.summary() if active else "Andar %d · Torre: %d/50 criaturas" % [selected_floor, progress.ascension.defeats[str(selected_floor)]])
		_add_description("Ascensão do Andar %d concluída%s" % [progress.ascension.current_floor, FloorCatalog.seal_note(progress.ascension.current_floor)] if cleared else "Abandonar reinicia a tentativa, sem penalidade." if active else "Prova concluída" if progress.ascension.completed_trials[str(selected_floor)] else "Prova de Ascensão liberada" if progress.ascension.entrance_unlocked(selected_floor) else "Prova bloqueada: derrote 50 criaturas neste andar.")
		_add_description("+%d XP · +%d ouro" % [FloorConfig.reward(AscensionProgress.GUARDIAN_XP, progress.ascension.current_floor), FloorConfig.reward(AscensionProgress.GUARDIAN_GOLD, progress.ascension.current_floor)] if cleared and victory_first else "Recompensas únicas já recebidas." if cleared else "Desafio: três hordas e %s." % guardian_name)
		_add_description(("Campanha inicial conquistada! Cinco andares superados." if progress.ascension.current_floor == 5 else "Andar %d desbloqueado · viaje pela Torre no %s." % [progress.ascension.current_floor + 1, return_name]) if cleared else "Se morrer, a prova recomeça da primeira horda.")
		_add_description("Retorne ao %s em segurança." % return_name if cleared else "Sem checkpoints. Fechar o jogo encerra a tentativa.")
		tower_action_button.text = ("Retornar à Mata" if return_name == "Mata" else "Retornar ao %s" % return_name) if cleared else "Abandonar Prova" if active else "Entrar na Prova"
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
			station_tab_host.hide()
			_first_weapon_interface(progress)
			call_deferred("_qa_ui_state","blacksmith")
			return
		_smith_tabs(progress)
		match smith_tab:
			0: _smith_craft(progress)
			1: _smith_instance_page(progress,"enhance")
			2: _smith_instance_page(progress,"rarity")
	elif station_name == "Baú":
		_add_description("Mochila/Baú · itens guardados ficam protegidos.")
		var chest_items := GameProgress.ITEMS.duplicate()
		for item: String in progress.bag.keys():
			if not chest_items.has(item): chest_items.append(item)
		for item: String in progress.chest.keys():
			if not chest_items.has(item): chest_items.append(item)
		for item: String in _page_items(chest_items):
			_add_row(item, "%d/%d" % [progress.bag.get(item, 0), progress.chest.get(item, 0)], "Guardar", "Retirar", int(progress.bag.get(item, 0)) > 0, int(progress.chest.get(item, 0)) > 0)
		_add_page_navigation(chest_items.size(), progress)
	elif station_name == "Vendedor":
		_vendor_shop(progress)
	if station_name == "Ferreiro": call_deferred("_qa_ui_state","blacksmith")

func _apply_station_look() -> void:
	var forge := station_name == "Ferreiro" and not station_intro
	station_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if forge else CanvasItem.TEXTURE_FILTER_PARENT_NODE
	station_tab_host.visible = forge
	station_close_button.visible = not forge
	ForgeView.style_close(station_header_close,forge)
	if forge:
		station_panel.add_theme_stylebox_override("panel",DefeatArt.plate("frame",12))
		station_scroll.add_theme_stylebox_override("panel",DefeatArt.plate("paper_bg",6))
		station_title.add_theme_stylebox_override("normal",DefeatArt.plate("title",6))
		station_title.add_theme_font_override("font",DefeatView.font())
		station_title.add_theme_font_size_override("font_size",32)
		station_title.add_theme_color_override("font_color",DefeatView.CREAM)
		station_title.add_theme_color_override("font_outline_color",Color("#10261b"))
		station_title.add_theme_constant_override("outline_size",4)
		station_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		station_wallet.add_theme_color_override("font_color",ForgeView.GOLD)
		station_wallet.add_theme_font_override("font",DefeatView.font())
		station_wallet.add_theme_font_size_override("font_size",16)
	else:
		station_scroll.remove_theme_stylebox_override("panel")
		station_title.remove_theme_stylebox_override("normal")
		station_title.remove_theme_color_override("font_color")
		station_title.remove_theme_color_override("font_outline_color")
		station_title.remove_theme_constant_override("outline_size")
		station_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		station_wallet.remove_theme_color_override("font_color")
		station_wallet.remove_theme_font_override("font")
		station_wallet.add_theme_font_size_override("font_size",13)

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
	if death_panel.visible and event is InputEventScreenTouch and event.pressed and OS.has_feature("web") and bool(JavaScriptBridge.eval("window.__ARVEON_UI2_TEST__ === true", true)):
		var panel_touch := death_panel.make_input_local(event) as InputEventScreenTouch
		var scroll_touch_event := death_scroll.make_input_local(event) as InputEventScreenTouch
		var touch_diagnostic := {"stage":"input","raw":[event.position.x,event.position.y],"panel":[panel_touch.position.x,panel_touch.position.y],"panel_size":[death_panel.size.x,death_panel.size.y],"panel_hit":_touch_contains(death_panel,event),"scroll":[scroll_touch_event.position.x,scroll_touch_event.position.y],"scroll_size":[death_scroll.size.x,death_scroll.size.y],"scroll_hit":_touch_contains(death_scroll,event),"transition":transition_active,"restart":restart.visible,"save":save_panel.visible}
		JavaScriptBridge.eval("console.log("+JSON.stringify("ARVEON_UI2_TOUCH "+JSON.stringify(touch_diagnostic))+")")
	if event is InputEventScreenDrag and event.index == scroll_touch and is_instance_valid(touch_scroll):
		var local_drag := touch_scroll.make_input_local(event) as InputEventScreenDrag
		if local_drag.position.distance_to(inventory_touch_origin) > 8.0:
			inventory_touch_dragged = true
		touch_scroll.scroll_vertical -= roundi(local_drag.relative.y)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch and not event.pressed and event.index == scroll_touch:
		var tapped_card := inventory_touch_card
		var local_release: InputEventScreenTouch = event as InputEventScreenTouch
		if is_instance_valid(touch_scroll):
			local_release = touch_scroll.make_input_local(event) as InputEventScreenTouch
		var activate: bool = not inventory_touch_dragged and is_instance_valid(tapped_card) and local_release.position.distance_to(inventory_touch_origin) <= 8.0
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
		_touch_buttons(save_panel, event)
		get_viewport().set_input_as_handled()
		return
	if restart.visible:
		_activate_touch_button(restart, event)
		return
	if death_panel.visible:
		# The death actions sit outside the scrolling loss report; hit them first
		# so a translated touch at the scroll boundary cannot swallow their tap.
		if _touch_buttons(death_panel,event):
			get_viewport().set_input_as_handled()
			return
		if _touch_contains(death_scroll,event):
			_defer_menu_touch(death_body,death_scroll,event)
		get_viewport().set_input_as_handled()
		return
	if map_panel.visible:
		_activate_touch_button(map_close, event)
		get_viewport().set_input_as_handled()
		return
	if rpg_panel.visible:
		if _activate_touch_button(rpg_panel.close_button, event):
			return
		if _touch_contains(rpg_panel.scroll,event):
			_defer_menu_touch(rpg_panel.content,rpg_panel.scroll,event)
			return
		if not _touch_buttons(rpg_panel, event):
			_begin_scroll(rpg_panel.scroll, event)
		get_viewport().set_input_as_handled()
		return
	if inventory_open:
		if _activate_touch_button(inventory_close, event):
			return
		# Delay card activation until release so a swipe can scroll over the cards.
		if inventory_category == 1 and _touch_contains(inventory_scroll,event):
			inventory_touch_card = null
			inventory_touch_origin = (inventory_scroll.make_input_local(event) as InputEventScreenTouch).position
			inventory_touch_dragged = false
			for card: Button in equipment_bag.cards.values():
				if _touch_contains(card,event):
					inventory_touch_card = card
					break
			if inventory_touch_card != null:
				_begin_scroll(inventory_scroll,event)
				get_viewport().set_input_as_handled()
				return
		if not _touch_buttons(inventory_panel, event):
			_begin_scroll(inventory_scroll, event)
		get_viewport().set_input_as_handled()
		return
	if not station_panel.visible:
		for button in [inventory_button, character_button, map_button, mission_toggle]:
			if _activate_touch_button(button, event):
				return
	if not station_panel.visible:
		return
	if _activate_touch_button(travel_button, event) or _activate_touch_button(tower_action_button, event):
		return
	if station_name == TowerEntrance.NAME:
		if _activate_touch_button(station_close_button, event):
			return
		if _touch_contains(station_scroll,event) and not _touch_buttons(station_content, event):
			_begin_scroll(station_scroll, event)
		get_viewport().set_input_as_handled()
		return
	if station_name in ["Ferreiro","Vendedor"]:
		if _activate_touch_button(station_close_button,event) or _activate_touch_button(station_header_close,event): return
		for tab: Node in station_tab_host.get_children():
			if tab is Button and _activate_touch_button(tab,event): return
		if _touch_contains(station_scroll,event):
			_defer_menu_touch(station_content,station_scroll,event)
		get_viewport().set_input_as_handled()
		return

	if _activate_touch_button(station_close_button, event):
		return
	if not _touch_contains(station_scroll,event):
		return
	for row in station_content.get_children():
		if row.is_queued_for_deletion() or not row is HBoxContainer:
			continue
		for node in row.get_children():
			if node is Button and _activate_touch_button(node, event):
				return
	_begin_scroll(station_scroll, event)
	get_viewport().set_input_as_handled()

func _button_under(node: Node, event: InputEventScreenTouch) -> Button:
	if node is Control and node.clip_contents and not _touch_contains(node,event): return null
	if node is Button:
		return node if not node.disabled and node.is_visible_in_tree() and _touch_contains(node,event) else null
	var children := node.get_children()
	children.reverse()
	for child: Node in children:
		var button := _button_under(child,event)
		if button != null: return button
	return null

func _defer_menu_touch(content: Control, scroll: ScrollContainer, event: InputEventScreenTouch) -> void:
	inventory_touch_card = _button_under(content,event)
	inventory_touch_origin = (scroll.make_input_local(event) as InputEventScreenTouch).position
	inventory_touch_dragged = false
	_begin_scroll(scroll,event)
	get_viewport().set_input_as_handled()

func _activate_touch_button(button: Button, event: InputEventScreenTouch) -> bool:
	if death_panel.visible and (button.text.contains("Ver detalhes") or button.text.contains("Voltar ao acampamento")) and OS.has_feature("web") and bool(JavaScriptBridge.eval("window.__ARVEON_UI2_TEST__ === true", true)):
		var local_event := button.make_input_local(event) as InputEventScreenTouch
		var diagnostic := {"text":button.text,"raw":[event.position.x,event.position.y],"local":[local_event.position.x,local_event.position.y],"size":[button.size.x,button.size.y]}
		JavaScriptBridge.eval("console.log("+JSON.stringify("ARVEON_UI2_TOUCH "+JSON.stringify(diagnostic))+")")
	if not button.disabled and button.is_visible_in_tree() and _touch_contains(button,event):
		button.pressed.emit()
		get_viewport().set_input_as_handled()
		return true
	return false

func _touch_contains(control: Control, event: InputEvent) -> bool:
	var local_event := control.make_input_local(event)
	return Rect2(Vector2.ZERO,control.size).has_point(local_event.position)

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
	var blocked := transition_active or save_panel.visible or inventory_open or station_panel.visible or rpg_panel.visible or map_panel.visible or restart.visible or death_panel.visible
	menu_shade.visible = blocked and not transition_active and not restart.visible and not death_panel.visible
	for button in [inventory_button, character_button, map_button]:
		button.disabled = blocked
	mission_toggle.disabled = blocked
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
	if inventory_open or station_panel.visible or restart.visible or map_panel.visible:
		return
	rpg_panel.tab = 3
	rpg_panel.show()
	rpg_panel.refresh(progress)
	rpg_panel.scroll.scroll_vertical = 0
	_sync_controls()
	_layout()
	call_deferred("_qa_ui_state","evolution")

func close_character() -> void:
	rpg_panel.hide()
	_sync_controls()
	call_deferred("_qa_ui_state","hud")

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
		actions[i].legend = "Skill %d" % (i+1)
		actions[i].tooltip_text = rule.get("name","Slot vazio")
		actions[i].icon = category if i == 0 and not category.is_empty() else "charge"
		actions[i].charge_fraction = -1.0
		var left := player.skill_cooldowns[i]
		actions[i].set_recharge(left,float(rule.get("cooldown",10.0)),false)
		if rule.is_empty(): actions[i].set_caption("—")
		var enabled := not blocked and player.skill_ready(i)
		skill_available[i] = player.skill_ready(i)
		if actions[i].enabled != enabled:
			actions[i].enabled = enabled
			actions[i].queue_redraw()
	var ultimate_rule := AbilityRules.active_skill(category,progress.abilities.loadouts[category].ultimate) if not category.is_empty() else {}
	var ultimate_ready := not ultimate_rule.is_empty() and player.skill_ready(3)
	actions[4].visible = ultimate_ready
	actions[4].legend = "Ultimate"
	actions[4].tooltip_text = ultimate_rule.get("name","Ultimate")
	actions[4].charge_fraction = 1.0 if ultimate_ready else -1.0
	actions[4].set_recharge(0.0,float(ultimate_rule.get("cooldown",10.0)),ultimate_ready)
	actions[4].set_caption("ULT")
	actions[4].enabled = not blocked and ultimate_ready
	actions[4].queue_redraw()

func show_map(progress: GameProgress) -> void:
	if inventory_open or station_panel.visible or rpg_panel.visible or restart.visible:
		return
	expanded_map.progress = progress
	expanded_map.arena_bounds = minimap.arena_bounds
	map_title.text = "Mapa · Arena da Torre" if minimap.arena_bounds.has_area() else FloorCatalog.map_title(progress.ascension.current_floor)
	map_legend.text = "● Você · Dourado: portais\nSaída para o %s ao sul" % FloorConfig.tower_return_name(progress.ascension.current_floor) if minimap.arena_bounds.has_area() else "● Você · Verde: acampamento\nColetas e baús: somente os descobertos"
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
		rpg_panel.tab = 3
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
	var current: String = progress.equipped[item.slot]
	var button := Button.new()
	button.custom_minimum_size.y = 44
	if in_bag:
		var description := Label.new()
		description.text = RPGRules.bonus_text(id, upgrade)
		if current != id:
			description.text += "\nAtual: " + (RPGRules.EQUIPMENT[current].name if current != "" else "nenhum")
			if current != "":
				description.text += "\n" + RPGRules.bonus_text(current, int(progress.equipment[current]))
		description.add_theme_font_size_override("font_size", 12)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(description)
		box.add_child(button)
		button.text = "Desequipar" if current == id else "Equipar"
		button.pressed.connect(func(): rpg_action.emit("unequip" if current == id else "equip", item.slot if current == id else id, 0))
	else:
		var expected := int(progress.equipment.get(id, -1))
		var cost := RPGRules.recipe(id, owned, upgrade)
		label.text = "%s  +%d\n%s%s" % [item.name, upgrade, item.slot.to_upper(), "  ·  EQUIPADO" if current == id else ""]
		var status := Label.new()
		status.text = "NO LIMITE" if owned and upgrade >= 3 else "PRONTO" if progress.can_forge(id) else "REQUISITOS"
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		status.add_theme_font_size_override("font_size", 11)
		status.add_theme_color_override("font_color", DiaryTheme.GREEN if progress.can_forge(id) else Color("#8c5b35"))
		header.add_child(status)
		var summary := Label.new()
		summary.text = _forge_summary(id, owned, upgrade)
		summary.add_theme_font_size_override("font_size", 12)
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(summary)
		if not (owned and upgrade >= 3):
			var requirements := GridContainer.new()
			requirements.columns = 2
			requirements.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			requirements.add_theme_constant_override("h_separation", 4)
			requirements.add_theme_constant_override("v_separation", 3)
			box.add_child(requirements)
			requirements.add_child(_forge_requirement("Ouro", progress.gold, int(cost.gold)))
			for material: String in cost.materials:
				requirements.add_child(_forge_requirement(material, int(progress.bag.get(material, 0)), int(cost.materials[material])))
		button.text = "No limite de melhoria" if owned and upgrade >= 3 else "Aprimorar para +%d" % (upgrade + 1) if owned else "Fabricar equipamento"
		button.disabled = owned and upgrade >= 3 or not progress.can_forge(id)
		if not button.disabled:
			DiaryTheme.primary(button)
		box.add_child(button)
		button.pressed.connect(func(): rpg_action.emit("forge", id, expected))

func _forge_summary(id: String, owned: bool, upgrade: int) -> String:
	if owned:
		if upgrade >= 3:
			return "Melhoria máxima alcançada."
		return "Atual +%d  →  Próximo +%d   ·   %s" % [upgrade, upgrade + 1, _bonus_delta(id, upgrade, upgrade + 1)]
	return "Ao fabricar: " + _compact_bonus(id, 0)

func _bonus_delta(id: String, before_upgrade: int, after_upgrade: int) -> String:
	var before := RPGRules.bonuses(id, before_upgrade)
	var after := RPGRules.bonuses(id, after_upgrade)
	var labels := {"damage":"Dano", "hp":"HP", "speed":"Vel", "spirit":"Espírito", "armor":"Defesa"}
	var result: Array[String] = []
	for key: String in ["damage", "hp", "speed", "spirit", "armor"]:
		var value := int(after[key]) - int(before[key])
		if value != 0:
			result.append("%s %+d" % [labels[key], value])
	return " · ".join(result) if not result.is_empty() else "Sem mudança"

func _compact_bonus(id: String, upgrade: int) -> String:
	var values := RPGRules.bonuses(id, upgrade)
	var labels := {"damage":"Dano", "hp":"HP", "speed":"Vel", "spirit":"Espírito", "armor":"Defesa"}
	var result: Array[String] = []
	for key: String in ["damage", "hp", "speed", "spirit", "armor"]:
		var value := int(values[key])
		if value != 0:
			result.append("%s %+d" % [labels[key], value])
	return " · ".join(result) if not result.is_empty() else "Bônus base"

func _forge_requirement(name: String, available: int, required: int) -> PanelContainer:
	var enough := available >= required
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(132, 30)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.add_theme_stylebox_override("panel",DiaryTheme.box(Color("#d8e7bd") if enough else Color("#f0d6bd"), Color("#668055") if enough else Color("#a26a42"),4,1))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	chip.add_child(row)
	var material_meta := EquipmentEconomy.split_key(name)
	var icon := ITEM_ICON.new(material_meta.item)
	icon.framed = false
	icon.custom_minimum_size = Vector2(20,20)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var label := Label.new()
	var caption: String = material_meta.item + (" · " + ArsenalRules.RARITIES[material_meta.rarity].name if EquipmentEconomy.MATERIALS.has(material_meta.item) and material_meta.rarity != "comum" else "")
	label.text = ("✓ " if enough else "Falta ") + "%s  %d/%d" % [caption, available, required]
	label.add_theme_font_size_override("font_size", 11)
	label.clip_text = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	return chip

func _smith_tabs(progress: GameProgress) -> void:
	ForgeView.tab_bar(station_tab_host,smith_tab,func(index: int):
		smith_tab = index
		smith_shop_selected = ""
		smith_confirm = false
		station_scroll.scroll_vertical = 0
		refresh_station(progress))

func _smith_section(icon: String, caption: String, scale: int = 1) -> void:
	station_content.add_child(DefeatView.section(icon,caption,scale))

func _smith_requirements(recipe: Dictionary, progress: GameProgress) -> void:
	var needs: Array = []
	for material: String in recipe.materials:
		var meta := EquipmentEconomy.split_key(material)
		var caption: String = meta.item + (" " + ArsenalRules.RARITIES[meta.rarity].name if EquipmentEconomy.MATERIALS.has(meta.item) and meta.rarity != "comum" else "")
		needs.append({"item":meta.item,"name":caption,"have":int(progress.bag.get(material,0)),"need":int(recipe.materials[material])})
	station_content.add_child(ForgeView.materials(needs))
	station_content.add_child(ForgeView.gold_row(progress.gold,int(recipe.gold)))

func _smith_action(caption: String, icon: String, action: String, payload: String, enabled: bool, progress: GameProgress) -> Button:
	var confirming := smith_confirm and smith_shop_selected == payload
	var button := ForgeView.action_button(("Confirmar · " if confirming else "")+caption,icon,enabled)
	button.pressed.connect(func():
		if smith_confirm and smith_shop_selected == payload:
			smith_confirm = false
			smith_shop_selected = ""
			station_action.emit(action,payload)
		else:
			smith_confirm = true
			smith_shop_selected = payload
			refresh_station(progress))
	station_content.add_child(button)
	smith_action_buttons[payload] = button
	return button

func _smith_craft(progress: GameProgress) -> void:
	_smith_section("swords","ESCOLHA A ARMA")
	var weapons: Array = []
	for id: String in ArsenalRules.CATEGORIES:
		weapons.append({"id":id,"title":ArsenalRules.category_name(id),"tag":progress.equipped.Arma == id})
	station_content.add_child(ForgeView.picker(weapons,smith_craft_category,func(id: String): smith_craft_category = id; smith_confirm = false; refresh_station(progress),smith_pick_buttons))
	_smith_section("star","RARIDADE")
	var rarities: Array = []
	for rarity: String in EquipmentEconomy.RARITY_ORDER:
		rarities.append({"id":rarity,"title":ArsenalRules.RARITIES[rarity].name,"color":ForgeView.rarity_color(rarity)})
	station_content.add_child(ForgeView.chips(rarities,smith_craft_rarity,func(id: String): smith_craft_rarity = id; smith_confirm = false; refresh_station(progress)))
	_smith_section("bag","MATERIAIS NECESSÁRIOS")
	_smith_requirements(EquipmentEconomy.craft_recipe(smith_craft_category,smith_craft_rarity),progress)
	_add_description("Nova %s %s +0 · Cópias são independentes." % [ArsenalRules.category_name(smith_craft_category),ArsenalRules.RARITIES[smith_craft_rarity].name])
	_smith_action("Forjar","hammer","craft_weapon",smith_craft_category+"|"+smith_craft_rarity,progress.can_craft_weapon(smith_craft_category,smith_craft_rarity),progress)
	if FloorCatalog.feature(progress.ascension.current_floor,"vale_iron"):
		_smith_section("bag","FERRO DO VALE · RECEITA DE TESTE")
		for iron_rarity: String in ["comum", "raro"]:
			_smith_requirements(EquipmentEconomy.vale_iron_recipe(iron_rarity),progress)
			_smith_action("Forjar espada de ferro · " + ArsenalRules.RARITIES[iron_rarity].name,"hammer","craft_vale_iron",iron_rarity,progress.can_craft_vale_iron(iron_rarity),progress)
	_smith_section("shield","ARMADURAS E ACESSÓRIOS")
	for id: String in RPGRules.EQUIPMENT:
		if not ArsenalRules.CATEGORIES.has(id): _add_equipment(id,progress,station_content,false)
	var shop_toggle := Button.new()
	shop_toggle.text = ("− " if smith_shop_expanded else "+ ")+"Armas iniciais por ouro"
	shop_toggle.custom_minimum_size.y = 44
	shop_toggle.pressed.connect(func(): smith_shop_expanded = not smith_shop_expanded; refresh_station(progress))
	station_content.add_child(shop_toggle)
	if smith_shop_expanded:
		_add_description("Armas disponíveis para compra com as regras atuais.")
		_smith_shop(progress)

func _smith_instance_page(progress: GameProgress, page: String) -> void:
	if not progress.weapon_instances.has(smith_instance_selected) and not progress.weapon_instances.is_empty():
		smith_instance_selected = progress.equipped_weapon_uid if progress.weapon_instances.has(progress.equipped_weapon_uid) else str(progress.weapon_instances.keys()[0])
	_smith_section("swords","SELECIONE UM EQUIPAMENTO")
	if progress.weapon_instances.is_empty():
		_add_description("Nenhuma arma na mochila. Use a aba Forjar para fabricar uma.")
		return
	var owned: Array = []
	for uid: String in progress.weapon_instances:
		var data: Dictionary = progress.weapon(uid)
		owned.append({"id":uid,"icon":data.category,"title":ArsenalRules.category_name(data.category),"sub":"%s +%d" % [ArsenalRules.RARITIES[data.rarity].name,int(data.level)],"color":ForgeView.rarity_color(data.rarity),"tag":uid == progress.equipped_weapon_uid})
	station_content.add_child(ForgeView.picker(owned,smith_instance_selected,func(uid: String): smith_instance_selected = uid; smith_confirm = false; refresh_station(progress),smith_pick_buttons))
	var uid := smith_instance_selected
	var weapon: Dictionary = progress.weapon(uid)
	if page == "rarity": _smith_rarity_page(progress,uid,weapon)
	else: _smith_enhance_page(progress,uid,weapon)

func _smith_stat_rows(current: Dictionary, next: Dictionary, category: String) -> Array:
	var speed_now := 1.0/float(current.interval)
	var speed_next := 1.0/float(next.interval)
	return [
		{"icon":"swords","name":"Dano mágico" if category == "cajado" else "Dano físico","now":str(int(current.damage)),"next":str(int(next.damage)),"better":int(next.damage) > int(current.damage)},
		{"icon":"heart","scale":2,"name":"Vida","now":str(int(current.hp)),"next":str(int(next.hp)),"better":int(next.hp) > int(current.hp)},
		{"icon":"shield","name":"Defesa","now":str(int(current.armor)),"next":str(int(next.armor)),"better":int(next.armor) > int(current.armor)},
		{"icon":"bolt","scale":2,"name":"Veloc. de Ataque","now":"%s/s" % String.num(speed_now,2),"next":"%s/s" % String.num(speed_next,2),"better":speed_next > speed_now + 0.0001}]

func _smith_enhance_page(progress: GameProgress, uid: String, weapon: Dictionary) -> void:
	_smith_section("hammer","APRIMORAMENTO",2)
	var level := int(weapon.level)
	if level >= 20:
		_add_description("Aprimoramento máximo: +20.")
		return
	var rarity_name: String = ArsenalRules.RARITIES[weapon.rarity].name
	var current := _weapon_instance_stats(progress,uid,weapon.rarity,level,weapon.choices)
	var next := _weapon_instance_stats(progress,uid,weapon.rarity,level+1,weapon.choices)
	station_content.add_child(ForgeView.compare_card(weapon.category,"%s · %s" % [ArsenalRules.category_name(weapon.category),rarity_name],"Aprimoramento +%d" % level,"+%d" % level,"+%d" % (level+1),Color("#fff1c9"),Color("#9be58f")))
	station_content.add_child(ForgeView.stat_table(_smith_stat_rows(current,next,weapon.category)))
	var chance: float = EquipmentEconomy.SUCCESS[level]
	station_content.add_child(ForgeView.chance(roundi(chance*100)))
	if chance < 1.0:
		var loss := "O item mantém o nível +%d." % level if level < int(EquipmentEconomy.FAILURE.safe_through) else "O item perde 1 nível." if level < 15 else "O item perde 1 ou 2 níveis."
		station_content.add_child(ForgeView.danger("Em caso de falha","%s Ouro e materiais gastos não são devolvidos." % loss))
	_smith_section("bag","MATERIAIS NECESSÁRIOS")
	var recipe := EquipmentEconomy.enhance_recipe(level,weapon.rarity)
	_smith_requirements(recipe,progress)
	_smith_section("shield","PROTEÇÃO (OPCIONAL)")
	var seals := int(progress.bag.get(EquipmentEconomy.SEAL,0))
	station_content.add_child(ForgeView.protection(seals,smith_use_seal and seals > 0,"Evita a perda de níveis ao falhar a partir de +10.",func(): smith_use_seal = not smith_use_seal; refresh_station(progress)))
	_smith_action("Aprimorar","up","enhance_weapon",uid,progress.can_enhance_weapon(uid),progress)

func _smith_rarity_page(progress: GameProgress, uid: String, weapon: Dictionary) -> void:
	_smith_section("star","EVOLUÇÃO DE RARIDADE",2)
	var recipe := EquipmentEconomy.rarity_recipe(weapon.rarity)
	if recipe.is_empty():
		_add_description("Raridade máxima alcançada.")
		return
	var next_rarity: String = EquipmentEconomy.RARITY_ORDER[EquipmentEconomy.RARITY_ORDER.find(weapon.rarity)+1]
	var current := _weapon_instance_stats(progress,uid,weapon.rarity,int(weapon.level),weapon.choices)
	var next := _weapon_instance_stats(progress,uid,next_rarity,0,{})
	station_content.add_child(ForgeView.compare_card(weapon.category,ArsenalRules.category_name(weapon.category),"Aprimoramento atual +%d" % int(weapon.level),ArsenalRules.RARITIES[weapon.rarity].name,ArsenalRules.RARITIES[next_rarity].name,Color(ArsenalRules.RARITIES[weapon.rarity].color),Color(ArsenalRules.RARITIES[next_rarity].color)))
	station_content.add_child(ForgeView.stat_table(_smith_stat_rows(current,next,weapon.category)))
	_smith_section("bag","MATERIAIS NECESSÁRIOS")
	_smith_requirements(recipe,progress)
	_smith_action("Evoluir","star","evolve_weapon",uid,progress.can_evolve_weapon(uid),progress)
	station_content.add_child(ForgeView.note("Importante","Ao evoluir para uma raridade superior, o aprimoramento volta a +0 e os bônus escolhidos são reiniciados."))
	var bonuses := Button.new()
	bonuses.text = ("− " if smith_bonus_expanded else "+ ")+"Bônus dos aprimoramentos"
	bonuses.custom_minimum_size.y = 44
	bonuses.pressed.connect(func(): smith_bonus_expanded = not smith_bonus_expanded; refresh_station(progress))
	station_content.add_child(bonuses)
	if smith_bonus_expanded: _smith_bonus_options(progress,uid,weapon)

func _smith_bonus_options(progress: GameProgress, uid: String, weapon: Dictionary) -> void:
	_add_description("Bônus de atributos nos marcos de aprimoramento existentes.")
	for milestone: int in EquipmentEconomy.MILESTONES:
		var active := int(weapon.level) >= milestone
		var chosen: String = weapon.choices.get(str(milestone),"")
		_add_description("+%d · %s" % [milestone,"Escolhido: "+chosen.capitalize() if chosen != "" else "Escolha disponível" if active else "Bloqueado"])
		if not active or chosen != "": continue
		for option: Dictionary in EquipmentEconomy.bonus_options(weapon.category,milestone):
			var id := "%s|%d|%s" % [uid,milestone,option.id]
			_smith_confirm_action("%s %s" % [option.name,_smith_bonus_value(option)],"weapon_bonus",id,true,progress)
			if smith_confirm and smith_shop_selected == id:
				_add_description("%s %s. %s Escolha definitiva até evoluir a raridade desta arma." % [option.name,_smith_bonus_value(option),_smith_bonus_description(option.stat)])

func _weapon_instance_stats(progress: GameProgress, uid: String, rarity: String, level: int, choices: Dictionary) -> Dictionary:
	var candidate := GameProgress.new()
	candidate.attributes = progress.attributes.duplicate(true)
	candidate.equipment = progress.equipment.duplicate(true)
	candidate.weapon_instances = progress.weapon_instances.duplicate(true)
	candidate.talents = progress.talents
	candidate.abilities = progress.abilities
	candidate.etapa2_enabled = progress.etapa2_enabled
	candidate.equipped = progress.equipped.duplicate(true)
	candidate.equipped.Arma = str(candidate.weapon_instances[uid].category)
	candidate.equipped_weapon_uid = uid
	candidate.weapon_instances[uid].rarity = rarity
	candidate.weapon_instances[uid].level = level
	candidate.weapon_instances[uid].choices = choices.duplicate(true)
	return ArsenalRules.effective(candidate,str(candidate.weapon_instances[uid].category))

func _weapon_comparison(current: Dictionary, next: Dictionary, category: String) -> String:
	var damage_label := "Dano mágico" if category == "cajado" else "Dano físico"
	return "%s: %d → %d\nVida: %d → %d · Defesa: %d → %d\nVelocidade do ataque: %.2f → %.2f/s" % [damage_label,int(current.damage),int(next.damage),int(current.hp),int(next.hp),int(current.armor),int(next.armor),1.0/float(current.interval),1.0/float(next.interval)]

func _smith_bonus_value(option: Dictionary) -> String:
	return "+%s%%" % String.num(float(option.value)*100.0,1) if option.stat in ["critical","attack_speed"] else "+%d" % int(option.value)

func _smith_bonus_description(stat: String) -> String:
	return {"physical":"Aumenta o dano físico.","magical":"Aumenta o dano mágico.","critical":"Aumenta a chance de crítico.","attack_speed":"Reduz o intervalo do ataque básico.","hp":"Aumenta a vida máxima.","armor":"Aumenta a defesa.","spirit":"Aumenta o Espírito e a magia."}.get(stat,"")

func _smith_cost(recipe: Dictionary, progress: GameProgress) -> void:
	var box := _service_card(station_content)
	box.add_child(DiaryTheme.label("REQUISITOS",14))
	box.add_child(_forge_requirement("Ouro",progress.gold,int(recipe.gold)))
	for material: String in recipe.materials:
		box.add_child(_forge_requirement(material,int(progress.bag.get(material,0)),int(recipe.materials[material])))

func _smith_confirm_action(caption: String, action: String, payload: String, enabled: bool, progress: GameProgress) -> void:
	var button := _shop_action(("Confirmar · " if smith_confirm and smith_shop_selected == payload else "Selecionar · ")+caption,func():
		if smith_confirm and smith_shop_selected == payload:
			smith_confirm = false
			smith_shop_selected = ""
			station_action.emit(action,payload)
		else:
			smith_confirm = true
			smith_shop_selected = payload
			refresh_station(progress))
	button.disabled = not enabled
	DiaryTheme.primary(button)

func _smith_shop(progress: GameProgress) -> void:
	if progress.equipment.has(smith_shop_selected): smith_confirm = false
	if smith_confirm and ArsenalRules.CATEGORIES.has(smith_shop_selected):
		var chosen := smith_shop_selected
		var cost := GameProgress.starter_weapon_price(chosen)
		_add_description("Comprar %s por %d ouro?\nSerá equipada · saldo restante: %d ouro." % [RPGRules.EQUIPMENT[chosen].name,cost,progress.gold-cost])
		var confirm := _shop_action("Confirmar · %d ouro" % cost,func(): station_action.emit("buy_starter",chosen))
		confirm.disabled = not progress.can_buy_starter_weapon(chosen)
		DiaryTheme.primary(confirm)
		smith_shop_buttons["confirm"] = confirm
		var back := _shop_action("Voltar às armas",func():
			smith_confirm = false
			refresh_station(progress))
		smith_shop_buttons["back"] = back
		return
	_add_description("Armas iniciais")
	smith_grid = GridContainer.new()
	smith_grid.columns = 2
	smith_grid.add_theme_constant_override("h_separation",6)
	smith_grid.add_theme_constant_override("v_separation",6)
	station_content.add_child(smith_grid)
	for id: String in ArsenalRules.CATEGORIES: _smith_shop_weapon(id,progress)
	if not ArsenalRules.CATEGORIES.has(smith_shop_selected): return
	var chosen := smith_shop_selected
	var detail := _service_card(station_content)
	detail.add_child(DiaryTheme.label("%s · %s" % [RPGRules.EQUIPMENT[chosen].name,TalentRules.CLASSES[chosen]],16))
	detail.add_child(DiaryTheme.label(WEAPON_STYLES[chosen],13))
	var stats := ArsenalRules.effective(progress,chosen)
	var row := HBoxContainer.new()
	detail.add_child(row)
	for value: String in ["Dano\n%d" % stats.damage,"Alcance\n%.0f" % stats.reach,"%s\natq/s" % String.num(1.0/stats.interval,2).replace(".",",")]:
		var label := DiaryTheme.label(value,14)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(label)
	var buy := _shop_action("Comprar por %d ouro" % GameProgress.starter_weapon_price(chosen),func():
		smith_confirm = true
		station_scroll.scroll_vertical = 0
		refresh_station(progress))
	buy.disabled = not progress.can_buy_starter_weapon(chosen)
	DiaryTheme.primary(buy)
	smith_shop_buttons["purchase"] = buy
	_add_description("Confirmação antes da compra.")
	_focus_station_action.call_deferred(buy)

func _shop_action(caption: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 44
	button.pressed.connect(callback)
	station_content.add_child(button)
	return button

func _service_card(parent: Container) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",DiaryTheme.box(DiaryTheme.PAPER,Color("#bea16a"),8,1))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",4)
	panel.add_child(box)
	return box

func _focus_station_action(button: Button) -> void:
	await get_tree().process_frame
	if is_instance_valid(button) and station_panel.visible:
		station_scroll.ensure_control_visible(button)

func _smith_shop_weapon(id: String, progress: GameProgress) -> void:
	var price := GameProgress.starter_weapon_price(id)
	var owned := progress.equipment.has(id)
	var button := Button.new()
	button.custom_minimum_size = Vector2(0,86)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = owned
	button.tooltip_text = TalentRules.CLASSES[id]
	DiaryTheme.select(button,smith_shop_selected == id)
	button.pressed.connect(func():
		smith_shop_selected = id
		smith_confirm = false
		refresh_station(progress))
	smith_grid.add_child(button)
	var body := VBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 6
	body.offset_top = 5
	body.offset_right = -6
	body.offset_bottom = -5
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("separation",1)
	button.add_child(body)
	var icon := ITEM_ICON.new(id)
	icon.custom_minimum_size = Vector2(36,36)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.framed = false
	body.add_child(icon)
	for text: String in [ArsenalRules.category_name(id),"Equipada" if progress.equipped.Arma == id else "Na mochila" if owned else "%d ouro" % price]:
		var label := DiaryTheme.label(text,13)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if smith_shop_selected == id: label.add_theme_color_override("font_color",Color("#fff0ce"))
		body.add_child(label)
	smith_shop_buttons[id] = button

func _vendor_shop(progress: GameProgress) -> void:
	var tabs := HBoxContainer.new()
	station_content.add_child(tabs)
	for index in range(2):
		var button := Button.new()
		button.text = "Vender" if index == 0 else "Comprar"
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 44
		DiaryTheme.select(button,vendor_tab == index)
		button.pressed.connect(func():
			vendor_tab = index
			station_scroll.scroll_vertical = 0
			refresh_station(progress))
		tabs.add_child(button)
		vendor_tabs.append(button)
	_add_description("Na sua mochila" if vendor_tab == 0 else "Materiais à venda")
	var items: Array[String] = []
	if vendor_tab == 0:
		for item: String in progress.bag:
			if (GameProgress.SELL_ITEMS.has(item) or EquipmentEconomy.valid_item(item) and item != EquipmentEconomy.SEAL) and int(progress.bag[item]) > 0: items.append(item)
	else:
		for item: String in GameProgress.TRADE_ITEMS:
			for rarity: String in EquipmentEconomy.RARITY_ORDER: items.append(EquipmentEconomy.key(item,rarity))
		items.append(EquipmentEconomy.SEAL)
	for item: String in items: _vendor_item(item,progress)
	if items.is_empty(): _add_description("Nenhum material para vender.")
	_add_description("O valor é por unidade.")

func _vendor_item(item: String, progress: GameProgress) -> void:
	var card := _service_card(station_content)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",6)
	card.add_child(row)
	var icon := ITEM_ICON.new(item)
	icon.framed = false
	icon.custom_minimum_size = Vector2(32,32)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var caption := VBoxContainer.new()
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(caption)
	var item_meta := EquipmentEconomy.split_key(item)
	var item_title: String = item_meta.item + (" · "+ArsenalRules.RARITIES[item_meta.rarity].name if EquipmentEconomy.MATERIALS.has(item_meta.item) else "")
	var item_label := DiaryTheme.label(item_title,14)
	if EquipmentEconomy.MATERIALS.has(item_meta.item): item_label.add_theme_color_override("font_color",Color(ArsenalRules.RARITIES[item_meta.rarity].color))
	caption.add_child(item_label)
	caption.add_child(DiaryTheme.label("%d na mochila" % progress.bag.get(item,0),12))
	var action := "Comprar" if vendor_tab == 1 else "Vender"
	var button := Button.new()
	button.name = action+item
	button.text = "%s 1 · %d ouro" % [action,GameProgress.buy_price(item) if vendor_tab == 1 else GameProgress.sell_price(item)]
	button.custom_minimum_size = Vector2(112,44)
	button.add_theme_font_size_override("font_size",14)
	button.disabled = progress.gold < GameProgress.buy_price(item) if vendor_tab == 1 else int(progress.bag.get(item,0)) <= 0
	button.pressed.connect(func(): station_action.emit(action,item))
	DiaryTheme.primary(button)
	row.add_child(button)
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

func _touch_buttons(node: Node, event: InputEventScreenTouch) -> bool:
	if node is Control and node.clip_contents and not _touch_contains(node,event):
		return false
	if node is Button:
		return _activate_touch_button(node, event)
	var children := node.get_children()
	children.reverse()
	for child in children:
		if _touch_buttons(child, event):
			return true
	return false

func _qa_ui_state(kind: String) -> void:
	if not OS.has_feature("web"): return
	var root_node: Control = rpg_panel if kind == "evolution" else station_panel if kind == "blacksmith" else death_panel if kind == "death" else self
	var buttons: Array[Dictionary] = []
	var labels: Array[String] = []
	_qa_collect_buttons(root_node,buttons)
	_qa_collect_labels(root_node,labels)
	var joy_rect := joystick.get_global_rect()
	var interact_rect := interact_button.get_global_rect()
	var payload := {"screen":kind,"panel_visible":root_node.visible,"viewport":[size.x,size.y],"buttons":buttons,"labels":labels,
		"joystick":{"x":joy_rect.position.x,"y":joy_rect.position.y,"w":joy_rect.size.x,"h":joy_rect.size.y},
		"interact":{"visible":interact_button.visible,"caption":interact_button.caption.text,"x":interact_rect.position.x,"y":interact_rect.position.y,"w":interact_rect.size.x,"h":interact_rect.size.y}}
	if kind == "death": payload["death_result"] = death_result
	if kind == "blacksmith": payload["scroll_y"] = station_scroll.scroll_vertical
	var message := "ARVEON_UI2_STATE "+JSON.stringify(payload)
	JavaScriptBridge.eval("if(window.__ARVEON_UI2_TEST__===true) console.log("+JSON.stringify(message)+")")

func _qa_collect_buttons(node: Node, result: Array[Dictionary]) -> void:
	if node is Button and node.is_visible_in_tree():
		var button := node as Button
		var rect := button.get_global_rect()
		var local_y := minf(button.size.y * 0.5,22.0) if button.text in ["×","Fechar"] else button.size.y * 0.5
		# Screen touch InputEvents use the canvas space consumed by make_input_local.
		var touch_point := button.get_global_transform() * Vector2(button.size.x * 0.5,local_y)
		result.append({"text":button.text,"tooltip":button.tooltip_text,"disabled":button.disabled,"x":rect.position.x,"y":rect.position.y,"w":rect.size.x,"h":rect.size.y,"touch_x":touch_point.x,"touch_y":touch_point.y})
	for child in node.get_children():
		_qa_collect_buttons(child,result)

func _qa_collect_labels(node: Node, result: Array[String]) -> void:
	if node is Label and node.is_visible_in_tree():
		result.append((node as Label).text)
	for child in node.get_children():
		_qa_collect_labels(child,result)

func _begin_scroll(scroll: ScrollContainer, event: InputEventScreenTouch) -> void:
	if scroll_touch == -1 and _touch_contains(scroll,event):
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
	mission_prefix.visible = not active
	mission_hint_label.visible = not active
	mission_toggle.visible = not active
	if changed: _layout()
	if active:
		boss_name.text = "%s · Fase %d\nHP %d/%d" % [FloorConfig.tower_guardian_name(tower_trial.floor_id if tower_trial != null else 1), 2 if boss.health.current * 2 <= boss.health.maximum else 1, boss.health.current, boss.health.maximum]
		boss_bar.max_value = boss.health.maximum
		boss_bar.value = boss.health.current
