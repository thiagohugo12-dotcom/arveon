class_name DiaryTab
extends Button

var glyph := "bag"

func _draw() -> void:
	if size.x >= 135:
		PixelIcon.illustrate(self,glyph,Rect2(12,(size.y-24)/2,24,24),get_theme_color("font_color"))

