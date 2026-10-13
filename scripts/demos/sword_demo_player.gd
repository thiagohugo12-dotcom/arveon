extends PlayerActor
const DEMO_VIEW := preload("res://scripts/demos/sword_demo_view.gd")
## Same player physics/combat. Only the view callback differs in this demo.
func _physics_process(delta: float) -> void:
	var demo_view := view as DEMO_VIEW
	if demo_view != null:
		var candidate: Node2D = null
		if input_driver != null and not input_driver.blocked and health.is_alive() and attack.armed and attack.cooldown_left > 0 and attack.cooldown_left <= demo_view.PREPARE_TIME:
			candidate = attack.select_target(self)
		if candidate != null:
			demo_view.prepare_sword(candidate.global_position-global_position,attack.cooldown_left)
		else:
			demo_view.cancel_preparation()
	super._physics_process(delta)

func _on_attack(target: Node2D) -> void:
	(view as DEMO_VIEW).play_sword_attack(target.global_position-global_position,attack.weapon.interval)
