class_name FloorV2View
extends RefCounted

# Original alpha, proportional rectangles and integer 2x art grid.
const VILLAGE := preload("res://assets/art/hub_v3/village.png")
const PROPS := preload("res://assets/art/hub_v3/props.png")
const GROUND := preload("res://assets/art/hub_v3/ground.png")
const NATURE := preload("res://assets/art/mata_v2/nature.png")
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
const BENCH := Rect2(64,64,32,24)
const PEBBLES := Rect2(96,64,28,20)
const BUILDING_BASES := [Rect2(600,340,160,30),Rect2(356,378,166,24),Rect2(610,566,140,26)]
var layout: FloorView
var depth_commands: Array = []

static func canopy_conflicts(feet: Vector2) -> bool:
	return Rect2(340,250,196,196).has_point(feet) or Rect2(584,180,196,212).has_point(feet) or Rect2(594,450,196,194).has_point(feet)

func visible_tree_positions() -> Array[Vector2]:
	return layout.tree_positions().filter(func(feet: Vector2): return not canopy_conflicts(feet))

func sprite(atlas: Texture2D, region: Rect2, feet: Vector2, scale: int = 2) -> void:
	if atlas == VILLAGE or (atlas == PROPS and region != PEBBLES):
		if layout.depth_scenery == null:
			depth_commands.append([atlas,region,feet,scale])
		return
	var size := region.size * scale
	layout.draw_texture_rect_region(atlas,Rect2((feet-Vector2(size.x*0.5,size.y)).round(),size),region)

func shadow(at: Vector2, width: float, height: float) -> void:
	for i in range(6):
		var extent: float = width * [0.5,0.8,1.0,0.95,0.8,0.5][i]
		layout.draw_rect(Rect2((at+Vector2(-extent*0.5,-height*0.5+i*height/6)).snapped(Vector2(2,2)),Vector2(extent,height/6).snapped(Vector2(2,2))),Color("#718f3f80"))

func paint() -> void:
	if layout == null: return
	depth_commands.clear()
	layout.draw_texture_rect(GROUND,Rect2(0,0,1200,900),false)
	for i in range(75):
		var at := Vector2(24+layout._hash(i,27)%1152,24+layout._hash(i,82)%852).snapped(Vector2(2,2))
		if layout._free_for_decoration(at) and not Rect2(330,210,470,440).has_point(at):
			if i%13 == 0: flowers(at)
			else: grass(at,i)
	for at in bush_positions():
		shadow(at+Vector2(8,2),52,14)
		sprite(VILLAGE,BUSH,at)
	for feet in visible_tree_positions():
		shadow(feet+Vector2(14,4),90,24)
		sprite(VILLAGE,ORANGE if layout._hash(roundi(feet.y),roundi(feet.x))%3 != 0 else GREEN,feet+Vector2(0,6))
	for rock: Rect2 in FloorView.ROCKS:
		# Western rock remains physical beneath the workshop's stone back.
		if rock.position.x < 500: continue
		shadow(rock.get_center()+Vector2(10,rock.size.y*0.4),rock.size.x,18)
		layout.draw_texture_rect_region(NATURE,rock.grow(4),STONE)
	_camp()
	if layout.depth_scenery == null:
		layout.call_deferred("_build_depth_scenery",depth_commands.duplicate())

func bush_positions() -> Array[Vector2]:
	# Authored groups frame the service areas; the center and approaches stay open.
	return [Vector2(332,416),Vector2(776,376),Vector2(386,622),Vector2(730,674),
		Vector2(84,280),Vector2(252,180),Vector2(862,230),Vector2(1080,230),
		Vector2(1090,580),Vector2(906,752),Vector2(664,822),Vector2(342,776),
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
	sprite(PROPS,BENCH,Vector2(440,540))
	sprite(PROPS,FIRE,Vector2(534,570))
	for at: Vector2 in [Vector2(328,476),Vector2(558,326),Vector2(764,422),Vector2(400,614),Vector2(620,652),Vector2(750,676)]:
		flowers(at)
	for at: Vector2 in [Vector2(584,432),Vector2(574,608),Vector2(340,530)]:
		sprite(PROPS,PEBBLES,at,1)
