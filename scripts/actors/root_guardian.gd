class_name RootGuardian
extends EnemyActor

var attack_index := 0
var windup := 0.0
var recover := 1.4
var aim := Vector2.DOWN

func _physics_process(delta: float) -> void:
	if not is_targetable() or not is_instance_valid(target) or not target.health.is_alive():
		_cancel_attack()
		return
	if SafeCamp.in_clearance(target.global_position) or target.global_position.distance_to(home_position) > 320.0:
		_cancel_attack()
		_return_home()
		return
	var offset := target.global_position - global_position
	view.set_facing(offset)
	velocity = Vector2.ZERO
	if windup > 0.0:
		windup = maxf(0.0, windup - delta)
		if windup == 0.0:
			_resolve_attack()
			attack_index = (attack_index + 1) % 3
			recover = 1.6
			view.set_warning(false)
	elif recover > 0.0:
		recover = maxf(0.0, recover - delta)
		if offset.length() > 100.0:
			velocity = offset.normalized() * stats.move_speed
	else:
		windup = [0.8, 1.0, 1.1][attack_index]
		aim = offset.normalized()
		view.set_warning(true)
		view.set("telegraph_kind", attack_index)
		view.set("telegraph_direction", aim)
	var before := global_position
	move_and_slide()
	if SafeCamp.in_clearance(global_position):
		global_position = before
	view.set_moving(velocity.length_squared() > 1.0)

func _cancel_attack() -> void:
	windup = 0.0
	recover = 1.4
	view.set_warning(false)
	view.set_moving(false)

func _resolve_attack() -> void:
	if not is_targetable() or not target.health.is_alive() or SafeCamp.in_clearance(target.global_position):
		return
	var offset := target.global_position - global_position
	var hit := false
	match attack_index:
		0: hit = offset.length_squared() <= 100.0 * 100.0
		1: hit = offset.dot(aim) > 0.0 and offset.dot(aim) <= 200.0 and absf(offset.cross(aim)) < 28.0
		2:
			for angle in [-0.35, 0.0, 0.35]:
				projectile_requested.emit(global_position, aim.rotated(angle), 13)
	if hit:
		var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
		if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			target.receive_damage(18)
	view.play_attack()
