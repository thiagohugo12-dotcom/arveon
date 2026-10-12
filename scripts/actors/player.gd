class_name PlayerActor
extends CharacterBody2D

signal skill_used(index: int)

@export var stats: ActorData
@onready var health: Health = $Health
@onready var dash: DashMotor = $DashMotor
@onready var attack: AutoAttack = $AutoAttack
@onready var view: ActorView = $View
var input_driver: InputDriver
var last_direction := Vector2.DOWN
var skill_cooldowns: Array[float] = [0.0, 0.0, 0.0]
var skill_ranks: Array[int] = [1, 1, 1]
var cooldown_factor := 1.0
var spirit := 0
var armor := 0
var resistance := 0.0
var physical_damage := 12
var fury_left := 0.0
var charge_left := 0.0
var charge_direction := Vector2.DOWN
var charge_hits: Dictionary = {}
var base_max_hp := 100
var base_weapon_damage := 12

func _ready() -> void:
	stats = stats.duplicate() as ActorData
	attack.weapon = attack.weapon.duplicate() as WeaponData
	health.changed.connect(view.set_health)
	health.died.connect(_on_died)
	attack.attacked.connect(_on_attack)
	health.initialize(stats.max_hp)

func _physics_process(delta: float) -> void:
	for i in range(3):
		skill_cooldowns[i] = maxf(0.0, skill_cooldowns[i] - delta)
	fury_left = maxf(0.0, fury_left - delta)
	attack.damage_scale = 1.0 + (0.3 + 0.1 * (skill_ranks[2] - 1) if fury_left > 0.0 else 0.0)
	view.set_fury(fury_left > 0.0)
	if not health.is_alive() or input_driver == null:
		velocity = Vector2.ZERO
		view.set_moving(false)
		return
	if input_driver.blocked:
		dash.time_left = 0.0
		charge_left = 0.0
		charge_hits.clear()
		velocity = Vector2.ZERO
		view.set_moving(false)
		return
	dash.tick(delta)
	var movement := input_driver.movement()
	if not movement.is_zero_approx():
		last_direction = movement.normalized()
		view.set_facing(last_direction)
	if input_driver.consume_dash() and charge_left <= 0.0:
		dash.request(movement, last_direction, stats)
	velocity = charge_direction * 420.0 if charge_left > 0.0 else dash.direction * stats.dash_speed if dash.active() else movement * stats.move_speed
	# Charge respects camp and walls; it never deals damage from the protected side.
	if charge_left > 0.0 and SafeCamp.in_clearance(global_position + velocity * delta):
		charge_left = 0.0
		velocity = Vector2.ZERO
	move_and_slide()
	if charge_left > 0.0:
		_hit_skill(46.0, 1.2 + 0.1 * (skill_ranks[1] - 1), charge_hits)
		charge_left = maxf(0.0, charge_left - delta)
	view.set_moving(velocity.length_squared() > 1.0)
	attack.tick(delta, self)

func receive_damage(amount: int, damage_type: String = "physical") -> void:
	if SafeCamp.in_clearance(global_position) or not health.is_alive() or amount <= 0:
		return
	var fury := 0.25 + 0.05 * (skill_ranks[2] - 1) if fury_left > 0.0 else 0.0
	var reduced := RPGRules.received_damage(amount,damage_type,armor,resistance,fury)
	var before := health.current
	health.damage(reduced)
	view.show_damage(before - health.current)

func apply_progression(progress: GameProgress, initial: bool = false) -> void:
	var values := progress.combat_stats()
	stats.max_hp = int(values.hp)
	stats.move_speed = float(values.speed)
	attack.weapon.damage = int(values.damage)
	stats.dash_speed = 620.0
	physical_damage = int(values.physical)
	resistance = float(values.resistance)
	var configuration := ArsenalRules.profile(progress.equipped.Arma)
	attack.weapon.category = progress.equipped.Arma if ArsenalRules.CATEGORIES.has(progress.equipped.Arma) else "espada"
	attack.weapon.reach = configuration.reach
	attack.weapon.projectile_kind = configuration.projectile
	attack.weapon.projectile_speed = configuration.speed
	attack.weapon.interval = configuration.interval * float(values.basic_interval_factor)
	spirit = int(values.spirit)
	armor = int(values.armor)
	cooldown_factor = float(values.cooldown)
	for i in range(3):
		skill_ranks[i] = progress.skill_rank(i)
	if initial:
		health.initialize(stats.max_hp)
	else:
		# Repeated equip/unequip cannot heal or revive the player.
		health.maximum = stats.max_hp
		health.current = mini(health.current, health.maximum)
		health.changed.emit(health.current, health.maximum)

func use_skill(index: int) -> bool:
	if index < 0 or index >= 3 or input_driver == null or input_driver.blocked or not health.is_alive() or SafeCamp.in_clearance(global_position):
		return false
	if skill_cooldowns[index] > 0.0 or charge_left > 0.0:
		return false
	skill_cooldowns[index] = [5.0, 8.0, 35.0][index] * cooldown_factor
	match index:
		0:
			_hit_skill(90.0, 1.4 + 0.15 * (skill_ranks[0] - 1), {})
			view.play_skill(0)
		1:
			var direction := input_driver.movement()
			charge_direction = last_direction if direction.is_zero_approx() else direction.normalized()
			charge_left = 0.22
			dash.time_left = 0.0
			charge_hits.clear()
			view.set_facing(charge_direction)
			view.play_skill(1)
		2:
			fury_left = 6.0 + skill_ranks[2] - 1
			attack.damage_scale = 1.3 + 0.1 * (skill_ranks[2] - 1)
			view.set_fury(true)
			view.play_skill(2)
	skill_used.emit(index)
	return true

func _hit_skill(radius: float, multiplier: float, hits: Dictionary) -> void:
	if SafeCamp.in_clearance(global_position) or not health.is_alive() or input_driver.blocked:
		return
	for candidate in get_tree().get_nodes_in_group("damageable_enemies"):
		if not is_instance_valid(candidate) or candidate.is_queued_for_deletion() or not candidate.is_targetable():
			continue
		var id: int = candidate.get_instance_id()
		if hits.has(id) or global_position.distance_squared_to(candidate.global_position) > radius * radius:
			continue
		var query := PhysicsRayQueryParameters2D.create(global_position, candidate.global_position, 1)
		if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			continue
		hits[id] = true
		candidate.receive_damage(roundi(physical_damage * multiplier * attack.damage_scale),attack.weapon.category)

func _on_attack(target: Node2D) -> void:
	# Snapshot the selected target, independently of movement/dash facing.
	view.play_attack(target.global_position - global_position)

func _on_died() -> void:
	charge_left = 0.0
	fury_left = 0.0
	charge_hits.clear()
	velocity = Vector2.ZERO
	view.set_moving(false)
	if input_driver != null:
		input_driver.reset()
