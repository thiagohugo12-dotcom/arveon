class_name FloorView
extends Node2D

# Static low-cost ground drawing, deliberately not a tiled debug grid.
const FOREST := Color("#1c382a")
const FOREST_LIGHT := Color("#244431")
const TRAIL := Color("#564b35")
const TRAIL_HIGHLIGHT := Color("#6d5a3d")
const ROCK := Color("#45554d")
const ROCKS := [Rect2(340, 300, 130, 50), Rect2(760, 520, 90, 110)]
const TRAILS := [
	[Vector2(40, 450), Vector2(240, 445), Vector2(360, 480), Vector2(545, 458), Vector2(720, 445), Vector2(880, 485), Vector2(1160, 455)],
	[Vector2(550, 50), Vector2(555, 220), Vector2(540, 400), Vector2(570, 550), Vector2(540, 690), Vector2(560, 860)],
	[Vector2(240, 445), Vector2(205, 360), Vector2(170, 225), Vector2(95, 145)],
	[Vector2(560, 390), Vector2(660, 250), Vector2(800, 165), Vector2(905, 90)],
	[Vector2(530, 520), Vector2(405, 625), Vector2(230, 700), Vector2(120, 735)],
	[Vector2(690, 505), Vector2(830, 680), Vector2(1040, 740), Vector2(1100, 790)],
	[Vector2(890, 480), Vector2(1010, 360), Vector2(1080, 335)]
]
const TRAIL_WIDTHS := [62.0, 54.0, 24.0, 24.0, 26.0, 26.0, 22.0]
const RESERVED := [Vector2(850, 400), Vector2(930, 440), Vector2(610, 750),
	Vector2(180, 460), Vector2(630, 135), Vector2(955, 665)]

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1200, 900), FOREST)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12051
	# Small tonal squares make a readable pixel-style floor.
	for x in range(0, 1200, 32):
		for y in range(0, 900, 32):
			if rng.randi_range(0, 4) == 0:
				draw_rect(Rect2(x + 4, y + 5, 24, 20), FOREST_LIGHT)
	# Meandering routes and branches keep all points of interest walkable.
	for center: Vector2 in [Vector2(175, 215), Vector2(260, 685), Vector2(900, 175), Vector2(980, 715)]:
		draw_rect(Rect2(center - Vector2(39, 31), Vector2(78, 62)), Color("#34513a"))
		draw_rect(Rect2(center - Vector2(31, 25), Vector2(62, 50)), Color("#45513a"))
	for i in range(TRAILS.size()):
		draw_polyline(PackedVector2Array(TRAILS[i]), TRAIL, TRAIL_WIDTHS[i], false)
		# Broken, integer ground accents avoid a continuous bright seam on vertical paths.
		var trail: Array = TRAILS[i]
		for j in range(trail.size() - 1):
			var distance: float = trail[j].distance_to(trail[j + 1])
			for n in range(0, int(distance), 36):
				var point: Vector2 = trail[j].lerp(trail[j + 1], float(n) / distance).floor()
				draw_rect(Rect2(point, Vector2(5, 3)), TRAIL_HIGHLIGHT)
	draw_rect(Rect2(465, 355, 185, 200), Color("#476447"))
	for i in range(205):
		var px_pos := Vector2(rng.randi_range(30, 1160), rng.randi_range(30, 865))
		if not _free_for_decoration(px_pos):
			continue
		match i % 4:
			0, 1:
				_draw_tree(px_pos, i % 2 == 0)
			2:
				draw_rect(Rect2(px_pos, Vector2(13, 8)), Color("#315a3b"))
				draw_rect(Rect2(px_pos + Vector2(3, -5), Vector2(8, 8)), Color("#63894e"))
			3:
				draw_rect(Rect2(px_pos, Vector2(18, 5)), Color("#684d34"))
				draw_rect(Rect2(px_pos + Vector2(4, -3), Vector2(12, 3)), Color("#9c7850"))
	for i in range(65):
		var blade := Vector2(rng.randi_range(20, 1170), rng.randi_range(30, 870))
		if not _free_for_decoration(blade):
			continue
		draw_rect(Rect2(blade, Vector2(3, 6)), Color("#668952"))
		draw_rect(Rect2(blade + Vector2(5, -2), Vector2(3, 7)), Color("#426d4c"))
	# Visual rocks exactly match the two blocking CollisionShape2D rectangles.
	for rock: Rect2 in ROCKS:
		_draw_stone(rock)
	_draw_camp()

func _free_for_decoration(at: Vector2) -> bool:
	if SafeCamp.AREA.grow(26).has_point(at):
		return false
	for rock: Rect2 in ROCKS:
		if rock.grow(18).has_point(at):
			return false
	for spot: Dictionary in Exploration.RESOURCE_SPOTS:
		if at.distance_squared_to(spot.position) < 42.0 * 42.0:
			return false
	for cache: Dictionary in Exploration.HIDDEN_CHESTS:
		if at.distance_squared_to(cache.position) < 42.0 * 42.0:
			return false
	for spawn: Vector2 in RESERVED:
		if at.distance_squared_to(spawn) < 24.0 * 24.0:
			return false
	for i in range(TRAILS.size()):
		var trail: Array = TRAILS[i]
		for j in range(trail.size() - 1):
			if at.distance_to(Geometry2D.get_closest_point_to_segment(at, trail[j], trail[j + 1])) < TRAIL_WIDTHS[i] * 0.5 + 12.0:
				return false
	return true

func _draw_tree(at: Vector2, tall: bool) -> void:
	draw_rect(Rect2(at + Vector2(-8, 11), Vector2(23, 5)), Color("#172e26"))
	draw_rect(Rect2(at + Vector2(1, 1), Vector2(5, 13)), Color("#705237"))
	draw_rect(Rect2(at + Vector2(2, 3), Vector2(2, 8)), Color("#a17b4b"))
	if tall:
		draw_rect(Rect2(at + Vector2(-9, -15), Vector2(25, 16)), Color("#284c38"))
		draw_rect(Rect2(at + Vector2(-5, -20), Vector2(17, 12)), Color("#3f7048"))
	else:
		draw_rect(Rect2(at + Vector2(-10, -11), Vector2(27, 13)), Color("#365e3f"))
		draw_rect(Rect2(at + Vector2(-5, -16), Vector2(17, 10)), Color("#5d824c"))
	draw_rect(Rect2(at + Vector2(-3, -14 if tall else -10), Vector2(7, 3)), Color("#779759"))

func _draw_camp() -> void:
	var area := SafeCamp.AREA
	# The former clearance outline created a long pale vertical line across the forest.
	# Clearance/hitboxes remain in SafeCamp; only subtle corner ground marks are drawn.
	var edge := area.grow(SafeCamp.CLEARANCE)
	for corner: Vector2 in [edge.position, Vector2(edge.end.x, edge.position.y), edge.end, Vector2(edge.position.x, edge.end.y)]:
		draw_rect(Rect2(corner - Vector2(3, 2), Vector2(6, 4)), Color("#526747"))
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
