class_name EnemyActor
extends CharacterBody2D

signal defeated(kind: int)

@export var stats: ActorData
@export_range(0, 2, 1) var kind: int = 0  # 0 Javali, 1 Aranha, 2 Mandacaru
@onready var health: Health = $Health
@onready var view: ActorView = $View
var target: PlayerActor
var contact_left: float = 0.0

func _ready() -> void:
	view.appearance = kind + 1
	view.queue_redraw()
	add_to_group("damageable_enemies")
	health.changed.connect(view.set_health)
	health.died.connect(_on_died)
	health.initialize(stats.max_hp)

func _physics_process(delta: float) -> void:
	contact_left = maxf(0.0, contact_left - delta)
	velocity = Vector2.ZERO
	if not is_targetable() or not is_instance_valid(target) or not target.health.is_alive():
		view.set_moving(false)
		return
	var offset := target.global_position - global_position
	var distance := offset.length()
	if distance <= stats.detection_range:
		view.set_facing(offset)
		if distance > 28.0:
			velocity = offset.normalized() * stats.move_speed
	move_and_slide()
	view.set_moving(velocity.length_squared() > 1.0)
	if distance <= stats.contact_range and contact_left == 0.0:
		var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
		if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			target.receive_damage(stats.contact_damage)
			contact_left = stats.contact_interval

func is_targetable() -> bool:
	return health.is_alive() and not is_queued_for_deletion()

func receive_damage(amount: int) -> void:
	health.damage(amount)
	view.flash()

func _on_died() -> void:
	remove_from_group("damageable_enemies")
	defeated.emit(kind)
	queue_free()
