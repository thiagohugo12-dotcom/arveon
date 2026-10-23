class_name TowerGuardian
extends EnemyActor

# Gameplay does not depend on the procedural view; replace View to upgrade art.
enum Action { ROOTS, SPIKES, CHARGE, ROOT_WAVE, SEEDS }
enum State { APPROACH, WINDUP, ACTIVE, RECOVERY }
const MAX_HP := 360
const ROOT_RANGE := 90.0
const SPIKE_RADIUS := 26.0
const CHARGE_SPEED := 320.0
const WINDUPS := [0.75,1.0,0.8,1.10,0.90]
const ACTIVES := [0.12,0.45,0.65,0.65,0.90]
const WAVE_START := 28.0
const WAVE_END := 160.0
const WAVE_HALF_WIDTH := 12.0
const SEED_SPEED := 240.0
const SEED_RADIUS := 12.0
const SEED_ANGLES := [-PI/7.2,0.0,PI/7.2]
var attack_origin := Vector2.ZERO
var seed_blocked := [false,false,false]
var action := Action.ROOTS
var state := State.APPROACH
var phase_two := false
var action_left := 0.0
var recovery_left := 0.8
var aim := Vector2.DOWN
var spike_points: Array[Vector2] = []
var attack_hit := false

func display_name() -> String:
	return "Guardião da Prova"

func _physics_process(delta: float) -> void:
	tick_ability_status(delta)
	velocity = Vector2.ZERO
	if not is_targetable() or not is_instance_valid(target) or not target.health.is_alive():
		_clear_warning()
		view.hazards_active = false
		return
	# Stop immediately on modal input, before Main pauses the next physics frame.
	if target.input_driver != null and target.input_driver.blocked:
		view.set_moving(false)
		return
	phase_two = health.current * 2 <= health.maximum
	view.second_phase = phase_two
	var offset := target.global_position - global_position
	match state:
		State.APPROACH:
			recovery_left = maxf(0.0, recovery_left - delta)
			view.set_facing(offset)
			if offset.length() > 72.0:
				_move_bounded(offset.normalized() * stats.move_speed * delta)
			if recovery_left == 0.0:
				_begin_attack()
		State.WINDUP:
			action_left = maxf(0.0, action_left - delta)
			if action_left < 0.000001: action_left = 0.0
			if action_left == 0.0:
				state = State.ACTIVE
				action_left = ACTIVES[action]
				view.play_attack()
				# The root contact is the WINDUP -> ACTIVE event, shared with the pose.
				if action == Action.ROOTS and roots_contains(target.global_position): _damage_once(20)
		State.ACTIVE:
			if action == Action.CHARGE:
				var before := global_position
				var collision := _move_bounded(aim * CHARGE_SPEED * minf(delta, action_left))
				var nearest := Geometry2D.get_closest_point_to_segment(target.global_position, before, global_position)
				if nearest.distance_to(target.global_position) <= 30.0:
					_damage_once(22)
				if collision:
					action_left = 0.0
			elif action == Action.ROOTS and roots_contains(target.global_position):
				_damage_once(20)
			elif action == Action.SPIKES:
				for point in spike_points:
					if point.distance_to(target.global_position) <= SPIKE_RADIUS:
						_damage_once(18)
			elif action in [Action.ROOT_WAVE,Action.SEEDS]:
				var before := float(ACTIVES[action])-action_left
				_apply_new_hazards(before,minf(float(ACTIVES[action]),before+delta))
			action_left = maxf(0.0, action_left - delta)
			if action_left < 0.000001: action_left = 0.0
			if action_left == 0.0:
				_finish_attack()
		State.RECOVERY:
			recovery_left = maxf(0.0, recovery_left - delta)
			if recovery_left == 0.0:
				state = State.APPROACH
	view.hazards_active = state == State.ACTIVE
	view.set_moving(velocity.length_squared() > 1.0)
	view.charge_length = CHARGE_SPEED * 0.65
	view.queue_redraw()

