class_name DefeatView
extends RefCounted

# Presentation-only builders for the Interface 2.0 defeat screen. They receive the
# result dictionary produced by Main from the existing penalty and never decide
# what is lost.
const INK := Color("#3a2416")
const MUTED := Color("#6b5538")
const RED := Color("#8e1c14")
const CREAM := Color("#f7e9c4")
const LINE := Color("#cdb77f")
const FLAVOR := "Suas aventuras ainda não terminaram. Você ficará mais forte."
# Monster index in Floor2MonsterView.SHEETS and the idle crop that frames it.
const PORTRAITS := {
	"Goblin Garimpeiro": {"sheet": 0, "region": Rect2(8,8,56,52)},
	"Tatu Rochoso": {"sheet": 1, "region": Rect2(4,20,64,40)},
	"Escorpião da Chapada": {"sheet": 2, "region": Rect2(8,8,56,52)}
}

static var _font: FontVariation

static func font() -> FontVariation:
	if _font == null:
		# Lining figures keep amounts like 120 or x1 readable; the shared heading font uses old-style digits.
		_font = FontVariation.new()
		_font.base_font = DiaryTheme.TITLE_FONT
		_font.variation_opentype = {0x77676874: 700.0}
		_font.variation_embolden = 0.25
		_font.opentype_features = {"lnum": 1}
	return _font

static func text(value: String, size: int, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font",font())
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

static func picture(id: String, scale: int = 2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = DefeatArt.texture(id,scale)
	rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	rect.custom_minimum_size = rect.texture.get_size()
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

static func card(kind: String, margin: int = 8) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",DefeatArt.plate(kind,margin))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel

static func divider() -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation",4)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var left := ColorRect.new()
	left.color = LINE
	left.custom_minimum_size = Vector2(0,2)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(left)
	line.add_child(picture("diamond",1))
	return line

static func title() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",-2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crest := picture("crest",2)
	crest.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	crest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crest.custom_minimum_size.x = 0
	column.add_child(crest)
	var plate := card("banner",6)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation",-6)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(inner)
	var first := text("VOCÊ FOI",20,CREAM)
	first.autowrap_mode = TextServer.AUTOWRAP_OFF
	first.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(first)
	var second_row := HBoxContainer.new()
	second_row.alignment = BoxContainer.ALIGNMENT_CENTER
	second_row.add_theme_constant_override("separation",6)
	second_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	second_row.add_child(picture("diamond",2))
	var second := text("DERROTADO",38,Color("#ee6a52"))
	second.autowrap_mode = TextServer.AUTOWRAP_OFF
	second.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	second.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	second.add_theme_color_override("font_outline_color",Color("#2a0a08"))
	second.add_theme_constant_override("outline_size",6)
	second_row.add_child(second)
	second_row.add_child(picture("diamond",2))
	inner.add_child(second_row)
	column.add_child(plate)
	return column

static func portrait(enemy: String) -> Control:
	var spec: Dictionary = PORTRAITS.get(enemy,{})
	if spec.is_empty():
		return picture("skull",4)
	var atlas := AtlasTexture.new()
	atlas.atlas = Floor2MonsterView.SHEETS[int(spec.sheet)]
	atlas.region = spec.region
	var rect := TextureRect.new()
	rect.texture = atlas
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.custom_minimum_size = (spec.region as Rect2).size*2.0
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

static func enemy_card(enemy: String) -> Control:
	var plate := card("paper",8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(row)
	row.add_child(portrait(enemy))
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.add_theme_constant_override("separation",0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(text("Derrotado por:",16,INK))
	column.add_child(text(enemy,24,RED))
	column.add_child(divider())
	column.add_child(text(FLAVOR,14,MUTED))
	row.add_child(column)
	return plate

static func section(icon: String, caption: String, scale: int = 1) -> Control:
	var plate := card("section",4)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(row)
	row.add_child(picture(icon,scale))
	var label := text(caption,16,CREAM)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	row.add_child(picture("diamond",1))
	return plate

static func slot(icon: Control) -> Control:
	var plate := card("slot",3)
	plate.custom_minimum_size = Vector2(40,40)
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	plate.add_child(icon)
	return plate

static func loss_row(icon: Control, caption: String, detail: String, value: String, zero: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(slot(icon))
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	names.add_theme_constant_override("separation",-2)
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.add_child(text(caption,17 if detail.is_empty() else 13,INK if detail.is_empty() else MUTED))
	if not detail.is_empty(): names.add_child(text(detail,17,INK))
	row.add_child(names)
	var amount := text(value,22,MUTED if zero else RED)
	amount.autowrap_mode = TextServer.AUTOWRAP_OFF
	amount.size_flags_horizontal = Control.SIZE_SHRINK_END
	amount.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(amount)
	return row

static func item_title(raw: String) -> String:
	var parts := raw.split("|")
	return parts[0] if parts.size() < 2 else "%s %s" % [parts[0],str(parts[1]).capitalize()]

static func losses(result: Dictionary) -> Control:
	var plate := card("paper",8)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation",4)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(rows)
	var gold := int(result.get("gold_lost",0))
	var xp := int(result.get("xp_lost",0))
	rows.add_child(loss_row(picture("coins",2),"Ouro perdido","","-%d" % gold if gold > 0 else "0",gold <= 0))
	rows.add_child(divider())
	rows.add_child(loss_row(picture("xp",2),"XP perdido","","-%d" % xp if xp > 0 else "0",xp <= 0))
	rows.add_child(divider())
	var count := int(result.get("item_count",0))
	var raw := str(result.get("item_lost",""))
	if count > 0 and not raw.is_empty():
		var icon := PixelItemIcon.new(raw.split("|")[0])
		icon.framed = false
		icon.custom_minimum_size = Vector2(32,32)
		rows.add_child(loss_row(icon,"Item perdido",item_title(raw),"x%d" % count,false))
	else:
		rows.add_child(loss_row(picture("bag",2),"Nenhum item perdido","","0",true))
	return plate

static func equipment(result: Dictionary) -> Control:
	var lost: Array = result.get("equipment_lost",[])
	var plate := card("bad" if not lost.is_empty() else "ok",6)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(row)
	row.add_child(picture("swords" if not lost.is_empty() else "shield",2))
	var label := text("Equipamento perdido: %s" % ", ".join(PackedStringArray(lost)) if not lost.is_empty() else "Nenhum equipamento foi perdido.",15,RED if not lost.is_empty() else Color("#24502f"))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return plate

static func return_card(floor_number: int) -> Control:
	var plate := card("paper",8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(row)
	row.add_child(picture("fire",3))
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.add_theme_constant_override("separation",0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(text("Retorno: Acampamento do Andar %d" % floor_number,17,INK))
	column.add_child(divider())
	column.add_child(text("Você será levado de volta ao acampamento deste andar.",14,MUTED))
	row.add_child(column)
	return plate

static func style_button(button: Button, kind: String, icon: String, size: int, icon_scale: int = 2, pressed_kind: String = "") -> void:
	button.add_theme_stylebox_override("normal",DefeatArt.plate(kind,8))
	button.add_theme_stylebox_override("hover",DefeatArt.plate(kind,8))
	button.add_theme_stylebox_override("pressed",DefeatArt.plate(pressed_kind if not pressed_kind.is_empty() else kind+"_down",8))
	button.add_theme_stylebox_override("focus",DefeatArt.plate(kind,8))
	button.add_theme_font_override("font",font())
	button.add_theme_font_size_override("font_size",size)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		button.add_theme_color_override(state,CREAM)
	button.add_theme_constant_override("h_separation",10)
	button.icon = DefeatArt.texture(icon,icon_scale)
