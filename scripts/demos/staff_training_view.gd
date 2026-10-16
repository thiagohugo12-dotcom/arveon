extends "res://scripts/demos/bow_training_view.gd"
func _draw() -> void:
	super._draw()
	if impact_left <= 0: return
	for direction: Vector2 in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		var at := (Vector2(0,-27)+direction*(7+(IMPACT_DURATION-impact_left)*45)).round()
		draw_rect(Rect2(at,Vector2(2,2)),Color("#a9e4c2"))
