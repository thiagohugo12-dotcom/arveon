class_name PixelMenuButton
extends Button

var glyph :=  "bag"
var wood_style: StyleBoxTexture
var notification := false:
	set(value):
		if notification != value:
			notification = value
			queue_redraw()

func _draw() -> void:
	if wood_style == null: wood_style = DiaryTheme.piece("wood",0)
	draw_style_box(wood_style,Rect2(Vector2.ZERO,size))
	PixelIcon.illustrate(self, glyph, Rect2(Vector2(8, 6), size - Vector2(16, 12)), Color("#e5bb77") if not disabled else Color("#a39170"))
	if notification:
		draw_rect(Rect2(size.x - 13, 3, 10, 10), Color("#182921"))
		draw_rect(Rect2(size.x - 11, 5, 6, 6), Color("#f2c26b"))
