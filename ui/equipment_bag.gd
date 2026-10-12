class_name EquipmentBag
extends VBoxContainer

signal selected(id: String)
signal action_requested(action: String, id: String)
signal compare_requested
var cards: Dictionary = {}
var equip_button: Button
var compare_button: Button
var back_button: Button
var comparison: VBoxContainer
var progress: GameProgress
var grid: GridContainer
var spread: BoxContainer
var profile: BoxContainer
var items_page: VBoxContainer
var profile_heading: Label
var detail_panel: PanelContainer
var portrait: DiaryPortrait

func _init(value: GameProgress = null, selection: String = "", comparing: bool = false) -> void:
	progress = value
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	if value == null:
		return
	_overview()
	for id: String in progress.equipment:
		_card(id)
	# Empty cells are presentation, never fake owned items or a capacity limit.
	for i in range(maxi(0,12-progress.equipment.size())):
		var empty := PanelContainer.new()
		empty.custom_minimum_size = Vector2(60,68)
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		empty.add_theme_stylebox_override("panel",DiaryTheme.piece("empty",0))
		grid.add_child(empty)
	resized.connect(_reflow)
	if not selection.is_empty() and progress.equipment.has(selection):
		_details(selection,comparing)
		DiaryTheme.select(cards[selection],true)
	else:
		var hint := PanelContainer.new()
		hint.add_theme_stylebox_override("panel",DiaryTheme.piece("paper",10))
		add_child(hint)
		hint.add_child(_label("Selecione um equipamento para ver os atributos e equipar.",DiaryTheme.INK,12))

func _style(color: Color) -> StyleBoxFlat:
	return DiaryTheme.box(Color("#e7d2a4"),color,7)

func _label(text: String, color: Color = DiaryTheme.INK, font_size: int = 12) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color",color)
	label.add_theme_font_size_override("font_size",font_size)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _overview() -> void:
	spread = BoxContainer.new()
	spread.vertical = true
	spread.add_theme_constant_override("separation",22)
	add_child(spread)
	items_page = VBoxContainer.new()
	items_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spread.add_child(items_page)
	grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",6)
	grid.add_theme_constant_override("v_separation",6)
	items_page.add_child(grid)
	profile = DiaryProfile.new()
	profile.vertical = true
	profile.custom_minimum_size.x = 230
	profile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spread.add_child(profile)
	profile_heading = _label("EXPLORADOR",DiaryTheme.GREEN,12)
	profile_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	profile.add_child(profile_heading)
	var portrait_row := HBoxContainer.new()
	portrait_row.alignment = BoxContainer.ALIGNMENT_CENTER
	profile.add_child(portrait_row)
	var slots := VBoxContainer.new()
	portrait_row.add_child(slots)
	for slot: String in ["Arma","Acessório"]:
		_equipped_slot(slot,slots)
	portrait = DiaryPortrait.new()
	portrait_row.add_child(portrait)
	var right_slots := VBoxContainer.new()
	portrait_row.add_child(right_slots)
	_equipped_slot("Armadura",right_slots)
	var summary := VBoxContainer.new()
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile.add_child(summary)
	var level := _label("Nv. %d" % progress.level(),DiaryTheme.INK,18)
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_child(level)
	var stats := progress.combat_stats()
	var attributes := HBoxContainer.new()
	summary.add_child(attributes)
	for stat: String in ["Dano","Defesa"]:
		var tile := PanelContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.add_theme_stylebox_override("panel",DiaryTheme.piece("paper",7))
		attributes.add_child(tile)
		var label := _label("%s   %d" % [stat,stats.damage if stat == "Dano" else stats.armor],DiaryTheme.INK,16)
		label.add_theme_font_override("font",DiaryTheme.heading_font())
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(label)

func _equipped_slot(slot: String, slots: VBoxContainer) -> void:
		var equipped: String = progress.equipped.get(slot,"")
		var button := Button.new()
		button.custom_minimum_size = Vector2(48,48)
		button.add_theme_stylebox_override("normal",DiaryTheme.piece("slot",0))
		button.tooltip_text = slot+": "+(RPGRules.EQUIPMENT[equipped].name if not equipped.is_empty() else "vazio")
		button.disabled = equipped.is_empty()
		if not equipped.is_empty(): button.pressed.connect(func(): selected.emit(equipped))
		slots.add_child(button)
		var icon := PixelItemIcon.new(ArsenalRules.metadata(equipped).icon if not equipped.is_empty() else slot)
		icon.framed = false
		icon.position = Vector2(6,6)
		icon.size = Vector2(36,36)
		icon.modulate.a = 1.0 if not equipped.is_empty() else 0.3
		button.add_child(icon)

func _reflow() -> void:
	if spread == null: return
	spread.vertical = size.x < 500
	profile.vertical = true
	profile_heading.visible = not spread.vertical
	(profile as DiaryProfile).split = not spread.vertical
	profile.queue_redraw()
	portrait.custom_minimum_size.y = 114 if spread.vertical else 118
	spread.move_child(profile,0 if spread.vertical else 1)
	grid.columns = 3 if spread.vertical else 4
	var visible_cells := maxi(progress.equipment.size(),6 if spread.vertical else 12)
	for i in range(grid.get_child_count()): grid.get_child(i).visible = i < visible_cells

