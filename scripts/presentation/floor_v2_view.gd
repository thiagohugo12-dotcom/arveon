class_name FloorV2View
extends RefCounted

# Original alpha, proportional rectangles and integer 2x art grid.
const VILLAGE := preload("res://assets/art/hub_v3/village.png")
const PROPS := preload("res://assets/art/hub_v3/props.png")
const GROUND := preload("res://assets/art/hub_v3/ground.png")
const EXPANSION_GROUND := preload("res://assets/art/hub_v3/expansion_ground.png")
const GRASS_SURROUND := preload("res://assets/art/hub_v3/grass_surround.png")
const NATURE := preload("res://assets/art/mata_v2/nature.png")
const CAMP := preload("res://assets/art/mata_v2/camp.png")
const RUIN_KIT := preload("res://assets/art/mata_v2/ancient_ruins_kit.png")
const STONE := Rect2(192,0,48,36)
const GRASS := Rect2(192,72,16,12)
const FLOWERS := Rect2(216,72,16,16)
const HOUSE := Rect2(0,0,96,96)
const FORGE := Rect2(104,0,96,80)
const MARKET := Rect2(208,0,80,72)
const ORANGE := Rect2(0,104,56,64)
const GREEN := Rect2(64,104,56,64)
const BUSH := Rect2(128,104,28,24)
const FENCE := Rect2(0,0,32,24)
const SIGN := Rect2(32,0,32,48)
const BARREL := Rect2(64,0,24,32)
const CRATE := Rect2(96,0,28,28)
const FIRE := Rect2(0,64,32,40)
const LANTERN := Rect2(32,64,32,56)
const PEBBLES := Rect2(96,64,28,20)
const RUIN_CELLS := [Rect2(0,0,128,128),Rect2(128,0,128,128),Rect2(256,0,128,128),
	Rect2(0,128,128,128),Rect2(128,128,128,128),Rect2(256,128,128,128)]
const BUILDING_BASES := [Rect2(600,340,160,30),Rect2(356,378,166,24),Rect2(610,566,140,26)]
var layout: FloorView
var depth_commands: Array = []

static func canopy_conflicts(feet: Vector2) -> bool:
	return Rect2(340,250,196,196).has_point(feet) or Rect2(584,180,196,212).has_point(feet) or Rect2(594,450,196,194).has_point(feet)

func visible_tree_positions() -> Array[Vector2]:
	return layout.tree_positions().filter(func(feet: Vector2): return not canopy_conflicts(feet))

func sprite(atlas: Texture2D, region: Rect2, feet: Vector2, scale: float = 2.0) -> void:
	if atlas == VILLAGE or atlas == CAMP or (atlas == PROPS and region != PEBBLES):
		if layout.depth_scenery == null:
			depth_commands.append([atlas,region,feet,scale])
			# Draw the same art as a first-frame fallback while its depth-sorted
			# Sprite2D is created after drawing. This prevents village props from
			# visibly popping in without mutating the scene tree inside _draw().
		else:
			return
	var size := region.size * scale
	layout.draw_texture_rect_region(atlas,Rect2((feet-Vector2(size.x*0.5,size.y)).round(),size),region)

func ruin_sprite(index: int, feet: Vector2, size: Vector2) -> void:
	var region: Rect2 = RUIN_CELLS[index]
	layout.draw_texture_rect_region(RUIN_KIT,Rect2((feet-Vector2(size.x*0.5,size.y)).round(),size),region)

func shadow(at: Vector2, width: float, height: float) -> void:
	for i in range(6):
		var extent: float = width * [0.5,0.8,1.0,0.95,0.8,0.5][i]
		layout.draw_rect(Rect2((at+Vector2(-extent*0.5,-height*0.5+i*height/6)).snapped(Vector2(2,2)),Vector2(extent,height/6).snapped(Vector2(2,2))),Color("#718f3f80"))

