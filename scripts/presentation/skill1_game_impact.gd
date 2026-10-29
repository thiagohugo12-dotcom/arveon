extends Node2D
var category := ""
var remaining := 0.0
func show_hit(weapon: String,effective: int,event: int,actor: EnemyActor) -> void:
	if effective <= 0 or not get_parent().village_scale: return
	var rule: Dictionary = AbilityRules.CATEGORIES.get(weapon,{}).get("skill1",{})
	if rule.is_empty() or actor.hit_details(event).get("source","") != rule.id: return
	category = weapon
	remaining = 0.12
	queue_redraw()
func _process(delta: float) -> void:
	if remaining <= 0: return
	remaining = maxf(0,remaining-delta)
	queue_redraw()
func _draw() -> void:
	if remaining > 0:
		preload("res://scripts/presentation/skill1_impact_marks.gd").draw_marks(self,category,remaining/0.12)
