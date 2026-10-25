class_name ForgeView
extends RefCounted

# Presentation-only components for the Interface 2.0 Blacksmith. They are built
# from values the HUD reads from GameProgress and EquipmentEconomy; nothing here
# decides costs, chances or results.
const GOOD := Color("#7be07a")
const BAD := Color("#ff8a7a")
const GOLD := Color("#f0d890")
const RAISED := Color("#24502f")

static func icon(item: String, size: int = 32) -> Control:
	var node := PixelItemIcon.new(item)
	node.framed = false
	node.custom_minimum_size = Vector2(UiScale.px(size),UiScale.px(size))
	node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return node

static func rarity_color(rarity: String) -> Color:
	return Color(str(ArsenalRules.RARITIES[rarity].color)).darkened(0.45)

static func tab_bar(host: HBoxContainer, selected: int, on_pick: Callable) -> void:
	for child in host.get_children():
		host.remove_child(child)
		child.queue_free()
	var names := ["Forjar","Aprimorar","Evoluir"]
	var icons := ["hammer","up","star"]
	for index in range(3):
		var tab := Button.new()
		tab.text = names[index]
		tab.custom_minimum_size = Vector2(0,maxi(40,UiScale.px(46)))
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		DefeatView.style_button(tab,"tab_on" if index == selected else "tab",icons[index],17,2,"tab_on")
		tab.add_theme_constant_override("h_separation",6)
		tab.pressed.connect(on_pick.bind(index))
		host.add_child(tab)

static func style_close(button: Button, forge: bool) -> void:
	if forge:
		DefeatView.style_button(button,"close","x",1,2)
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
			button.add_theme_color_override(state,Color.TRANSPARENT)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		for name in ["normal","hover","pressed","focus"]: button.remove_theme_stylebox_override(name)
		for name in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: button.remove_theme_color_override(name)
		button.remove_theme_font_override("font")
		button.remove_theme_font_size_override("font_size")
		button.remove_theme_constant_override("h_separation")
		button.icon = null

