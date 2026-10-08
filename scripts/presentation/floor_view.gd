extends Node2D

# Static low-cost ground drawing, deliberately not a tiled debug grid.
const FOREST := Color("#1c382a")
const FOREST_LIGHT := Color("#244431")
const TRAIL := Color("#564b35")
const TRAIL_HIGHLIGHT := Color("#6d5a3d")
const ROCK := Color("#45554d")

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1200, 900), FOREST)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12051
	# Small tonal squares make a readable pixel-style floor.
	for x in range(0, 1200, 32):
		for y in range(0, 900, 32):
			if rng.randi_range(0, 4) == 0:
				draw_rect(Rect2(x + 4, y + 5, 24, 20), FOREST_LIGHT)
	# Compact crossing paths and a clearing around the initial player.
	draw_rect(Rect2(45, 404, 1110, 108), TRAIL)
	draw_rect(Rect2(500, 60, 110, 790), TRAIL)
	draw_rect(Rect2(55, 415, 1080, 13), TRAIL_HIGHLIGHT)
	draw_rect(Rect2(512, 72, 12, 760), TRAIL_HIGHLIGHT)
	draw_rect(Rect2(465, 355, 185, 200), Color("#476447"))
	for i in range(155):
		var px_pos := Vector2(rng.randi_range(23, 1175), rng.randi_range(25, 875))
		if Rect2(465, 350, 190, 205).has_point(px_pos):
			continue
		var green := Color("#396447") if i % 3 == 0 else Color("#31553b")
		draw_rect(Rect2(px_pos, Vector2(10, 7)), green)
		draw_rect(Rect2(px_pos + Vector2(3, -4), Vector2(4, 5)), Color("#6a8d57"))
	for i in range(80):
		var blade := Vector2(rng.randi_range(20, 1170), rng.randi_range(30, 870))
		draw_rect(Rect2(blade, Vector2(3, 6)), Color("#668952"))
		draw_rect(Rect2(blade + Vector2(5, -2), Vector2(3, 7)), Color("#426d4c"))
	# Visual rocks exactly match the two blocking CollisionShape2D rectangles.
	_draw_stone(Rect2(340, 300, 130, 50))
	_draw_stone(Rect2(760, 520, 90, 110))

func _draw_stone(area: Rect2) -> void:
	draw_rect(area, Color("#20362f"))
	draw_rect(area.grow(-4), ROCK)
	draw_rect(Rect2(area.position + Vector2(8, 7), area.size - Vector2(23, 22)), Color("#65786b"))
	draw_rect(Rect2(area.position + Vector2(11, 10), area.size * Vector2(0.35, 0.18)), Color("#879486"))
