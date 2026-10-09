class_name PixelItemIcon
extends Control

var slot := "Arma"

func _init(value: String = "Arma") -> void:
	slot = value
	custom_minimum_size = Vector2(30, 30)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	draw_rect(Rect2(0, 0, 30, 30), Color("#142a25"))
	draw_rect(Rect2(1, 1, 28, 28), Color("#67805b"), false, 2)
	var gold := Color("#e3c781")
	match slot:
		"Arma":
			for i in range(10):
				draw_rect(Rect2(7 + i, 17 - i, 3, 3), gold)
			draw_rect(Rect2(7, 18, 10, 3), Color("#97704b"))
			draw_rect(Rect2(5, 20, 5, 5), Color("#b78c58"))
		"Armadura":
			draw_colored_polygon(PackedVector2Array([Vector2(8, 7), Vector2(15, 10), Vector2(22, 7), Vector2(21, 20), Vector2(15, 25), Vector2(9, 20)]), Color("#a3b2a2"))
			draw_rect(Rect2(14, 12, 3, 9), gold)
		_:
			draw_rect(Rect2(11, 7, 8, 3), gold)
			draw_rect(Rect2(8, 11, 3, 9), gold)
			draw_rect(Rect2(19, 11, 3, 9), gold)
			draw_rect(Rect2(11, 20, 8, 3), gold)
			draw_rect(Rect2(13, 13, 4, 5), Color("#6aa797"))