func paint() -> void:
	if layout == null: return
	depth_commands.clear()
	_paint_clean_ground()
	if layout.expanded_world:
		_paint_expansion_ground_details()
		_paint_biome_ground()
		_draw_expansion_trails()
	for i in range(75):
		var at := Vector2(24+layout._hash(i,27)%1152,24+layout._hash(i,82)%852).snapped(Vector2(2,2))
		if layout._free_for_decoration(at) and not Rect2(330,210,470,440).has_point(at):
			if i%13 == 0: flowers(at)
			else: grass(at,i)
	for at in bush_positions():
		shadow(at+Vector2(8,2),52,14)
		sprite(VILLAGE,BUSH,at)
	if layout.expanded_world:
		for at in layout.expansion_bush_positions():
			shadow(at+Vector2(8,2),52,14)
			sprite(VILLAGE,BUSH,at)
	for feet in visible_tree_positions():
		var expansion_tree := layout.expanded_world and (feet.x>1200.0 or feet.y>900.0)
		var tree_scale := float([1.35,1.55,1.72][layout._hash(roundi(feet.x),roundi(feet.y))%3]) if expansion_tree else 2.0
		shadow(feet+Vector2(10,4),72 if expansion_tree else 90,20 if expansion_tree else 24)
		var tree_region := GREEN if layout.expanded_world and layout.expansion_tree_is_green(feet) else ORANGE if layout._hash(roundi(feet.y),roundi(feet.x))%3 != 0 else GREEN
		sprite(VILLAGE,tree_region,feet+Vector2(0,6),tree_scale)
	for rock: Rect2 in FloorView.ROCKS:
		# Western rock remains physical beneath the workshop's stone back.
		if rock.position.x < 500: continue
		shadow(rock.get_center()+Vector2(10,rock.size.y*0.4),rock.size.x,18)
		layout.draw_texture_rect_region(NATURE,rock.grow(4),STONE)
	if layout.expanded_world:
		_draw_expansion_landmarks()
		_draw_deepwood_mushrooms()
		_draw_deepwood_logs()
	_camp()
	if layout.depth_scenery == null:
		layout.call_deferred("_build_depth_scenery",depth_commands.duplicate())

func _paint_expansion_ground() -> void:
	# Authored at the original ground's 2x pixel scale and exact grass/dirt palette.
	# The visual overdraw avoids a flat rectangular edge on tall/mobile screens.
	layout.draw_texture_rect(GRASS_SURROUND,Rect2(-600,-600,2900,2550),false)
	layout.draw_texture_rect(EXPANSION_GROUND,Rect2(0,0,1700,1350),false)

func _paint_expansion_ground_details() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 181026
	for i in range(82):
		var at: Vector2
		if i % 5 != 0:
			at = Vector2(rng.randi_range(34,1285),rng.randi_range(920,1320)).snapped(Vector2(2,2))
		else:
			at = Vector2(rng.randi_range(1215,1672),rng.randi_range(24,875)).snapped(Vector2(2,2))
		if not layout._free_for_decoration(at):
			continue
		if i % 17 == 0:
			layout.draw_texture_rect_region(NATURE,Rect2(at-Vector2(8,8),FLOWERS.size),FLOWERS,Color("#e6df9e"))
		else:
			_ground_tuft(at,i)
	# Tufts gather in irregular pockets along the forest floor, leaving routes clear.
	var pockets := [Vector2(250,1040),Vector2(495,1090),Vector2(300,1250),Vector2(900,930),Vector2(1020,1190),Vector2(1510,880)]
	for i in range(36):
		var center: Vector2 = pockets[i%pockets.size()]
		var at := (center+Vector2(rng.randi_range(-82,82),rng.randi_range(-68,68))).snapped(Vector2(2,2))
		if not layout._free_for_decoration(at): continue
		if i%11==0:
			layout.draw_texture_rect_region(NATURE,Rect2(at-Vector2(8,8),FLOWERS.size),FLOWERS,Color("#d2d995"))
		elif i%7==0:
			layout.draw_texture_rect_region(NATURE,Rect2(at-Vector2(12,9),Vector2(24,18)),STONE,Color("#cbc79a"))
		else:
			_ground_tuft(at,i+91)

