extends Node2D
## Sword technique feedback only. Damage, reach and cooldown remain in ClassCombat.
var kind := ""
var direction := Vector2.RIGHT
var remaining := 0.0
var duration := 0.32
var guard_follow: Node2D
var bursts := 0

func cast(id: String, at: Vector2, aim: Vector2, guard_time: float = 0.0) -> void:
	kind = id
	direction = aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
	global_position = at
	duration = guard_time if id == "guarda_reativa" else (0.44 if id == "danca_laminas" else 0.29)
	remaining = duration
	guard_follow = get_parent().get_parent() if id == "guarda_reativa" else null
	bursts = 0
	queue_redraw()

func counter(at: Vector2, aim: Vector2) -> void:
	if kind != "guarda_reativa" or remaining <= 0: return
	global_position = at
	direction = aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
	bursts = 1
	queue_redraw()

func clear() -> void:
	kind = ""
	remaining = 0.0
	guard_follow = null
	bursts = 0
	queue_redraw()

func _process(delta: float) -> void:
	if remaining <= 0: return
	remaining = maxf(0.0,remaining-delta)
	if kind == "guarda_reativa" and is_instance_valid(guard_follow):
		global_position = guard_follow.global_position
	if remaining == 0: clear()
	else: queue_redraw()

func _draw() -> void:
	if remaining <= 0: return
	var progress := 1.0-remaining/duration
	if kind == "estocada_precisa":
		# The visible blue edge follows the existing 155 px line, 22 px width.
		var head := 155.0*minf(1.0,progress*4.0)
		var fade := minf(1.0,remaining/0.16)
		var side := direction.orthogonal()
		for width in [7.0,4.0,2.0]:
			draw_line((direction*18.0+side*width).round(),(direction*head+side*width).round(),Color(0.14,0.55,0.96,0.34*fade),2.0,false)
			draw_line((direction*18.0-side*width).round(),(direction*head-side*width).round(),Color(0.14,0.55,0.96,0.34*fade),2.0,false)
		draw_line((direction*20.0).round(),(direction*head).round(),Color(0.9,0.98,1.0,fade),4.0,false)
		for i in range(3):
			var point := direction*(head-5.0-i*9.0)+side*float(i-1)*3.0
			draw_rect(Rect2(point.round(),Vector2(4,2)),Color(0.5,0.86,1.0,fade))
	elif kind == "guarda_reativa":
		var pulse := minf(1.0,progress*8.0)
		var blue := Color(0.22,0.65,1.0,0.5*pulse)
		for i in range(20):
			var start := Vector2.RIGHT.rotated(i*TAU/20.0)*26.0
			var end := Vector2.RIGHT.rotated((i+1)*TAU/20.0)*26.0
			draw_line(start.round(),end.round(),blue,2.0,false)
		if bursts > 0:
			var side := direction.orthogonal()
			for i in range(4):
				draw_line((direction*15.0+side*(i-2)*3.0).round(),(direction*(32.0+i*4.0)+side*(i-2)*4.0).round(),Color(1.0,0.87,0.45,0.85),2.0,false)
			bursts = 0
	elif kind == "danca_laminas":
		# Crimson sweeping arcs stay inside the existing 150 px disk.
		var fade := minf(1.0,remaining/0.22)
		var sweep := minf(1.0,progress*4.0)
		for layer in range(3):
			var radius := (46.0+float(layer)*45.0)*sweep
			var color := Color(0.95,0.12+0.12*layer,0.19,fade*(0.92-0.19*layer))
			for i in range(13):
				var a := direction.angle()-1.15+float(i)*2.3/13.0+progress*0.35
				var b := direction.angle()-1.15+float(i+1)*2.3/13.0+progress*0.35
				draw_line((Vector2.RIGHT.rotated(a)*radius).round(),(Vector2.RIGHT.rotated(b)*radius).round(),color,5.0-float(layer),false)
		var tip := direction*minf(150.0,150.0*sweep)
		draw_line((direction*22.0).round(),tip.round(),Color(1.0,0.88,0.75,fade),3.0,false)
