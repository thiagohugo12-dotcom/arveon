class_name FloorView
extends Node2D

# Minimal shared pixel atlas; physical trunks use the same deterministic feet.
var atlas: Texture2D
@export var visual_v2 := false
var v2_view: FloorV2View
var depth_scenery: Node2D
var chest_view: Node2D
var expanded_world := false
var secret_path_revealed := false

func set_chest_open(opened: bool) -> void:
	if is_instance_valid(chest_view): chest_view.set_open(opened)

func set_expanded_world(enabled: bool) -> void:
	if expanded_world == enabled: return
	expanded_world = enabled
	if depth_scenery != null:
		depth_scenery.queue_free()
		depth_scenery = null
		chest_view = null
	queue_redraw()
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
const EXPANSION_TRAILS := [
	{"points": [Vector2(1160,455),Vector2(1240,380),Vector2(1300,270),Vector2(1430,260)], "width": 38.0},
	{"points": [Vector2(1300,270),Vector2(1320,170),Vector2(1450,105)], "width": 26.0},
	{"points": [Vector2(1240,380),Vector2(1280,475),Vector2(1380,535),Vector2(1480,635),Vector2(1640,665)], "width": 34.0},
	{"points": [Vector2(1480,635),Vector2(1580,790),Vector2(1410,825),Vector2(1310,715),Vector2(1380,520)], "width": 24.0},
	{"points": [Vector2(560,860),Vector2(620,960),Vector2(720,1035),Vector2(760,1185),Vector2(635,1260),Vector2(430,1270)], "width": 34.0},
	{"points": [Vector2(720,1035),Vector2(930,1010),Vector2(1110,1110),Vector2(1250,1255),Vector2(1450,1250)], "width": 30.0},
	{"points": [Vector2(1100,790),Vector2(1210,895),Vector2(1300,955),Vector2(1250,1055),Vector2(1110,1110)], "width": 28.0},
	{"points": [Vector2(635,1260),Vector2(680,1308),Vector2(830,1320)], "width": 27.0}
]
const SECRET_TRAIL := [Vector2(1250,1255),Vector2(1270,1185),Vector2(1280,1108),Vector2(1350,1135),Vector2(1415,1160)]
const EXPANSION_ROCKS := [
	Rect2(1308,492,62,46),Rect2(1450,454,62,46),Rect2(1608,500,62,46),
	Rect2(1292,704,62,46),Rect2(1492,756,62,46),Rect2(1620,696,62,46),
	Rect2(1330,448,58,44),Rect2(1640,570,58,44),Rect2(1284,785,58,44),Rect2(1650,785,58,44)
]
const GROVE_FRAME_TREES := [Vector2(1405,1040),Vector2(1650,1040),Vector2(1650,1295),Vector2(1370,1300)]
const DANGER_FRAME_TREES := [Vector2(1305,520),Vector2(1640,520),Vector2(1305,740),Vector2(1640,740)]
const DEEPWOOD_TREE_CLUSTERS := [
	[Vector2(155,970),Vector2(220,925),Vector2(288,966),Vector2(205,1033)],
	[Vector2(140,1125),Vector2(210,1085),Vector2(277,1139),Vector2(180,1200)],
	[Vector2(365,1000),Vector2(430,965),Vector2(495,1015),Vector2(405,1090)],
	[Vector2(450,1160),Vector2(520,1120),Vector2(570,1180),Vector2(460,1220)],
	[Vector2(835,930),Vector2(900,890),Vector2(970,930),Vector2(850,985)],
	[Vector2(880,1185),Vector2(950,1135),Vector2(1020,1190),Vector2(940,1260)],
	[Vector2(80,1270),Vector2(155,1310),Vector2(255,1280)]
]
const AUTHORED_DEEPWOOD_GROUPS := [
	{"center":Vector2(112,985),"offsets":[Vector2(-30,-18),Vector2(18,-34),Vector2(48,4),Vector2(4,30)]},
	{"center":Vector2(285,1045),"offsets":[Vector2(-38,-20),Vector2(8,-42),Vector2(42,-8),Vector2(22,35)]},
	{"center":Vector2(110,1190),"offsets":[Vector2(-20,-34),Vector2(26,-10),Vector2(54,26)]},
	{"center":Vector2(405,1240),"offsets":[Vector2(-42,-10),Vector2(-8,-40),Vector2(35,-24),Vector2(54,20)]},
	{"center":Vector2(465,970),"offsets":[Vector2(-34,-18),Vector2(12,-38),Vector2(47,2)]},
	{"center":Vector2(835,965),"offsets":[Vector2(-38,-20),Vector2(2,-42),Vector2(40,-10),Vector2(30,30)]},
	{"center":Vector2(1015,1000),"offsets":[Vector2(-30,-26),Vector2(15,-44),Vector2(46,-4)]},
	{"center":Vector2(880,1210),"offsets":[Vector2(-40,-18),Vector2(2,-42),Vector2(39,-14),Vector2(34,28)]},
	{"center":Vector2(1085,1290),"offsets":[Vector2(-38,-18),Vector2(8,-40),Vector2(40,-8)]}
]
const DANGER_TREE_GROUPS := [
	{"center":Vector2(1620,445),"offsets":[Vector2(-30,-16),Vector2(10,-34),Vector2(34,0),Vector2(4,30)]},
	{"center":Vector2(1258,620),"offsets":[Vector2(-18,-26),Vector2(24,-14),Vector2(-4,18),Vector2(28,34)]},
	{"center":Vector2(1650,650),"offsets":[Vector2(-20,-24),Vector2(16,-4),Vector2(-10,28)]},
	{"center":Vector2(1640,770),"offsets":[Vector2(-24,-16),Vector2(12,12),Vector2(-12,38)]}
]
const DANGER_DRY_PATCHES := [Vector2(1282,490),Vector2(1640,485),Vector2(1288,770),Vector2(1652,790)]
const DEEPWOOD_LOGS := [Rect2(155,1080,34,12),Rect2(405,1165,38,13),Rect2(915,1080,36,12),Rect2(1030,1235,40,13)]
const DEEPWOOD_MUSHROOMS := [Vector2(310,1095),Vector2(360,1210),Vector2(585,1100),Vector2(900,1100),Vector2(1070,1190)]
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
const EXPANSION_RESERVED := [Vector2(1350,250),Vector2(1510,260),Vector2(1600,365),Vector2(1335,400),
	Vector2(1360,560),Vector2(1510,590),Vector2(1630,650),Vector2(1530,770),Vector2(1370,760),
	Vector2(630,1015),Vector2(800,1110),Vector2(980,1045),Vector2(1090,1190),
	Vector2(660,1250),Vector2(1000,1260),Vector2(1640,1310)]

