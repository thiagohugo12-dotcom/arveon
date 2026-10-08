class_name PlayerActor
extends CharacterBody2D

@export var stats: ActorData
@onready var health: Health = $Health
@onready var dash: DashMotor = $DashMotor
@onready var attack: AutoAttack = $AutoAttack
@onready var view: ActorView = $View
var input_driver: InputDriver
var last_direction := Vector2.DOWN
var progression: GameProgress
var base_max_hp := 0
var base_move_speed := 0.0
var base_dash_speed := 0.0
var base_weapon_damage := 0
var base_weapon_interval := 0.0

func _ready() -> void:
	health.changed.connect(view.set_health)
	health.died.connect(_on_died)
	attack.attacked.connect(_on_attack)
	health.initialize(stats.max_hp)

func apply_progression(progress: GameProgress) -> void:
	if base_max_hp == 0:
		stats = stats.duplicate() as ActorData
		attack.weapon = attack.weapon.duplicate() as WeaponData
		base_max_hp = stats.max_hp
		base_move_speed = stats.move_speed
		base_dash_speed = stats.dash_speed
		base_weapon_damage = attack.weapon.damage
		base_weapon_interval = attack.weapon.interval
	progression = progress
	var vitality := int(progress.attributes.get("Vitalidade", 0))
	var strength := int(progress.attributes.get("Força", 0))
	var agility := int(progress.attributes.get("Agilidade", 0))
	var spirit := int(progress.attributes.get("Espírito", 0))
	var old_max := health.maximum
	stats.max_hp = base_max_hp + vitality * 8 + spirit * 2
	stats.move_speed = base_move_speed + agility * 2.0
	stats.dash_speed = base_dash_speed + agility * 3.0
	attack.weapon.damage = base_weapon_damage + strength * 2 + spirit
	attack.weapon.interval = maxf(0.25, base_weapon_interval * (1.0 - minf(0.25, agility * 0.01)))
	if stats.max_hp != old_max:
		health.maximum = stats.max_hp
		health.current = mini(health.maximum, health.current + maxi(0, stats.max_hp - old_max))
		health.changed.emit(health.current, health.maximum)

func _physics_process(delta: float) -> void:
	if not health.is_alive() or input_driver == null:
		velocity = Vector2.ZERO
		view.set_moving(false)
		return
	if input_driver.blocked:
		dash.time_left = 0.0
		velocity = Vector2.ZERO
		view.set_moving(false)
		return
	dash.tick(delta)
	var movement := input_driver.movement()
	if not movement.is_zero_approx():
		last_direction = movement.normalized()
		view.set_facing(last_direction)
	if input_driver.consume_dash():
		dash.request(movement, last_direction, stats)
	velocity = dash.direction * stats.dash_speed if dash.active() else movement * stats.move_speed
	move_and_slide()
	view.set_moving(velocity.length_squared() > 1.0)
	attack.tick(delta, self)

func receive_damage(amount: int) -> void:
	if SafeCamp.in_clearance(global_position) or not health.is_alive() or amount <= 0:
		return
	health.damage(amount)
	view.show_damage(amount)

func _on_attack(_target: Node2D) -> void:
	view.play_attack()

func _on_died() -> void:
	velocity = Vector2.ZERO
	view.set_moving(false)
	if input_driver != null:
		input_driver.reset()
