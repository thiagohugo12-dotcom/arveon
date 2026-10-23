Warning: truncated output (original token count: 22083)
Total output lines: 1881

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
var death_scroll: ScrollContainer
var death_body: VBoxContainer
var death_details: VBoxContainer
var death_details_button: Button
var death_details_open := false
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
	death_panel.add_theme_stylebox_override("panel",DiaryTheme.piece("frame",18))
	add_child(death_panel)
	var death_column := VBoxContainer.new()
	death_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_column.offset_left = 16
	death_column.offset_top = 16
	death_column.offset_right = -16
	death_column.offset_bottom = -16
	death_column.add_theme_constant_override("separation",6)
	death_panel.add_child(death_column)
	var death_heading := DiaryTheme.label("VOCÊ FOI DERROTADO",26)
	death_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_heading.add_theme_font_override("font",DiaryTheme.heading_font())
	death_heading.add_theme_color_override("font_color",Color("#8b3328"))
	death_column.add_child(death_heading)
	death_scroll = ScrollContainer.new()
	death_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	death_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	death_column.add_child(death_scroll)
	death_body =…12083 tokens truncated…d = uid; smith_confirm = false; refresh_station(progress))
		picker.add_child(button)
	if not progress.weapon_instances.has(smith_instance_selected): return
	var uid := smith_instance_selected
	var weapon: Dictionary = progress.weapon(uid)
	var title := "%s · %s +%d" % [ArsenalRules.category_name(weapon.category),ArsenalRules.RARITIES[weapon.rarity].name,int(weapon.level)]
	_add_description(title)
	if page == "rarity":
		var recipe := EquipmentEconomy.rarity_recipe(weapon.rarity)
		if recipe.is_empty(): _add_description("Raridade máxima alcançada."); return
		var next_rarity: String = EquipmentEconomy.RARITY_ORDER[EquipmentEconomy.RARITY_ORDER.find(weapon.rarity)+1]
		_add_description("Nova raridade: %s · melhoria volta a +0; bônus escolhidos são reiniciados." % ArsenalRules.RARITIES[next_rarity].name)
		var current_stats := _weapon_instance_stats(progress,uid,weapon.rarity,int(weapon.level),weapon.choices)
		var next_stats := _weapon_instance_stats(progress,uid,next_rarity,0,{})
		_add_description(_weapon_comparison(current_stats,next_stats,weapon.category))
		_smith_cost(recipe,progress)
		_smith_confirm_action("Evoluir raridade", "evolve_weapon",uid,progress.can_evolve_weapon(uid),progress)
		var bonuses := Button.new()
		bonuses.text = ("− " if smith_bonus_expanded else "+ ")+"Bônus dos aprimoramentos"
		bonuses.custom_minimum_size.y = 44
		bonuses.pressed.connect(func(): smith_bonus_expanded = not smith_bonus_expanded; refresh_station(progress))
		station_content.add_child(bonuses)
		if smith_bonus_expanded: _smith_bonus_options(progress,uid,weapon)
	elif page == "enhance":
		if int(weapon.level) >= 20: _add_description("Aprimoramento máximo: +20."); return
		var recipe := EquipmentEconomy.enhance_recipe(int(weapon.level),weapon.rarity)
		_smith_cost(recipe,progress)
		var current_stats := _weapon_instance_stats(progress,uid,weapon.rarity,int(weapon.level),weapon.choices)
		var next_stats := _weapon_instance_stats(progress,uid,weapon.rarity,int(weapon.level)+1,weapon.choices)
		_add_description(_weapon_comparison(current_stats,next_stats,weapon.category))
		var chance: float = EquipmentEconomy.SUCCESS[int(weapon.level)]
		_add_description("+%d → +%d · %d%% de sucesso. Falha: %s." % [int(weapon.level),int(weapon.level)+1,roundi(chance*100),"pode baixar 1–2 níveis" if int(weapon.level) >= 15 else "baixa 1 nível" if int(weapon.level) >= 10 else "mantém o nível"])
		var seal := CheckButton.new()
		seal.text = "Usar Selo de Proteção (%d)" % progress.bag.get(EquipmentEconomy.SEAL,0)
		seal.button_pressed = smith_use_seal
		seal.disabled = int(progress.bag.get(EquipmentEconomy.SEAL,0)) == 0
		seal.toggled.connect(func(value: bool): smith_use_seal = value)
		station_content.add_child(seal)
		_smith_confirm_action("Tentar aprimorar", "enhance_weapon",uid,progress.can_enhance_weapon(uid),progress)
	else:
		_smith_bonus_options(progress,uid,weapon)

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

func _qa_ui_state(kind: String) -> void:
	if not OS.has_feature("web"): return
	var root_node: Control = rpg_panel if kind == "evolution" else station_panel if kind == "blacksmith" else death_panel if kind == "death" else self
	var buttons: Array[Dictionary] = []
	_qa_collect_buttons(root_node,buttons)
	var joy_rect := joystick.get_global_rect()
	var interact_rect := interact_button.get_global_rect()
	var payload := {"screen":kind,"panel_visible":root_node.visible,"viewport":[size.x,size.y],"buttons":buttons,
		"joystick":{"x":joy_rect.position.x,"y":joy_rect.position.y,"w":joy_rect.size.x,"h":joy_rect.size.y},
		"interact":{"visible":interact_button.visible,"caption":interact_button.caption.text,"x":interact_rect.position.x,"y":interact_rect.position.y,"w":interact_rect.size.x,"h":interact_rect.size.y}}
	if kind == "blacksmith": payload["scroll_y"] = station_scroll.scroll_vertical
	var message := "ARVEON_UI2_STATE "+JSON.stringify(payload)
	JavaScriptBridge.eval("if(window.__ARVEON_UI2_TEST__===true) console.log("+JSON.stringify(message)+")")

func _qa_collect_buttons(node: Node, result: Array[Dictionary]) -> void:
	if node is Button and node.is_visible_in_tree():
		var button := node as Button
		var rect := button.get_global_rect()
		result.append({"text":button.text,"tooltip":button.tooltip_text,"disabled":button.disabled,"x":rect.position.x,"y":rect.position.y,"w":rect.size.x,"h":rect.size.y})
	for child in node.get_children():
		_qa_collect_buttons(child,result)

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
	mission_prefix.visible = not active
	mission_hint_label.visible = not active
	mission_toggle.visible = not active
	if changed: _layout()
	if active:
		boss_name.text = "%s · Fase %d\nHP %d/%d" % [FloorConfig.tower_guardian_name(tower_trial.floor_id if tower_trial != null else 1), 2 if boss.health.current * 2 <= boss.health.maximum else 1, boss.health.current, boss.health.maximum]
		boss_bar.max_value = boss.health.maximum
		boss_bar.value = boss.health.current


