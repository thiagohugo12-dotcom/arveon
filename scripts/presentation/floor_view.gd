extends Node2D

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1200, 900), Color(0.12, 0.23, 0.16))
	for x in range(0, 1200, 60):
		draw_line(Vector2(x, 0), Vector2(x, 900), Color(0.15, 0.27, 0.19))
	for y in range(0, 900, 60):
		draw_line(Vector2(0, y), Vector2(1200, y), Color(0.15, 0.27, 0.19))
	for rect: Rect2 in [Rect2(340, 300, 130, 50), Rect2(760, 520, 90, 110)]:
		draw_rect(rect, Color(0.28, 0.33, 0.27))