func _ready() -> void:
	atlas = MataArt.texture()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Floor 1 can start with the approved renderer already selected by its scene.
	# Create the helper before the first draw so the legacy map never flashes.
	if visual_v2 and v2_view == null:
		v2_view = FloorV2View.new()
		v2_view.layout = self
	for station: String in ["Ferreiro", "Vendedor"]:
		var npc := NPC_VIEW.new()
		npc.kind = 0 if station == "Ferreiro" else 1
		npc.visual_v2 = visual_v2
		npc.position = _npc_position(station,visual_v2)
		add_child(npc)

func _npc_position(station: String, use_v2: bool) -> Vector2:
	# V2 places people at the fronts of their expanded visual service zones.
	if use_v2:
		return SafeCamp.DISPLAY_STATIONS[station] - Vector2(0,21)
	return Vector2(606, 423 if station == "Ferreiro" else 475)

func set_visual_v2(enabled: bool) -> void:
	if visual_v2 == enabled:
		if enabled and v2_view == null:
			v2_view = FloorV2View.new()
			v2_view.layout = self
			queue_redraw()
		return
	visual_v2 = enabled
	if depth_scenery != null: depth_scenery.visible = enabled
	if is_inside_tree() and get_parent().has_method("set_village_solids"):
		get_parent().set_village_solids(enabled)
	for child in get_children():
		if child is CampNpcView:
			child.visual_v2 = enabled
			child.position = _npc_position("Ferreiro" if child.kind == 0 else "Vendedor",enabled)
			child.z_as_relative = false
			child.z_index = roundi(child.position.y+21)+100 if enabled else 0
	if enabled and v2_view == null:
		v2_view = FloorV2View.new()
		v2_view.layout = self
	queue_redraw()

