class_name TowerView
extends Node2D

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
	# Static geometry in the existing forest palette. No textures, particles,
	# per-frame animation or new gameplay effects.
	draw_rect(Rect2(-40, -5, 80, 18), Color("#284333"))
	draw_rect(Rect2(-38, -78, 76, 65), Color("#26382e"))
	draw_rect(Rect2(-32, -74, 64, 59), Color("#68735a"))
	for y in [-70, -56, -42, -28]:
		draw_rect(Rect2(-30, y, 60, 2), Color("#465441"))
		for x in [-22, 0, 22]:
			draw_rect(Rect2(x + (6 if y == -56 or y == -28 else 0), y - 11, 2, 10), Color("#4d5c46"))
	for x in [-34, -12, 10, 26]:
		draw_rect(Rect2(x, -87, 12, 13), Color("#839071"))
	draw_rect(Rect2(-16, -49, 32, 42), Color("#26382e"))
	draw_rect(Rect2(-20, -53, 40, 5), Color("#ab9d6d"))
	for x in [-20, 16]:
		draw_rect(Rect2(x, -49, 4, 43), Color("#928960"))
	draw_rect(Rect2(-12, -45, 24, 38), Color("#365344") if unlocked else Color("#182d24"))
	var rune := Color("#e4c87f") if unlocked else Color("#7a8a6d")
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
	draw_string(font, Vector2(-font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x * 0.5, -96), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#f1dfaa"))
	if nearby:
		draw_rect(Rect2(-3, 16, 6, 6), rune)
