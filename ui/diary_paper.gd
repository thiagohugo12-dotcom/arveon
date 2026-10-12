class_name DiaryPaper
extends ColorRect

func _init() -> void:
	name = "PaperBacking"
	color = DiaryTheme.PAPER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	resized.connect(queue_redraw)

func _draw() -> void:
	if get_parent().get_meta("diary_spread",false):
		draw_rect(Rect2(roundf(size.x/2)-2,0,4,size.y),Color("#b89861"))
