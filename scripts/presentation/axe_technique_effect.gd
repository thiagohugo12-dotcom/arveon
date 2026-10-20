class_name AxeTechniqueEffect
extends Node2D

# Presentation only. ClassCombat owns the original cone/disk, damage and buff.
const TIMINGS := {
	"golpe_devastador": {"duration": 0.88, "release": 0.34, "contact": 0.46},
	"quebra_guarda": {"duration": 0.98, "release": 0.40, "contact": 0.52},
	"impacto_brutal": {"duration": 1.07, "release": 0.47, "contact": 0.55}
}
const FURY_PREVIEW := 1.40

var kind := ""
var direction := Vector2.RIGHT
var reach := 0.0
var elapsed := 0.0
var buff_duration := 0.0
var active := false

func cast(id: String, at: Vector2, aim: Vector2, real_reach: float, fury_time: float = 0.0) -> void:
	if not TIMINGS.has(id) and id != "furia_machado": return
	kind = id
	direction = aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
	reach = real_reach
	buff_duration = fury_time
	global_position = at
	elapsed = 0.0
	active = true
	queue_redraw()

func seek(time: float, at: Vector2) -> void:
	if not active or kind == "furia_machado": return
	elapsed = clampf(time, 0.0, float(TIMINGS[kind].duration))
	global_position = at
	queue_redraw()

func seek_fury(remaining: float, at: Vector2) -> void:
	if not active or kind != "furia_machado": return
	if remaining <= 0.0:
		clear()
		return
	elapsed = maxf(0.0, buff_duration-remaining)
	global_position = at
	queue_redraw()

func clear() -> void:
	active = false
	kind = ""
	queue_redraw()

func pose_frame() -> int:
	if not active: return 0
	var release: float = 0.46 if kind == "furia_machado" else float(TIMINGS[kind].release)
	if kind == "impacto_brutal":
		if elapsed < release: return clampi(int(elapsed/release*3.0), 0, 2)
		var after := elapsed-release
		if after < 0.08: return 3
		if after < 0.31: return 4 if after < 0.18 else 5
		return 6 if after < 0.47 else 7
	if elapsed < release: return clampi(int(elapsed/release*4.0), 0, 3)
	return clampi(4+int((elapsed-release)/0.15*2.0), 4, 7)

func _ring(at: Vector2, radius: float, color: Color, width: float) -> void:
	if radius > 0.0: draw_arc(at, radius, 0.0, TAU, 48, color, width, true)

func _crescent(radius: float, span: float, alpha: float, shift: float = 0.0) -> void:
	var angle := direction.angle()+shift
	var at := Vector2(0,-24)
	draw_arc(at, radius, angle-span, angle+span, 28, Color(0.47,0.22,0.11,alpha*0.65), 18.0, true)
	draw_arc(at, radius, angle-span, angle+span, 28, Color(0.96,0.67,0.36,alpha), 10.0, true)
	draw_arc(at, radius+3.0, angle-span, angle+span, 28, Color(1.0,0.96,0.77,alpha), 2.0, true)

func _draw() -> void:
	if not active: return
	var release: float = 0.46 if kind == "furia_machado" else float(TIMINGS[kind].release)
	var wind := clampf(elapsed/release,0.0,1.0)
	var after := maxf(0.0,elapsed-release)
	var alpha := maxf(0.0,1.0-after/0.57)
	if kind == "golpe_devastador":
		if elapsed < release: _crescent(32.0+wind*12.0,0.42,0.25+0.35*wind,-0.60)
		else: _crescent(45.0+reach*0.48*clampf(after/0.23,0,1),0.68,alpha,-0.35+clampf(after/0.23,0,1)*0.35)
	elif kind == "quebra_guarda":
		var target := direction*reach*0.59
		if elapsed < release:
			_ring(target+Vector2(0,-7),24.0,Color(0.88,0.76,0.50,0.55),3.0)
			_crescent(35.0+wind*10.0,0.35,0.25+0.35*wind,-0.45)
		else:
			_crescent(48.0+reach*0.38*clampf(after/0.22,0,1),0.78,alpha)
			if after > 0.10:
				draw_line(target+Vector2(-14,-20),target+Vector2(3,-4),Color(1,0.95,0.76,alpha),4.0)
				draw_line(target+Vector2(3,-4),target+Vector2(-2,13),Color(1,0.95,0.76,alpha),3.0)
				draw_line(target+Vector2(3,-4),target+Vector2(15,-14),Color(1,0.95,0.76,alpha),3.0)
	elif kind == "impacto_brutal":
		if elapsed < release:
			_ring(Vector2.ZERO,24.0+wind*15.0,Color(0.96,0.80,0.53,0.55),3.0)
		else:
			# The blade's bright contact is forward; the ring retains the real disk center.
			var strike := direction*42.0
			var flash := maxf(0.0,1.0-after/0.32)
			draw_line(strike-direction*12.0+Vector2(0,-30),strike+Vector2(0,-3),Color(1,0.97,0.79,flash),7.0)
			_ring(strike+Vector2(0,-3),10.0+after*40.0,Color(1,0.88,0.59,flash),4.0)
			var wave := reach*clampf(after/0.31,0,1)
			draw_circle(Vector2.ZERO,wave,Color(0.61,0.38,0.17,alpha*0.12))
			_ring(Vector2.ZERO,wave,Color(0.97,0.82,0.57,alpha),8.0*alpha+1.0)
			for i in range(12):
				var spoke := Vector2.RIGHT.rotated(float(i)*TAU/12.0)
				draw_line(spoke*wave*0.28,spoke*wave*(0.65+float(i%3)*0.10),Color(0.35,0.22,0.14,alpha*0.8),3.0)
	else:
		var p := wind if elapsed < release else 1.0
		var glow := 0.35 if elapsed < release else 0.55+0.12*sin(elapsed*12.0)
		var center := Vector2(0,-28)
		draw_circle(center,44.0*p,Color(0.86,0.34,0.16,glow*0.17))
		_ring(center,44.0*p,Color(1,0.78,0.44,glow),4.0)
		for i in range(7):
			var mote := center+Vector2.RIGHT.rotated(float(i)*TAU/7.0+elapsed*1.5)*44.0*p
			draw_rect(Rect2(mote.round()-Vector2(2,2),Vector2(4,4)),Color(1,0.69,0.34,glow))
