class_name EnemyActor
extends CharacterBody2D

signal defeated(kind: int)
signal weapon_hit(category: String, effective: int, event: int)
signal projectile_requested(origin: Vector2, direction: Vector2, damage: int, source_name: String)
signal phase_changed(phase: int)
signal summon_requested(kinds: Array, limit: int)

@export var stats: ActorData
@export_range(0, 7, 1) var kind: int = 0  # 0-4 Mata/Torre; 5 Goblin, 6 Tatu, 7 Escorpião
@onready var health: Health = $Health
@onready var view: ActorView = $View
var arena_bounds := Rect2()
var damage_scale := 1.0
var projectile_damage_override := 0
var target: PlayerActor
var contact_left := 0.0
var special_left := 0.0
var charge_windup := 0.0
var charge_left := 0.0
var charge_direction := Vector2.ZERO
var spine_windup := 0.0
var melee_windup := 0.0
var strafe_sign := 1.0
const AGGRO_ENTER := 245.0
const AGGRO_EXIT := 375.0
const TERRITORY_RADIUS := 260.0
const MAX_CHASE_FROM_HOME := 340.0
const SLEEP_ENTER := 620.0
const SLEEP_EXIT := 520.0
var home_position := Vector2.ZERO
var awake := true
var chasing := false
var invulnerable := false
var _damage_events: Dictionary = {}
var _proficiency_budget := -1
var _hit_receipts: Dictionary = {}
var _receipt_details: Dictionary = {}
var control_left := 0.0
var mark_left := 0.0
var mark_category := ""
var mark_bonus := 0.0

func display_name() -> String:
	if kind >= 5:
		return ["Goblin Garimpeiro","Tatu Rochoso","Escorpião da Chapada"][kind-5]
	return ["Javali","Aranha","Mandacaru","Javali Elite","Criatura da Mata"][mini(kind,4)]

func _ready() -> void:
	home_position = global_position
	view.appearance = (kind - 4 if kind >= 5 else (0 if kind == 3 else kind) + 1)
	view.elite = kind == 3
	view.queue_redraw()
	add_to_group("damageable_enemies")
	health.changed.connect(view.set_health)
	health.died.connect(_on_died)
	health.initialize(stats.max_hp)

func update_activity(player_position: Vector2) -> void:
	if not health.is_alive():
		return
	if arena_bounds.has_area():
		return # Arena members stay awake and cannot despawn by distance.
	var distance_squared := global_position.distance_squared_to(player_position)
	if awake and distance_squared > SLEEP_ENTER * SLEEP_ENTER:
		awake = false
		set_physics_process(false)
		view.set_moving(false)
		view.set_warning(false)
		melee_windup = 0.0
	elif not awake and distance_squared < SLEEP_EXIT * SLEEP_EXIT:
		awake = true
		set_physics_process(true)

func tick_ability_status(delta: float) -> void:
	control_left = maxf(0,control_left-delta)
	mark_left = maxf(0,mark_left-delta)

func _physics_process(delta: float) -> void:
	if is_instance_valid(target) and target.input_driver != null and target.input_driver.blocked:
		view.set_moving(false)
		return
	tick_ability_status(delta)
	if control_left > 0:
		velocity = Vector2.ZERO
		view.set_moving(false)
		return
	contact_left = maxf(0.0, contact_left - delta)
	special_left = maxf(0.0, special_left - delta)
	velocity = Vector2.ZERO
	if not is_targetable() or not is_instance_valid(target) or not target.health.is_alive():
		view.set_moving(false)
		view.set_warning(false)
		return
	var offset := target.global_position - global_position
	var distance := offset.length()
	var home_distance := target.global_position.distance_to(home_position)
	if arena_bounds.has_area():
		chasing = true
	elif chasing:
		if distance > AGGRO_EXIT or home_distance > MAX_CHASE_FROM_HOME or SafeCamp.in_clearance(target.global_position):
			chasing = false
			charge_windup = 0.0
			charge_left = 0.0
			melee_windup = 0.0
	else:
		if distance <= AGGRO_ENTER and home_distance <= TERRITORY_RADIUS and not SafeCamp.in_clearance(target.global_position):
			chasing = true
	if not chasing:
		_return_home()
		return
	view.set_facing(offset)
	match kind:
		0, 3, 6: _boar_behavior(delta, offset, distance)
		1, 5, 7: _spider_behavior(delta, offset, distance)
		2: _cactus_behavior(offset, distance, delta)
	var before := global_position
	move_and_slide()
	if SafeCamp.in_clearance(global_position) or (not arena_bounds.has_area() and global_position.distance_to(home_position) > MAX_CHASE_FROM_HOME):
		global_position = before
		velocity = Vector2.ZERO
		chasing = false
	view.set_moving(velocity.length_squared() > 1.0)
	if kind != 2 and kind not in [1,5,7]:
		_try_contact(distance)