func _ground_tuft(at: Vector2,seed: int) -> void:
	# Low grass belongs to the ground plane; the old 16x12 dark sprite read as a shrub.
	var green := Color("#7fa94a") if seed%3 else Color("#91b64f")
	layout.draw_rect(Rect2(at+Vector2(-3,-2),Vector2(2,3)),green)
	layout.draw_rect(Rect2(at+Vector2(1,-4),Vector2(2,5)),green)
	if seed%4==0:
		layout.draw_rect(Rect2(at+Vector2(4,-1),Vector2(2,2)),Color("#a3bf56"))

func _paint_biome_ground() -> void:
	# Broad, low-contrast patches establish distinct places while keeping the shared grass palette.
	for patch: Dictionary in [
		{"center":Vector2(240,1085),"rx":210.0,"ry":145.0,"color":Color("#66894a22")},
		{"center":Vector2(760,1120),"rx":255.0,"ry":175.0,"color":Color("#708d4b1c")},
		{"center":Vector2(1480,245),"rx":142.0,"ry":106.0,"color":Color("#a7a17a28")},
		{"center":Vector2(1480,640),"rx":182.0,"ry":126.0,"color":Color("#7f875020")},
		{"center":Vector2(1510,1160),"rx":145.0,"ry":118.0,"color":Color("#82964f1c")}
	]:
		_draw_broken_patch(patch.center,float(patch.rx),float(patch.ry),patch.color)
	for center: Vector2 in FloorView.DANGER_DRY_PATCHES:
		_draw_broken_patch(center,54.0,30.0,Color("#b8955a28"))
		for i in range(5):
			var mark := center+Vector2(-22+i*10,3+(i%2)*5)
			layout.draw_rect(Rect2(mark,Vector2(6,2)),Color("#766c4a48"))

