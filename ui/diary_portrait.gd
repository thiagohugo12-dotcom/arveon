class_name DiaryPortrait
extends Control

func _init() -> void:
	custom_minimum_size = Vector2(120,150)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	var feet := Vector2(floorf(size.x/2),size.y-28)
	draw_rect(Rect2(feet+Vector2(-28,3),Vector2(56,6)),Color("#d1b681"))
	draw_rect(Rect2(feet+Vector2(-19,9),Vector2(38,3)),Color("#dcc393"))
	# Source sprite uses 2x; 1.5 here produces exact 3x source pixels.
	draw_set_transform(feet,0,Vector2(1.5,1.5))
	VillageActorArt.person(self,0,0,Vector2.ZERO)
