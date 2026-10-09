class_name AutoAttack
extends Node

signal attacked(target: Node2D)
@export var weapon: WeaponData
var cooldown_left: float = 0.0
var damage_scale := 1.0
const EMPTY_SEARCH_INTERVAL := 0.08
var search_left := 0.0

func tick(delta: float, origin: Node2D) -> void:
	if SafeCamp.in_clearance(origin.global_position):
		return
	cooldown_left = maxf(0.0, cooldown_left - delta)
	search_left = maxf(0.0, search_left - delta)
	if cooldown_left > 0.000001 or search_left > 0.000001 or weapon == null:
		return
	# An empty search is not a swing. Bound retries without spending hit cooldown.
	var target: Node2D = select_target(origin)
	if target == null:
		search_left = EMPTY_SEARCH_INTERVAL
		return
	# Set before callbacks: re-entrant ticks cannot apply the same swing twice.
	cooldown_left = weapon.interval
	search_left = 0.0
	attacked.emit(target)
	target.receive_damage(roundi(weapon.damage * damage_scale))

func select_target(origin: Node2D) -> Node2D:
	if weapon == null:
		return null
	var selected: Node2D = null
	var best_distance: float = weapon.reach * weapon.reach
	for candidate: Node in get_tree().get_nodes_in_group("damageable_enemies"):
		if not is_instance_valid(candidate) or candidate.is_queued_for_deletion():
			continue
		if not candidate is Node2D or not candidate.has_method("is_targetable"):
			continue
		if not candidate.is_targetable():
			continue
		var distance: float = origin.global_position.distance_squared_to(candidate.global_position)
		if distance > best_distance:
			continue
		var query := PhysicsRayQueryParameters2D.create(origin.global_position, candidate.global_position, 1)
		if not origin.get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			continue
		if selected == null or distance < best_distance:
			selected = candidate as Node2D
			best_distance = distance
	return selected
