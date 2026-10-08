class_name ExplorationView
extends Node2D

var progress: GameProgress
var current_time := 0

func _draw() -> void:
	if progress == null:
		return
	var altar := Vector2(1060, 155)
	draw_rect(Rect2(altar - Vector2(24, 20), Vector2(48, 40)), Color("#4b5740"))
	draw_rect(Rect2(altar - Vector2(10, 30), Vector2(20, 44)), Color("#8a7854"))
	draw_string(ThemeDB.fallback_font, altar + Vector2(-54, -38), "Guardião · opcional", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#decb91"))
	for spot: Dictionary in Exploration.RESOURCE_SPOTS:
		if int(progress.harvested_until.get(spot.id, 0)) > current_time:
			continue
		_draw_resource(spot.position, spot.item)
	for cache: Dictionary in Exploration.HIDDEN_CHESTS:
		_draw_cache(cache.position, progress.opened_caches.has(cache.id))

func _draw_resource(at: Vector2, item: String) -> void:
	draw_rect(Rect2(at + Vector2(-13, 9), Vector2(26, 4)), Color("#172b23"))
	match item:
		"Ervas":
			draw_rect(Rect2(at + Vector2(-2, -5), Vector2(4, 15)), Color("#589250"))
			draw_rect(Rect2(at + Vector2(-10, -10), Vector2(9, 7)), Color("#83ae5c"))
			draw_rect(Rect2(at + Vector2(2, -13), Vector2(9, 8)), Color("#a1c66f"))
		"Cogumelos":
			for dx in [-7, 5]:
				draw_rect(Rect2(at + Vector2(dx, -2), Vector2(4, 12)), Color("#d8c9a4"))
				draw_rect(Rect2(at + Vector2(dx - 4, -8), Vector2(12, 6)), Color("#bb705a"))
		"Madeira":
			draw_rect(Rect2(at + Vector2(-12, -6), Vector2(24, 16)), Color("#614531"))
			draw_rect(Rect2(at + Vector2(-9, -3), Vector2(18, 4)), Color("#9a7147"))
			draw_rect(Rect2(at + Vector2(4, 3), Vector2(5, 4)), Color("#b48d5b"))
		"Pedras":
			draw_rect(Rect2(at + Vector2(-12, -2), Vector2(23, 12)), Color("#4d6767"))
			draw_rect(Rect2(at + Vector2(-6, -8), Vector2(14, 9)), Color("#82938c"))
			draw_rect(Rect2(at + Vector2(0, -8), Vector2(4, 5)), Color("#a7aaa0"))

func _draw_cache(at: Vector2, opened: bool) -> void:
	draw_rect(Rect2(at + Vector2(-13, 10), Vector2(28, 5)), Color("#1d2824"))
	draw_rect(Rect2(at + Vector2(-12, -6), Vector2(25, 17)), Color("#715431"))
	if opened:
		draw_rect(Rect2(at + Vector2(-12, -13), Vector2(25, 6)), Color("#a58853"))
		draw_rect(Rect2(at + Vector2(-8, -3), Vector2(17, 8)), Color("#2b3429"))
	else:
		draw_rect(Rect2(at + Vector2(-12, -10), Vector2(25, 5)), Color("#b59149"))
		draw_rect(Rect2(at + Vector2(-3, -8), Vector2(6, 16)), Color("#e1cb75"))
