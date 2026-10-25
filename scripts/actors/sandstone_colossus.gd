class_name SandstoneColossus
extends RootGuardian

# Optional guardian in the open arena of the Vale. The floor's existing
# guardian state, drops and save path remain the source of truth.
const ARENA_LIMITS := Rect2(1210, 920, 340, 315)

func display_name() -> String:
	return "Colosso de Arenito"

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	global_position = Vector2(
		clampf(global_position.x, ARENA_LIMITS.position.x + 28, ARENA_LIMITS.end.x - 28),
		clampf(global_position.y, ARENA_LIMITS.position.y + 28, ARENA_LIMITS.end.y - 28))

func _resolve_attack() -> void:
	if not is_targetable() or not target.health.is_alive():
		return
	var offset := target.global_position - global_position
	var hit := false
	match attack_index:
		0: hit = offset.length_squared() <= 110.0 * 110.0
		1: hit = offset.dot(aim) > 0.0 and offset.dot(aim) <= 210.0 and absf(offset.cross(aim)) < 36.0
		2:
			for angle in [-0.38, 0.0, 0.38]:
				projectile_requested.emit(global_position, aim.rotated(angle), roundi(17 * damage_scale),display_name())
		3, 4: _resolve_extra()
	if hit:
		var ray := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
		if get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			target.receive_damage(roundi((25 if attack_index == 0 else 22) * damage_scale),"physical",display_name())
	view.play_attack()
