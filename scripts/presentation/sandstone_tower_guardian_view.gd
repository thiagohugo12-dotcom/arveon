class_name SandstoneTowerGuardianView
extends TowerGuardianView

const GOLEM := preload("res://assets/art/andar2/refined/sandstone-guardian-atlas.png")

func _pose() -> Vector2i:
	var boss := get_parent() as TowerGuardian
	if defeat_left > 0.0:
		return Vector2i(clampi(int((1.0 - defeat_left / 0.22) * 6.0), 0, 5), 4)
	if flash_left > 0.0:
		return Vector2i(int(guardian_time * 12.0) % 3, 3)
	if boss != null:
		match boss.state:
			TowerGuardian.State.WINDUP:
				return Vector2i(0 if boss.action_left > 0.3 else 1, 2)
			TowerGuardian.State.ACTIVE:
				return Vector2i(2 + int(guardian_time * 10.0) % 4, 2)
			TowerGuardian.State.RECOVERY:
				return Vector2i(3, 0)
	return Vector2i(int(guardian_time * (7.0 if walking else 2.0)) % (6 if walking else 4), 1 if walking else 0)

func _draw_body() -> void:
	var pose := _pose()
	draw_texture_rect_region(GOLEM, Rect2(-128, -192, 256, 192),
		Rect2(pose.x * 128, pose.y * 96, 128, 96),
		Color(1.3, 1.2, 1.05) if flash_left > 0.0 else Color.WHITE)

func _draw_caption(_title: String) -> void:
	draw_rect(Rect2(-48, -164, 96, 6), Color("#30271d"))
	draw_rect(Rect2(-48, -164, 96 * hp_ratio, 6), Color("#e3aa57"))
	draw_string(ThemeDB.fallback_font, Vector2(-74, -172), "Guardião de Arenito",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#fff1ca"))
	if second_phase:
		draw_string(ThemeDB.fallback_font, Vector2(-24, -186), "FASE II",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#ffe0a0"))
	_draw_hit_feedback(-182.0)

func _draw() -> void:
	var boss := get_parent() as TowerGuardian
	if warning and boss != null:
		var fill := Color("#b8814e66")
		var edge := Color("#ffe1a0")
		match telegraph_kind:
			TowerGuardian.Action.ROOTS:
				var polygon := PackedVector2Array([Vector2.ZERO])
				for i in range(13):
					polygon.append(telegraph_direction.rotated(deg_to_rad(-50.0 + i * 100.0 / 12.0)) * TowerGuardian.ROOT_RANGE)
				draw_colored_polygon(polygon, fill)
				draw_polyline(polygon, edge, 2.0)
			TowerGuardian.Action.SPIKES:
				for point in spike_points:
					var local := to_local(point)
					draw_circle(local, TowerGuardian.SPIKE_RADIUS, fill)
					draw_arc(local, TowerGuardian.SPIKE_RADIUS, 0, TAU, 24, edge, 2.0)
					if hazards_active:
						for offset in [-12, 0, 12]:
							draw_colored_polygon(PackedVector2Array([local + Vector2(offset - 5, 4), local + Vector2(offset, -18), local + Vector2(offset + 5, 4)]), Color("#a67745"))
			TowerGuardian.Action.CHARGE:
				var side := telegraph_direction.orthogonal() * 30.0
				var end := telegraph_direction * charge_length
				draw_colored_polygon(PackedVector2Array([-side, side, end + side, end - side]), fill)
				draw_line(Vector2.ZERO, end, edge, 3.0)
			TowerGuardian.Action.ROOT_WAVE:
				var origin := to_local(boss.attack_origin)
				if not hazards_active:
					draw_arc(origin, TowerGuardian.WAVE_END, 0, TAU, 64, edge, 2.0)
				else:
					var radius := boss.wave_radius(float(TowerGuardian.ACTIVES[boss.action]) - boss.action_left)
					draw_arc(origin, radius, 0, TAU, 80, Color("#a27147"), TowerGuardian.WAVE_HALF_WIDTH * 2.0)
					draw_arc(origin, radius, 0, TAU, 80, edge, 2.0)
			TowerGuardian.Action.SEEDS:
				var origin := to_local(boss.attack_origin)
				for i in range(3):
					var end := to_local(boss.seed_position(i, float(TowerGuardian.ACTIVES[TowerGuardian.Action.SEEDS])))
					if not hazards_active:
						draw_line(origin, end, edge, 2.0)
					elif not boss.seed_blocked[i]:
						var time := float(TowerGuardian.ACTIVES[boss.action]) - boss.action_left
						var point := to_local(boss.seed_position(i, time))
						draw_circle(point, TowerGuardian.SEED_RADIUS, Color("#9d6b43"))
						draw_circle(point, 5.0, Color("#f4d48a"))
	_draw_body()
	_draw_caption("")
