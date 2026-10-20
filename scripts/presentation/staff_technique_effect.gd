class_name StaffTechniqueEffect
extends Node2D

# Visual-only presentation. ClassCombat owns damage, marks, control and guard.
const TIMINGS := {
	"onda_arcana":{"duration":0.84,"release":0.28,"contact":0.58},
	"selo_mistico":{"duration":1.06,"release":0.46,"contact":0.56},
	"tempestade_arcana":{"duration":1.28,"release":0.60,"contact":0.78}
}
const GUARD_PREVIEW := 1.35

var kind := ""
var direction := Vector2.RIGHT
var reach := 0.0
var elapsed := 0.0
var guard_duration := 0.0
var active := false

func cast(id: String, at: Vector2, aim: Vector2, real_reach: float, real_guard: float = 0.0) -> void:
	if not TIMINGS.has(id) and id != "barreira_espiritual": return
	kind = id
	direction = aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
	reach = real_reach
	guard_duration = real_guard
	global_position = at
	elapsed = 0.0
	active = true
	queue_redraw()

func seek(time: float, at: Vector2) -> void:
	if not active or kind == "barreira_espiritual": return
	elapsed = clampf(time,0.0,float(TIMINGS[kind].duration))
	global_position = at
	queue_redraw()

func seek_guard(remaining: float, at: Vector2) -> void:
	if not active or kind != "barreira_espiritual": return
	if remaining <= 0.0:
		clear()
		return
	elapsed = maxf(0.0,guard_duration-remaining)
	global_position = at
	queue_redraw()

func clear() -> void:
	active = false
	kind = ""
	queue_redraw()

func _ring(radius: float, color: Color, width: float = 2.0) -> void:
	if radius > 0: draw_arc(Vector2.ZERO,radius,0,TAU,64,color,width,true)

func _rune(at: Vector2, size: float, angle: float, alpha: float) -> void:
	var side := Vector2.RIGHT.rotated(angle)
	var normal := side.orthogonal()
	draw_line(at-side*size,at+side*size,Color(0.65,0.96,0.81,alpha),2.0)
	draw_line(at-normal*size,at+normal*size,Color(0.65,0.96,0.81,alpha),2.0)
	draw_colored_polygon(PackedVector2Array([at+side*size*0.65,at+normal*size*0.65,at-side*size*0.65,at-normal*size*0.65]),Color(0.88,1.0,0.85,alpha*0.28))

func _motes(count: int, radius: float, alpha: float, spin: float) -> void:
	for i in range(count):
		var angle := float(i)*TAU/float(count)+spin
		var at := Vector2(cos(angle),sin(angle))*radius
		draw_rect(Rect2(at.round()-Vector2(2,2),Vector2(4,4)),Color(0.77,1.0,0.87,alpha))

func _draw() -> void:
	if not active: return
	var release := 0.42 if kind == "barreira_espiritual" else float(TIMINGS[kind].release)
	var wind := clampf(elapsed/maxf(0.01,release),0,1)
	var after := maxf(0.0,elapsed-release)
	if kind == "onda_arcana":
		if elapsed < release:
			_ring(12.0+wind*16.0,Color(0.69,0.98,0.86,0.75))
			_motes(6,24.0+wind*10.0,0.60,elapsed*2.0)
		else:
			var p := clampf(after/0.30,0,1)
			var alpha := maxf(0.0,1.0-after/0.56)
			var wave := reach*p
			draw_circle(Vector2.ZERO,wave,Color(0.32,0.82,0.70,alpha*0.12))
			_ring(wave,Color(0.69,1.0,0.87,alpha),8.0*alpha+1.0)
			_ring(maxf(1.0,wave-13.0),Color(0.24,0.73,0.66,alpha*0.8),3.0)
			_motes(9,wave,alpha*0.9,elapsed*1.6)
	elif kind == "selo_mistico":
		var p := wind if elapsed < release else 1.0
		var alpha := 0.75 if elapsed < release else maxf(0.25,1.0-after/0.65)
		_ring(reach*p,Color(0.53,0.94,0.79,alpha),3.0)
		_ring(reach*p*0.78,Color(0.87,1.0,0.84,alpha*0.65),2.0)
		for i in range(8):
			var angle := float(i)*TAU/8.0+elapsed*0.4
			_rune(Vector2(cos(angle),sin(angle))*reach*p*0.89,5.0+p*4.0,angle,alpha)
		if elapsed >= float(TIMINGS[kind].contact):
			for node in get_tree().get_nodes_in_group("damageable_enemies"):
				if not node is EnemyActor or node.get_world_2d() != get_world_2d() or node.mark_category != "cajado" or node.mark_left <= 0: continue
				var at := to_local(node.global_position)
				if at.length_squared() <= reach*reach: draw_arc(at+Vector2(0,-8),22,0,TAU,24,Color(0.72,1.0,0.86,alpha),2.0,true)
	elif kind == "barreira_espiritual":
		var p := wind if elapsed < release else 1.0
		var alpha := 0.35 if elapsed < release else 0.55+0.10*sin(elapsed*10.0)
		var center := Vector2(0,-28)
		draw_circle(center,44.0*p,Color(0.25,0.80,0.65,alpha*0.25))
		draw_arc(center,44.0*p,0,TAU,40,Color(0.80,1.0,0.88,alpha),4.0,true)
		draw_arc(center,35.0*p,0,TAU,40,Color(0.42,0.83,0.72,alpha*0.8),2.0,true)
		for i in range(6):
			var angle := float(i)*TAU/6.0+elapsed*1.2
			_rune(center+Vector2(cos(angle),sin(angle))*43.0*p,4.0,angle,alpha)
	else:
		if elapsed < release:
			_ring(reach*(0.3+0.7*wind),Color(0.47,0.90,0.78,0.63),3.0)
			_motes(12,reach*(0.2+0.75*wind),0.6,elapsed*3.0)
		else:
			var alpha := maxf(0.0,1.0-after/0.68)
			_ring(reach,Color(0.72,1.0,0.85,alpha*0.78),3.0)
			for i in range(10):
				var angle := float(i)*2.39996+after*2.0
				var distance := sqrt((float(i)+0.5)/10.0)*reach*0.9
				var at := Vector2(cos(angle),sin(angle))*distance
				var phase := (after-float(i)*0.04)/0.18
				if phase <= 0 or phase > 1.7: continue
				var flash := minf(1.0,phase)*maxf(0.0,1.0-(phase-1.0)*0.8)*alpha
				draw_line(at+Vector2(-8,-18),at+Vector2(5,5),Color(0.75,1.0,0.89,flash),3.0)
				draw_line(at+Vector2(6,-9),at+Vector2(-4,8),Color(0.36,0.90,0.80,flash),2.0)
				draw_arc(at,6.0+phase*5.0,0,TAU,16,Color(0.78,1.0,0.87,flash*0.85),2.0,true)
			_motes(14,reach*0.88,alpha*0.7,after*2.0)
