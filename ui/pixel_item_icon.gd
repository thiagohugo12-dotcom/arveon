class_name PixelItemIcon
extends Control

var slot := "Arma"
var frame_color := Color("#67805b")
var framed := true

func _init(value: String = "Arma", color: Color = Color("#67805b")) -> void:
	slot = value
	frame_color = color
	custom_minimum_size = Vector2(30, 30)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,size/30.0)
	if framed:
		draw_style_box(DiaryTheme.piece("slot",0),Rect2(0,0,30,30))
	if DiaryArt.icon(self,slot,Rect2(2,2,26,26) if framed else Rect2(0,0,30,30)): return
	var gold := Color("#697f78")
	match slot:
		"Madeira":
			draw_rect(Rect2(5,11,20,12),Color("#89552f"))
			draw_rect(Rect2(5,11,6,12),Color("#d5a454"))
			draw_rect(Rect2(13,13,11,3),Color("#b58042"))
		"Cogumelo", "Cogumelos":
			draw_rect(Rect2(12,16,7,10),Color("#fff1c9"))
			draw_rect(Rect2(5,9,21,9),Color("#bd5237"))
			draw_rect(Rect2(9,5,13,5),Color("#d76642"))
			draw_rect(Rect2(10,10,4,3),Color("#fff1c9"))
		"Pedra", "Pedras":
			draw_rect(Rect2(6,13,20,10),Color("#7c827b"))
			draw_rect(Rect2(10,8,12,10),Color("#b1b2a0"))
		"Erva", "Ervas":
			draw_rect(Rect2(14,6,3,20),Color("#4c7339"))
			draw_rect(Rect2(6,10,8,7),Color("#68963d"))
			draw_rect(Rect2(17,6,7,8),Color("#82a743"))
		"Arma", "espada":
			for i in range(10):
				draw_rect(Rect2(7 + i, 17 - i, 3, 3), gold)
			draw_rect(Rect2(7, 18, 10, 3), Color("#97704b"))
			draw_rect(Rect2(5, 20, 5, 5), Color("#b78c58"))
		"machado":
			for i in range(14):
				draw_rect(Rect2(6+i,23-i,2,2),Color("#ae7848"))
			draw_rect(Rect2(15,5,9,9),Color("#7d8f88"))
			draw_rect(Rect2(22,6,3,9),Color("#d4ded8"))
			draw_rect(Rect2(13,7,4,5),gold)
		"lanca":
			for i in range(17):
				draw_rect(Rect2(5+i,24-i,2,2),Color("#ae7848"))
			draw_rect(Rect2(21,4,4,6),Color("#d4ded8"))
			draw_rect(Rect2(23,3,2,3),Color("#eef2cf"))
		"arco":
			for y in range(6,25):
				var x := 9 + absi(y-15)/3
				draw_rect(Rect2(x,y,3,2),Color("#b58a51"))
			draw_rect(Rect2(18,6,1,19),Color("#d5d3b7"))
			draw_rect(Rect2(8,15,15,1),Color("#c4ae7c"))
			draw_rect(Rect2(22,14,3,3),Color("#d9e0d2"))
		"cajado":
			for i in range(14):
				draw_rect(Rect2(6+i,24-i,3,2),Color("#ae7848"))
			draw_rect(Rect2(16,4,9,9),Color("#3a7259"))
			draw_rect(Rect2(18,5,6,7),Color("#8edb8b"))
			draw_rect(Rect2(19,5,3,3),Color("#ebf0b4"))
		"Armadura":
			draw_colored_polygon(PackedVector2Array([Vector2(8, 7), Vector2(15, 10), Vector2(22, 7), Vector2(21, 20), Vector2(15, 25), Vector2(9, 20)]), Color("#a3b2a2"))
			draw_rect(Rect2(14, 12, 3, 9), gold)
		_:
			draw_rect(Rect2(11, 7, 8, 3), gold)
			draw_rect(Rect2(8, 11, 3, 9), gold)
			draw_rect(Rect2(19, 11, 3, 9), gold)
			draw_rect(Rect2(11, 20, 8, 3), gold)
			draw_rect(Rect2(13, 13, 4, 5), Color("#6aa797"))
