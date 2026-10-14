class_name Skill1GameView
extends "res://scripts/demos/skill1_actor_view.gd"
## Reuses the approved review presentation; combat remains owned by PlayerActor.
var ground_effect: Node2D
func _ready() -> void:
	ground_effect = preload("res://scripts/demos/skill1_ground_effect.gd").new()
	add_child(ground_effect)
	ground_effect.top_level = true
	ground_effect.z_as_relative = false
func clear_skill1() -> void:
	super.clear_skill1()
	if is_instance_valid(ground_effect): ground_effect.clear()
func play_skill(index: int) -> void:
	super.play_skill(index)
	if index != 0 or not village_scale or skill_config.is_empty(): return
	var actor = get_parent()
	var reach_bonus := 20.0 if actor.class_combat.has_passive("alcance_treinado") else 0.0
	ground_effect.show_cast(actor.global_position,skill1_direction,skill_category,reach_bonus)
	ground_effect.z_index = clampi(roundi(actor.global_position.y)+99,-4096,4096)
