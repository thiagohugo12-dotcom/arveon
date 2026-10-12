class_name DiaryHeart
extends Control

var glyph := "heart"
var tint := Color("#dd5143")

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	PixelIcon.illustrate(self,glyph,Rect2(Vector2.ZERO,size),tint)
