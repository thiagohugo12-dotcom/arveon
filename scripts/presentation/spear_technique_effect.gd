class_name SpearTechniqueEffect
extends Node2D

# Visual only. The original line, disk and cone rules stay in ClassCombat.
const TIMINGS := {
	"estocada_longa": {"duration": 0.86, "release": 0.28, "contact": 0.56},
	"varredura": {"duration": 0.96, "release": 0.35, "contact": 0.61},
	"marca_caca": {"duration": 1.05, "release": 0.43, "contact": 0.71},
	"muralha_lancas": {"duration": 1.19, "release": 0.53, "contact": 0.85}
}

var kind := ""
var direction := Vector2.RIGHT
var reach := 0.0
var elapsed := 0.0
var active := false

func cast(id: String, at: Vector2, aim: Vector2, real_reach: float) -> void:
	if not TIMINGS.has(id): return
	kind = id
	direction = aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
	reach = real_reach
	global_position = at
	elapsed = 0.0
	active = true
	queue_redraw()

func seek(time: float, at: Vector2) -> void:
	if not active: return
	elapsed = clampf(time,0.0,float(TIMINGS[kind].duration))
	global_position = at
	queue_redraw()

func clear() -> void:
	active = false
	kind = ""
	queue_redraw()

func pose_frame() -> int:
	if not active: return 0
	var release: float = TIMINGS[kind].release
	if elapsed < release: return clampi(int(elapsed/maxf(0.01,release)*4.0),0,3)
	return clampi(4+int((elapsed-release)/0.15*2.0),4,7)

func _ring(at: Vector2, radius: float, color: Color, width: float = 2.0) -> void:
	if radius > 0.0: draw_arc(at,radius,0,TAU,48,color,width,true)

func _point(at: Vector2, angle: float, alpha: float, size: float = 1.0) -> void:
	var forward := Vector2.RIGHT.rotated(angle)
	var across := forward.orthogonal()
	draw_line(at-forward*22.0*size,at+forward*2.0*size,Color(0.45,0.27,0.15,alpha),4.0*size)
	draw_colored_polygon(PackedVector2Array([at+forward*13.0*size,at+across*5.0*size,at-forward*3.0*size,at-across*5.0*size]),Color(0.97,0.96,0.82,alpha))

func _mark(at: Vector2, alpha: float) -> void:
	var center := at+Vector2(0,-7)
	_ring(center,25,Color(0.96,0.86,0.52,alpha),3.0)
	draw_line(center+Vector2(-12,0),center+Vector2(12,0),Color(1,0.95,0.74,alpha),2.0)
	draw_line(center+Vector2(0,-12),center+Vector2(0,12),Color(1,0.95,0.74,alpha),2.0)

func _draw() -> void:
	if not active: return
	var release: float = TIMINGS[kind].release
	var wind := clampf(elapsed/release,0,1)
	var after := maxf(0.0,elapsed-release)
	var alpha := maxf(0.0,1.0-after/0.66)
	if kind == "estocada_longa":
		if elapsed < release:
			_ring(direction*(30.0+wind*22.0)+Vector2(0,-24),8.0+wind*7.0,Color(1,0.92,0.69,0.70))
		else:
			var tip := direction*reach*clampf(after/0.28,0,1)+Vector2(0,-24)
			draw_line(direction*26.0+Vector2(0,-24),tip,Color(0.96,0.88,0.64,alpha),5.0)
			_point(tip,direction.angle(),alpha,1.05)
	elif kind == "varredura":
		if elapsed < release:
			_ring(Vector2.ZERO,reach*0.35*wind,Color(0.95,0.84,0.61,0.65))
		else:
			var end_angle := direction.angle()-PI+clampf(after/0.36,0,1)*TAU
			draw_arc(Vector2.ZERO,reach*0.94,end_angle-2.2,end_angle,32,Color(0.95,0.84,0.61,alpha),9.0,true)
			draw_arc(Vector2.ZERO,reach*0.94,end_angle-1.2,end_angle,20,Color(1,0.98,0.84,alpha),3.0,true)
			_ring(Vector2.ZERO,reach*0.96,Color(0.86,0.75,0.47,alpha*0.55))
	elif kind == "marca_caca":
		var target := direction*reach*0.65
		if elapsed < release:
			_mark(target,0.25+0.65*wind)
			_ring(direction*27.0+Vector2(0,-24),8.0+8.0*wind,Color(0.97,0.88,0.62,0.65))
		else:
			var tip := direction*reach*clampf(after/0.28,0,1)+Vector2(0,-24)
			draw_line(direction*20.0+Vector2(0,-24),tip,Color(1,0.93,0.69,alpha),5.0)
			_point(tip,direction.angle(),alpha)
			_mark(target,maxf(0.35,alpha))
	else:
		if elapsed < release:
			_ring(Vector2.ZERO,30.0+25.0*wind,Color(0.95,0.84,0.61,0.25+0.45*wind))
		else:
			for i in range(-2,3):
				var angle := direction.angle()+float(i)*0.58
				var lane := Vector2.RIGHT.rotated(angle)
				var front := reach*clampf((after-float(i)*0.035)/0.36,0,1)
				var tip := lane*front+Vector2(0,-24)
				draw_line(lane*maxf(12,front-32.0)+Vector2(0,-24),tip,Color(0.99,0.90,0.67,alpha*0.70),4.0)
				_point(tip,angle,alpha,0.8)
