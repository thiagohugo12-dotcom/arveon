class_name TowerGuardianView
extends GuardianView
const GUARDIAN_ATLAS := preload("res://assets/art/local_combat_review/guardiao.png")
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
	var row := SwordActorView.direction_row(facing)
	var tint := Color(1.7,1.55,1.25) if flash_left > 0 else Color.WHITE
	draw_texture_rect_region(GUARDIAN_ATLAS,Rect2(-80,-132,160,160),Rect2(sprite_frame()*80,row*80,80,80),tint)

func _draw_caption(title: String) -> void:
	if legacy_body:
		super._draw_caption(title)
		return
	draw_rect(Rect2(-34,-138,68,5),Color("#1a241e"))
	draw_rect(Rect2(-34,-138,68*hp_ratio,5),Color("#97c273"))
	draw_string(ThemeDB.fallback_font,Vector2(-48,-145),title,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#e7cf8a"))
	_draw_hit_feedback(-158)

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
