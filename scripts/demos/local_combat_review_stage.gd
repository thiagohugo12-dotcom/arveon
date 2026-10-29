extends Node2D
var kind := 0
var technique := "estocada_precisa"
var direction := Vector2.RIGHT
var show_hitbox := true
var reach_bonus := 0.0
func _draw() -> void:
	draw_rect(Rect2(300,-200,1400,1300),Color("#657b4e"))
	for x in range(300,1700,40): draw_line(Vector2(x,-200),Vector2(x,1100),Color("#6c8255"),1,false)
	for y in range(-200,1100,40): draw_line(Vector2(300,y),Vector2(1700,y),Color("#6c8255"),1,false)
	if not show_hitbox: return
	var origin := Vector2(1100,440)
	var edge := Color("#ffe0a0")
	if kind == 0:
		if technique == "guarda_reativa": return
		var effect := AbilityRules.effect(technique)
		var reach := float(effect.reach)+reach_bonus
		draw_arc(origin,reach,0,TAU,64,Color("#ffe0a060"),1,false)
		if effect.shape == "line":
			# Exact intersection: range disk AND forward strip, not a rectangle beyond reach.
			var width := float(effect.width)
			var length := sqrt(reach*reach-width*width)
			var side := direction.orthogonal()*width
			draw_polyline(PackedVector2Array([origin-side,origin+direction*length-side,origin+direction*length+side,origin+side,origin-side]),edge,1,false)
		else: draw_arc(origin,reach,0,TAU,64,edge,1,false)
	elif kind == 1:
		if technique == "guardian_idle": return
		if technique in ["root_wave","seeds"]:
			draw_arc(origin,TowerGuardian.WAVE_END if technique == "root_wave" else TowerGuardian.SEED_SPEED*0.90,0,TAU,64,Color("#ffe0a060"),1,false)
			return
		var pts := PackedVector2Array([origin])
		for i in range(21): pts.append(origin+direction.rotated(deg_to_rad(-50+i*5))*TowerGuardian.ROOT_RANGE)
		pts.append(origin)
		draw_polyline(pts,edge,1,false)
	else: draw_arc(origin,36 if kind != 4 else 245,0,TAU,48,edge,1,false)
