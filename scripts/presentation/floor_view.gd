class_name FloorView
extends Node2D

# A static pixel atlas and seeded brush stamps. All geometry is presentation only.
const ATLAS := preload("res://assets/art/forest_atlas.png")
const FOREST := Color("#294c37")
const FOREST_LIGHT := Color("#244431")
const TRAIL := Color("#786044")
const TRAIL_HIGHLIGHT := Color("#a28255")
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

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	_draw_ground()
	_draw_paths()
	for center: Vector2 in [Vector2(175, 215), Vector2(260, 685), Vector2(900, 175), Vector2(980, 715)]:
		_draw_clearing(center)
	_draw_decoration()
	for rock: Rect2 in ROCKS:
		_draw_stone(rock)
	_draw_camp()

func _hash(x: int, y: int) -> int:
	var n := x * 74509 + y * 53197 + 19033
	return absi((n ^ (n >> 11)) * 31337) % 9973

func _draw_ground() -> void:
	for y in range(0, 900, 32):
		for x in range(0, 1200, 32):
			var tile := _hash(x / 32, y / 32) % 4
			draw_texture_rect_region(ATLAS, Rect2(x, y, 32, 32), Rect2(tile * 32, 0, 32, 32))

func _draw_paths() -> void:
	# One continuous outline per trail prevents spikes at changes in direction.
	for i in range(TRAILS.size()):
		var centers := PackedVector2Array()
		var trail: Array = TRAILS[i]
		for j in range(trail.size() - 1):
			var start: Vector2 = trail[j]
			var finish: Vector2 = trail[j + 1]
			var steps := ceili(start.distance_to(finish) / 8.0)
			for n in range(0 if j == 0 else 1, steps + 1):
				centers.append(start.lerp(finish, float(n) / steps))
		for border in [7.0, 0.0]:
			var left := PackedVector2Array()
			var right := PackedVector2Array()
			for n in range(centers.size()):
				var prev: Vector2 = centers[maxi(0, n - 1)]
				var next: Vector2 = centers[mini(n + 1, centers.size() - 1)]
				var normal := (next - prev).normalized().orthogonal()
				var waviness := sin(float(n) * 0.32 + i) * 2.0 + float(_hash(n / 5, i * 19) % 3 - 1)
				var width: float = TRAIL_WIDTHS[i] * 0.5 + border + waviness
				left.append((centers[n] + normal * width).floor())
				right.append((centers[n] - normal * width).floor())
			for n in range(right.size() - 1, -1, -1):
				left.append(right[n])
			draw_colored_polygon(left, Color("#493d30") if border > 0.0 else TRAIL)
	var rng := RandomNumberGenerator.new()
	rng.seed = 33042
	for i in range(TRAILS.size()):
		var trail: Array = TRAILS[i]
		for j in range(trail.size() - 1):
			var length: float = trail[j].distance_to(trail[j + 1])
			for n in range(0, int(length), 23):
				var at: Vector2 = trail[j].lerp(trail[j + 1], float(n) / length).floor()
				at += Vector2(rng.randi_range(-8, 8), rng.randi_range(-6, 6))
				draw_rect(Rect2(at, Vector2(2 + n % 3, 2)), TRAIL_HIGHLIGHT if n % 3 == 0 else Color("#655137"))

func _draw_clearing(center: Vector2) -> void:
	for y in range(-28, 29, 6):
		var span := roundi(39.0 * sqrt(maxf(0.0, 1.0 - pow(y / 33.0, 2))))
		span += _hash(roundi(center.x), y) % 5 - 2
		draw_rect(Rect2(center + Vector2(-span, y), Vector2(span * 2, 6)), Color("#556246"))
	for n in range(11):
		var x := _hash(n, roundi(center.x)) % 61 - 30
		var y := _hash(n, roundi(center.y)) % 37 - 18
		draw_rect(Rect2(center + Vector2(x, y), Vector2(3, 2)), Color("#aa9363"))

func _draw_decoration() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12051
	var trees: Array[Vector2] = []
	for i in range(290):
		var at := Vector2(rng.randi_range(30, 1160), rng.randi_range(30, 865))
		if not _free_for_decoration(at):
			continue
		if i % 3 != 2:
			var free := true
			for tree in trees:
				if at.distance_squared_to(tree) < 46.0 * 46.0:
					free = false
					break
			if free:
				trees.append(at)
				_draw_tree(at, i % 3)
		elif i % 2 == 0:
			_draw_shrub(at)
		else:
			_draw_ground_details(at, i)
	for i in range(100):
		var at := Vector2(rng.randi_range(22, 1175), rng.randi_range(25, 875))
		if _free_for_decoration(at):
			_draw_ground_details(at, i)

