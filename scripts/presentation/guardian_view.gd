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
	_draw_body()
	_draw_caption("Guardião das Raízes")

func _draw_body() -> void:
	# Root feet, knotted trunk and offset crown give the guardian its own silhouette.
	draw_rect(Rect2(-32, 23, 64, 6), Color("#14291e"))
	for side in [-1, 1]:
		var s: float = side
		draw_colored_polygon(PackedVector2Array([
			Vector2(s * 6, 4), Vector2(s * 20, 8), Vector2(s * 29, 25),
			Vector2(s * 18, 22), Vector2(s * 10, 15)
		]), Color("#60442e"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(s * 14, -24), Vector2(s * 28, -29), Vector2(s * 41, -19),
			Vector2(s * 36, -10), Vector2(s * 22, -14)
		]), Color("#294c38"))
		draw_rect(Rect2(s * 25 - 4, -25, 9, 4), Color("#61905a"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-20, 17), Vector2(-23, -8), Vector2(-17, -28), Vector2(-10, -39),
		Vector2(12, -39), Vector2(22, -24), Vector2(20, 7), Vector2(13, 22), Vector2(-9, 24)
	]), Color("#4b392b"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-13, 14), Vector2(-16, -12), Vector2(-10, -34),
		Vector2(10, -34), Vector2(16, -13), Vector2(13, 16)
	]), Color("#977047") if flash_left <= 0.0 else Color("#f7e4aa"))
	draw_rect(Rect2(-7, -20, 4, 26), Color("#b38b5b"))
	draw_rect(Rect2(4, -27, 3, 19), Color("#684932"))
	draw_rect(Rect2(-10, -5, 5, 4), Color("#e8c077"))
	draw_rect(Rect2(5, -5, 5, 4), Color("#e8c077"))
	draw_rect(Rect2(-5, 5, 10, 3), Color("#493927"))
	for p in [Vector2(-35, -43), Vector2(-27, -51), Vector2(-15, -57), Vector2(0, -59), Vector2(17, -53), Vector2(28, -43)]:
		draw_rect(Rect2(p, Vector2(17, 14)), Color("#203e32"))
		draw_rect(Rect2(p + Vector2(2, -2), Vector2(13, 10)), Color("#416d48"))
		draw_rect(Rect2(p + Vector2(4, -2), Vector2(6, 3)), Color("#73935b"))
	draw_rect(Rect2(-22, -47, 5, 3), Color("#a5a66b"))
	draw_rect(Rect2(21, -42, 4, 3), Color("#9baa65"))

func _draw_caption(title: String) -> void:
	draw_rect(Rect2(-34, -57, 68, 5), Color("#1a241e"))
	draw_rect(Rect2(-34, -57, 68 * hp_ratio, 5), Color("#97c273"))
	draw_string(ThemeDB.fallback_font, Vector2(-48, -64), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e7cf8a"))
	_draw_hit_feedback(-78.0)