func _return_home() -> void:
	spine_windup = 0.0
	melee_windup = 0.0
	view.set_warning(false)
	var offset := home_position - global_position
	if offset.length_squared() <= 64.0:
		view.set_moving(false)
		return
	velocity = offset.normalized() * stats.move_speed * 0.65
	var before := global_position
	move_and_slide()
	if SafeCamp.in_clearance(global_position):
		global_position = before
		velocity = Vector2.ZERO
	view.set_moving(velocity.length_squared() > 1.0)

func _boar_behavior(delta: float, offset: Vector2, distance: float) -> void:
	if charge_left > 0.0:
		charge_left = maxf(0.0, charge_left - delta)
		velocity = charge_direction * stats.move_speed * 2.5
		view.set_warning(false)
		return
	if charge_windup > 0.0:
		charge_windup = maxf(0.0, charge_windup - delta)
		view.set_warning(true)
		if charge_windup == 0.0:
			charge_left = 0.38
			special_left = 2.8
		return
	if distance > 72.0 and distance < 230.0 and special_left == 0.0:
		charge_direction = offset.normalized()
		charge_windup = 0.42
		view.set_warning(true)
		return
	view.set_warning(false)
	if distance > 28.0:
		velocity = offset.normalized() * stats.move_speed

func _spider_behavior(delta: float, offset: Vector2, distance: float) -> void:
	if melee_windup > 0.0:
		melee_windup = maxf(0.0, melee_windup - delta)
		velocity = Vector2.ZERO
		view.set_warning(true)
		if melee_windup == 0.0:
			_resolve_agile_melee()
		return
	if contact_left == 0.0 and distance <= 56.0:
		melee_windup = 0.34
		velocity = Vector2.ZERO
		view.set_warning(true)
		return
	view.set_warning(false)
	var direction := offset.normalized()
	if distance < 26.0:
		velocity = -direction * stats.move_speed * 0.8
	elif distance > 44.0:
		velocity = direction * stats.move_speed
	else:
		# Strafe around the player instead of stacking on top of them.
		var tangent := Vector2(-direction.y, direction.x) * strafe_sign
		velocity = tangent * stats.move_speed * 0.62
		if special_left == 0.0:
			strafe_sign *= -1.0
			special_left = 1.25

func _resolve_agile_melee() -> void:
	view.set_warning(false)
	if not is_targetable() or not chasing or not is_instance_valid(target) or not target.health.is_alive():
		return
	var distance := global_position.distance_to(target.global_position)
	view.play_attack()
	# The warning gives a short dodge window; leaving the visible strike radius
	# prevents damage instead of allowing an unavoidable contact tick.
	if distance > 56.0 or SafeCamp.in_clearance(target.global_position):
		return
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
	if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		target.receive_damage(stats.contact_damage,"physical",display_name())
		contact_left = stats.contact_interval