func _build_depth_scenery(commands: Array) -> void:
	if depth_scenery != null: return
	depth_scenery = Node2D.new()
	depth_scenery.name = "VillageDepth"
	depth_scenery.visible = visual_v2
	add_child(depth_scenery)
	for command: Array in commands:
		var piece := Sprite2D.new()
		var region: Rect2 = command[1]
		var feet: Vector2 = command[2]
		piece.texture = command[0]
		piece.region_enabled = true
		piece.region_rect = region
		piece.centered = false
		piece.offset = Vector2(-region.size.x*0.5,-region.size.y)
		piece.position = feet.round()
		piece.scale = Vector2.ONE*command[3]
		piece.z_as_relative = false
		piece.z_index = roundi(feet.y)+100
		depth_scenery.add_child(piece)
	var fire := Node2D.new()
	fire.set_script(preload("res://scripts/presentation/village_fire_view.gd"))
	fire.position = Vector2(534,570)
	fire.z_as_relative = false
	fire.z_index = 670
	depth_scenery.add_child(fire)
	chest_view = Node2D.new()
	chest_view.set_script(preload("res://scripts/presentation/village_chest_view.gd"))
	# Storage is at the house entrance, leaving the campfire clearing unobstructed.
	chest_view.position = Vector2(500,497)
	chest_view.z_as_relative = false
	# Sort at the chest's feet so an explorer standing south of it appears in front.
	chest_view.z_index = roundi(chest_view.position.y)+110
	depth_scenery.add_child(chest_view)

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
	var trees := _base_tree_positions()
	if expanded_world: trees.append_array(expansion_tree_positions())
	return trees

func _base_tree_positions() -> Array[Vector2]:
	var was_expanded := expanded_world
	expanded_world = false
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
	var filtered := trees.filter(func(at: Vector2): return not REMOVED_SECONDARY.has(at) and not TowerEntrance.LEGACY_BODY.grow(12.0).has_point(at))
	expanded_world = was_expanded
	return filtered

func expansion_tree_positions() -> Array[Vector2]:
	var trees: Array[Vector2] = []
	# These authored groupings frame each biome and preserve deliberate open spaces.
	for group: Dictionary in AUTHORED_DEEPWOOD_GROUPS:
		for offset: Vector2 in group.offsets:
			var at: Vector2 = group.center + offset
			if _free_for_expansion_tree(at,trees): trees.append(at)
	for group: Dictionary in DANGER_TREE_GROUPS:
		for offset: Vector2 in group.offsets:
			var at: Vector2 = group.center + offset
			if _free_for_expansion_tree(at,trees): trees.append(at)
	# Ruin perimeter and hidden grove are intentionally framed, not randomly seeded.
	for at: Vector2 in GROVE_FRAME_TREES:
		if _free_for_expansion_tree(at,trees): trees.append(at)
	for at: Vector2 in [Vector2(1260,110),Vector2(1370,92),Vector2(1550,105),Vector2(1630,340),Vector2(1280,345)]:
		if _free_for_expansion_tree(at,trees): trees.append(at)
	return trees

func expansion_bush_positions() -> Array[Vector2]:
	return [Vector2(1250,360),Vector2(1680,410),Vector2(1260,830),Vector2(1160,1015),
		Vector2(1650,1280),Vector2(120,1090),Vector2(330,1190),
		Vector2(620,1115),Vector2(1040,960),Vector2(1670,755),
		Vector2(300,1010),Vector2(560,1075),Vector2(1020,1170)]

