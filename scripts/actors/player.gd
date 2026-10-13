class_name PlayerActor
extends CharacterBody2D

signal skill_used(index: int)

@export var stats: ActorData
@onready var health: Health = $Health
@onready var dash: DashMotor = $DashMotor
@onready var attack: AutoAttack = $AutoAttack
@onready var view: ActorView = $View
var input_driver: InputDriver
var progress: GameProgress
var class_combat := ClassCombat.new()
var last_direction := Vector2.DOWN
var skill_cooldowns: Array[float] = [0.0, 0.0, 0.0]
var skill_ranks: Array[int] = [1, 1, 1]
var cooldown_factor := 1.0
var spirit := 0
var armor := 0
var resistance := 0.0
var physical_damage := 12
var special_bonus := 1.0
var charge_event := 0
var charge_build: Dictionary = {}
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
	if progress != null:
		progress.abilities.tick(delta,progress.active_category())
		class_combat.tick(delta)
		_sync_skill_cooldowns()
	fury_left = class_combat.fury_left
	attack.damage_scale = 1.0
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

	view.set_moving(velocity.length_squared() > 1.0)
	attack.tick(delta, self)

func receive_damage(amount: int, damage_type: String = "physical") -> void:
	if SafeCamp.in_clearance(global_position) or not health.is_alive() or amount <= 0:
		return
	var reduced := RPGRules.received_damage(amount,damage_type,armor,resistance)
	reduced = class_combat.receive(reduced) if progress != null else reduced
	var before := health.current
	health.damage(reduced)
	view.show_damage(before - health.current)

func apply_progression(value: GameProgress, initial: bool = false) -> void:
	progress = value
	class_combat.bind(self,progress)
	_sync_skill_cooldowns()
	var values := progress.combat_stats()
	stats.max_hp = int(values.hp)
	stats.move_speed = float(values.speed)
	attack.weapon.damage = int(values.damage)
	stats.dash_speed = 620.0
	physical_damage = int(values.physical)
	resistance = float(values.resistance)
	special_bonus = 1.0+float(values.automatic)+float(values.special)
	attack.damage_base = float(values[values.damage_type])
	attack.basic_bonus = 1.0+float(values.automatic)+float(values.basic)
	attack.critical_chance = float(values.critical_chance)
	attack.critical_multiplier = float(values.critical_multiplier)
	attack.damage_type = values.damage_type
	var configuration := ArsenalRules.profile(progress.equipped.Arma)
	attack.weapon.category = progress.active_category()
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
	if index < 0 or index >= 3 or progress == null or input_driver == null or input_driver.blocked or not health.is_alive() or SafeCamp.in_clearance(global_position): return false
	var used := class_combat.use(index)
	_sync_skill_cooldowns()
	return used

func _sync_skill_cooldowns() -> void:
	if progress == null: return
	var category := progress.active_category()
	if category.is_empty():
		skill_cooldowns = [0.0,0.0,0.0]
		return
	skill_cooldowns[0] = float(progress.abilities.skill1_cooldowns[category])
	for i in range(1,3):
		var id: String = progress.abilities.loadouts[category].skills[i-1]
		skill_cooldowns[i] = float(progress.abilities.cooldowns[category].get(id,0.0))

func skill_ready(index: int) -> bool:
	if progress == null or progress.active_category().is_empty(): return false
	if index == 0: return skill_cooldowns[0] <= 0
	var category := progress.active_category()
	var id: String = progress.abilities.loadouts[category].skills[index-1]
	if id.is_empty(): return false
	if id == AbilityRules.CATEGORIES[category].ultimate.id:
		return int(progress.abilities.charge[category]) == 100 and (progress.abilities.global_ultimate_cooldown == 0 or progress.abilities.last_ultimate_category == category)
	return skill_cooldowns[index] <= 0

func _on_attack(target: Node2D) -> void:
	# Snapshot the selected target, independently of movement/dash facing.
	view.play_attack(target.global_position - global_position)

func _on_died() -> void:
	charge_left = 0.0
	fury_left = 0.0
	class_combat.clear_effects()
	if progress != null: progress.abilities.death_reset()
	_sync_skill_cooldowns()
	charge_hits.clear()
	velocity = Vector2.ZERO
	view.set_moving(false)
	if input_driver != null:
		input_driver.reset()
