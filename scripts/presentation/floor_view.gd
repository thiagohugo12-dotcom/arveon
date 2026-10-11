class_name FloorView
extends Node2D

# Minimal shared pixel atlas; physical trunks use the same deterministic feet.
var atlas: Texture2D
var visual_v2 := false
var v2_view: FloorV2View
const BERRY := preload("res://assets/art/forest_shrub_v035.png") # Existing arena keeps its art.
const REMOVED_SECONDARY := [Vector2(705,392),Vector2(738,498),Vector2(475,633),Vector2(969,638),Vector2(196,786),Vector2(1092,91)]
const REFUGE := preload("res://assets/art/forest_refuge_v035.png")
const NPC_VIEW := preload("res://scripts/presentation/camp_npc_view.gd")
const FOREST := Color("#294c37")
const FOREST_LIGHT := Color("#244431")
const TRAIL := Color("#d5ba7d")
const TRAIL_HIGHLIGHT := Color("#e3cf9a")
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
	atlas = MataArt.texture()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for station: String in ["Ferreiro", "Vendedor"]:
		var npc := NPC_VIEW.new()
		npc.kind = 0 if station == "Ferreiro" else 1
		npc.visual_v2 = visual_v2
		npc.position = _npc_position(station,visual_v2)
		add_child(npc)

func _npc_position(station: String, use_v2: bool) -> Vector2:
	# V2 places people at the fronts of their expanded visual service zones.
	if use_v2:
		return SafeCamp.DISPLAY_STATIONS[station] + (Vector2(0,32) if station == "Ferreiro" else Vector2(0,12))
	return Vector2(606, 423 if station == "Ferreiro" else 475)

func set_visual_v2(enabled: bool) -> void:
	if visual_v2 == enabled:
		return
	visual_v2 = enabled
	for child in get_children():
		if child is CampNpcView:
			child.visual_v2 = enabled
			child.position = _npc_position("Ferreiro" if child.kind == 0 else "Vendedor",enabled)
	if enabled and v2_view == null:
		v2_view = FloorV2View.new()
		v2_view.layout = self
	queue_redraw()

func _draw() -> void:
	if visual_v2:
		v2_view.paint()
		return
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
	# Quiet flat ground; sparse vegetation supplies variation without tiled noise.
	draw_rect(Rect2(0,0,1200,900),Color("#98a765"))

func _draw_paths() -> void:
	# One continuous outline per trail prevents spikes at changes in direction.
	for i in range(TRAILS.size()):
		var centers := PackedVector2Array()
		var trail: Array = TRAILS[i]
		for j in range(trail.size() - 1):
			var start: Vector2 = trail[j]
			var finish: Vector2 = trail[j + 1]
			var steps := ceili(start.distance_to(finish) / 12.0)
			for n in range(0 if j == 0 else 1, steps + 1):
				var t := float(n) / steps
				var bend := sin(t * PI) * (5.0 * sin(t * 5.0 + i * 2.3) + 3.0 * sin(t * 9.0 + j * 1.8))
				centers.append(start.lerp(finish, t) + (finish - start).normalized().orthogonal() * bend)
		for border in [4.0, 0.0]:
			var left := PackedVector2Array()
			var right := PackedVector2Array()
			for n in range(centers.size()):
				var prev: Vector2 = centers[maxi(0, n - 1)]
				var next: Vector2 = centers[mini(n + 1, centers.size() - 1)]
				var normal := (next - prev).normalized().orthogonal()
				var waviness := sin(float(n) * 0.17 + i) * 1.5
				var width: float = TRAIL_WIDTHS[i] * 0.5 + border + waviness
				left.append((centers[n] + normal * width).floor())
				right.append((centers[n] - normal * width).floor())
			for n in range(right.size() - 1, -1, -1):
				left.append(right[n])
			draw_colored_polygon(left, Color("#899853") if border > 0.0 else TRAIL)
	# Rare worn marks; the routes stay legible at phone scale.
	for trail: Array in TRAILS:
		for j in range(trail.size()-1):
			var center: Vector2 = trail[j].lerp(trail[j+1],0.5).floor()
			draw_rect(Rect2(center,Vector2(5,2)),TRAIL_HIGHLIGHT)