func _cactus_behavior(offset: Vector2, distance: float, delta: float = 0.0) -> void:
	if spine_windup > 0.0:
		spine_windup = maxf(0.0,spine_windup-delta)
		if spine_windup < 0.000001: spine_windup = 0.0
		view.set_warning(spine_windup > 0)
		if spine_windup == 0.0: _fire_cactus_spine()
	if distance < 118.0:
		velocity = -offset.normalized() * stats.move_speed * 0.72
	elif distance > 205.0:
		velocity = offset.normalized() * stats.move_speed * 0.65
	else:
		velocity = Vector2.ZERO
	if distance <= 245.0 and special_left == 0.0:
		view.set_warning(true)
		special_left = 1.65
		spine_windup = 0.34
	elif special_left < 1.28:
		view.set_warning(false)

func _fire_cactus_spine() -> void:
	if not is_targetable() or not chasing or not is_instance_valid(target) or not target.health.is_alive():
		view.set_warning(false)
		return
	if SafeCamp.in_clearance(target.global_position) or (not arena_bounds.has_area() and target.global_position.distance_to(home_position) > MAX_CHASE_FROM_HOME):
		view.set_warning(false)
		return
	var direction := global_position.direction_to(target.global_position)
	projectile_requested.emit(global_position, direction, projectile_damage_override if projectile_damage_override > 0 else max(4, stats.contact_damage - 2),display_name())
	view.set_warning(false)
	view.play_attack()

func _try_contact(distance: float) -> void:
	if kind in [0,3,6] and charge_windup > 0.0: return
	if distance > stats.contact_range or contact_left > 0.0:
		return
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
	if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		target.receive_damage(stats.contact_damage,"physical",display_name())
		contact_left = stats.contact_interval
		view.play_attack()

func is_targetable() -> bool:
	return health.is_alive() and awake and not SafeCamp.in_clearance(global_position) and not is_queued_for_deletion()

func consume_hit_receipt(category: String, amount: int, event: int) -> bool:
	if _hit_receipts.get(event) != [category,amount]: return false
	_hit_receipts.erase(event)
	return true

func receive_damage(amount: int, category: String = "", event: int = 0, damage_type: String = "physical", critical: bool = false, ultimate: bool = false, source: String = "basic", eligible_damage: int = -1) -> void:
	if amount <= 0 or invulnerable or not is_targetable() or damage_type not in ["physical","magical"]:
		return
	if event == 0: event = CombatRules.next_event()
	if event < 0 or _damage_events.has(event): return
	_damage_events[event] = true
	if _proficiency_budget < 0: _proficiency_budget = health.maximum
	if mark_left > 0 and mark_category == category:
		amount = ceili(amount*(1.0+mark_bonus))
		if eligible_damage >= 0: eligible_damage = ceili(eligible_damage*(1.0+mark_bonus))
	var before := health.current
	var effective := mini(amount,before)
	var credit := mini(effective,_proficiency_budget)
	_proficiency_budget -= credit # Healing never replenishes a life's XP budget.
	# Emit before lethal callbacks so the defeat save includes this last hit.
	if credit > 0 and ArsenalRules.CATEGORIES.has(category):
		_hit_receipts[event] = [category,credit]
		_receipt_details[event] = {"ultimate":ultimate,"source":source,"critical":critical,"charge":0 if ultimate else mini(credit,amount if eligible_damage < 0 else eligible_damage)}
		weapon_hit.emit(category,credit,event)
		_hit_receipts.erase(event)
		_receipt_details.erase(event)
	health.damage(amount)
	view.show_damage(before - health.current,critical)

func _on_died() -> void:
	remove_from_group("damageable_enemies")
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	view.play_defeat()
	defeated.emit(kind)
	get_tree().create_timer(1.0 if kind >= 5 else 0.22).timeout.connect(queue_free)


func hit_details(event: int) -> Dictionary:
	return _receipt_details.get(event,{}).duplicate()

func apply_control(duration: float) -> void:
	# Guardians retain their approved telegraphs and are immune to interruption.
	if kind == 4 or not is_targetable(): return
	control_left = maxf(control_left,minf(1.0,duration))

func apply_mark(category: String, bonus: float, duration: float) -> void:
	if not is_targetable(): return
	mark_category = category
	mark_bonus = clampf(bonus,0,0.25)
	mark_left = minf(duration,5.0)
