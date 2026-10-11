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
	layout.draw_rect(Rect2(0,0,1200,900),Color("#b6c95a"))
	# Sparse tiny colour clusters; no dense repeated texture.
	for i in range(120):
		var at := Vector2(18+layout._hash(i,27)%1164,18+layout._hash(i,82)%864).snapped(Vector2(2,2))
		var tone := Color("#c3d46d") if i%3 else Color("#a9bf50")
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
		_simple_tree(feet,layout._hash(roundi(feet.y),roundi(feet.x))%8==0)
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
		if positions.size() == 12:
			break
	return positions

func _simple_tree(feet: Vector2, autumn: bool) -> void:
	# Three broad colour masses replace the detailed canopy texture.
	shadow(feet+Vector2(4,1),56,14)
	var trunk_dark := Color("#5a3c2d")
	var trunk := Color("#8b5534")
	layout.draw_colored_polygon(PackedVector2Array([
		feet+Vector2(-12,-2),feet+Vector2(-6,-8),feet+Vector2(-5,-27),
		feet+Vector2(5,-27),feet+Vector2(6,-8),feet+Vector2(13,-2),
		feet+Vector2(7,2),feet+Vector2(1,-3),feet+Vector2(-6,2)
	]),trunk_dark)
	layout.draw_rect(Rect2(feet+Vector2(-3,-27),Vector2(6,24)),trunk)
	var dark := Color("#b94f25") if autumn else Color("#246047")
	var mid := Color("#e96a26") if autumn else Color("#4e8c50")
	var light := Color("#ff9f2c") if autumn else Color("#91ad43")
	layout.draw_colored_polygon(PackedVector2Array([
		feet+Vector2(-30,-31),feet+Vector2(-33,-48),feet+Vector2(-26,-62),
		feet+Vector2(-15,-67),feet+Vector2(-10,-78),feet+Vector2(7,-80),
		feet+Vector2(16,-73),feet+Vector2(27,-68),feet+Vector2(32,-53),
		feet+Vector2(29,-35),feet+Vector2(18,-26),feet+Vector2(3,-28),
		feet+Vector2(-10,-24),feet+Vector2(-23,-27)
	]),dark)
	layout.draw_colored_polygon(PackedVector2Array([
		feet+Vector2(-25,-39),feet+Vector2(-27,-52),feet+Vector2(-19,-61),
		feet+Vector2(-9,-62),feet+Vector2(-5,-72),feet+Vector2(8,-74),
		feet+Vector2(14,-67),feet+Vector2(24,-62),feet+Vector2(27,-50),
		feet+Vector2(22,-37),feet+Vector2(10,-32),feet+Vector2(-3,-35),
		feet+Vector2(-14,-31)
	]),mid)
	for cluster in [Rect2(feet+Vector2(-18,-60),Vector2(14,10)),Rect2(feet+Vector2(-3,-69),Vector2(16,10)),Rect2(feet+Vector2(7,-51),Vector2(15,11))]:
		layout.draw_rect(cluster,light)

func _simple_cabin(base: Vector2) -> void:
	# The house keeps the original footprint and uses only the parts needed for recognition.
	shadow(base+Vector2(3,-1),84,13)
	var outline := Color("#503329")
	var wood := Color("#9a5f35")
	var wall := Color("#e5d39d")
	var roof_dark := Color("#823b2d")
	var roof := Color("#bd5233")
	layout.draw_rect(Rect2(base+Vector2(-38,-52),Vector2(76,52)),outline)
	layout.draw_rect(Rect2(base+Vector2(-34,-48),Vector2(68,45)),wall)
	layout.draw_colored_polygon(PackedVector2Array([
		base+Vector2(-44,-48),base+Vector2(-33,-72),base+Vector2(-17,-84),
		base+Vector2(17,-84),base+Vector2(34,-72),base+Vector2(44,-48),
		base+Vector2(36,-43),base+Vector2(-36,-43)
	]),roof_dark)
	layout.draw_colored_polygon(PackedVector2Array([
		base+Vector2(-37,-50),base+Vector2(-28,-69),base+Vector2(-14,-79),
		base+Vector2(15,-79),base+Vector2(29,-68),base+Vector2(37,-50)
	]),roof)
	layout.draw_rect(Rect2(base+Vector2(-31,-47),Vector2(5,44)),wood)
	layout.draw_rect(Rect2(base+Vector2(26,-47),Vector2(5,44)),wood)
	layout.draw_rect(Rect2(base+Vector2(-10,-36),Vector2(20,36)),outline)
	layout.draw_rect(Rect2(base+Vector2(-7,-33),Vector2(14,33)),wood)
	layout.draw_rect(Rect2(base+Vector2(16,-33),Vector2(13,13)),outline)
	layout.draw_rect(Rect2(base+Vector2(19,-30),Vector2(7,7)),Color("#5ba4a1"))
	layout.draw_rect(Rect2(base+Vector2(-34,-47),Vector2(68,5)),wood)

func _camp() -> void:
	# Apply the refreshed style over the original compact hub composition.
	for n in range(18):
		layout._draw_flagstone(Vector2(556+layout._hash(n,71)%21-10,369+n*10),n)
	for at in [Vector2(478,380),Vector2(643,380),Vector2(478,510),Vector2(643,510)]:
		prop(FENCE_PROP,at,1.0)
	_simple_cabin(Vector2(500,384))
	sprite_scaled(CAMP,FORGE,SafeCamp.DISPLAY_STATIONS["Ferreiro"]+Vector2(0,18),1.05)
	sprite_scaled(CAMP,MARKET,SafeCamp.DISPLAY_STATIONS["Vendedor"]+Vector2(0,18),1.05)
	layout._draw_chest(SafeCamp.DISPLAY_STATIONS["Baú"])
	for name: String in ["Baú","Ferreiro","Vendedor"]:
		prop(SIGN_PROP,SafeCamp.DISPLAY_STATIONS[name]+Vector2(25,-7),1.0)
	prop(BARREL_PROP,Vector2(632,421),1.0)
	prop(CRATE_PROP,Vector2(484,526),1.0)
	prop(LANTERN_PROP,Vector2(638,474),1.0)
	prop(FIRE_PROP,Vector2(516,492),1.0)
