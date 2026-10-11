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

func _init(value: GameProgress = null, selection: String = "", comparing: bool = false) -> void:
	progress = value
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	if value == null:
		return
	if selection.is_empty() or not progress.equipment.has(selection):
		for id: String in progress.equipment:
			_card(id)
	else:
		_details(selection,comparing)

func _style(color: Color) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = Color("#1b342c")
	result.border_color = color
	result.set_border_width_all(1)
	result.set_content_margin_all(7)
	return result

func _label(text: String, color: Color = Color("#e6dfc5"), font_size: int = 12) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color",color)
	label.add_theme_font_size_override("font_size",font_size)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _attributes(id: String) -> String:
	var values := ArsenalRules.effective(progress,id)
	if RPGRules.EQUIPMENT[id].slot == "Arma":
		return "Dano %d · %.2fs · %dpx" % [values.damage,values.interval,values.reach]
	var bonus := RPGRules.bonuses(id,int(progress.equipment[id]))
	return "HP %+d · Defesa %+d · Espírito %+d" % [bonus.hp,bonus.armor,bonus.spirit]

func _card(id: String) -> void:
	var meta := ArsenalRules.metadata(id)
	var rarity := ArsenalRules.rarity(id)
	var color := Color(rarity.color)
	var button := Button.new()
	button.custom_minimum_size.y = 72
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal",_style(color))
	button.add_theme_stylebox_override("hover",_style(color.lightened(0.2)))
	button.add_theme_stylebox_override("pressed",_style(Color("#e3c781")))
	button.pressed.connect(func(): selected.emit(id))
	add_child(button)
	cards[id] = button
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8
	row.offset_top = 5
	row.offset_right = -8
	row.offset_bottom = -5
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	row.add_child(PixelItemIcon.new(meta.icon,color))
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation",0)
	row.add_child(column)
	column.add_child(_label("%s +%d" % [RPGRules.EQUIPMENT[id].name,progress.equipment[id]],color,13))
	column.add_child(_label("%s · %s%s" % [ArsenalRules.category_name(id),rarity.name," · Equipado" if progress.equipped[RPGRules.EQUIPMENT[id].slot] == id else ""],color,11))
	column.add_child(_label(_attributes(id),Color("#ddd9c7"),11))

func _details(id: String, comparing: bool) -> void:
	var item: Dictionary = RPGRules.EQUIPMENT[id]
	var rarity := ArsenalRules.rarity(id)
	var color := Color(rarity.color)
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
		comparison.add_child(_label("%s: %+.2f" % [label,difference],Color("#90d49b") if good else Color("#ec9c91") if not is_zero_approx(difference) else Color("#c1c5b7"),11))
