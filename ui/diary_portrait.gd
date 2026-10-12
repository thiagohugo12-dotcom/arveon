class_name DiaryPortrait
extends Control

func _init() -> void:
	custom_minimum_size = Vector2(112,144)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	draw_style_box(DiaryTheme.box(Color("#e3cfa2"),Color("#b99863"),0),Rect2(Vector2.ZERO,size))
	var feet := Vector2(floorf(size.x/2),size.y-28)
	draw_rect(Rect2(feet+Vector2(-20,6),Vector2(40,4)),Color("#b69d6c"))
	# Source sprite uses 2x; 1.5 here produces exact 3x source pixels.
	draw_set_transform(feet,0,Vector2(1.5,1.5))
	VillageActorArt.person(self,0,0,Vector2.ZERO)