func _draw_grass(at: Vector2, seed: int) -> void:
	var dark := Color("#74884d")
	var light := Color("#aabb68")
	draw_colored_polygon(PackedVector2Array([at + Vector2(-5, 3), at + Vector2(-3, -5), at, at + Vector2(1, -8), at + Vector2(3, 0), at + Vector2(6, -4), at + Vector2(5, 4)]), dark)
	draw_rect(Rect2(at + Vector2(-2, -3), Vector2(2, 5)), light)
	draw_rect(Rect2(at + Vector2(3, -1), Vector2(2, 4)), light)

func _draw_pebble(at: Vector2, seed: int) -> void:
	draw_colored_polygon(PackedVector2Array([at + Vector2(-4, 2), at + Vector2(-2, -2), at + Vector2(2, -3), at + Vector2(5, 1), at + Vector2(3, 3)]), Color("#8c7e62"))
	draw_rect(Rect2(at + Vector2(-1, -2), Vector2(3, 1)), Color("#c7b795") if seed % 2 else Color("#b2ab8a"))

func _draw_clearing(center: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([center+Vector2(-32,-18),center+Vector2(22,-18),center+Vector2(38,-6),center+Vector2(38,16),center+Vector2(20,26),center+Vector2(-28,26),center+Vector2(-38,12),center+Vector2(-38,-6)]),Color("#a5af70"))

func _draw_decoration() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12051
	for i in range(56):
		var at := Vector2(rng.randi_range(20, 1175), rng.randi_range(20, 875))
		if _free_for_decoration(at):
			if i % 11 == 0:
				_draw_flower(at, i)
			elif i % 19 == 0:
				_draw_pebble(at, i)
			elif i % 23 == 0:
				_draw_shrub(at)
			else:
				_draw_grass(at, i)
	for at in tree_positions():
		_draw_tree(at)

func tree_positions() -> Array[Vector2]:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12051
	var trees: Array[Vector2] = []
	for i in range(155):
		var at := Vector2(rng.randi_range(30, 1160), rng.randi_range(30, 865))
		if i % 3 == 2 or not _free_for_decoration(at):
			continue
		var free := true
		for tree in trees:
			if at.distance_squared_to(tree) < 96.0 * 96.0:
				free = false
				break
		if free:
			trees.append(at)
	# Filter after generation so clearing the entrance never rerolls other trees.
	return trees.filter(func(at: Vector2): return not REMOVED_SECONDARY.has(at) and not TowerEntrance.BODY.grow(12.0).has_point(at))

func _draw_tree(at: Vector2) -> void:
	var species := _hash(roundi(at.y),roundi(at.x)) % 8
	var kind := 2 if species == 0 else 1 if species < 3 else 0
	# Smaller canopies and a visible root silhouette leave combat/navigation clear.
	draw_colored_polygon(PackedVector2Array([at+Vector2(-23,3),at+Vector2(-18,-7),at+Vector2(20,-7),at+Vector2(29,2),at+Vector2(24,10),at+Vector2(-16,10)]),Color("#819255"))
	draw_texture_rect_region(atlas,Rect2(at-Vector2(32,72),Vector2(64,80)),MataArt.TREE_REGIONS[kind])

func _draw_shrub(at: Vector2) -> void:
	draw_texture_rect_region(atlas,Rect2(at+Vector2(-16,-24),Vector2(32,32)),MataArt.SHRUB_REGION)

func _draw_ground_details(at: Vector2, seed: int) -> void:
	if seed % 3 == 0:
		_draw_flower(at, seed)
	else:
		_draw_grass(at, seed)

