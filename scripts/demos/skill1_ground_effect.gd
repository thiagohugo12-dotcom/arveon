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
