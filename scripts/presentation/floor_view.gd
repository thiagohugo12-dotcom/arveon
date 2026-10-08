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
	_draw_camp()

func _draw_camp() -> void:
	var area := SafeCamp.AREA
	draw_rect(area.grow(5), Color("#253627"))
	draw_rect(area, Color("#92794c"))
	draw_rect(area.grow(-8), Color("#667750"))
	for x in range(482, 646, 16):
		draw_rect(Rect2(x, 363, 8, 6), Color("#bead72"))
		draw_rect(Rect2(x, 541, 8, 6), Color("#bead72"))
	for y in range(379, 540, 20):
		draw_rect(Rect2(472, y, 6, 9), Color("#bead72"))
		draw_rect(Rect2(642, y, 6, 9), Color("#bead72"))
	# Pixel shapes for the chest, forge and vendor stall; labels follow the same HUD font.
	_draw_station(SafeCamp.STATIONS["Baú"], Color("#6e4b29"), Color("#d5b369"))
	_draw_station(SafeCamp.STATIONS["Ferreiro"], Color("#424849"), Color("#ed9c46"))
	_draw_station(SafeCamp.STATIONS["Vendedor"], Color("#365b4b"), Color("#d7c87b"))
	_draw_npc(Vector2(606, 423), Color("#637587"), Color("#764e37"))
	_draw_npc(Vector2(606, 475), Color("#9b6947"), Color("#dbc079"))
	draw_rect(Rect2(526, 420, 27, 9), Color("#604734"))
	draw_rect(Rect2(530, 411, 20, 12), Color("#de8d4b"))
	draw_rect(Rect2(534, 407, 12, 10), Color("#f2c26b"))

func _draw_station(at: Vector2, base: Color, accent: Color) -> void:
	draw_rect(Rect2(at + Vector2(-15, -11), Vector2(30, 27)), Color("#273027"))
	draw_rect(Rect2(at + Vector2(-13, -14), Vector2(26, 24)), base)
	draw_rect(Rect2(at + Vector2(-10, -10), Vector2(20, 6)), accent)
	draw_rect(Rect2(at + Vector2(-4, -7), Vector2(8, 12)), accent.darkened(0.3))

func _draw_npc(at: Vector2, tunic: Color, hat: Color) -> void:
	draw_rect(Rect2(at + Vector2(-9, 12), Vector2(7, 5)), Color("#253228"))
	draw_rect(Rect2(at + Vector2(3, 12), Vector2(7, 5)), Color("#253228"))
	draw_rect(Rect2(at + Vector2(-10, -3), Vector2(20, 16)), tunic)
	draw_rect(Rect2(at + Vector2(-7, -14), Vector2(14, 11)), Color("#c79d71"))
	draw_rect(Rect2(at + Vector2(-10, -18), Vector2(20, 5)), hat)
	draw_rect(Rect2(at + Vector2(-6, -7), Vector2(3, 3)), Color("#212a28"))
	draw_rect(Rect2(at + Vector2(3, -7), Vector2(3, 3)), Color("#212a28"))

func _draw_stone(area: Rect2) -> void:
	draw_rect(area, Color("#20362f"))
	draw_rect(area.grow(-4), ROCK)
	draw_rect(Rect2(area.position + Vector2(8, 7), area.size - Vector2(23, 22)), Color("#65786b"))
	draw_rect(Rect2(area.position + Vector2(11, 10), area.size * Vector2(0.35, 0.18)), Color("#879486"))
