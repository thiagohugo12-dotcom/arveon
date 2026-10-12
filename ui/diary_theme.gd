class_name DiaryTheme
extends RefCounted

const INK := Color("#493321")
const PAPER := Color("#f0dfb3")
const GREEN := Color("#356443")
const WOOD := Color("#815332")

static func box(fill := PAPER, edge := WOOD, margin: int = 8, border: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(border)
	style.set_content_margin_all(margin)
	if border >= 2:
		style.shadow_color = Color(0.20,0.13,0.07,0.25)
		style.shadow_size = 2
		style.shadow_offset = Vector2(2,2)
	return style

static func create() -> Theme:
	var result := Theme.new()
	result.default_font_size = 13
	for type: String in ["Label", "Button", "CheckButton"]:
		result.set_color("font_color", type, INK)
		result.set_color("font_hover_color", type, INK)
		result.set_color("font_pressed_color", type, Color("#fff0ce"))
		result.set_color("font_disabled_color", type, Color("#8c7d62"))
	result.set_constant("outline_size", "Label", 0)
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var fill := PAPER
		if state == "hover": fill = Color("#fff0cc")
		if state == "pressed": fill = GREEN
		if state == "disabled": fill = Color("#d7c79f")
		if state == "focus": fill = Color.TRANSPARENT
		result.set_stylebox(state,"Button",box(fill,Color("#b69459") if state != "focus" else GREEN,6))
	result.set_stylebox("panel","PanelContainer",box())
	result.set_stylebox("background","ProgressBar",box(Color("#b5a379"),WOOD,0,1))
	result.set_stylebox("fill","ProgressBar",box(GREEN,GREEN,0,0))
	result.set_stylebox("scroll","VScrollBar",box(Color("#dac69b"),Color("#dac69b"),0,0))
	result.set_stylebox("grabber","VScrollBar",box(Color("#a88450"),WOOD,0,1))
	result.set_stylebox("grabber_highlight","VScrollBar",box(GREEN,WOOD,0,1))
	result.set_stylebox("grabber_pressed","VScrollBar",box(GREEN,WOOD,0,1))
	result.set_constant("separation","VBoxContainer",8)
	result.set_constant("separation","HBoxContainer",8)
	return result

static func select(button: Button, selected: bool) -> void:
	button.add_theme_stylebox_override("normal",box(GREEN if selected else PAPER,WOOD,6))
	button.add_theme_color_override("font_color",Color("#fff0ce") if selected else INK)

static func label(text: String, font_size: int = 13) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",INK)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