func wave_radius(time: float) -> float:
	return lerpf(WAVE_START,WAVE_END,clampf(time/float(ACTIVES[Action.ROOT_WAVE]),0,1))

func seed_position(index: int,time: float) -> Vector2:
	var point := attack_origin+aim.rotated(SEED_ANGLES[index])*SEED_SPEED*time
	return Vector2(clampf(point.x,arena_bounds.position.x+12,arena_bounds.end.x-12),clampf(point.y,arena_bounds.position.y+12,arena_bounds.end.y-12))

func _apply_new_hazards(before: float,after: float) -> void:
	if action == Action.ROOT_WAVE:
		var distance := attack_origin.distance_to(target.global_position)
		if distance >= wave_radius(before)-WAVE_HALF_WIDTH and distance <= wave_radius(after)+WAVE_HALF_WIDTH:
			_damage_once(18)
	elif action == Action.SEEDS:
		for i in range(3):
			if seed_blocked[i]: continue
			var start := seed_position(i,before)
			var end := seed_position(i,after)
			var wall := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(start,end,1))
			if not wall.is_empty():
				end=wall.position
				seed_blocked[i]=true
			var nearest := Geometry2D.get_closest_point_to_segment(target.global_position,start,end)
			if nearest.distance_to(target.global_position) <= SEED_RADIUS: _damage_once(16)

func roots_contains(point: Vector2) -> bool:
	var offset := point - global_position
	return offset.length_squared() <= ROOT_RANGE * ROOT_RANGE and (offset.is_zero_approx() or offset.normalized().dot(aim) >= cos(deg_to_rad(50.0)))

func _begin_attack() -> void:
	if not is_instance_valid(target) or not target.health.is_alive():
		return
	state = State.WINDUP
	attack_hit = false
	aim = global_position.direction_to(target.global_position)
	if aim.is_zero_approx():
		aim = Vector2.DOWN
	action_left = WINDUPS[action]
	attack_origin = global_position
	seed_blocked = [false,false,false]
	spike_points.clear()
	if action == Action.SPIKES:
		for side in [0, -1, 1]:
			var point: Vector2 = target.global_position + aim.orthogonal() * side * 58.0
			spike_points.append(Vector2(clampf(point.x, arena_bounds.position.x + 62, arena_bounds.end.x - 62), clampf(point.y, arena_bounds.position.y + 62, arena_bounds.end.y - 62)))
	view.set_facing(aim)
	view.set_warning(true)
	view.telegraph_kind = action
	view.telegraph_direction = aim
	view.spike_points = spike_points

func _damage_once(amount: int) -> void:
	if attack_hit or not target.health.is_alive():
		return
	var ray := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		return
	attack_hit = true # All spike areas and charge frames share one hit per action.
	target.receive_damage(roundi(amount * damage_scale),"physical",display_name())

func _finish_attack() -> void:
	_clear_warning()
	state = State.RECOVERY
	# Missing a charge leaves a longer opening in both phases.
	recovery_left = 1.4 if action == Action.CHARGE and not attack_hit else 1.0 * (0.8 if phase_two else 1.0)
	action = (action + 1) % Action.size()

func _clear_warning() -> void:
	view.set_warning(false)
	view.hazards_active = false
	spike_points.clear()
	view.spike_points = spike_points

func _move_bounded(motion: Vector2) -> bool:
	velocity = motion * 60.0
	var hit := move_and_collide(motion)
	var bounded := Vector2(clampf(global_position.x, arena_bounds.position.x + 46, arena_bounds.end.x - 46), clampf(global_position.y, arena_bounds.position.y + 46, arena_bounds.end.y - 46))
	var outside := not bounded.is_equal_approx(global_position)
	global_position = bounded
	return hit != null or outside

func _on_died() -> void:
	_clear_warning()
	super._on_died()
