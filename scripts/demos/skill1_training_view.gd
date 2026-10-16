extends "res://scripts/demos/bow_training_view.gd"
var skill1_impact := ""
func _draw() -> void:
	super._draw()
	if impact_left <= 0 or skill1_impact.is_empty(): return
	preload("res://scripts/presentation/skill1_impact_marks.gd").draw_marks(self,skill1_impact,impact_left/IMPACT_DURATION)