func _free_for_expansion_tree(at: Vector2, existing: Array[Vector2]) -> bool:
	if at.x < 38.0 or at.x > 1662.0 or at.y < 42.0 or at.y > 1310.0:
		return false
	# Keep the tall tower's full silhouette clear, not just its colliding base.
	if Rect2(TowerEntrance.POSITION+Vector2(-115,-230),Vector2(230,260)).has_point(at): return false
	if not _free_for_decoration(at):
		return false
	# Keep extra breathing room around trails so tree trunks never pinch a route.
	for route: Dictionary in EXPANSION_TRAILS:
		var points: Array = route.points
		for i in range(points.size()-1):
			if at.distance_to(Geometry2D.get_closest_point_to_segment(at,points[i],points[i+1])) < float(route.width)*0.5+22.0:
				return false
	for i in range(SECRET_TRAIL.size()-1):
		if at.distance_to(Geometry2D.get_closest_point_to_segment(at,SECRET_TRAIL[i],SECRET_TRAIL[i+1])) < 42.0:
			return false
	for other: Vector2 in existing:
		if at.distance_squared_to(other) < 44.0*44.0:
			return false
	return true

func _draw_tree(at: Vector2) -> void:
	var species := _hash(roundi(at.y),roundi(at.x)) % 8
	var kind := 0
	if GROVE_FRAME_TREES.has(at):
		kind = 1
	elif at.y >= 900.0 and at.x < 1300.0:
		kind = 2 if _hash(roundi(at.y),roundi(at.x)+73)%9==0 else 0
	else:
		kind = 2 if species == 0 else 1 if species < 3 else 0
	# Smaller canopies and a visible root silhouette leave combat/navigation clear.
	draw_colored_polygon(PackedVector2Array([at+Vector2(-23,3),at+Vector2(-18,-7),at+Vector2(20,-7),at+Vector2(29,2),at+Vector2(24,10),at+Vector2(-16,10)]),Color("#819255"))
	draw_texture_rect_region(atlas,Rect2(at-Vector2(32,72),Vector2(64,80)),MataArt.TREE_REGIONS[kind])

func expansion_tree_is_green(at: Vector2) -> bool:
	if GROVE_FRAME_TREES.has(at) or DANGER_FRAME_TREES.has(at): return true
	if at.y >= 900.0 and at.x < 1300.0:
		return _hash(roundi(at.y),roundi(at.x)+73)%9 != 0
	return _hash(roundi(at.y),roundi(at.x))%3 == 0

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
	if expanded_world:
		for spawn: Vector2 in EXPANSION_RESERVED:
			if at.distance_squared_to(spawn)<32.0*32.0: return false
	var trails: Array = TRAILS.duplicate()
	if expanded_world:
		for trail_data: Dictionary in EXPANSION_TRAILS:
			trails.append(trail_data.points)
	for i in range(trails.size()):
		var trail: Array = trails[i]
		for j in range(trail.size() - 1):
			var width: float = TRAIL_WIDTHS[i] if i < TRAIL_WIDTHS.size() else float(EXPANSION_TRAILS[i-TRAIL_WIDTHS.size()].width)
			if at.distance_to(Geometry2D.get_closest_point_to_segment(at, trail[j], trail[j + 1])) < width * 0.5 + 12.0:
				return false
	if expanded_world:
		for j in range(SECRET_TRAIL.size()-1):
			if at.distance_to(Geometry2D.get_closest_point_to_segment(at,SECRET_TRAIL[j],SECRET_TRAIL[j+1]))<28.0:
				return false
		for rock: Rect2 in EXPANSION_ROCKS:
			if rock.grow(18).has_point(at): return false
		for block: Rect2 in _ruin_blocks():
			if block.grow(8).has_point(at): return false
		for bush: Vector2 in expansion_bush_positions():
			if at.distance_squared_to(bush)<36.0*36.0: return false
	return true

static func _ruin_blocks() -> Array[Rect2]:
	# A broken horseshoe leaves a clear western threshold and open courtyard center.
	return [Rect2(1300,142,72,24),Rect2(1390,136,58,25),Rect2(1480,145,68,24),
		Rect2(1284,176,20,54),Rect2(1284,306,22,30),Rect2(1320,320,55,20),
		Rect2(1408,322,48,20),Rect2(1486,314,72,22),Rect2(1550,176,22,62),
		Rect2(1550,266,22,48)]

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
