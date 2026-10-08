class_name EnemyActor
extends CharacterBody2D

signal defeated(kind: int)
signal projectile_requested(origin: Vector2, direction: Vector2, damage: int)

@export var stats: ActorData
@export_range(0, 2, 1) var kind: int = 0  # 0 Javali, 1 Aranha, 2 Mandacaru
@onready var health: Health = $Health
@onready var view: ActorView = $View
var target: PlayerActor
var contact_left := 0.0
var special_left := 0.0
var charge_windup := 0.0
var charge_left := 0.0
var charge_direction := Vector2.ZERO
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

func _ready() -> void:
	home_position = global_position
	view.appearance = kind + 1
	view.queue_redraw()
	add_to_group("damageable_enemies")
	health.changed.connect(view.set_health)
	health.died.connect(_on_died)
	health.initialize(stats.max_hp)

func update_activity(player_position: Vector2) -> void:
	if not health.is_alive():
		return
	var distance_squared := global_position.distance_squared_to(player_position)
	if awake and distance_squared > SLEEP_ENTER * SLEEP_ENTER:
		awake = false
		set_physics_process(false)
		view.set_moving(false)
		view.set_warning(false)
	elif not awake and distance_squared < SLEEP_EXIT * SLEEP_EXIT:
		awake = true
		set_physics_process(true)

func _physics_process(delta: float) -> void:
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
	if chasing:
		if distance > AGGRO_EXIT or home_distance > MAX_CHASE_FROM_HOME or SafeCamp.in_clearance(target.global_position):
			chasing = false
			charge_windup = 0.0
			charge_left = 0.0
	else:
		if distance <= AGGRO_ENTER and home_distance <= TERRITORY_RADIUS and not SafeCamp.in_clearance(target.global_position):
			chasing = true
	if not chasing:
		_return_home()
		return
	view.set_facing(offset)
	match kind:
		0: _boar_behavior(delta, offset, distance)
		1: _spider_behavior(offset, distance)
		2: _cactus_behavior(offset, distance)
	var before := global_position
	move_and_slide()
	if SafeCamp.in_clearance(global_position) or global_position.distance_to(home_position) > MAX_CHASE_FROM_HOME:
		global_position = before
		velocity = Vector2.ZERO
		chasing = false
	view.set_moving(velocity.length_squared() > 1.0)
	if kind != 2:
		_try_contact(distance)

func _return_home() -> void:
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

func _spider_behavior(offset: Vector2, distance: float) -> void:
	view.set_warning(false)
	var direction := offset.normalized()
	if distance < 74.0:
		velocity = -direction * stats.move_speed * 0.8
	elif distance > 132.0:
		velocity = direction * stats.move_speed
	else:
		# Strafe around the player instead of stacking on top of them.
		var tangent := Vector2(-direction.y, direction.x) * strafe_sign
		velocity = tangent * stats.move_speed * 0.62
		if special_left == 0.0:
			strafe_sign *= -1.0
			special_left = 1.25

func _cactus_behavior(offset: Vector2, distance: float) -> void:
	if distance < 118.0:
		velocity = -offset.normalized() * stats.move_speed * 0.72
	elif distance > 205.0:
		velocity = offset.normalized() * stats.move_speed * 0.65
	else:
		velocity = Vector2.ZERO
	if distance <= 245.0 and special_left == 0.0:
		view.set_warning(true)
		special_left = 1.65
		get_tree().create_timer(0.34).timeout.connect(_fire_cactus_spine)
	elif special_left < 1.28:
		view.set_warning(false)

func _fire_cactus_spine() -> void:
	if not is_targetable() or not chasing or not is_instance_valid(target) or not target.health.is_alive():
		view.set_warning(false)
		return
	if SafeCamp.in_clearance(target.global_position) or target.global_position.distance_to(home_position) > MAX_CHASE_FROM_HOME:
		view.set_warning(false)
		return
	var direction := global_position.direction_to(target.global_position)
	projectile_requested.emit(global_position, direction, max(4, stats.contact_damage - 2))
	view.set_warning(false)
	view.play_attack()

func _try_contact(distance: float) -> void:
	if distance > stats.contact_range or contact_left > 0.0:
		return
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
	if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		target.receive_damage(stats.contact_damage)
		contact_left = stats.contact_interval
		view.play_attack()

func is_targetable() -> bool:
	return health.is_alive() and awake and not SafeCamp.in_clearance(global_position) and not is_queued_for_deletion()

func receive_damage(amount: int) -> void:
	if not is_targetable():
		return
	health.damage(amount)
	view.show_damage(amount)

func _on_died() -> void:
	remove_from_group("damageable_enemies")
	defeated.emit(kind)
	queue_free()
