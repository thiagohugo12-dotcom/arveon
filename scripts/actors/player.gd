class_name PlayerActor
extends CharacterBody2D

@export var stats: ActorData
@onready var health: Health = $Health
@onready var dash: DashMotor = $DashMotor
@onready var attack: AutoAttack = $AutoAttack
@onready var view: ActorView = $View
var input_driver: InputDriver
var last_direction := Vector2.DOWN

func _ready() -> void:
	health.changed.connect(view.set_health)
	health.died.connect(_on_died)
	attack.attacked.connect(_on_attack)
	health.initialize(stats.max_hp)

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
	if SafeCamp.in_clearance(global_position):
		return
	health.damage(amount)
	view.flash()

func _on_attack(_target: Node2D) -> void:
	view.play_attack()

func _on_died() -> void:
	velocity = Vector2.ZERO
	view.set_moving(false)
	if input_driver != null:
		input_driver.reset()
