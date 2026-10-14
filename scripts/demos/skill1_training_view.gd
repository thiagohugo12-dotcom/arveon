extends "res://scripts/demos/bow_training_view.gd"
var skill1_impact := ""
func _draw() -> void:
	super._draw()
	if impact_left <= 0 or skill1_impact.is_empty(): return
	var alpha := impact_left/IMPACT_DURATION
	var spread := 5+(1-alpha)*9
	for axis: Vector2 in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		draw_rect(Rect2((Vector2(0,-27)+axis*spread).round(),Vector2(2,2)),Color(1,0.94,0.72,alpha))
