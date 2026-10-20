class_name BowTechniqueEffect
extends Node2D

# Visual-only timeline. ClassCombat owns the single contact and all damage rules.
const TIMINGS := {
	"rajada_flechas":{"release":0.22},
	"tiro_marcado":{"release":0.40},
	"flecha_perfurante":{"release":0.30},
	"chuva_flechas":{"duration":1.28,"release":0.54,"contact":0.79}
}
const ARROW_SPEED := 550.0 # Visual travel; the basic arrow uses 440 px/s.
const RECOVERY := 0.22
const ARROW_SHAFT := {"rajada_flechas":16.0,"tiro_marcado":18.0,"flecha_perfurante":21.0}

static func contact_time(id: String, real_reach: float) -> float:
	if id == "chuva_flechas": return float(TIMINGS[id].contact)
	return float(TIMINGS[id].release)+real_reach/ARROW_SPEED

static func duration_time(id: String, real_reach: float) -> float:
	if id == "chuva_flechas": return float(TIMINGS[id].duration)
	return contact_time(id,real_reach)+RECOVERY

var kind := ""
var direction := Vector2.RIGHT
var reach := 0.0
var elapsed := 0.0
var active := false
var marked_target: Node2D

func cast(id: String, at: Vector2, aim: Vector2, real_reach: float, target: Node2D = null) -> void:
	if not TIMINGS.has(id): return
	kind = id
	direction = aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
	reach = real_reach
	marked_target = target
	global_position = at
	elapsed = 0.0
	active = true
	queue_redraw()

func seek(time: float, at: Vector2) -> void:
	if not active: return
	elapsed = clampf(time,0.0,duration_time(kind,reach))
	global_position = at
	queue_redraw()

func clear() -> void:
	active = false
	kind = ""
	marked_target = null
	queue_redraw()

static func rain_arrow_points(at: Vector2, phase: float) -> Array[Vector2]:
	var fall := minf(1.0,phase)
	return [at+Vector2(0,-100+fall*85),at+Vector2(0,-82+fall*85)]

func _arrow(tail: Vector2, tip: Vector2, tint: Color, width: float = 3.0, size: float = 1.0) -> void:
	var axis := (tip-tail).normalized()
	if axis.is_zero_approx(): return
	var side := axis.orthogonal()
	draw_line(tail-axis*13.0*size,tip,Color(0.42,0.24,0.12,0.52),width+2.5)
	draw_line(tail,tip,tint,width)
	draw_colored_polygon(PackedVector2Array([tip+axis*8.0*size,tip-axis*11.0*size-side*6.0*size,tip-axis*11.0*size+side*6.0*size]),Color("#fff4ca"))

func _draw() -> void:
	if not active: return
	var release: float = TIMINGS[kind].release
	var travel := clampf((elapsed-release)*ARROW_SPEED/maxf(1.0,reach),0.0,1.0)
	var origin := Vector2(0,-24)
	if kind == "chuva_flechas":
		var ring_alpha := 0.62 if elapsed < release else 0.34*(1.0-clampf((elapsed-release)/0.74,0,1))
		if ring_alpha > 0: draw_arc(Vector2.ZERO,reach,0,TAU,72,Color(0.98,0.85,0.53,ring_alpha),2.0,true)
		for i in range(14):
			var angle := float(i)*2.39996
			var distance := sqrt((float(i)+0.5)/14.0)*reach*0.92
			var at := Vector2(cos(angle),sin(angle))*distance
			var phase := (elapsed-release-float(i)*0.035)/0.25
			if phase <= 0 or phase >= 1.45: continue
			var points := rain_arrow_points(at,phase)
			_arrow(points[0],points[1],Color("#f7e3a3"),2.0)
			if phase >= 1: draw_line(at+Vector2(-8,-3),at+Vector2(8,-3),Color(0.97,0.86,0.56,0.55),2.0)
		return
	if kind == "tiro_marcado" and elapsed < release:
		var target := to_local(marked_target.global_position) if is_instance_valid(marked_target) else direction*minf(reach*0.55,180.0)
		draw_arc(target,22.0+(1.0-elapsed/release)*10.0,0,TAU,32,Color("#f4d77e"),2.0,true)
		draw_line(target+Vector2(0,-32),target+Vector2(0,-20),Color("#fff5be"),2.0)
		draw_line(target+Vector2(0,23),target+Vector2(0,33),Color("#fff5be"),2.0)
	if elapsed < release or elapsed > duration_time(kind,reach): return
	var front := maxf(18.0,travel*reach)
	if kind == "rajada_flechas":
		for i in range(3):
			var angle := (float(i)-1.0)*0.24
			var lane := direction.rotated(angle)
			var tip := origin+lane*front
			_arrow(tip-lane*ARROW_SHAFT[kind],tip,Color("#fff8d9") if i == 1 else Color("#f5d687"),2.5 if i == 1 else 2.0,0.48)
	elif kind == "tiro_marcado":
		var tip := origin+direction*front
		_arrow(tip-direction*ARROW_SHAFT[kind],tip,Color("#f3e4a4"),2.5,0.52)
	elif kind == "flecha_perfurante":
		var tip := origin+direction*front
		_arrow(tip-direction*ARROW_SHAFT[kind],tip,Color("#fff9db"),3.0,0.55)
		draw_arc(tip,7.5,0,TAU,20,Color(0.96,0.85,0.56,0.75),1.5,true)
