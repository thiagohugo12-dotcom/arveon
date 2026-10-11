class_name TowerView
extends Node2D

var visual_v2 := false
var unlocked := false
var nearby := false

func _ready() -> void:
	position = TowerEntrance.POSITION
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func set_state(available: bool, close: bool) -> void:
	if available != unlocked or close != nearby:
		unlocked = available
		nearby = close
		queue_redraw()

func _draw() -> void:
	if visual_v2:
		draw_texture_rect_region(FloorV2View.CAMP,Rect2(-42,-88,84,100),FloorV2View.PORTAL)
		var glow := Color("#52d2ad") if unlocked else Color("#304847")
		draw_rect(Rect2(-12,-45,24,38),glow)
		if unlocked:
			draw_rect(Rect2(-7,-25,14,6),Color("#9df0c1"))
		else:
			draw_rect(Rect2(-4,-29,8,10),Color("#dab16a"))
		draw_string(ThemeDB.fallback_font,Vector2(-52,-98),"Torre de Ascensão",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#344d3d"))
		if nearby: draw_rect(Rect2(-3,16,6,6),glow)
		return
	# Static geometry in the existing forest palette. No textures, particles,
	# per-frame animation or new gameplay effects.
	draw_rect(Rect2(-40, -5, 80, 18), Color("#819255"))
	draw_rect(Rect2(-38, -78, 76, 65), Color("#4b6254"))
	draw_rect(Rect2(-32, -74, 64, 59), Color("#939b83"))
	draw_rect(Rect2(-32,-74,64,7),Color("#bfc0a3"))
	for y in [-56,-28]:
		draw_rect(Rect2(-30,y,60,2),Color("#7e8971"))
	for x in [-34, -12, 10, 26]:
		draw_rect(Rect2(x, -87, 12, 13), Color("#b1b79a"))
	draw_rect(Rect2(-16, -49, 32, 42), Color("#26382e"))
	draw_rect(Rect2(-20, -53, 40, 5), Color("#ab9d6d"))
	for x in [-20, 16]:
		draw_rect(Rect2(x, -49, 4, 43), Color("#928960"))
	draw_rect(Rect2(-12, -45, 24, 38), Color("#3f9d83") if unlocked else Color("#243e34"))
	if unlocked:
		draw_rect(Rect2(-9,-12,18,5),Color("#78d5a8"))
	var rune := Color("#a1e3b2") if unlocked else Color("#8a9274")
	draw_rect(Rect2(-3, -66, 6, 9), rune)
	draw_rect(Rect2(-8, -63, 16, 3), rune)
	if not unlocked:
		draw_rect(Rect2(-14, -32, 28, 3), Color("#837650"))
		draw_rect(Rect2(-4, -36, 8, 10), Color("#ab9d6d"))
	for step in range(3):
		draw_rect(Rect2(-22 - step * 3, -6 + step * 4, 44 + step * 6, 4), Color("#918b63") if step % 2 == 0 else Color("#69745a"))
	# Roots join the entrance to the Mata without covering the main trail.
	for side in [-1, 1]:
		draw_rect(Rect2(27 * side - 3, -32, 6, 32), Color("#715536"))
		draw_rect(Rect2(32 * side - 6, -4, 12, 5), Color("#9a784a"))
	var font := ThemeDB.fallback_font
	var title := "Torre de Ascensão"
	draw_string(font, Vector2(-font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x * 0.5, -96), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#344d3d"))
	if nearby:
		draw_rect(Rect2(-3, 16, 6, 6), rune)