func _draw_flower(at: Vector2, seed: int) -> void:
	draw_rect(Rect2(at + Vector2(0, 0), Vector2(2, 5)), Color("#285e3e"))
	var petal := Color("#f7e9b0") if seed % 2 else Color("#f2b565")
	for offset: Vector2 in [Vector2(-2, -3), Vector2(2, -3), Vector2(0, -5), Vector2(0, -1)]:
		draw_rect(Rect2(at + offset, Vector2(2, 2)), petal)
	draw_rect(Rect2(at + Vector2(0, -3), Vector2(2, 2)), Color("#c48a42"))
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
	# A sheltered clearing keeps the forest floor visible and the paths open.
	for y in range(int(area.position.y) - 6, int(area.end.y) + 6, 7):
		var extent := 13 + _hash(y, 47) % 9
		var center := 557 + sin(float(y) * 0.06) * 8.0
		draw_rect(Rect2(center - extent, y, extent * 2, 7), Color("#ad8051"))
		for n in range(3):
			var at := Vector2(center + _hash(y, n) % (extent * 2) - extent, y + _hash(n, y) % 6)
			draw_rect(Rect2(at, Vector2(3, 2)), Color("#cf9c62") if n == 0 else Color("#906e47"))
	for n in range(10):
		var at := area.position + Vector2(8 + _hash(n, 115) % 165, 8 + _hash(n, 116) % 183)
		if absf(at.x - 557.0) > 29.0:
			if n % 6 == 0:
				_draw_flower(at, n)
			else:
				_draw_grass(at, n)
	# Scattered worn flagstones suggest routes between stations while grass remains visible.
	for n in range(18):
		var center := Vector2(556 + _hash(n, 71) % 21 - 10, 369 + n * 10)
		_draw_flagstone(center, n)
	for n in range(9):
		_draw_flagstone(Vector2(551 - n * 6, 394 + n * 2 + _hash(n, 72) % 7), n + 18)
		_draw_flagstone(Vector2(566 + n * 6, 400 + n * 2 + _hash(n, 73) % 7), n + 27)
	for n in range(7):
		_draw_flagstone(Vector2(567 + n * 7, 499 + n * 2 + _hash(n, 74) % 5), n + 36)
	for y in range(int(area.position.y) + 13, int(area.end.y) - 12, 21):
		for x in range(int(area.position.x) + 13, int(area.end.x) - 11, 24):
			if _hash(x, y) % 3 == 0:
				draw_rect(Rect2(x, y, 5, 3), Color("#678054"))
			elif _hash(x, y) % 4 == 0:
				draw_rect(Rect2(x, y, 3, 2), Color("#b09a68"))
	for segment: Vector2 in [Vector2(478, 515), Vector2(583, 641)]:
		_draw_rail(Vector2(segment.x, 352), segment.y - segment.x)
		_draw_rail(Vector2(segment.x, 548), segment.y - segment.x)
	for y in [380, 400, 490, 510]:
		_draw_fence(Vector2(473, y))
		_draw_fence(Vector2(643, y))
	# The cabin sits west of the northern trail; its doorstep marks the chest service.
	draw_texture_rect(REFUGE, Rect2(452, 288, 96, 96), false)
	_draw_chest(SafeCamp.STATIONS["Baú"])
	_draw_camp_stall(SafeCamp.STATIONS["Ferreiro"], 1)
	_draw_camp_stall(SafeCamp.STATIONS["Vendedor"], 2)
	_draw_service_sign(SafeCamp.STATIONS["Baú"] + Vector2(27, -12), 0)
	_draw_service_sign(SafeCamp.STATIONS["Ferreiro"] + Vector2(28, -10), 1)
	_draw_service_sign(SafeCamp.STATIONS["Vendedor"] + Vector2(28, -10), 2)
	_draw_barrel(Vector2(480, 411))
	_draw_barrel(Vector2(633, 420))
	_draw_crate(Vector2(484, 526))
	_draw_crate(Vector2(631, 535))
	_draw_lantern(Vector2(479, 374))
	_draw_lantern(Vector2(638, 474))
	_draw_fire(Vector2(516, 492))

func _draw_flagstone(at: Vector2, seed: int) -> void:
	var w := 8 + _hash(seed, 75) % 6
	var h := 4 + _hash(seed, 76) % 3
	var left := -w / 2
	var edge := _hash(seed, 77) % 3
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(left + 1, 0), at + Vector2(left + w - edge, 0),
		at + Vector2(left + w, h - 2), at + Vector2(left + w - 2, h),
		at + Vector2(left, h - 1)
	]), Color("#75856b") if seed % 3 else Color("#907c5d"))
	draw_rect(Rect2(at + Vector2(left + 2, 1), Vector2(maxi(2, w - 6), 1)), Color("#aeb096"))

func _draw_fence(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-2, 5), Vector2(8, 6)), Color("#334b37"))
	draw_rect(Rect2(at + Vector2(-2, -4), Vector2(7, 13)), Color("#6e4930"))
	draw_rect(Rect2(at + Vector2(-1, -6), Vector2(5, 4)), Color("#c18c53"))
	draw_rect(Rect2(at + Vector2(0, 0), Vector2(2, 6)), Color("#a97240"))

func _draw_rail(at: Vector2, length: float) -> void:
	draw_rect(Rect2(at + Vector2(0, 4), Vector2(length, 5)), Color("#4f382e"))
	draw_rect(Rect2(at, Vector2(length, 5)), Color("#8c5d38"))
	draw_rect(Rect2(at + Vector2(0, 1), Vector2(length, 1)), Color("#b9844a"))
	for x in range(0, int(length) + 1, 16):
		_draw_fence(at + Vector2(x, 0))

