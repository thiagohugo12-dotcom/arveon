class_name DiaryHeart
extends Control

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	PixelIcon.paint(self,"heart",Rect2(Vector2.ZERO,size),Color("#b64c38"))
