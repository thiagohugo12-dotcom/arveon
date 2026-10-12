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

func _init(value: GameProgress = null, selection: String = "", comparing: bool = false) -> void:
	progress = value
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	if value == null:
		return
	if selection.is_empty() or not progress.equipment.has(selection):
		_overview()
		for id: String in progress.equipment:
			_card(id)
		resized.connect(_reflow)
	else:
		_details(selection,comparing)

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
	add_child(spread)
	profile = BoxContainer.new()
	profile.custom_minimum_size.x = 180
	spread.add_child(profile)
	profile.add_child(DiaryPortrait.new())
	var summary := VBoxContainer.new()
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile.add_child(summary)
	summary.add_child(_label("Explorador · Nv. %d" % progress.level(),DiaryTheme.INK,15))
	for slot: String in ["Arma","Armadura"]:
		var equipped: String = progress.equipped.get(slot,"")
		summary.add_child(_label(RPGRules.EQUIPMENT[equipped].name if not equipped.is_empty() else slot+": vazio"))
	var stats := progress.combat_stats()
	summary.add_child(_label("Dano %d · Defesa %d" % [stats.damage,stats.armor]))
	var items := VBoxContainer.new()
	items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spread.add_child(items)
	items.add_child(_label("Seus equipamentos",DiaryTheme.INK,14))
	grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",6)
	grid.add_theme_constant_override("v_separation",6)
	items.add_child(grid)
	add_child(_label("Toque em um item para ver atributos, comparar e equipar."))

func _reflow() -> void:
	if spread == null: return
	spread.vertical = size.x < 460
	profile.vertical = not spread.vertical
	grid.columns = 3

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
	button.custom_minimum_size = Vector2(68,106)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal",_style(color))
	button.add_theme_stylebox_override("hover",_style(color.lightened(0.2)))
	button.add_theme_stylebox_override("pressed",_style(Color("#e3c781")))
	button.pressed.connect(func(): selected.emit(id))
	grid.add_child(button)
	cards[id] = button
	var row := VBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8
	row.offset_top = 5
	row.offset_right = -8
	row.offset_bottom = -5
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	var icon := PixelItemIcon.new(meta.icon,color)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var name_label := _label(RPGRules.EQUIPMENT[id].name,DiaryTheme.INK,11)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(name_label)
	var equipped: bool = progress.equipped[RPGRules.EQUIPMENT[id].slot] == id
	var marker := _label("Equipado" if equipped else "+%d · %s" % [progress.equipment[id],rarity.name],DiaryTheme.GREEN,10)
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(marker)
	button.tooltip_text = "%s · %s\n%s" % [RPGRules.EQUIPMENT[id].name,rarity.name,_attributes(id)]

func _details(id: String, comparing: bool) -> void:
	var item: Dictionary = RPGRules.EQUIPMENT[id]
	var rarity := ArsenalRules.rarity(id)
	var color := DiaryTheme.INK
	var row := HBoxContainer.new()
	add_child(row)
	back_button = Button.new()
	back_button.text = "‹"
	back_button.tooltip_text = "Voltar aos equipamentos"
	back_button.custom_minimum_size = Vector2(44,44)
	back_button.pressed.connect(func(): selected.emit(""))
	row.add_child(back_button)
	row.add_child(PixelItemIcon.new(ArsenalRules.metadata(id).icon,color))
	row.add_child(_label("%s +%d\n%s · %s" % [item.name,progress.equipment[id],ArsenalRules.category_name(id),rarity.name],color,13))
	add_child(_label(_attributes(id) + "\nRequisito: nível %d" % ArsenalRules.metadata(id).level))
	var actions := HBoxContainer.new()
	add_child(actions)
	equip_button = Button.new()
	equip_button.text = "Desequipar" if progress.equipped[item.slot] == id else "Equipar"
	equip_button.custom_minimum_size.y = 44
	equip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_button.pressed.connect(func(): action_requested.emit("unequip" if progress.equipped[item.slot] == id else "equip",item.slot if progress.equipped[item.slot] == id else id))
	actions.add_child(equip_button)
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
	add_child(comparison)
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
