class_name EnemyProjectile
extends Area2D

var arena_bounds := Rect2()
var direction := Vector2.RIGHT
var speed := 240.0
var damage := 6
var lifetime := 2.0
var target: PlayerActor
var spent := false
var visual_offset := Vector2.ZERO # Review-only height; collision remains on ground.

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
	if spent: return
	var start := global_position
	var end := start+direction*speed*maxf(0,delta)
	var wall := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(start,end,1))
	if not wall.is_empty(): end = wall.position
	global_position = end
	lifetime -= delta
	if SafeCamp.in_clearance(global_position) or (arena_bounds.has_area() and not arena_bounds.has_point(global_position)):
		queue_free()
		return
	if is_instance_valid(target) and target.health.is_alive() and Geometry2D.get_closest_point_to_segment(target.global_position,start,end).distance_to(target.global_position) <= 19.0:
		spent = true
		target.receive_damage(damage)
		queue_free()
	elif lifetime <= 0.0 or not wall.is_empty():
		spent = true
		queue_free()

func _draw() -> void:
	draw_set_transform(visual_offset,direction.angle())
	draw_rect(Rect2(-7, -2, 14, 4), Color("#e9d584"))
	draw_rect(Rect2(-5, -1, 9, 2), Color("#fff1a8"))