func _draw_barrel(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-9, 8), Vector2(18, 4)), Color("#31523d"))
	draw_rect(Rect2(at + Vector2(-7, -9), Vector2(14, 19)), Color("#6b432d"))
	draw_rect(Rect2(at + Vector2(-5, -8), Vector2(10, 16)), Color("#a06d3c"))
	for y in [-6, 5]:
		draw_rect(Rect2(at + Vector2(-8, y), Vector2(16, 3)), Color("#40504b"))
	draw_rect(Rect2(at + Vector2(-4, -5), Vector2(2, 10)), Color("#cc9351"))

func _draw_crate(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-10, 7), Vector2(20, 4)), Color("#31523d"))
	draw_rect(Rect2(at + Vector2(-9, -9), Vector2(18, 18)), Color("#71472f"))
	draw_rect(Rect2(at + Vector2(-7, -7), Vector2(14, 14)), Color("#a77642"))
	draw_line(at + Vector2(-6, -6), at + Vector2(6, 6), Color("#765033"), 2)
	draw_line(at + Vector2(6, -6), at + Vector2(-6, 6), Color("#765033"), 2)

func _draw_chest(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-15, 7), Vector2(30, 5)), Color("#31503b"))
	draw_rect(Rect2(at + Vector2(-14, -10), Vector2(28, 19)), Color("#4d352a"))
	draw_rect(Rect2(at + Vector2(-11, -8), Vector2(22, 16)), Color("#945c38"))
	draw_rect(Rect2(at + Vector2(-12, -8), Vector2(24, 5)), Color("#b57a48"))
	for x in [-9, 7]:
		draw_rect(Rect2(at + Vector2(x, -9), Vector2(3, 18)), Color("#d1a35a"))
	draw_rect(Rect2(at + Vector2(-3, -3), Vector2(6, 6)), Color("#4b5147"))
	draw_rect(Rect2(at + Vector2(-1, -1), Vector2(2, 3)), Color("#f3c86d"))

func _draw_service_sign(at: Vector2, kind: int) -> void:
	# Small wood pictograms make the three existing services recognisable from
	# the path without adding a text panel or moving their interaction points.
	draw_rect(Rect2(at + Vector2(-7, 7), Vector2(14, 3)), Color("#36503a"))
	draw_rect(Rect2(at + Vector2(-1, 4), Vector2(2, 6)), Color("#574230"))
	draw_rect(Rect2(at + Vector2(-8, -8), Vector2(16, 14)), Color("#3b3028"))
	draw_rect(Rect2(at + Vector2(-6, -6), Vector2(12, 10)), Color("#9d7145"))
	if kind == 0:
		draw_rect(Rect2(at + Vector2(-4, -3), Vector2(8, 5)), Color("#51382c"))
		draw_rect(Rect2(at + Vector2(-3, -4), Vector2(6, 2)), Color("#dcab65"))
		draw_rect(Rect2(at + Vector2(-1, -2), Vector2(2, 3)), Color("#eccb83"))
	elif kind == 1:
		draw_rect(Rect2(at + Vector2(-4, -3), Vector2(8, 3)), Color("#b1b3a0"))
		draw_rect(Rect2(at + Vector2(-2, 0), Vector2(4, 2)), Color("#596866"))
		draw_rect(Rect2(at + Vector2(-1, 2), Vector2(2, 2)), Color("#434c4a"))
	else:
		draw_rect(Rect2(at + Vector2(-4, -2), Vector2(8, 5)), Color("#4b6954"))
		draw_rect(Rect2(at + Vector2(-2, -4), Vector2(4, 3)), Color("#dec17e"))
		draw_rect(Rect2(at + Vector2(-1, 0), Vector2(2, 2)), Color("#e9c57c"))

func _draw_lantern(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-13, -12), Vector2(26, 28)), Color(1.0, 0.69, 0.31, 0.08))
	draw_rect(Rect2(at + Vector2(-2, -23), Vector2(5, 19)), Color("#805437"))
	draw_rect(Rect2(at + Vector2(-5, -7), Vector2(11, 13)), Color("#382f28"))
	draw_rect(Rect2(at + Vector2(-3, -5), Vector2(7, 9)), Color("#efad4f"))
	draw_rect(Rect2(at + Vector2(-1, -4), Vector2(3, 6)), Color("#ffe19a"))

