extends Node2D
const SOURCE := preload("res://assets/art/actors_v4/monsters.png")
var kind := 0
var row := 0
var frame := 0
func part(area: Rect2,offset := Vector2.ZERO) -> void:
	draw_texture_rect_region(SOURCE,Rect2(area.position+offset,area.size),Rect2(area.position+Vector2(0,kind*32),area.size))
func _draw() -> void:
	var shift := Vector2(-16,-24)
	draw_set_transform(shift)
	var prep := frame in [1,2]
	var contact := frame == 3
	var aim: Vector2 = SwordActorView.DIRECTIONS[row]
	var lean := aim*(-1 if prep else 2 if contact else 1 if frame == 4 else 0)
	if kind == 0:
		part(Rect2(0,20,32,12))
		part(Rect2(0,0,32,20),lean+Vector2(0,2 if prep else -1 if contact else 0))
	elif kind == 1:
		part(Rect2(9,0,14,32),lean+Vector2(0,2 if prep else -1 if contact else 0))
		part(Rect2(0,0,9,32),Vector2(2 if prep else -2 if contact else 0,0))
		part(Rect2(23,0,9,32),Vector2(-2 if prep else 2 if contact else 0,0))
	else:
		part(Rect2(10,0,12,32),Vector2(0,2 if prep else -1 if contact else 0))
		part(Rect2(0,0,10,32),Vector2(2 if prep else -1 if contact else 0,-2 if prep else 0))
		part(Rect2(22,0,10,32),Vector2(-2 if prep else 2 if contact else 0,-3 if prep else 0))
	draw_set_transform(Vector2.ZERO)
