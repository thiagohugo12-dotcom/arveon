class_name AutoAttack
extends Node

signal attacked(target: Node2D)
signal projectile_requested(origin: Node2D, target: Node2D, specification: Dictionary)
@export var weapon: WeaponData
var cooldown_left: float = 0.0
var damage_scale := 1.0
var damage_base := -1.0
var basic_bonus := 1.0
var critical_chance := 0.05
var critical_multiplier := 1.5
var damage_type := "physical"
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
	if not weapon.projectile_kind.is_empty() and get_tree().get_nodes_in_group("player_projectiles").size() >= PlayerProjectile.MAX_ACTIVE:
		search_left = EMPTY_SEARCH_INTERVAL
		return
	# Set before callbacks: re-entrant ticks cannot apply the same swing twice.
	cooldown_left = weapon.interval
	search_left = 0.0
	attacked.emit(target)
	var modifiers := {"scale":1.0,"chance":critical_chance,"charge_scale":1.0}
	if origin is PlayerActor and origin.progress != null and target is EnemyActor: modifiers = origin.class_combat.hit_modifiers(target,"basic")
	var roll := CombatRules.roll()
	var hit := CombatRules.resolve(damage_base if damage_base >= 0 else float(weapon.damage),basic_bonus,damage_scale*float(modifiers.scale),float(modifiers.chance),critical_multiplier,roll,float(modifiers.chance) if float(modifiers.chance) > critical_chance else -1.0)
	var eligible := CombatRules.resolve(damage_base if damage_base >= 0 else float(weapon.damage),basic_bonus,damage_scale*float(modifiers.charge_scale),float(modifiers.chance),critical_multiplier,roll,float(modifiers.chance) if float(modifiers.chance) > critical_chance else -1.0)
	var hit_damage: int = hit.damage
	var event := CombatRules.next_event()
	if weapon.projectile_kind.is_empty():
		if target is EnemyActor: target.receive_damage(hit_damage,weapon.category,event,damage_type,hit.critical,false,"basic",eligible.damage)
		else: target.receive_damage(hit_damage)
	else:
		projectile_requested.emit(origin, target, {"damage": hit_damage, "kind": weapon.projectile_kind, "speed": weapon.projectile_speed, "reach": weapon.reach, "category":weapon.category,"event":event,"damage_type":damage_type,"critical":hit.critical,"ultimate":false,"source":"basic","eligible_damage":eligible.damage})

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
