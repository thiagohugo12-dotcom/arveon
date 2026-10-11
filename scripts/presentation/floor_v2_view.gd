class_name FloorV2View
extends RefCounted

const NATURE := preload("res://assets/art/mata_v2/nature.png")
const PATHS := preload("res://assets/art/mata_v2/paths.png")
const CAMP := preload("res://assets/art/mata_v2/camp.png")
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
var layout: FloorView


func sprite(atlas: Texture2D, region: Rect2, at: Vector2) -> void:
	layout.draw_texture_rect_region(atlas,Rect2(at-Vector2(region.size.x*0.5,region.size.y),region.size),region)

func shadow(at: Vector2, width: float, height: float) -> void:
	for i in range(6):
		var extent: float = width * [0.5,0.8,1.0,0.95,0.8,0.5][i]
		layout.draw_rect(Rect2(at+Vector2(-extent*0.5,-height*0.5+i*height/6),Vector2(extent,height/6)),Color("#9ab94f"))

func paint() -> void:
	if layout == null:
		return
	layout.draw_rect(Rect2(0,0,1200,900),Color("#b7ce60"))
	# Sparse tiny colour clusters; no dense repeated texture.
	for i in range(250):
		var at := Vector2(18+layout._hash(i,27)%1164,18+layout._hash(i,82)%864).snapped(Vector2(2,2))
		layout.draw_rect(Rect2(at,Vector2(4,2)),Color("#c0d66b") if i%3 else Color("#afc75a"))
	# One cached authored path texture, rather than thousands of stamp commands.
	layout.draw_texture_rect(PATHS,Rect2(0,0,1200,900),false)
	# Identical decorative anchors / safety exclusions as the existing layout.
	var rng := RandomNumberGenerator.new()
	rng.seed = 12051
	for i in range(56):
		var at := Vector2(rng.randi_range(20,1175),rng.randi_range(20,875))
		if layout._free_for_decoration(at):
			sprite(NATURE,FLOWERS if i%11==0 else STONE if i%19==0 else BUSH if i%23==0 else GRASS,at)
	for feet in layout.tree_positions():
		shadow(feet+Vector2(6,2),62,18)
		sprite(NATURE,ORANGE if layout._hash(roundi(feet.y),roundi(feet.x))%8==0 else GREEN,feet+Vector2(0,6))
	for rock: Rect2 in FloorView.ROCKS:
		shadow(rock.get_center()+Vector2(0,rock.size.y*0.4),rock.size.x,18)
		# Cover the existing collision footprint with a recognisable stone mass.
		layout.draw_texture_rect_region(NATURE,rock.grow(4),STONE)
	_camp()

func _camp() -> void:
	# Keep every cabin, stall, fence and decoration at its established anchor.
	for n in range(18):
		layout._draw_flagstone(Vector2(556+layout._hash(n,71)%21-10,369+n*10),n)
	for segment: Vector2 in [Vector2(478,515),Vector2(583,641)]:
		layout._draw_rail(Vector2(segment.x,352),segment.y-segment.x)
		layout._draw_rail(Vector2(segment.x,548),segment.y-segment.x)
	for y in [380,400,490,510]:
		layout._draw_fence(Vector2(473,y))
		layout._draw_fence(Vector2(643,y))
	# Draw replacements inside the original footprints, not new buildings.
	layout.draw_texture_rect_region(CAMP,Rect2(452,288,96,96),CABIN)
	sprite(CAMP,FORGE,SafeCamp.STATIONS["Ferreiro"]+Vector2(0,14))
	sprite(CAMP,MARKET,SafeCamp.STATIONS["Vendedor"]+Vector2(0,14))
	layout._draw_chest(SafeCamp.STATIONS["Baú"])
	for i in range(3):
		var name: String = ["Baú","Ferreiro","Vendedor"][i]
		layout._draw_service_sign(SafeCamp.STATIONS[name]+Vector2(28,-10),i)
	for point: Vector2 in [Vector2(480,411),Vector2(633,420)]: layout._draw_barrel(point)
	for point: Vector2 in [Vector2(484,526),Vector2(631,535)]: layout._draw_crate(point)
	for point: Vector2 in [Vector2(479,374),Vector2(638,474)]: layout._draw_lantern(point)
	layout._draw_fire(Vector2(516,492))