static func picker(items: Array, selected: String, on_pick: Callable, buttons: Dictionary, columns: int = 2, strip: bool = false) -> Control:
	if strip:
		return _picker_strip(items, selected, on_pick, buttons)
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation",6)
	grid.add_theme_constant_override("v_separation",6)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for item: Dictionary in items:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0,maxi(42,UiScale.px(54)))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var plate := "item_on" if str(item.id) == selected else "item"
		for state in ["normal","hover","focus"]: button.add_theme_stylebox_override(state,DefeatArt.plate(plate,4))
		button.add_theme_stylebox_override("pressed",DefeatArt.plate("item_on",4))
		button.pressed.connect(on_pick.bind(str(item.id)))
		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 4
		row.offset_right = -4
		row.add_theme_constant_override("separation",6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(row)
		row.add_child(DefeatView.slot(icon(str(item.get("icon",item.id)),30)))
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		column.add_theme_constant_override("separation",-3)
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(DefeatView.text(str(item.title),16,DefeatView.INK))
		var sub := str(item.get("sub",""))
		if not sub.is_empty(): column.add_child(DefeatView.text(sub,14,item.get("color",DefeatView.MUTED)))
		row.add_child(column)
		if bool(item.get("tag",false)):
			var tag := DefeatView.text("E",13,Color.WHITE)
			tag.size_flags_horizontal = Control.SIZE_SHRINK_END
			tag.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			tag.autowrap_mode = TextServer.AUTOWRAP_OFF
			tag.add_theme_stylebox_override("normal",DefeatArt.plate("chip_on",1))
			tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tag.custom_minimum_size = Vector2(18,18)
			tag.size_flags_horizontal = Control.SIZE_SHRINK_END
			row.add_child(tag)
		grid.add_child(button)
		buttons[str(item.id)] = button
	return grid

# Vertical: as armas ficam numa faixa de cartões compactos (ícone, nome e nível) que
# quebra de linha só se houver muitas, em vez de uma lista que ocupa a tela toda.
static func _picker_strip(items: Array, selected: String, on_pick: Callable, buttons: Dictionary) -> Control:
	var flow := GridContainer.new()
	flow.columns = clampi(items.size(),1,5)
	flow.add_theme_constant_override("h_separation",4)
	flow.add_theme_constant_override("v_separation",4)
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for item: Dictionary in items:
		var card := Button.new()
		card.custom_minimum_size = Vector2(UiScale.px(48),UiScale.px(78))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var plate := "item_on" if str(item.id) == selected else "item"
		for state in ["normal","hover","focus"]: card.add_theme_stylebox_override(state,DefeatArt.plate(plate,3))
		card.add_theme_stylebox_override("pressed",DefeatArt.plate("item_on",3))
		card.pressed.connect(on_pick.bind(str(item.id)))
		var column := VBoxContainer.new()
		column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		column.offset_left = 2
		column.offset_right = -2
		column.offset_top = 3
		column.offset_bottom = -2
		column.add_theme_constant_override("separation",0)
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(column)
		var art := DefeatView.slot(icon(str(item.get("icon",item.id)),28))
		art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(art)
		var title := DefeatView.text(str(item.title),13,DefeatView.INK)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.autowrap_mode = TextServer.AUTOWRAP_OFF
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		column.add_child(title)
		var sub := str(item.get("sub",""))
		if not sub.is_empty():
			var detail := DefeatView.text(sub,11,item.get("color",DefeatView.MUTED))
			detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			detail.autowrap_mode = TextServer.AUTOWRAP_OFF
			detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			column.add_child(detail)
		if bool(item.get("tag",false)):
			var tag := DefeatView.text("E",11,Color.WHITE)
			tag.autowrap_mode = TextServer.AUTOWRAP_OFF
			tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tag.add_theme_stylebox_override("normal",DefeatArt.plate("chip_on",1))
			tag.custom_minimum_size = Vector2(15,15)
			tag.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			tag.offset_top = 2
			tag.offset_right = -2
			tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(tag)
		flow.add_child(card)
		buttons[str(item.id)] = card
	return flow

static func chips(options: Array, selected: String, on_pick: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for option: Dictionary in options:
		var chip := Button.new()
		chip.text = str(option.title)
		chip.custom_minimum_size = Vector2(0,maxi(36,UiScale.px(40)))
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var on := str(option.id) == selected
		for state in ["normal","hover","pressed","focus"]: chip.add_theme_stylebox_override(state,DefeatArt.plate("chip_on" if on else "chip",3))
		chip.add_theme_font_override("font",DefeatView.font())
		chip.add_theme_font_size_override("font_size",13)
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
			chip.add_theme_color_override(state,DefeatView.CREAM if on else option.get("color",DefeatView.INK))
		chip.pressed.connect(on_pick.bind(str(option.id)))
		row.add_child(chip)
	return row

static func badge_slot(item: String, badge: String, color: Color) -> Control:
	var plate := DefeatView.card("slot",0)
	plate.custom_minimum_size = Vector2(UiScale.px(62),UiScale.px(62))
	var stack := Control.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(stack)
	var art := icon(item,42)
	art.position = Vector2(UiScale.px(8),UiScale.px(4))
	stack.add_child(art)
	var label := DefeatView.text(badge,15,color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_color_override("font_outline_color",Color("#1b0f08"))
	label.add_theme_constant_override("outline_size",5)
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	label.offset_right = -4
	label.offset_bottom = -2
	stack.add_child(label)
	return plate

static func compare_card(item: String, title: String, subtitle: String, from_badge: String, to_badge: String, from_color: Color, to_color: Color) -> Control:
	var plate := DefeatView.card("item",8)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(column)
	column.add_child(DefeatView.text(title,20,DefeatView.INK))
	if not UiScale.compact and not UiScale.dense: column.add_child(DefeatView.text(subtitle,14,DefeatView.MUTED))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(badge_slot(item,from_badge,from_color))
	var arrow := DefeatView.text("➜",30,Color("#8a7a5a"))
	arrow.autowrap_mode = TextServer.AUTOWRAP_OFF
	arrow.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_child(arrow)
	row.add_child(badge_slot(item,to_badge,to_color))
	column.add_child(row)
	return plate

static func stat_table(rows: Array) -> Control:
	var plate := DefeatView.card("item",6)
	var box: Container
	if UiScale.compact:
		# Horizontal: os quatro atributos em duas colunas, para ocupar metade da altura.
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation",14)
		grid.add_theme_constant_override("v_separation",1)
		box = grid
	else:
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation",2)
		box = column
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(box)
	for row: Dictionary in rows:
		var line := HBoxContainer.new()
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_theme_constant_override("separation",6)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var art := DefeatView.picture(str(row.icon),int(row.get("scale",1)))
		art.custom_minimum_size = Vector2(20,20)
		line.add_child(art)
		line.add_child(DefeatView.text(str(row.name),15,DefeatView.INK))
		var now := DefeatView.text(str(row.now),15,DefeatView.MUTED)
		now.autowrap_mode = TextServer.AUTOWRAP_OFF
		now.size_flags_horizontal = Control.SIZE_SHRINK_END
		line.add_child(now)
		var better := bool(row.better)
		var arrow := DefeatView.text("➜",12,RAISED if better else Color("#a8956a"))
		arrow.autowrap_mode = TextServer.AUTOWRAP_OFF
		arrow.size_flags_horizontal = Control.SIZE_SHRINK_END
		line.add_child(arrow)
		var then := DefeatView.text(str(row.next),16,RAISED if better else DefeatView.MUTED)
		then.autowrap_mode = TextServer.AUTOWRAP_OFF
		then.size_flags_horizontal = Control.SIZE_SHRINK_END
		then.custom_minimum_size.x = 44
		line.add_child(then)
		box.add_child(line)
	return plate

static func chance(percent: int) -> Control:
	var plate := DefeatView.card("section",6)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(row)
	row.add_child(DefeatView.picture("clover",2))
	var caption := DefeatView.text("Chance de Sucesso",17,DefeatView.CREAM)
	caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(caption)
	var value := DefeatView.text("%d%%" % percent,30,GOOD if percent >= 50 else Color("#ffd27a") if percent >= 30 else BAD)
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	value.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(value)
	return plate

static func danger(title: String, body: String) -> Control:
	var plate := DefeatView.card("danger",8)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(column)
	column.add_child(DefeatView.text(title,17,Color("#ff9f6b")))
	column.add_child(DefeatView.text(body,14,Color("#f1d0c0")))
	return plate

static func note(title: String, body: String) -> Control:
	var plate := DefeatView.card("note",8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(row)
	row.add_child(DefeatView.picture("diamond",3))
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(DefeatView.text(title,17,GOLD))
	column.add_child(DefeatView.text(body,14,DefeatView.CREAM))
	row.add_child(column)
	return plate

static func materials(requirements: Array) -> Control:
	var grid := HBoxContainer.new()
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("separation",6)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for need: Dictionary in requirements:
		var plate := DefeatView.card("slot",4)
		plate.custom_minimum_size.x = UiScale.px(88)
		if requirements.size() >= 3: plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation",0)
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_child(column)
		column.add_child(icon(str(need.item),32))
		var name := DefeatView.text(str(need.name),13,DefeatView.CREAM)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(name)
		var enough := int(need.have) >= int(need.need)
		var amount := DefeatView.text("%d / %d" % [int(need.have),int(need.need)],19,GOOD if enough else BAD)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		amount.autowrap_mode = TextServer.AUTOWRAP_OFF
		column.add_child(amount)
		grid.add_child(plate)
	return grid

static func gold_row(have: int, need: int) -> Control:
	var plate := DefeatView.card("item",6)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(row)
	row.add_child(DefeatView.picture("coins",2))
	var caption := DefeatView.text("Custo em Ouro",17,DefeatView.INK)
	caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(caption)
	var value := DefeatView.text("%d" % need,22,DefeatView.INK if have >= need else DefeatView.RED)
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	value.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(value)
	return plate

static func protection(count: int, active: bool, effect: String, on_toggle: Callable) -> Control:
	var plate := DefeatView.card("item",6)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(row)
	row.add_child(DefeatView.slot(DefeatView.picture("shield",2)))
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.add_theme_constant_override("separation",-2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(DefeatView.text(EquipmentEconomy.SEAL,17,DefeatView.INK))
	column.add_child(DefeatView.text(effect,12,DefeatView.MUTED))
	column.add_child(DefeatView.text("Possui: %d" % count,13,DefeatView.INK))
	row.add_child(column)
	var button := Button.new()
	button.text = "Selecionado" if active else "Selecionar"
	button.custom_minimum_size = Vector2(92,40)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.disabled = count <= 0
	DefeatView.style_button(button,"button","shield",14,1)
	button.add_theme_stylebox_override("disabled",DefeatArt.plate("dim",8))
	button.icon = null
	button.pressed.connect(on_toggle)
	if active: button.add_theme_stylebox_override("normal",DefeatArt.plate("button_down",8))
	row.add_child(button)
	return plate

static func action_button(caption: String, icon_id: String, enabled: bool) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0,maxi(44,UiScale.px(56)))
	button.disabled = not enabled
	DefeatView.style_button(button,"button",icon_id,24,2)
	button.add_theme_stylebox_override("disabled",DefeatArt.plate("dim",8))
	button.add_theme_color_override("font_disabled_color",Color("#b8b8a8"))
	return button