func _draw_broken_patch(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(40):
		var angle := TAU*float(i)/40.0
		var wobble := 0.9+float(layout._hash(roundi(center.x)+i,roundi(center.y))%21)/100.0
		points.append((center+Vector2(cos(angle)*radius_x,sin(angle)*radius_y)*wobble).snapped(Vector2(2,2)))
	var tint := color
	tint.a *= 0.45
	layout.draw_colored_polygon(points,tint)

func _draw_expansion_trails() -> void:
	# Main trails are baked into the matching pixel ground texture.
	if layout.secret_path_revealed:
		_draw_trail(FloorView.SECRET_TRAIL,23.0,-1)

func _draw_trail(points: Array, width: float, route_index: int) -> void:
	if points.size()<2: return
	var centers := PackedVector2Array()
	var curve := Curve2D.new()
	for i in range(points.size()):
		var point: Vector2 = points[i]
		var before: Vector2 = points[maxi(0,i-1)]
		var after: Vector2 = points[mini(i+1,points.size()-1)]
		var tangent := (after-before)/6.0
		curve.add_point(point,-tangent,tangent)
	centers = curve.get_baked_points()
	var distance_from_start: Array[float] = [0.0]
	for n in range(1,centers.size()):
		distance_from_start.append(distance_from_start[n-1]+centers[n-1].distance_to(centers[n]))
	var total_distance: float = distance_from_start[distance_from_start.size()-1]
	var start_is_junction := _shared_trail_endpoint(points[0],route_index)
	var end_is_junction := _shared_trail_endpoint(points[points.size()-1],route_index)
	for border in [5.0,0.0]:
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		for n in range(centers.size()):
			var prev: Vector2 = centers[maxi(0,n-1)]
			var next: Vector2 = centers[mini(n+1,centers.size()-1)]
			var normal := (next-prev).normalized().orthogonal()
			var edge_wobble := sin(float(n)*0.105+width*1.7)*1.15+sin(float(n)*0.29+width)*0.55
			var start_fade := 1.0 if start_is_junction else smoothstep(0.0,40.0,distance_from_start[n])
			var end_fade := 1.0 if end_is_junction else smoothstep(0.0,40.0,total_distance-distance_from_start[n])
			var fade := maxf(0.08,minf(start_fade,end_fade))
			var half_width: float = (width*.5+border+edge_wobble)*fade
			left.append((centers[n]+normal*half_width).floor())
			right.append((centers[n]-normal*half_width).floor())
		for n in range(right.size()-1,-1,-1): left.append(right[n])
		layout.draw_colored_polygon(left,Color("#9b8953") if border>0 else Color("#edcd80"))
		var cap_color := Color("#9b8953") if border>0 else Color("#edcd80")
	# The last 40 world units taper into the grass unless another trail joins there.

func _shared_trail_endpoint(point: Vector2, route_index: int) -> bool:
	for i in range(FloorView.EXPANSION_TRAILS.size()):
		if i==route_index: continue
		for candidate: Vector2 in FloorView.EXPANSION_TRAILS[i].points:
			if point.distance_to(candidate)<1.0: return true
	return false

func _draw_expansion_landmarks() -> void:
	_draw_ruins()
	_draw_danger_arena()
	_draw_secret_grove()

func _draw_ruins() -> void:
	# An old courtyard, broken perimeter, and low altar make one readable landmark.
	_draw_ruin_courtyard()
	var blocks: Array[Rect2] = FloorView._ruin_blocks()
	for i in range(blocks.size()):
		var block: Rect2 = blocks[i]
		_ruin_wall(block,i)
	for at: Vector2 in [Vector2(1348,310),Vector2(1395,323),Vector2(1515,313)]:
		_draw_ruin_rubble(at)
	_draw_ruin_paving()
	_draw_ruin_altar(Vector2(1500,214))

func _draw_ruin_courtyard() -> void:
	# Broken, mossy paving clusters leave bare earth between the slabs.
	for entry: Array in [[Vector2(1384,224),Vector2(64,38)],[Vector2(1415,284),Vector2(70,40)],
		[Vector2(1515,278),Vector2(62,36)],[Vector2(1532,205),Vector2(58,36)]]:
		_slab(entry[0] - Vector2(0,entry[1].y * 0.5),entry[1])

func _draw_ruin_paving() -> void:
	for at: Vector2 in [Vector2(1402,203),Vector2(1456,285),Vector2(1510,250)]:
		_slab(at - Vector2(0,13),Vector2(46,26))

func _draw_ruin_rubble(at: Vector2) -> void:
	shadow(at + Vector2(3,2),26,8)
	stone_piece(at,0.5,Color(1.2,1.15,0.95))
	stone_piece(at + Vector2(15,3),0.5,Color(1.1,1.05,0.88))

func _draw_ruin_altar(feet: Vector2) -> void:
	# Altar baixo: duas pedras de base, uma sobre elas e uma laje no topo.
	shadow(feet + Vector2(4,3),84,16)
	stone_piece(feet + Vector2(-24,0),1.0,Color(1.2,1.15,0.95))
	stone_piece(feet + Vector2(24,0),1.0,Color(1.1,1.05,0.88))
	stone_piece(feet + Vector2(0,-14),1.0,Color(1.3,1.25,1.05))
	_slab(feet + Vector2(0,-48),Vector2(50,14))

func _draw_danger_arena() -> void:
	# Boulder clusters and edge growth frame the same clear central combat floor.
	for i in range(FloorView.EXPANSION_ROCKS.size()):
		var rock: Rect2 = FloorView.EXPANSION_ROCKS[i]
		var feet := Vector2(rock.get_center().x,rock.end.y)
		var size := rock.size
		shadow(feet+Vector2(6,3),size.x,16)
		layout.draw_texture_rect_region(NATURE,Rect2(Vector2(feet.x-size.x*0.5,feet.y-size.y),size),STONE)
		if i%2==0:
			var small_at := feet+Vector2(rock.size.x*0.46,1)
			layout.draw_texture_rect_region(NATURE,Rect2(small_at-Vector2(10,7),Vector2(20,14)),STONE)
	_draw_broken_trunk(Vector2(1288,574),-1)
	_draw_broken_trunk(Vector2(1638,724),1)
	for at: Vector2 in [Vector2(1330,520),Vector2(1625,770),Vector2(1268,690)]:
		_draw_claw_marks(at)

func _draw_broken_trunk(at: Vector2, direction: float) -> void:
	var points := PackedVector2Array([at,at+Vector2(48*direction,-8),at+Vector2(51*direction,2),at+Vector2(5*direction,13)])
	layout.draw_colored_polygon(points,Color("#593f2e"))
	layout.draw_line(at+Vector2(5*direction,2),at+Vector2(45*direction,-5),Color("#a8733d"),4.0)
	layout.draw_circle(at+Vector2(50*direction,-3),5.0,Color("#d1b173"))
	layout.draw_circle(at+Vector2(50*direction,-3),2.0,Color("#806042"))

func _draw_claw_marks(at: Vector2) -> void:
	for i in range(3):
		layout.draw_line(at+Vector2(i*7,0),at+Vector2(i*7+8,-10),Color("#6d6e4b99"),2.0)

func _draw_secret_grove() -> void:
	# Exposed roots and an enlarged native canopy give the ancestral tree a clear silhouette.
	var foot := Vector2(1510,1160)
	_draw_ancestral_roots(foot)
	shadow(foot+Vector2(0,4),116,24)
	sprite(VILLAGE,ORANGE,foot,2.45)
	# Old stones and muted plants trace the clearing without crowding the western approach.
	for at: Vector2 in [Vector2(1420,1165),Vector2(1580,1125),Vector2(1585,1180),Vector2(1580,1240),Vector2(1460,1252),Vector2(1450,1105)]:
		shadow(at+Vector2(6,3),28,8)
		layout.draw_texture_rect_region(NATURE,Rect2(at-Vector2(14,10),Vector2(28,20)),STONE)
	for at: Vector2 in [Vector2(1400,1118),Vector2(1440,1260),Vector2(1605,1100),Vector2(1550,1280)]:
		layout.draw_texture_rect_region(NATURE,Rect2(at-Vector2(8,8),FLOWERS.size),FLOWERS,Color("#bdc58a"))
	# A small, broken stone pair hints at the concealed western entry before discovery.
	for at: Vector2 in [Vector2(1318,1156),Vector2(1342,1145),Vector2(1367,1132),Vector2(1392,1118)]:
		layout.draw_texture_rect_region(NATURE,Rect2(at-Vector2(8,6),Vector2(16,12)),STONE)
	for at: Vector2 in [Vector2(1370,1168),Vector2(1398,1148),Vector2(1418,1136),Vector2(1436,1128)]:
		layout.draw_texture_rect_region(NATURE,Rect2(at-Vector2(11,8),Vector2(22,16)),GRASS,Color("#7e9e4b"))

func _draw_ancestral_roots(foot: Vector2) -> void:
	for root: Array in [[Vector2(-5,-2),Vector2(-47,9)],[Vector2(5,-2),Vector2(48,10)],[Vector2(-2,2),Vector2(-24,20)],[Vector2(3,2),Vector2(24,22)]]:
		var start: Vector2 = foot+root[0]
		var finish: Vector2 = foot+root[1]
		layout.draw_line(start,finish,Color("#65442d"),9.0)
		layout.draw_line(start+Vector2(0,-2),finish+Vector2(0,-2),Color("#a56b38"),4.0)

func _draw_deepwood_mushrooms() -> void:
	for i in range(FloorView.DEEPWOOD_MUSHROOMS.size()):
		var at: Vector2 = FloorView.DEEPWOOD_MUSHROOMS[i]
		if not layout._free_for_decoration(at): continue
		# Tiny red caps and cream stems match the game's existing forage icons.
		layout.draw_rect(Rect2(at+Vector2(-5,4),Vector2(12,2)),Color("#768d42"))
		layout.draw_rect(Rect2(at+Vector2(-1,-2),Vector2(3,7)),Color("#f0dfb0"))
		layout.draw_rect(Rect2(at+Vector2(-5,-5),Vector2(11,4)),Color("#b94936"))
		layout.draw_rect(Rect2(at+Vector2(-3,-6),Vector2(7,2)),Color("#cf6043"))
		layout.draw_rect(Rect2(at+Vector2(-3,-4),Vector2(2,2)),Color("#fff0c9"))
		layout.draw_rect(Rect2(at+Vector2(2,-5),Vector2(2,2)),Color("#fff0c9"))

func _draw_deepwood_logs() -> void:
	for i in range(FloorView.DEEPWOOD_LOGS.size()):
		var log: Rect2 = FloorView.DEEPWOOD_LOGS[i]
		var at := log.position
		shadow(at+Vector2(log.size.x*0.5,log.size.y+4),log.size.x+4,7)
		layout.draw_rect(Rect2(at+Vector2(3,3),Vector2(log.size.x-5,log.size.y-2)),Color("#573c2a"))
		layout.draw_rect(Rect2(at+Vector2(2,1),Vector2(log.size.x-7,log.size.y-4)),Color("#83552f"))
		layout.draw_rect(Rect2(at+Vector2(5,2),Vector2(log.size.x-14,2)),Color("#b17a42"))
		var end := Vector2(at.x+log.size.x-4,at.y+5)
		layout.draw_circle(end,5.0,Color("#d0a267"))
		layout.draw_circle(end,3.0,Color("#855a37"))
		if i%2==0:
			layout.draw_rect(Rect2(at+Vector2(8,-2),Vector2(12,4)),Color("#668b45"))

func bush_positions() -> Array[Vector2]:
	# Authored groups frame the service areas; the center and approaches stay open.
	return [Vector2(332,416),Vector2(776,376),Vector2(386,622),Vector2(730,674),
		Vector2(84,280),Vector2(252,180),Vector2(862,230),Vector2(1080,230),
		Vector2(1090,580),Vector2(974,804),Vector2(664,822),Vector2(342,776),
		Vector2(132,620),Vector2(430,144)]

func grass(at: Vector2, variant: int) -> void:
	var tone := Color("#7f9d43") if variant%3 else Color("#d5d86b")
	for blade: Rect2 in [Rect2(-6,-6,2,4),Rect2(-4,-4,2,4),Rect2(0,-10,2,10),Rect2(4,-6,2,6)]:
		layout.draw_rect(Rect2(at+blade.position,blade.size),tone)

func flowers(at: Vector2) -> void:
	for offset: Vector2 in [Vector2(-8,0),Vector2(2,-8),Vector2(10,2)]:
		var center := at+offset
		layout.draw_rect(Rect2(center+Vector2(0,2),Vector2(2,6)),Color("#749942"))
		layout.draw_rect(Rect2(center+Vector2(-2,-4),Vector2(6,2)),Color("#fff2c6"))
		layout.draw_rect(Rect2(center+Vector2(-4,-2),Vector2(10,2)),Color("#fff2c6"))
		layout.draw_rect(Rect2(center+Vector2(-2,0),Vector2(6,2)),Color("#fff2c6"))
		layout.draw_rect(Rect2(center+Vector2(0,-2),Vector2(2,2)),Color("#e9bd58"))

func _camp() -> void:
	# Separate service clearings, with an open central circulation route.
	for feet: Vector2 in [Vector2(346,462),Vector2(444,610),Vector2(714,420),Vector2(714,662)]:
		shadow(feet+Vector2(6,0),64,12)
		sprite(PROPS,FENCE,feet)
	shadow(Vector2(688,371),180,26)
	sprite(VILLAGE,HOUSE,Vector2(680,376))
	shadow(Vector2(448,404),180,24)
	sprite(VILLAGE,FORGE,Vector2(440,408))
	shadow(Vector2(688,591),150,22)
	sprite(VILLAGE,MARKET,Vector2(680,596))
	sprite(PROPS,SIGN,Vector2(546,390))
	sprite(PROPS,BARREL,Vector2(592,380))
	sprite(PROPS,CRATE,Vector2(348,396))
	sprite(PROPS,CRATE,Vector2(762,620))
	sprite(PROPS,LANTERN,Vector2(602,526))
	sprite(PROPS,FIRE,Vector2(534,570))
	for at: Vector2 in [Vector2(328,476),Vector2(558,326),Vector2(764,422),Vector2(400,614),Vector2(620,652),Vector2(750,676)]:
		flowers(at)
	for at: Vector2 in [Vector2(584,432),Vector2(574,608),Vector2(340,530)]:
		sprite(PROPS,PEBBLES,at,1)

# ── Terreno limpo do Andar 1 (substitui as texturas assadas) ───────────────────────────────
# Grama em duas tonalidades, trilhas lisas com borda de pixel e praça do acampamento: tudo vem
# dos mesmos dados (FloorView.TRAILS/EXPANSION_TRAILS) que o mapa usa, sem emendas retas.
const GRASS_BASE := Color("#b4c957")
const GRASS_DARK := Color("#a6bc4d")
const GRASS_LIGHT := Color("#c0d263")
const ROAD_FILL := Color("#efcd86")
const ROAD_EDGE := Color("#c5a35d")

func _paint_clean_ground() -> void:
	var expanded := layout.expanded_world
	var world := Rect2(0,0,1700,1350) if expanded else Rect2(0,0,1200,900)
	layout.draw_rect(Rect2(-600,-600,2900,2550) if expanded else world,GRASS_BASE)
	var step := 110
	for gy in range(-1,int(world.size.y / step) + 2):
		for gx in range(-1,int(world.size.x / step) + 2):
			var h := absi(layout._hash(gx + 31,gy + 17))
			if h % 100 >= 58: continue
			var center := Vector2(gx * step + h % 80,gy * step + (h / 80) % 80)
			var radius := 22.0 + float(h % 34)
			var color := GRASS_LIGHT if (h / 7) % 3 == 0 else GRASS_DARK
			_soft_blob(center,radius,radius * 0.68,color,h)
	_paint_roads(expanded)

func _soft_blob(center: Vector2, radius_x: float, radius_y: float, color: Color, seed: int) -> void:
	var points := PackedVector2Array()
	for i in range(28):
		var angle := TAU * float(i) / 28.0
		var wobble := 0.86 + float(layout._hash(seed + i * 13,i) % 29) / 100.0
		points.append((center + Vector2(cos(angle) * radius_x,sin(angle) * radius_y) * wobble).snapped(Vector2(2,2)))
	layout.draw_colored_polygon(points,color)

func _paint_roads(expanded: bool) -> void:
	var routes: Array = []
	for i in range(FloorView.TRAILS.size()):
		routes.append({"points":FloorView.TRAILS[i],"width":FloorView.TRAIL_WIDTHS[i]})
	if expanded: routes.append_array(FloorView.EXPANSION_TRAILS)
	var plaza := _plaza(0.0)
	var plaza_fill := _plaza(-4.0)
	# Bordas primeiro, depois os miolos: os cruzamentos ficam fundidos, sem costura.
	layout.draw_colored_polygon(plaza,ROAD_EDGE)
	for index in range(routes.size()):
		layout.draw_colored_polygon(_road_polygon(routes,index,4.0),ROAD_EDGE)
	layout.draw_colored_polygon(plaza_fill,ROAD_FILL)
	for index in range(routes.size()):
		layout.draw_colored_polygon(_road_polygon(routes,index,0.0),ROAD_FILL)
	# Marcas de uso: pontinhos mais claros ao longo do caminho.
	for route: Dictionary in routes:
		var points: Array = route.points
		for j in range(points.size() - 1):
			var mark: Vector2 = (points[j] as Vector2).lerp(points[j + 1],0.5).snapped(Vector2(2,2))
			layout.draw_rect(Rect2(mark,Vector2(6,2)),Color("#f7e3ae"))

func _plaza(grow: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(56):
		var angle := TAU * float(i) / 56.0
		var wobble := 0.93 + float(layout._hash(i * 7,91) % 15) / 100.0
		points.append((Vector2(560,478) + Vector2(cos(angle) * (250.0 + grow),sin(angle) * (176.0 + grow)) * wobble).snapped(Vector2(2,2)))
	return points

func _road_polygon(routes: Array, index: int, border: float) -> PackedVector2Array:
	var route: Dictionary = routes[index]
	var points: Array = route.points
	var width: float = route.width
	var curve := Curve2D.new()
	for i in range(points.size()):
		var before: Vector2 = points[maxi(0,i - 1)]
		var after: Vector2 = points[mini(i + 1,points.size() - 1)]
		var tangent := (after - before) / 6.0
		curve.add_point(points[i],-tangent,tangent)
	var centers := curve.get_baked_points()
	var travelled: Array[float] = [0.0]
	for n in range(1,centers.size()): travelled.append(travelled[n - 1] + centers[n - 1].distance_to(centers[n]))
	var total: float = travelled[travelled.size() - 1]
	var start_join := _road_join(points[0],routes,index)
	var end_join := _road_join(points[points.size() - 1],routes,index)
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for n in range(centers.size()):
		var previous: Vector2 = centers[maxi(0,n - 1)]
		var next: Vector2 = centers[mini(n + 1,centers.size() - 1)]
		var normal := (next - previous).normalized().orthogonal()
		var taper := minf(1.0 if start_join else smoothstep(0.0,34.0,travelled[n]),1.0 if end_join else smoothstep(0.0,34.0,total - travelled[n]))
		var half := width * 0.5 * maxf(0.35,taper) + border + sin(float(n) * 0.13 + width) * 0.9
		left.append((centers[n] + normal * half).snapped(Vector2(2,2)))
		right.append((centers[n] - normal * half).snapped(Vector2(2,2)))
	for n in range(right.size() - 1,-1,-1): left.append(right[n])
	return left

func _road_join(point: Vector2, routes: Array, own: int) -> bool:
	if point.distance_to(Vector2(560,478)) < 280.0: return true
	for i in range(routes.size()):
		if i == own: continue
		for candidate: Vector2 in routes[i].points:
			if candidate.distance_to(point) < 44.0: return true
	return false

# Pedra do próprio jogo (nature.png) ancorada nos pés; "tone" tinge de areia as ruínas.
func stone_piece(feet: Vector2, scale: float, tone: Color = Color.WHITE) -> void:
	var size := STONE.size * scale
	layout.draw_texture_rect_region(NATURE,Rect2((feet - Vector2(size.x * 0.5,size.y)).round(),size),STONE,tone)

func _ruin_wall(block: Rect2, index: int) -> void:
	var horizontal := block.size.x >= block.size.y
	var length := block.size.x if horizontal else block.size.y
	var big := length >= 50.0
	var spacing := 36.0 if big else 20.0
	var count := maxi(1,roundi(length / spacing))
	for n in range(count):
		var t := (float(n) + 0.5) / float(count)
		var feet := Vector2(block.position.x + block.size.x * t,block.end.y + 2.0) if horizontal else Vector2(block.get_center().x,block.position.y + block.size.y * t + 8.0)
		shadow(feet + Vector2(4,2),30 if big else 18,8)
		stone_piece(feet,1.0 if big and (n + index) % 2 == 0 else 0.5,Color(1.2,1.15,0.95) if (n + index) % 3 else Color(1.08,1.03,0.88))

# Laje de piso: pedra lisa em pixels, com brilho no topo, junta ao meio e um toque de musgo.
func _slab(center: Vector2, size: Vector2) -> void:
	var rect := Rect2((center - size * 0.5).snapped(Vector2(2,2)),size.snapped(Vector2(2,2)))
	layout.draw_rect(rect.grow(2),Color("#77735a"))
	layout.draw_rect(rect,Color("#b9b08c"))
	layout.draw_rect(Rect2(rect.position,Vector2(rect.size.x,2)),Color("#d3ccaa"))
	layout.draw_rect(Rect2(rect.position + Vector2(0,rect.size.y - 2),Vector2(rect.size.x,2)),Color("#948d6d"))
	layout.draw_rect(Rect2(rect.position + Vector2(roundf(rect.size.x * 0.25) * 2.0,2),Vector2(2,rect.size.y - 4)),Color("#968f70"))
	layout.draw_rect(Rect2(rect.position + Vector2(2,2),Vector2(8,4)),Color("#7fa04a"))
