class_name BagPage
extends RefCounted

# Página "Mochila": abas, barra de espaço e grade de itens com moldura por raridade.
# Mostra só o que o jogador realmente tem; Vender fica na loja, e Organizar, Separar, lixeira e
# Expandir aparecem apagados até existirem.
const TABS := [["todos","Todos","bag"],["equipamentos","Equipamentos","shield"],["materiais","Materiais","leaf"],
	["consumiveis","Consumíveis","heart"],["outros","Outros","chest"]]
const CAPACITY := 80
const FILLER := 24

# Cada entrada: {"id","kind","icon","color","badge","name"}; kind: equipment | material | other.
static func entries(progress: GameProgress) -> Array:
	var result: Array = []
	for uid: String in progress.weapon_instances:
		var data := progress.weapon(uid)
		result.append({"id":uid,"kind":"equipment","icon":str(data.category),"color":MenuKit.rarity_color(str(data.rarity)),"badge":"+%d" % int(data.level) if int(data.level) > 0 else "","name":ArsenalRules.category_name(str(data.category))})
	for id: String in progress.equipment:
		if ArsenalRules.CATEGORIES.has(id):
			if not progress.weapon_instances.is_empty(): continue
		var meta := ArsenalRules.metadata(id)
		if meta.is_empty(): continue
		var level := int(progress.equipment[id])
		result.append({"id":id,"kind":"equipment","icon":str(meta.icon),"color":MenuKit.rarity_color(str(meta.rarity)),"badge":"+%d" % level if level > 0 else "","name":str(RPGRules.EQUIPMENT[id].name)})
	for key: String in progress.bag:
		var amount := int(progress.bag[key])
		if amount < 1: continue
		var split := EquipmentEconomy.split_key(key)
		var trophy: bool = LootRules.is_named(key) and (key == FloorCatalog.LOOT.fragment or FloorCatalog.LOOT.trophy.values().has(key))
		var other: bool = trophy or key == EquipmentEconomy.SEAL
		var color := MenuKit.rarity_color(str(split.rarity)) if EquipmentEconomy.MATERIALS.has(split.item) else Color("#8a7a4a") if other else Color("#5a7a4a")
		result.append({"id":key,"kind":"other" if other else "material","icon":str(split.item),"color":color,"badge":str(amount),"name":str(split.item)})
	return result

static func filtered(all: Array, tab: String) -> Array:
	var result: Array = []
	for entry: Dictionary in all:
		match tab:
			"todos": result.append(entry)
			"equipamentos": if entry.kind == "equipment": result.append(entry)
			"materiais": if entry.kind == "material": result.append(entry)
			"outros": if entry.kind == "other": result.append(entry)
	return result

static func build(progress: GameProgress, hp: int, hp_max: int, tab: String, on_tab: Callable, on_tile: Callable, on_nav: Callable) -> PanelContainer:
	var all := entries(progress)
	var shown := filtered(all,tab)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation",6)
	body.add_child(_tabs(tab,on_tab))
	body.add_child(_space(all.size()))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var holder := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0f1d15")
	style.border_color = Color("#2a3d30")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	holder.add_theme_stylebox_override("panel",style)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(holder)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation",4)
	grid.add_theme_constant_override("v_separation",4)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.add_child(grid)
	for entry: Dictionary in shown:
		var tile := MenuKit.item_tile(str(entry.icon),entry.color,str(entry.badge),UiScale.px(58))
		tile.tooltip_text = str(entry.name)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var button := Button.new()
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for state in ["normal","hover","pressed","focus"]: button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		button.set_meta("skin_done",true)
		button.pressed.connect(on_tile.bind(str(entry.kind),str(entry.id)))
		tile.add_child(button)
		grid.add_child(tile)
	for _i in range(maxi(0,FILLER - shown.size())):
		var empty := MenuKit.item_tile("",Color("#22342a"),"",UiScale.px(58))
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(empty)
	body.add_child(scroll)
	body.add_child(_actions())
	return MenuKit.page("Mochila","mochila",on_nav,body,progress,hp,hp_max)

static func _tabs(active: String, on_tab: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",3)
	for entry: Array in TABS:
		var button := Button.new()
		button.name = "BagTab_" + str(entry[0])
		button.text = str(entry[1])
		button.custom_minimum_size = Vector2(0,maxi(50,UiScale.px(54)))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var on: bool = str(entry[0]) == active
		DefeatView.style_button(button,"tab_on" if on else "tab",str(entry[2]),10,2,"tab_on")
		button.icon = MenuKit.bag_tab_icon(str(entry[2]))
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("h_separation",0)
		button.add_theme_constant_override("icon_max_width",24)
		button.add_theme_font_size_override("font_size",10)
		MenuKit.tighten(button)
		button.pressed.connect(on_tab.bind(str(entry[0])))
		row.add_child(button)
	return row

static func _space(used: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	row.add_child(DefeatView.text("Espaço  %d/%d" % [used,CAPACITY],16,DefeatView.CREAM))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = CAPACITY
	bar.value = mini(used,CAPACITY)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size.y = 12
	bar.set_meta("skin_done",true)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#4cc26a")
	var back := StyleBoxFlat.new()
	back.bg_color = Color("#1b2a21")
	back.border_color = Color("#10261b")
	back.set_border_width_all(1)
	bar.add_theme_stylebox_override("fill",fill)
	bar.add_theme_stylebox_override("background",back)
	row.add_child(bar)
	row.add_child(_disabled("Expandir","plus",86))
	return row

static func _actions() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",6)
	var trash := _disabled("","x",52)
	row.add_child(trash)
	var organize := _disabled("Organizar","scroll",0)
	organize.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(organize)
	var split := _disabled("Separar","up",0)
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(split)
	return row

static func _disabled(caption: String, icon_id: String, width: int) -> Button:
	var button := Button.new()
	button.text = caption
	button.disabled = true
	button.tooltip_text = "Em breve"
	button.custom_minimum_size = Vector2(width,44)
	DefeatView.style_button(button,"ghost",icon_id,14,1)
	button.add_theme_stylebox_override("disabled",DefeatArt.plate("dim",6))
	button.add_theme_color_override("font_disabled_color",Color("#b8b8a8"))
	return button