func _draw_tree(at: Vector2, variant: int) -> void:
	# The crown, bark, shadow and leaves are a real 64x64 sprite in the atlas.
	draw_texture_rect_region(ATLAS, Rect2(at + Vector2(-32, -52), Vector2(64, 64)), Rect2(variant * 64, 64, 64, 64))

func _draw_shrub(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-10, 3), Vector2(22, 5)), Color("#18392e"))
	for patch in [Rect2(-10, -1, 9, 6), Rect2(-5, -6, 10, 9), Rect2(3, -3, 9, 9)]:
		draw_rect(Rect2(at + patch.position, patch.size), Color("#417348"))
	draw_rect(Rect2(at + Vector2(-4, -5), Vector2(5, 2)), Color("#80a45c"))
	draw_rect(Rect2(at + Vector2(4, -2), Vector2(3, 2)), Color("#7ca45c"))

func _draw_ground_details(at: Vector2, seed: int) -> void:
	match seed % 4:
		0:
			draw_rect(Rect2(at, Vector2(3, 4)), Color("#72945b"))
			draw_rect(Rect2(at + Vector2(-3, 1), Vector2(3, 2)), Color("#486b43"))
		1:
			draw_rect(Rect2(at, Vector2(6, 3)), Color("#a27652"))
			draw_rect(Rect2(at + Vector2(2, -1), Vector2(3, 1)), Color("#c39a63"))
		2:
			draw_rect(Rect2(at, Vector2(4, 3)), Color("#879381"))
			draw_rect(Rect2(at + Vector2(1, -1), Vector2(2, 1)), Color("#bac0a2"))
		3:
			draw_rect(Rect2(at, Vector2(2, 2)), Color("#efdc92"))
			draw_rect(Rect2(at + Vector2(-3, 0), Vector2(2, 2)), Color("#caa367"))
			draw_rect(Rect2(at + Vector2(-1, 2), Vector2(2, 2)), Color("#687f51"))
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

func _draw_camp() -> void:
	var area := SafeCamp.AREA
	# Warm, protected clearing. The fence is visual; physics remain unchanged.
	draw_rect(area.grow(5), Color("#263c31"))
	for y in range(int(area.position.y), int(area.end.y), 8):
		var edge := _hash(y, 47) % 5
		draw_rect(Rect2(area.position.x + edge, y, area.size.x - edge * 2, 8), Color("#756044"))
		draw_rect(Rect2(area.position.x + 7 + edge, y, area.size.x - 14 - edge * 2, 8), Color("#4b6849"))
	# Worn paving and short plank runs imply foot traffic without a new collision.
	for y in range(392, 539, 14):
		for x in range(490, 632, 18):
			if _hash(x, y) % 3 != 0:
				draw_rect(Rect2(x, y, 10, 4), Color("#849064"))
				draw_rect(Rect2(x + 2, y, 4, 1), Color("#b6a879"))
	for y in range(int(area.position.y) + 13, int(area.end.y) - 12, 21):
		for x in range(int(area.position.x) + 13, int(area.end.x) - 11, 24):
			if _hash(x, y) % 3 == 0:
				draw_rect(Rect2(x, y, 5, 3), Color("#678054"))
			elif _hash(x, y) % 4 == 0:
				draw_rect(Rect2(x, y, 3, 2), Color("#b09a68"))
	for x in range(int(area.position.x) + 6, int(area.end.x) - 5, 12):
		for y in [int(area.position.y) + 5, int(area.end.y) - 8]:
			_draw_fence(Vector2(x, y))
	for y in range(int(area.position.y) + 15, int(area.end.y) - 10, 15):
		for x in [int(area.position.x) + 4, int(area.end.x) - 8]:
			_draw_fence(Vector2(x, y))
	_draw_station(SafeCamp.STATIONS["Baú"], Color("#6f482c"), Color("#d4ae69"))
	_draw_station(SafeCamp.STATIONS["Ferreiro"], Color("#454c4a"), Color("#efab66"))
	_draw_station(SafeCamp.STATIONS["Vendedor"], Color("#40694d"), Color("#d6c681"))
	_draw_npc(Vector2(606, 423), Color("#637587"), Color("#764e37"))
	_draw_npc(Vector2(606, 475), Color("#9b6947"), Color("#dbc079"))
	_draw_fire(Vector2(516, 492))

