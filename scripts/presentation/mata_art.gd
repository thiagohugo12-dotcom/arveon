class_name MataArt
extends RefCounted

# Tiny deterministic atlas, generated locally with the accompanying Godot tool.
# The same imported texture is shared across all five floors, without runtime generation.
const ATLAS := preload("res://assets/art/mata_clean_atlas.png")
const SIZE := Vector2i(128,48)
const TREE_REGIONS := [Rect2(0,0,32,40),Rect2(32,0,32,40),Rect2(64,0,32,40)]
const SHRUB_REGION := Rect2(96,0,16,16)

static func texture() -> Texture2D:
	return ATLAS

static func generate_image() -> Image:
	var image := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for kind in range(3):
		_tree(image,Vector2i(kind*32,0),kind)
	_polygon(image,Vector2i(96,0),[[2,12],[0,8],[2,4],[5,4],[7,1],[11,2],[12,5],[15,7],[14,12],[11,14],[4,14]],Color("#395847"))
	_polygon(image,Vector2i(96,0),[[2,8],[3,5],[6,5],[7,3],[11,4],[13,8],[11,10],[5,11]],Color("#63844e"))
	_rect(image,Vector2i(96,0),Rect2i(5,5,4,2),Color("#8da25b"))
	return image

static func _rect(image: Image, origin: Vector2i, area: Rect2i, color: Color) -> void:
	for y in range(area.position.y,area.end.y):
		for x in range(area.position.x,area.end.x):
			image.set_pixelv(origin+Vector2i(x,y),color)

static func _polygon(image: Image, origin: Vector2i, points: Array, color: Color) -> void:
	var polygon := PackedVector2Array()
	for point: Array in points:
		polygon.append(Vector2(point[0],point[1]))
	for y in range(40):
		for x in range(32):
			if Geometry2D.is_point_in_polygon(Vector2(x+0.5,y+0.5),polygon):
				image.set_pixelv(origin+Vector2i(x,y),color)

static func _tree(image: Image, at: Vector2i, kind: int) -> void:
	# Root footprint surrounds the existing trunk collider at the sprite's foot.
	_rect(image,at,Rect2i(13,26,6,12),Color("#604932"))
	_rect(image,at,Rect2i(14,27,3,9),Color("#a07845"))
	_polygon(image,at,[[13,34],[18,34],[22,38],[19,39],[16,37],[12,39],[9,38]],Color("#795b37"))
	var dark := Color("#365541") if kind != 2 else Color("#805e39")
	var mid := Color("#66864c") if kind == 0 else Color("#4f7760") if kind == 1 else Color("#b88644")
	var light := Color("#8da553") if kind == 0 else Color("#73936c") if kind == 1 else Color("#d3a05b")
	_polygon(image,at,[[3,26],[1,22],[1,16],[4,13],[3,8],[7,5],[12,5],[14,2],[20,2],[23,6],[27,7],[29,12],[28,17],[31,20],[29,27],[24,30],[18,28],[12,30],[7,28]],dark)
	_polygon(image,at,[[4,21],[3,16],[6,13],[5,9],[9,6],[13,7],[15,4],[20,4],[22,8],[26,9],[27,13],[25,17],[28,20],[26,24],[21,27],[15,25],[11,27],[7,25]],mid)
	# Only three large light clusters, no leaf noise or outlines inside each leaf.
	_polygon(image,at,[[6,13],[7,9],[11,8],[15,10],[15,13],[11,16],[7,15]],light)
	_polygon(image,at,[[14,9],[15,5],[20,5],[23,9],[21,12],[16,13]],light)
	_polygon(image,at,[[13,20],[15,16],[20,15],[24,18],[23,21],[19,23],[15,22]],light)
