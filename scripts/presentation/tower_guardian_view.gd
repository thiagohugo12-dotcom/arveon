class_name TowerGuardianView
extends GuardianView

var hazards_active := false
var second_phase := false
var spike_points: Array[Vector2] = []
var charge_length := 208.0

func _draw() -> void:
	if warning:
		var fill := Color("#c9893870")
		var edge := Color("#ffd382")
		match telegraph_kind:
			0:
				var polygon := PackedVector2Array([Vector2.ZERO])
				for i in range(13):
					polygon.append(telegraph_direction.rotated(deg_to_rad(-50.0 + i * 100.0 / 12.0)) * TowerGuardian.ROOT_RANGE)
				draw_colored_polygon(polygon, fill)
				draw_polyline(polygon, edge, 2)
			1:
				for point in spike_points:
					var local := to_local(point)
					draw_circle(local, TowerGuardian.SPIKE_RADIUS, fill)
					draw_arc(local, TowerGuardian.SPIKE_RADIUS, 0, TAU, 16, edge, 2)
					draw_line(local + Vector2(-7, 0), local + Vector2(7, 0), edge, 2)
					draw_line(local + Vector2(0, -7), local + Vector2(0, 7), edge, 2)
					if hazards_active:
						for offset in [-12, 0, 12]:
							draw_colored_polygon(PackedVector2Array([local + Vector2(offset - 5, 4), local + Vector2(offset, -18), local + Vector2(offset + 5, 4)]), Color("#66472e"))
			2:
				var side := telegraph_direction.orthogonal() * 30.0
				var end := telegraph_direction * charge_length
				draw_colored_polygon(PackedVector2Array([-side, side, end + side, end - side]), fill)
				draw_line(Vector2.ZERO, end, edge, 3)
	_draw_body()
	if second_phase:
		for point in [Vector2(-10, -5), Vector2(5, -5), Vector2(-3, -24)]:
			draw_rect(Rect2(point, Vector2(5, 5)), Color("#87ffcd"))
	_draw_caption("Guardião da Mata")