func _attributes(id: String) -> String:
	var values := ArsenalRules.effective(progress,id)
	if RPGRules.EQUIPMENT[id].slot == "Arma":
		return "Dano %d · %.2fs · %dpx" % [values.damage,values.interval,values.reach]
	var bonus := RPGRules.bonuses(id,int(progress.equipment[id]))
	return "HP %+d · Defesa %+d · Espírito %+d" % [bonus.hp,bonus.armor,bonus.spirit]

func _card(id: String) -> void:
	var meta := ArsenalRules.metadata(id)
	var rarity := ArsenalRules.rarity(id)
	var color := Color(rarity.color).darkened(0.22)
	var button := Button.new()
	button.custom_minimum_size = Vector2(60,68)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal",DiaryTheme.piece("slot",0))
	button.add_theme_stylebox_override("hover",DiaryTheme.piece("paper",0))
	button.add_theme_stylebox_override("pressed",DiaryTheme.piece("green",0))
	button.pressed.connect(func(): selected.emit(id))
	grid.add_child(button)
	cards[id] = button
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation",0)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8
	row.offset_top = 5
	row.offset_right = -8
	row.offset_bottom = -5
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	var icon := PixelItemIcon.new(meta.icon,color)
	icon.framed = false
	icon.custom_minimum_size = Vector2(48,48)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var name_label := _label(RPGRules.EQUIPMENT[id].name,DiaryTheme.INK,11)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.hide()
	row.add_child(name_label)
	var equipped: bool = progress.equipped[RPGRules.EQUIPMENT[id].slot] == id
	var marker := _label("Equipado" if equipped else "+%d" % progress.equipment[id] if progress.equipment[id] > 0 else "",DiaryTheme.GREEN,10)
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(marker)
	button.tooltip_text = "%s · %s\n%s" % [RPGRules.EQUIPMENT[id].name,rarity.name,_attributes(id)]

func _details(id: String, comparing: bool) -> void:
	var item: Dictionary = RPGRules.EQUIPMENT[id]
	var rarity := ArsenalRules.rarity(id)
	var color := DiaryTheme.INK
	detail_panel = PanelContainer.new()
	detail_panel.add_theme_stylebox_override("panel",DiaryTheme.piece("paper",10))
	add_child(detail_panel)
	var detail := VBoxContainer.new()
	detail_panel.add_child(detail)
	var row := HBoxContainer.new()
	detail.add_child(row)
	back_button = Button.new()
	back_button.text = "<"
	back_button.tooltip_text = "Voltar aos equipamentos"
	back_button.custom_minimum_size = Vector2(44,44)
	back_button.pressed.connect(func(): selected.emit(""))
	var selection_header := HBoxContainer.new()
	add_child(selection_header)
	move_child(selection_header,0)
	selection_header.add_child(back_button)
	selection_header.add_child(_label("Equipamento selecionado",DiaryTheme.GREEN,12))
	row.add_child(PixelItemIcon.new(ArsenalRules.metadata(id).icon,color))
	row.add_child(_label("%s +%d\n%s · %s" % [item.name,progress.equipment[id],ArsenalRules.category_name(id),rarity.name],color,13))
	detail.add_child(_label(_attributes(id) + " · Nível %d" % ArsenalRules.metadata(id).level))
	var actions := HBoxContainer.new()
	detail.add_child(actions)
	equip_button = Button.new()
	equip_button.text = "Desequipar" if progress.equipped[item.slot] == id else "Equipar"
	equip_button.custom_minimum_size.y = 44
	equip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_button.pressed.connect(func(): action_requested.emit("unequip" if progress.equipped[item.slot] == id else "equip",item.slot if progress.equipped[item.slot] == id else id))
	actions.add_child(equip_button)
	DiaryTheme.primary(equip_button)
	compare_button = Button.new()
	compare_button.text = "Comparar" if not comparing else "Ocultar"
	compare_button.custom_minimum_size.y = 44
	compare_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	compare_button.pressed.connect(func(): compare_requested.emit())
	actions.add_child(compare_button)
	if not comparing:
		return
	comparison = VBoxContainer.new()
	comparison.add_theme_constant_override("separation",2)
	detail.add_child(comparison)
	var current: String = progress.equipped[item.slot]
	comparison.add_child(_label("Atual: " + (RPGRules.EQUIPMENT[current].name if not current.is_empty() else "nenhum")))
	var candidate := ArsenalRules.effective(progress,id)
	var before := progress.combat_stats()
	var config := ArsenalRules.profile(progress.equipped.Arma)
	before.reach = config.reach
	before.interval = maxf(0.25,config.interval * (1.0 - minf(0.25,int(progress.attributes.Agilidade)*0.01)))
	for key: String in ["damage","interval","reach","hp","armor","speed","spirit"]:
		var difference := float(candidate[key]) - float(before[key])
		var good := difference < 0 if key == "interval" else difference > 0
		var label: String = {"damage":"Dano","interval":"Intervalo (menor é melhor)","reach":"Alcance","hp":"HP","armor":"Defesa","speed":"Movimento","spirit":"Espírito"}[key]
		comparison.add_child(_label("%s: %+.2f" % [label,difference],DiaryTheme.GREEN if good else Color("#a13f30") if not is_zero_approx(difference) else DiaryTheme.INK,12))
