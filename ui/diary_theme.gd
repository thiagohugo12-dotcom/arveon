class_name DiaryTheme
extends RefCounted

const INK := Color("#493321")
const PAPER := Color("#f4e5bf")
const GREEN := Color("#2d5839")
const WOOD := Color("#815332")
const TITLE_FONT := preload("res://assets/fonts/CormorantGaramond.ttf")
static var title_font: FontVariation

static func heading_font() -> FontVariation:
	if title_font == null:
		title_font = FontVariation.new()
		title_font.base_font = TITLE_FONT
		title_font.variation_opentype = {0x77676874:700.0}
		title_font.variation_embolden = 0.25
	return title_font

const FRAMES := {
	"frame": preload("res://assets/art/diary_v3/frame.png"),
	"paper": preload("res://assets/art/diary_v3/paper.png"),
	"green": preload("res://assets/art/diary_v3/green.png"),
	"wood": preload("res://assets/art/diary_v3/wood.png"),
	"slot": preload("res://assets/art/diary_v3/slot.png"),
	"empty": preload("res://assets/art/diary_v3/empty.png")
}

static func piece(kind: String, margin: int = 8) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = FRAMES[kind]
	var edge := 20 if kind == "frame" else 9
	style.texture_margin_left = edge
	style.texture_margin_right = edge
	style.texture_margin_top = edge
	style.texture_margin_bottom = edge
	style.set_content_margin_all(margin)
	return style

static func primary(button: Button) -> void:
	button.add_theme_stylebox_override("normal",piece("green"))
	button.add_theme_stylebox_override("hover",piece("green"))
	button.add_theme_stylebox_override("pressed",piece("wood"))
	button.add_theme_color_override("font_color",Color("#fff0ce"))
	button.add_theme_color_override("font_hover_color",Color.WHITE)

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
	result.set_font("font","Button",heading_font())
	result.set_font_size("font_size","Button",17)
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
		result.set_stylebox(state,"Button",box(fill,GREEN,6,1) if state == "focus" else piece("green" if state == "pressed" else "empty" if state == "disabled" else "paper",8))
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
	if selected:
		button.add_theme_stylebox_override("normal",piece("green",10))
		button.add_theme_stylebox_override("hover",piece("green",10))
		button.add_theme_stylebox_override("pressed",piece("wood",10))
		button.add_theme_stylebox_override("focus",piece("green",10))
		button.add_theme_color_override("font_color",Color("#fff7dc"))
		button.add_theme_color_override("font_hover_color",Color.WHITE)
		button.add_theme_color_override("font_pressed_color",Color("#fff7dc"))
	else:
		button.add_theme_stylebox_override("normal",piece("paper",8))
		button.add_theme_stylebox_override("hover",piece("paper",8))
		button.add_theme_stylebox_override("pressed",piece("green",8))
		button.add_theme_stylebox_override("focus",piece("paper",8))
		button.add_theme_color_override("font_color",INK)
		button.add_theme_color_override("font_hover_color",INK)
		button.add_theme_color_override("font_pressed_color",Color("#fff0ce"))

static func label(text: String, font_size: int = 13) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",INK)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
