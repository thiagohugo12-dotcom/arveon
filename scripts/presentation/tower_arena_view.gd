class_name TowerArenaView
extends Node2D

const SANDSTONE := preload("res://assets/art/andar2/refined/sandstone-boulder.png")
const PILLAR := preload("res://assets/art/andar2/refined/ruin-pillar.png")
var floor_id := 1

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	if floor_id == 2:
		_draw_vale()
		return
	# Static stone courses, weathering, moss and roots; no lights or particles.
	draw_rect(Rect2(Vector2.ZERO, TowerTrial.SIZE), Color("#243b32"))
	for y in range(32, 508, 32):
		for x in range(32, 688, 40):
			var tone := Color("#69776d") if (x / 40 + y / 32) % 3 else Color("#607266")
			draw_rect(Rect2(x + 1, y + 1, 38, 30), tone)
			if (x + y) % 7 == 0:
				draw_rect(Rect2(x + 7, y + 8, 9, 3), Color("#849080"))
			if (x + y) % 11 == 0:
				draw_rect(Rect2(x + 4, y + 20, 18, 5), Color("#3b6246"))
	for rect: Rect2 in [Rect2(0, 0, 720, 32), Rect2(0, 508, 720, 32), Rect2(0, 0, 32, 540), Rect2(688, 0, 32, 540)]:
		draw_rect(rect, Color("#3b5047"))
		draw_rect(rect.grow(-5), Color("#869180"), false, 3)
	for x in [40, 640]:
		for y in [45, 170, 340, 470]:
			draw_polyline(PackedVector2Array([Vector2(x, y), Vector2(x + 13, y + 6), Vector2(x + 22, y + 20), Vector2(x + 10, y + 25)]), Color("#8c7958"), 5)
			draw_texture_rect(FloorView.BERRY, Rect2(x - 10, y - 8, 32, 26), false)
	draw_arc(Vector2(360, 270), 92, 0, TAU, 32, Color("#879584"), 3)
	draw_arc(Vector2(360, 270), 84, 0, TAU, 32, Color("#4b6654"), 2)
	for offset in [-28, 28]:
		draw_rect(Rect2(350 + offset, 261, 20, 18), Color("#526c5c"))
	_draw_gate(Vector2(360, 45), "Guardião da Mata", false)
	_draw_gate(Vector2(360, 484), "Saída para a Mata", true)

func _draw_vale() -> void:
	draw_rect(Rect2(Vector2.ZERO, TowerTrial.SIZE), Color("#7d704e"))
	for y in range(32, 508, 32):
		for x in range(32, 688, 40):
			var variant := (x / 40 + y / 32) % 4
			var tone: Color = [Color("#dfc48b"), Color("#e5ca91"), Color("#dcc18a"), Color("#e8ce97")][variant]
			draw_rect(Rect2(x + 1, y + 1, 38, 30), tone)
			if (x * 7 + y * 11) % 9 == 0:
				draw_rect(Rect2(x + 8, y + 11, 11, 2), Color("#c6a974"))
	for rect: Rect2 in [Rect2(0, 0, 720, 32), Rect2(0, 508, 720, 32),
		Rect2(0, 0, 32, 540), Rect2(688, 0, 32, 540)]:
		draw_rect(rect, Color("#a88154"))
		draw_rect(rect.grow(-5), Color("#f3d49a"), false, 3)
	for x in [65, 165, 555, 655]:
		for y in [48, 492]:
			draw_texture_rect(SANDSTONE, Rect2(x - 25, y - 26, 50, 37), false)
	for x in [52, 668]:
		for y in [150, 380]:
			draw_texture_rect(PILLAR, Rect2(x - 16, y - 44, 32, 56), false)
	draw_arc(Vector2(360, 270), 95, 0, TAU, 48, Color("#b99060"), 4)
	draw_arc(Vector2(360, 270), 88, 0, TAU, 48, Color("#f3d69d"), 2)
	for i in range(8):
		var point := Vector2(360, 270) + Vector2.RIGHT.rotated(i * TAU / 8) * 112
		draw_rect(Rect2(point - Vector2(3, 3), Vector2(6, 6)), Color("#b2895c"))
	_draw_vale_gate(Vector2(360, 45), "Guardião de Arenito", false)
	_draw_vale_gate(Vector2(360, 484), "Saída para o Vale", true)

func _draw_vale_gate(point: Vector2, label: String, open: bool) -> void:
	draw_rect(Rect2(point + Vector2(-43, -24), Vector2(86, 43)), Color("#8d6948"))
	draw_rect(Rect2(point + Vector2(-39, -21), Vector2(78, 38)), Color("#f2d69e"), false, 5)
	draw_rect(Rect2(point + Vector2(-29, -12), Vector2(58, 23)), Color("#f1ce8e") if open else Color("#69523b"))
	draw_rect(Rect2(point + Vector2(-17, -5), Vector2(34, 10)), Color("#ffe3a6") if open else Color("#a67749"))
	draw_string(ThemeDB.fallback_font, point + Vector2(-82 if open else -92, -31 if open else 38), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#fff0c9"))

func _draw_gate(point: Vector2, label: String, open: bool) -> void:
	draw_rect(Rect2(point + Vector2(-43, -24), Vector2(86, 43)), Color("#2b3f35"))
	draw_rect(Rect2(point + Vector2(-39, -21), Vector2(78, 38)), Color("#a0a184"), false, 5)
	draw_rect(Rect2(point + Vector2(-29, -12), Vector2(58, 23)), Color("#c3ae70") if open else Color("#455c4d"))
	draw_rect(Rect2(point + Vector2(-17, -5), Vector2(34, 10)), Color("#e4cc86") if open else Color("#617b5c"))
	draw_string(ThemeDB.fallback_font, point + Vector2(-82 if open else -106, -31 if open else 38), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e4d8a3"))
