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
	if layout.expanded_world:
		_paint_expansion_ground()
	layout.draw_texture_rect(GROUND,Rect2(0,0,1200,900),false)
	_heal_ground_seams()
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
		_draw_trail(FloorView.SECRET_TRAIL,30.0,-1)

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
	# Mesmo padrão das trilhas do chão: miolo liso na cor da trilha, sem contorno escuro.
	for border in [0.0]:
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
		layout.draw_colored_polygon(left,Color("#f4ce7e"))
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
		if block.size.x>=block.size.y:
			ruin_sprite(i%2,Vector2(block.get_center().x,block.end.y),Vector2(block.size.x+8,54.0))
		else:
			ruin_sprite(2,Vector2(block.get_center().x,block.end.y),Vector2(42.0,58.0))
	for at: Vector2 in [Vector2(1348,310),Vector2(1395,323),Vector2(1515,313)]:
		_draw_ruin_rubble(at)
	_draw_ruin_paving()
	_draw_ruin_altar(Vector2(1500,214))

func _draw_ruin_courtyard() -> void:
	# Broken, mossy paving clusters leave bare earth between the slabs.
	for entry: Array in [[Vector2(1384,224),Vector2(64,38)],[Vector2(1415,284),Vector2(70,40)],
		[Vector2(1515,278),Vector2(62,36)],[Vector2(1532,205),Vector2(58,36)]]:
		ruin_sprite(5,entry[0],entry[1])

func _draw_ruin_paving() -> void:
	for at: Vector2 in [Vector2(1402,203),Vector2(1456,285),Vector2(1510,250)]:
		ruin_sprite(5,at,Vector2(48,27))

func _draw_ruin_rubble(at: Vector2) -> void:
	ruin_sprite(3,at,Vector2(42,32))

func _draw_ruin_altar(feet: Vector2) -> void:
	ruin_sprite(4,feet,Vector2(76,52))

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

# ── Emendas do chão ────────────────────────────────────────────────────────────────────────
# O chão da vila (1200x900) e o da expansão são imagens separadas: em x=1200 e y=900 manchas e
# trilhas eram cortadas em linha reta. Uma faixa de grama com bordas suaves esconde o corte e a
# trilha é refeita ligando as duas pontas (lidas dos próprios pixels), na mesma cor e sem contorno.
const SEAM_HOLD := 12
const SEAM_FADE := 14
const SEAM_ROAD := Color("#f4ce7e")
const SEAM_GRASS := Color("#b5c953")

func _heal_ground_seams() -> void:
	if not layout.expanded_world: return
	var village := GROUND.get_image()
	var expansion := EXPANSION_GROUND.get_image()
	if village == null or expansion == null: return
	# Emenda vertical (x = 1200): linhas 0..449 das duas imagens.
	_seam_cover(true,Rect2(0,0,0,900))
	for pair: Array in _road_pairs(village,expansion,true):
		_seam_bridge(true,pair)
	# Emenda horizontal (y = 900): colunas 0..599 da vila contra 0..599 da expansão.
	_seam_cover(false,Rect2(0,0,1250,0))
	for pair: Array in _road_pairs(village,expansion,false):
		_seam_bridge(false,pair)

func _seam_cover(vertical: bool, span: Rect2) -> void:
	var seam := 1200.0 if vertical else 900.0
	var offsets := [-float(SEAM_HOLD + SEAM_FADE),-float(SEAM_HOLD),float(SEAM_HOLD),float(SEAM_HOLD + SEAM_FADE)]
	var alphas := [0.0,1.0,1.0,0.0]
	for i in range(3):
		var a: float = seam + offsets[i] * 2.0
		var b: float = seam + offsets[i + 1] * 2.0
		var from_alpha: float = alphas[i]
		var to_alpha: float = alphas[i + 1]
		var colors := PackedColorArray([Color(SEAM_GRASS,from_alpha),Color(SEAM_GRASS,to_alpha),Color(SEAM_GRASS,to_alpha),Color(SEAM_GRASS,from_alpha)])
		var points: PackedVector2Array
		if vertical:
			points = PackedVector2Array([Vector2(a,0),Vector2(b,0),Vector2(b,900),Vector2(a,900)])
		else:
			points = PackedVector2Array([Vector2(0,a),Vector2(0,b),Vector2(1250,b),Vector2(1250,a)])
		layout.draw_polygon(points,colors)

func _is_road_pixel(color: Color) -> bool:
	return color.a > 0.5 and color.r > 0.85 and color.g > 0.7 and color.b < 0.6

# Trechos de trilha (início, fim em pixels da imagem) numa coluna ou linha, nas duas imagens.
func _road_runs(image: Image, line: int, vertical: bool, length: int) -> Array:
	var runs := []
	var start := -1
	for i in range(length):
		var color := image.get_pixel(line,i) if vertical else image.get_pixel(i,line)
		var road := _is_road_pixel(color)
		if road and start < 0: start = i
		if not road and start >= 0:
			runs.append([start,i - 1])
			start = -1
	if start >= 0: runs.append([start,length - 1])
	return runs

func _road_pairs(village: Image, expansion: Image, vertical: bool) -> Array:
	var reach := SEAM_HOLD + SEAM_FADE
	var length := 450 if vertical else 600
	var left := _road_runs(village,600 - reach if vertical else 450 - reach,vertical,length)
	var right := _road_runs(expansion,600 + reach if vertical else 450 + reach,vertical,length)
	var pairs := []
	for a: Array in left:
		var best: Array = []
		var best_gap := 9999.0
		for b: Array in right:
			var gap := absf(float(a[0] + a[1]) * 0.5 - float(b[0] + b[1]) * 0.5)
			if gap < best_gap: best_gap = gap; best = b
		if not best.is_empty() and best_gap <= 60.0 and a[1] - a[0] >= 6 and best[1] - best[0] >= 6: pairs.append([a,best])
	return pairs

func _seam_bridge(vertical: bool, pair: Array) -> void:
	var reach := float(SEAM_HOLD + SEAM_FADE) * 2.0
	var seam := 1200.0 if vertical else 900.0
	var a: Array = pair[0]
	var b: Array = pair[1]
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	for step in range(13):
		var t := float(step) / 12.0
		var eased := smoothstep(0.0,1.0,t)
		var along := seam - reach + t * reach * 2.0
		var first := lerpf(float(a[0]) * 2.0,float(b[0]) * 2.0,eased)
		var last := lerpf(float(a[1] + 1) * 2.0,float(b[1] + 1) * 2.0,eased)
		if vertical:
			top.append(Vector2(along,first).snapped(Vector2(2,2)))
			bottom.append(Vector2(along,last).snapped(Vector2(2,2)))
		else:
			top.append(Vector2(first,along).snapped(Vector2(2,2)))
			bottom.append(Vector2(last,along).snapped(Vector2(2,2)))
	bottom.reverse()
	top.append_array(bottom)
	layout.draw_colored_polygon(top,SEAM_ROAD)