func _draw_camp_stall(at: Vector2, kind: int) -> void:
	var wood := Color("#8c5a35") if kind != 1 else Color("#645246")
	var roof := Color("#a67949") if kind == 0 else Color("#305d56") if kind == 1 else Color("#b58d52")
	draw_rect(Rect2(at + Vector2(-20, 11), Vector2(40, 7)), Color("#34513d"))
	draw_rect(Rect2(at + Vector2(-18, -16), Vector2(36, 28)), Color("#4b342b"))
	draw_rect(Rect2(at + Vector2(-15, -12), Vector2(30, 22)), wood)
	for x in [-12, -4, 4, 12]:
		draw_rect(Rect2(at + Vector2(x, -11), Vector2(2, 19)), wood.lightened(0.17) if x % 3 else wood.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-23, -14), at + Vector2(-18, -25),
		at + Vector2(11, -27), at + Vector2(23, -18), at + Vector2(21, -12)
	]), Color("#243f39"))
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-20, -17), at + Vector2(-17, -23),
		at + Vector2(10, -25), at + Vector2(19, -18), at + Vector2(18, -15)
	]), roof)
	for x in range(-12, 16, 8):
		draw_rect(Rect2(at + Vector2(x, -20 + x % 3), Vector2(5, 2)), roof.lightened(0.22))
	if kind == 0:
		_draw_crate(at + Vector2(0, 2))
	elif kind == 1:
		draw_rect(Rect2(at + Vector2(-9, -5), Vector2(18, 13)), Color("#334244"))
		draw_rect(Rect2(at + Vector2(-5, -2), Vector2(10, 7)), Color("#df8951"))
		draw_rect(Rect2(at + Vector2(-2, -1), Vector2(4, 5)), Color("#ffd77c"))
	else:
		draw_rect(Rect2(at + Vector2(-13, -4), Vector2(26, 4)), Color("#dcc18b"))
		for x in [-8, 2]:
			draw_rect(Rect2(at + Vector2(x, 0), Vector2(7, 7)), Color("#577c50"))

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

func _draw_fire(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-16, 4), Vector2(32, 6)), Color("#443e31"))
	draw_rect(Rect2(at + Vector2(-11, 0), Vector2(22, 8)), Color("#78553a"))
	draw_rect(Rect2(at + Vector2(-8, -10), Vector2(17, 13)), Color("#d87543"))
	draw_rect(Rect2(at + Vector2(-5, -16), Vector2(10, 16)), Color("#f3b95e"))
	draw_rect(Rect2(at + Vector2(-2, -10), Vector2(5, 11)), Color("#ffe09a"))

func _draw_stone(area: Rect2) -> void:
	# Broad stepped boulder silhouette, three quiet planes, no surface speckle.
	var p := area.position
	var size := area.size
	var outline := PackedVector2Array()
	for point: Vector2 in [Vector2(0,0.25),Vector2(0.1,0.25),Vector2(0.1,0.1),Vector2(0.25,0.1),Vector2(0.25,0),Vector2(0.75,0),Vector2(0.75,0.1),Vector2(0.9,0.1),Vector2(0.9,0.25),Vector2(1,0.25),Vector2(1,0.75),Vector2(0.9,0.75),Vector2(0.9,0.9),Vector2(0.75,0.9),Vector2(0.75,1),Vector2(0.25,1),Vector2(0.25,0.9),Vector2(0.1,0.9),Vector2(0.1,0.75),Vector2(0,0.75)]:
		outline.append(p+(point*size).snapped(Vector2(2,2)))
	draw_colored_polygon(outline,Color("#687361"))
	var top := PackedVector2Array()
	for point: Vector2 in [Vector2(0.12,0.24),Vector2(0.25,0.24),Vector2(0.25,0.08),Vector2(0.68,0.08),Vector2(0.68,0.16),Vector2(0.86,0.16),Vector2(0.86,0.38),Vector2(0.92,0.38),Vector2(0.92,0.65),Vector2(0.77,0.65),Vector2(0.77,0.78),Vector2(0.25,0.78),Vector2(0.25,0.66),Vector2(0.08,0.66),Vector2(0.08,0.38),Vector2(0.12,0.38)]:
		top.append(p+(point*size).snapped(Vector2(2,2)))
	draw_colored_polygon(top,Color("#a3a78b"))
	draw_rect(Rect2(p+Vector2(size.x*0.26,size.y*0.12).snapped(Vector2(2,2)),Vector2(size.x*0.3,4).snapped(Vector2(2,2))),Color("#c0bea0"))
