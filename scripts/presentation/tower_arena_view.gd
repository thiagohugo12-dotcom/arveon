class_name TowerArenaView
extends Node2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
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

func _draw_gate(point: Vector2, label: String, open: bool) -> void:
	draw_rect(Rect2(point + Vector2(-43, -24), Vector2(86, 43)), Color("#2b3f35"))
	draw_rect(Rect2(point + Vector2(-39, -21), Vector2(78, 38)), Color("#a0a184"), false, 5)
	draw_rect(Rect2(point + Vector2(-29, -12), Vector2(58, 23)), Color("#c3ae70") if open else Color("#455c4d"))
	draw_rect(Rect2(point + Vector2(-17, -5), Vector2(34, 10)), Color("#e4cc86") if open else Color("#617b5c"))
	draw_string(ThemeDB.fallback_font, point + Vector2(-82 if open else -106, -31 if open else 38), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e4d8a3"))
