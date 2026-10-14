extends Node2D
## One reused, non-colliding ground effect per review panel.
var category := "espada"
var direction := Vector2.RIGHT
var geometry: Dictionary = {}
var remaining := 0.0
var duration := 0.22
var activations := 0
func show_cast(at: Vector2,aim: Vector2,weapon: String,reach_bonus: float = 0) -> void:
	category = weapon
	direction = aim.normalized()
	geometry = AbilityRules.effect(AbilityRules.CATEGORIES[weapon].skill1.id)
	geometry.reach = float(geometry.reach)+reach_bonus
	duration = 0.30 if weapon == "machado" else 0.22
	global_position = at
	remaining = duration
	activations += 1
	z_index = clampi(roundi(at.y)-1,-4096,4096)
	queue_redraw()
func clear() -> void:
	remaining = 0
	queue_redraw()
func _process(delta: float) -> void:
	if remaining > 0:
		remaining = maxf(0,remaining-delta)
		queue_redraw()
func _draw() -> void:
	if remaining <= 0 or geometry.is_empty(): return
	var progress := 1-remaining/duration
	var alpha := remaining/duration
	if category == "espada":
		var radius := lerpf(40,float(geometry.reach),progress)
		for mark in range(13):
			var point := (direction.rotated(-PI/2+mark*PI/12)*radius).round()
			draw_rect(Rect2(point,Vector2(3,3)),Color(1,0.94,0.72,alpha))
	elif category == "machado":
		# Actual Racha-Chao is a disk around the player's feet, not a forward cone.
		var radius := lerpf(15,float(geometry.reach),progress)
		for mark in range(20):
			var axis := Vector2.RIGHT.rotated(mark*TAU/20)
			draw_rect(Rect2((axis*radius).round(),Vector2(4,2)),Color(0.88,0.73,0.48,alpha))
		for mark in range(8):
			var axis := Vector2.RIGHT.rotated(mark*TAU/8)
			var dust := (axis*(14+progress*26)+Vector2(0,-progress*6)).round()
			draw_rect(Rect2(dust,Vector2(3,2)),Color(0.77,0.61,0.39,alpha*0.8))
