class_name GuardianView
extends ActorView

var telegraph_kind := 0
var telegraph_direction := Vector2.DOWN

func _draw() -> void:
	if warning:
		match telegraph_kind:
			0:
				draw_circle(Vector2.ZERO, 100.0, Color("#d0a24a55"))
				draw_arc(Vector2.ZERO, 100.0, 0.0, TAU, 24, Color("#ffc570"), 3.0)
			1:
				var side := telegraph_direction.orthogonal() * 28.0
				var end := telegraph_direction * 200.0
				draw_colored_polygon(PackedVector2Array([-side, side, end + side, end - side]), Color("#d0a24a77"))
			2:
				for angle in [-0.35, 0.0, 0.35]:
					draw_line(Vector2.ZERO, telegraph_direction.rotated(angle) * 200.0, Color("#ffc570"), 3.0)
	draw_rect(Rect2(-30, 22, 60, 8), Color("#14291e"))
	for x in [-22, -10, 6, 20]:
		draw_rect(Rect2(x, 6, 8, 22), Color("#876448"))
	draw_rect(Rect2(-22, -20, 44, 46), Color("#69482f"))
	draw_rect(Rect2(-14, -28, 28, 45), Color("#966c41") if flash_left <= 0.0 else Color("#f7e4aa"))
	draw_rect(Rect2(-32, -34, 64, 18), Color("#315b3a"))
	draw_rect(Rect2(-23, -44, 46, 17), Color("#608150"))
	draw_rect(Rect2(-12, -8, 6, 6), Color("#e5c678"))
	draw_rect(Rect2(6, -8, 6, 6), Color("#e5c678"))
	draw_rect(Rect2(-34, -57, 68, 5), Color("#1a241e"))
	draw_rect(Rect2(-34, -57, 68 * hp_ratio, 5), Color("#97c273"))
	draw_string(ThemeDB.fallback_font, Vector2(-48, -64), "Guardião das Raízes", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e7cf8a"))
	if damage_left > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-8, -78), "-%d" % damage_amount, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#ffd59a"))
