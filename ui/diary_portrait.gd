class_name DiaryPortrait
extends Control

func _init() -> void:
	custom_minimum_size = Vector2(88,104)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	draw_style_box(DiaryTheme.box(Color("#e3cfa2"),Color("#b99863"),0),Rect2(Vector2.ZERO,size))
	var feet := Vector2(floorf(size.x/2),size.y-22)
	draw_rect(Rect2(feet+Vector2(-20,6),Vector2(40,4)),Color("#b69d6c"))
	VillageActorArt.person(self,0,0,feet)
