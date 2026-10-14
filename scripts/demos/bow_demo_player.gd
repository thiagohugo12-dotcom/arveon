extends PlayerActor
const BOW_VIEW := preload("res://scripts/demos/bow_demo_view.gd")
func _physics_process(delta: float) -> void:
	var bow := view as BOW_VIEW
	if bow != null:
		if input_driver == null or input_driver.blocked or not health.is_alive() or not attack.armed or SafeCamp.in_clearance(global_position):
			bow.clear_bow()
		else:
			var candidate: Node2D = null
			if attack.cooldown_left > 0 and attack.cooldown_left <= bow.prepare_time(attack.weapon.interval): candidate = attack.select_target(self)
			if candidate != null: bow.prepare_bow(candidate.global_position-global_position,attack.cooldown_left,attack.weapon.interval)
			else: bow.cancel_preparation()
	super._physics_process(delta)

func _on_attack(target: Node2D) -> void:
	(view as BOW_VIEW).play_bow_attack(target.global_position-global_position,attack.weapon.interval)