func _draw_fence(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(1, 3), Vector2(8, 6)), Color("#493d2e"))
	draw_rect(Rect2(at + Vector2(0, 0), Vector2(8, 5)), Color("#baa570"))
	draw_rect(Rect2(at + Vector2(2, 0), Vector2(4, 2)), Color("#e1c282"))

func _draw_station(at: Vector2, base: Color, accent: Color) -> void:
	draw_rect(Rect2(at + Vector2(-17, 11), Vector2(34, 7)), Color("#253b32"))
	draw_rect(Rect2(at + Vector2(-16, -16), Vector2(32, 29)), Color("#2d3933"))
	draw_rect(Rect2(at + Vector2(-13, -13), Vector2(26, 23)), base)
	draw_rect(Rect2(at + Vector2(-16, -18), Vector2(32, 7)), accent.darkened(0.25))
	draw_rect(Rect2(at + Vector2(-12, -19), Vector2(24, 3)), accent)
	draw_rect(Rect2(at + Vector2(-10, -9), Vector2(20, 5)), accent)
	draw_rect(Rect2(at + Vector2(-10, -4), Vector2(20, 2)), accent.darkened(0.4))
	draw_rect(Rect2(at + Vector2(-6, 2), Vector2(12, 6)), Color("#26372d"))
	draw_rect(Rect2(at + Vector2(-2, 0), Vector2(4, 8)), accent.lightened(0.12))

func _draw_npc(at: Vector2, tunic: Color, hat: Color) -> void:
	draw_rect(Rect2(at + Vector2(-10, 15), Vector2(20, 4)), Color("#263b32"))
	draw_rect(Rect2(at + Vector2(-8, 10), Vector2(6, 6)), Color("#373c37"))
	draw_rect(Rect2(at + Vector2(2, 10), Vector2(6, 6)), Color("#373c37"))
	draw_rect(Rect2(at + Vector2(-10, -4), Vector2(20, 16)), tunic.darkened(0.25))
	draw_rect(Rect2(at + Vector2(-8, -3), Vector2(16, 14)), tunic)
	draw_rect(Rect2(at + Vector2(-7, -15), Vector2(14, 12)), Color("#c79d71"))
	draw_rect(Rect2(at + Vector2(-9, -20), Vector2(18, 6)), hat)
	draw_rect(Rect2(at + Vector2(-5, -8), Vector2(3, 3)), Color("#212a28"))
	draw_rect(Rect2(at + Vector2(3, -8), Vector2(3, 3)), Color("#212a28"))

func _draw_fire(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-16, 4), Vector2(32, 6)), Color("#443e31"))
	draw_rect(Rect2(at + Vector2(-11, 0), Vector2(22, 8)), Color("#78553a"))
	draw_rect(Rect2(at + Vector2(-8, -10), Vector2(17, 13)), Color("#d87543"))
	draw_rect(Rect2(at + Vector2(-5, -16), Vector2(10, 16)), Color("#f3b95e"))
	draw_rect(Rect2(at + Vector2(-2, -10), Vector2(5, 11)), Color("#ffe09a"))

func _draw_stone(area: Rect2) -> void:
	# Ground shadow covers the blocking footprint; the uneven facets read as rock.
	draw_rect(area, Color("#2b4940"))
	var p := area.position
	var w := area.size.x
	var h := area.size.y
	var outline := PackedVector2Array([
		p + Vector2(0, 9), p + Vector2(7, 5), p + Vector2(15, 0),
		p + Vector2(w - 20, 0), p + Vector2(w - 9, 5), p + Vector2(w, 11),
		p + Vector2(w, h - 8), p + Vector2(w - 8, h), p + Vector2(8, h), p + Vector2(0, h - 7)
	])
	draw_colored_polygon(outline, Color("#324e45"))
	var top := PackedVector2Array([
		p + Vector2(7, 13), p + Vector2(18, 5), p + Vector2(w - 22, 5),
		p + Vector2(w - 8, 13), p + Vector2(w - 15, h - 14),
		p + Vector2(17, h - 11), p + Vector2(6, h - 15)
	])
	draw_colored_polygon(top, Color("#697e71"))
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(17, 12), p + Vector2(w - 26, 9),
		p + Vector2(w - 37, h * 0.42), p + Vector2(28, h * 0.38)
	]), Color("#96a293"))
	for i in range(13):
		var at := p + Vector2(10 + _hash(i, 52) % maxi(1, int(w) - 20), 9 + _hash(i, 53) % maxi(1, int(h) - 18))
		draw_rect(Rect2(at, Vector2(3 + i % 3, 2)), Color("#b1b9a1") if i % 4 == 0 else Color("#4c685d"))
