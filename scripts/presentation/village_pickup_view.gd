extends Node2D
var frame := 0
var tint := Color.WHITE

func set_pose(index: int, color := Color.WHITE) -> void:
	if frame != index or tint != color:
		frame = index
		tint = color
		queue_redraw()

func _draw() -> void:
	if frame == 8:
		draw_texture_rect_region(FloorV2View.PROPS,Rect2(-28,-30,56,40),FloorV2View.PEBBLES)
	else:
		VillageActorArt.pickup(self,Vector2.ZERO,frame,tint)
