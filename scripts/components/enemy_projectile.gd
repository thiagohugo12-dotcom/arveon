class_name EnemyProjectile
extends Area2D

var direction := Vector2.RIGHT
var speed := 240.0
var damage := 6
var lifetime := 2.0
var target: PlayerActor

func setup(origin: Vector2, travel_direction: Vector2, hit_damage: int, player: PlayerActor) -> void:
	global_position = origin
	direction = travel_direction.normalized()
	damage = hit_damage
	target = player

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	add_child(shape)
	queue_redraw()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if SafeCamp.contains(global_position):
		queue_free()
		return
	if is_instance_valid(target) and target.health.is_alive() and global_position.distance_to(target.global_position) <= 19.0:
		target.receive_damage(damage)
		queue_free()
	elif lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	draw_rect(Rect2(-7, -2, 14, 4), Color("#e9d584"))
	draw_rect(Rect2(-5, -1, 9, 2), Color("#fff1a8"))
