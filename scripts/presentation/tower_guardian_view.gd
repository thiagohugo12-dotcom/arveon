class_name TowerGuardianView
extends GuardianView
const FOREST_SHEET := preload("res://assets/art/andar1/forest_guardian_sheet.png")
# Crops are read directly from the supplied transparent sheet. Each source row
# has a different spacing, so a regular grid would cut antlers and fists.
const FOREST_IDLE := [
	Rect2(544, 23, 193, 174), Rect2(757, 23, 196, 174),
	Rect2(971, 23, 198, 174), Rect2(1188, 23, 203, 174)]
const FOREST_WALK := [
	Rect2(544, 213, 176, 179), Rect2(734, 213, 155, 179),
	Rect2(898, 213, 163, 179), Rect2(1075, 213, 167, 179),
	Rect2(1253, 213, 167, 179)]
const FOREST_STRIKE := [
	Rect2(528, 410, 199, 180), Rect2(730, 410, 175, 180),
	Rect2(911, 410, 204, 180), Rect2(1118, 410, 150, 180),
	Rect2(1271, 410, 163, 180)]
const FOREST_SLAM := [
	Rect2(18, 608, 202, 217), Rect2(220, 608, 255, 217),
	Rect2(491, 608, 254, 217), Rect2(745, 608, 256, 217),
	Rect2(1010, 608, 218, 217), Rect2(1237, 608, 202, 217)]
const FOREST_DEATH := [
	Rect2(13, 852, 221, 213), Rect2(250, 852, 221, 213),
	Rect2(488, 852, 215, 213), Rect2(709, 852, 224, 213),
	Rect2(940, 852, 240, 213), Rect2(1180, 852, 261, 213)]
var legacy_body := false
var guardian_time := 0.0
func _process(delta: float) -> void:
	super._process(delta)
	guardian_time += delta
	queue_redraw()

func sprite_frame() -> int:
	var boss := get_parent() as TowerGuardian
	if boss == null: return 0
	match boss.state:
		TowerGuardian.State.WINDUP:
			return 2 if boss.action_left > float(TowerGuardian.WINDUPS[boss.action])*0.5 else 3
		TowerGuardian.State.ACTIVE: return 4 if boss.action_left > float(TowerGuardian.ACTIVES[boss.action])*0.5 else 5
		TowerGuardian.State.RECOVERY: return 6 if boss.recovery_left > 0.4 else 7
	return int(guardian_time*(6 if walking else 2))%2

func _draw_body() -> void:
	if legacy_body:
		super._draw_body()
		return
	var tint := Color(1.4, 1.35, 1.15) if flash_left > 0.0 else Color.WHITE
	var horizontal_flip := facing.x < -0.35 and absf(facing.x) > absf(facing.y)
	if horizontal_flip:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	draw_texture_rect_region(FOREST_SHEET, Rect2(-95, -152, 190, 180), _forest_frame(), tint)
	if horizontal_flip:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _forest_frame() -> Rect2:
	if defeat_left > 0.0:
		return FOREST_DEATH[clampi(int((1.0 - defeat_left / 0.22) * FOREST_DEATH.size()), 0, FOREST_DEATH.size() - 1)]
	if flash_left > 0.0:
		return FOREST_DEATH[1]
	var boss := get_parent() as TowerGuardian
	if boss != null:
		var slam := boss.action in [TowerGuardian.Action.SPIKES, TowerGuardian.Action.ROOT_WAVE]
		if boss.state == TowerGuardian.State.WINDUP:
			return FOREST_SLAM[0 if boss.action_left > float(TowerGuardian.WINDUPS[boss.action]) * 0.5 else 1] if slam else FOREST_STRIKE[0 if boss.action_left > float(TowerGuardian.WINDUPS[boss.action]) * 0.5 else 1]
		if boss.state == TowerGuardian.State.ACTIVE:
			var progress := 1.0 - boss.action_left / maxf(0.001, float(TowerGuardian.ACTIVES[boss.action]))
			return FOREST_SLAM[clampi(2 + int(progress * 4.0), 2, 5)] if slam else FOREST_STRIKE[clampi(2 + int(progress * 3.0), 2, 4)]
		if boss.state == TowerGuardian.State.RECOVERY:
			return FOREST_SLAM[5] if slam else FOREST_IDLE[3]
	return FOREST_WALK[int(guardian_time * 7.0) % FOREST_WALK.size()] if walking else FOREST_IDLE[int(guardian_time * 2.0) % FOREST_IDLE.size()]

func _draw_caption(title: String) -> void:
	if legacy_body:
		super._draw_caption(title)
		return
	# The fixed boss panel already shows name, HP and phase on small screens.
	# Keep only the combat feedback near the sprite to avoid duplicate captions.
	_draw_hit_feedback(-165)

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
			3:
				var boss := get_parent() as TowerGuardian
				if boss != null:
					var origin := to_local(boss.attack_origin)
					if not hazards_active:
						draw_arc(origin,TowerGuardian.WAVE_END,0,TAU,80,edge,2,false)
						draw_arc(origin,TowerGuardian.WAVE_START-TowerGuardian.WAVE_HALF_WIDTH,0,TAU,32,Color("#8bce99"),2,false)
					else:
						var radius := boss.wave_radius(float(TowerGuardian.ACTIVES[boss.action])-boss.action_left)
						draw_arc(origin,radius,0,TAU,96,Color("#634b2b"),TowerGuardian.WAVE_HALF_WIDTH*2,false)
						draw_arc(origin,radius,0,TAU,96,Color("#d4c779"),3,false)
						for i in range(24):
							var point := origin+Vector2.RIGHT.rotated(i*TAU/24)*radius
							draw_colored_polygon(PackedVector2Array([point+Vector2(-4,2),point+Vector2(0,-10),point+Vector2(4,2)]),Color("#779c50"))
			4:
				var boss := get_parent() as TowerGuardian
				if boss != null:
					var origin := to_local(boss.attack_origin)
					for i in range(3):
						var end := to_local(boss.seed_position(i,float(TowerGuardian.ACTIVES[TowerGuardian.Action.SEEDS])))
						if not hazards_active:
							var side := boss.aim.rotated(TowerGuardian.SEED_ANGLES[i]).orthogonal()*TowerGuardian.SEED_RADIUS
							draw_colored_polygon(PackedVector2Array([origin-side,origin+side,end+side,end-side]),Color("#c9893825"))
							draw_line(origin,end,edge,1,false)
						elif not boss.seed_blocked[i]:
							var time := float(TowerGuardian.ACTIVES[boss.action])-boss.action_left
							var point := to_local(boss.seed_position(i,time))
							var tail := to_local(boss.seed_position(i,maxf(0,time-0.10)))
							draw_line(tail,point,Color("#76ac68"),5,false)
							draw_circle(point,TowerGuardian.SEED_RADIUS,Color("#725331"))
							draw_circle(point,6,Color("#cbe69a"))
	_draw_body()
	if warning and not hazards_active and telegraph_kind == TowerGuardian.Action.SEEDS:
		for i in range(3):
			var point := Vector2(-27+i*27,-92-absf(i-1)*8)
			draw_circle(point,5,Color("#729552"))
			draw_circle(point,2,Color("#e5f7a5"))
	if second_phase:
		for point in [Vector2(-10, -55), Vector2(5, -55), Vector2(-3, -74)]:
			draw_rect(Rect2(point, Vector2(5, 5)), Color("#87ffcd"))
	_draw_caption("Guardião da Mata")
