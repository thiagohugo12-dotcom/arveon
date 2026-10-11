class_name FloorV2View
extends RefCounted

const NATURE := preload("res://assets/art/mata_v2/nature_simple.png")
const PATHS := preload("res://assets/art/mata_v2/paths.png")
const CAMP := preload("res://assets/art/mata_v2/camp_simple.png")
const PROPS := preload("res://assets/art/mata_v2/camp_props.png")
const GREEN := Rect2(0,0,88,96)
const ORANGE := Rect2(96,0,88,96)
const STONE := Rect2(192,0,48,36)
const BUSH := Rect2(192,40,36,24)
const GRASS := Rect2(192,72,16,12)
const FLOWERS := Rect2(216,72,16,16)
const CABIN := Rect2(0,0,96,96)
const MARKET := Rect2(104,0,56,56)
const FORGE := Rect2(168,0,56,56)
const PORTAL := Rect2(104,64,84,100)
const FENCE_PROP := Rect2(0,0,32,16)
const SIGN_PROP := Rect2(32,0,20,28)
const BARREL_PROP := Rect2(52,0,20,24)
const CRATE_PROP := Rect2(76,0,20,24)
const FIRE_PROP := Rect2(0,32,32,32)
const LANTERN_PROP := Rect2(32,32,24,32)
const BENCH_PROP := Rect2(64,32,32,32)
const PEBBLES_PROP := Rect2(96,32,32,24)
var layout: FloorView


func sprite(atlas: Texture2D, region: Rect2, at: Vector2) -> void:
	layout.draw_texture_rect_region(atlas,Rect2(at-Vector2(region.size.x*0.5,region.size.y),region.size),region)

func sprite_scaled(atlas: Texture2D, region: Rect2, at: Vector2, scale: float) -> void:
	var size := region.size * scale
	layout.draw_texture_rect_region(atlas,Rect2(at-Vector2(size.x*0.5,size.y),size),region)

func prop(region: Rect2, at: Vector2, scale: float = 1.0) -> void:
	# Props keep their intended physical size instead of being compressed into the hub.
	sprite_scaled(PROPS,region,at,scale)

func shadow(at: Vector2, width: float, height: float) -> void:
	for i in range(6):
		var extent: float = width * [0.5,0.8,1.0,0.95,0.8,0.5][i]
		layout.draw_rect(Rect2(at+Vector2(-extent*0.5,-height*0.5+i*height/6),Vector2(extent,height/6)),Color("#9ab94f"))

func paint() -> void:
	if layout == null:
		return
	layout.draw_rect(Rect2(0,0,1200,900),Color("#b9cc59"))
	# Sparse tiny colour clusters; no dense repeated texture.
	for i in range(190):
		var at := Vector2(18+layout._hash(i,27)%1164,18+layout._hash(i,82)%864).snapped(Vector2(2,2))
		var tone := Color("#c2d46b") if i%3 else Color("#aec44f")
		layout.draw_rect(Rect2(at,Vector2(4,2)),tone)
		if i%4 == 0:
			layout.draw_rect(Rect2(at+Vector2(2,-2),Vector2(2,2)),tone)
	# One cached authored path texture, rather than thousands of stamp commands.
	layout.draw_texture_rect(PATHS,Rect2(0,0,1200,900),false)
	# Identical decorative anchors / safety exclusions as the existing layout.
	var rng := RandomNumberGenerator.new()
	rng.seed = 12051
	for i in range(56):
		var at := Vector2(rng.randi_range(20,1175),rng.randi_range(20,875))
		if layout._free_for_decoration(at):
			if i%19 == 0:
				prop(PEBBLES_PROP,at+Vector2(0,8),1.15)
			else:
				sprite(NATURE,FLOWERS if i%11==0 else BUSH if i%23==0 else GRASS,at)
	# A separate sparse pass makes bushes visible without competing with trees.
	for at in bush_positions():
		shadow(at+Vector2(2,1),30,8)
		sprite(NATURE,BUSH,at)
	for feet in layout.tree_positions():
		shadow(feet+Vector2(6,2),62,18)
		sprite(NATURE,ORANGE if layout._hash(roundi(feet.y),roundi(feet.x))%8==0 else GREEN,feet+Vector2(0,6))
	for rock: Rect2 in FloorView.ROCKS:
		shadow(rock.get_center()+Vector2(0,rock.size.y*0.4),rock.size.x,18)
		# Cover the existing collision footprint with a recognisable stone mass.
		layout.draw_texture_rect_region(NATURE,rock.grow(4),STONE)
	_camp()

func bush_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 28031
	var trees := layout.tree_positions()
	for i in range(240):
		var at := Vector2(rng.randi_range(40,1160),rng.randi_range(40,860)).snapped(Vector2(2,2))
		if not layout._free_for_decoration(at):
			continue
		var clear := true
		for feet in trees:
			if Rect2(feet-Vector2(58,108),Vector2(116,126)).has_point(at):
				clear = false
		for other in positions:
			if at.distance_squared_to(other) < 64.0*64.0:
				clear = false
		if clear:
			positions.append(at)
		if positions.size() == 18:
			break
	return positions

func _camp() -> void:
	# The camp uses a full environmental scale; interaction points remain unchanged.
	for n in range(18):
		layout._draw_flagstone(Vector2(556+layout._hash(n,71)%21-10,369+n*10),n)
	# The fence segments mark the hub without enclosing it or filling the scene.
	for at in [Vector2(496,352),Vector2(610,352),Vector2(496,548),Vector2(610,548)]:
		prop(FENCE_PROP,at,1.95)
	# Buildings deliberately occupy a larger footprint, matching the world scale.
	layout.draw_texture_rect_region(CAMP,Rect2(404,197,192,192),CABIN)
	sprite_scaled(CAMP,FORGE,SafeCamp.STATIONS["Ferreiro"]+Vector2(0,24),1.85)
	sprite_scaled(CAMP,MARKET,SafeCamp.STATIONS["Vendedor"]+Vector2(0,18),1.45)
	layout._draw_chest(SafeCamp.STATIONS["Baú"])
	# Service markers remain sparse, but are deliberately legible at gameplay scale.
	for name: String in ["Baú","Ferreiro","Vendedor"]:
		prop(SIGN_PROP,SafeCamp.STATIONS[name]+Vector2(28,-4),1.9)
	for point: Vector2 in [Vector2(480,411),Vector2(633,420)]:
		prop(BARREL_PROP,point,1.75)
	for point: Vector2 in [Vector2(484,526),Vector2(631,535)]:
		prop(CRATE_PROP,point,1.75)
	for point: Vector2 in [Vector2(479,374),Vector2(638,474)]:
		prop(LANTERN_PROP,point,1.9)
	prop(BENCH_PROP,Vector2(548,544),1.75)
	prop(FIRE_PROP,Vector2(516,492),1.75)
