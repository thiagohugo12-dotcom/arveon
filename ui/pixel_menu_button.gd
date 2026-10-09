class_name PixelMenuButton
extends Button

var glyph :=  "bag"
var notification := false:
	set(value):
		if notification != value:
			notification = value
			queue_redraw()

func _draw() -> void:
	PixelIcon.paint(self, glyph, Rect2(Vector2(8, 6), size - Vector2(16, 12)), Color("#e4dca6") if not disabled else Color("#78877b"))
	if notification:
		draw_rect(Rect2(size.x - 13, 3, 10, 10), Color("#182921"))
		draw_rect(Rect2(size.x - 11, 5, 6, 6), Color("#f2c26b"))
