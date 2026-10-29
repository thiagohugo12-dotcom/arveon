class_name DiaryProfile
extends BoxContainer

var split := false

func _draw() -> void:
	if split:
		draw_rect(Rect2(-12,4,1,size.y-8),Color("#c3a16a"))
		draw_rect(Rect2(-10,4,1,size.y-8),Color("#fff1d0"))
	else:
		draw_rect(Rect2(5,size.y+9,size.x-10,1),Color("#c9aa76"))
		draw_rect(Rect2(5,size.y+10,size.x-10,1),Color("#fff1d0"))
