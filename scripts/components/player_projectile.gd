class_name PlayerProjectile
extends Node2D

const MAX_ACTIVE := 4
var shooter: PlayerActor
var target: Node2D
var direction := Vector2.RIGHT
var speed := 440.0
var damage := 12
var distance_left := 300.0
var kind := "flecha"
var category := ""
var damage_type := "physical"
var critical := false
var event := 0
var spent := false
var arena_bounds := Rect2()

func setup(player: PlayerActor, selected: Node2D, specification: Dictionary, bounds: Rect2) -> void:
	shooter = player
	target = selected
	global_position = player.global_position
	direction = global_position.direction_to(selected.global_position)
	speed = specification.speed
	damage = specification.damage
	distance_left = specification.reach
	kind = specification.kind
	category = specification.get("category","")
	damage_type = specification.get("damage_type","physical")
	critical = specification.get("critical",false)
	event = specification.get("event",0)
	if event == 0: event = CombatRules.next_event()
	arena_bounds = bounds
	rotation = direction.angle()
	queue_redraw()

func _ready() -> void:
	add_to_group("player_projectiles")

func finish() -> void:
	spent = true
	remove_from_group("player_projectiles")
	set_physics_process(false)
	queue_free()

func _physics_process(delta: float) -> void:
	if spent:
		return
	if not is_instance_valid(shooter) or not shooter.health.is_alive():
		finish()
		return
	if shooter.input_driver != null and shooter.input_driver.blocked:
		return # Freeze both movement and budget during any modal.
	if kind == "orbe" and is_instance_valid(target) and target.is_targetable():
		# Limited steering; a lost/dead target is never replaced by a new enemy.
		var desired := global_position.direction_to(target.global_position)
		direction = direction.slerp(desired, minf(1.0, delta * 3.0)).normalized()
	var distance := minf(distance_left, speed * maxf(0.0, delta))
	var before := global_position
	var after := before + direction * distance
	var query := PhysicsRayQueryParameters2D.create(before, after, 1)
	var wall := get_world_2d().direct_space_state.intersect_ray(query)
	if not wall.is_empty():
		after = wall.position
	var victim: EnemyActor = null
	var nearest := INF
	for actor in get_tree().get_nodes_in_group("damageable_enemies"):
		if not actor is EnemyActor or not actor.is_targetable():
			continue
		var center: Vector2 = actor.global_position
		var point := Geometry2D.get_closest_point_to_segment(center, before, after)
		var radius := 26.0 if actor.kind == 4 else 14.0
		if center.distance_squared_to(point) > radius * radius:
			continue
		# A large body radius must never bridge a blocking trunk or wall.
		var visibility := PhysicsRayQueryParameters2D.create(before, center, 1)
		if not get_world_2d().direct_space_state.intersect_ray(visibility).is_empty():
			continue
		var along := before.distance_squared_to(point)
		if along < nearest:
			nearest = along
			victim = actor
	if victim != null:
		finish() # Mark before callbacks: exactly one victim per shot.
		victim.receive_damage(damage,category,event,damage_type,critical)
		return
	global_position = after
	distance_left -= distance
	rotation = direction.angle()
	if not wall.is_empty() or distance_left <= 0.0 or SafeCamp.in_clearance(after) or (arena_bounds.has_area() and not arena_bounds.has_point(after)):
		finish()

func _draw() -> void:
	if kind == "flecha":
		draw_rect(Rect2(-8,-1,13,2),Color("#b18b56"))
		draw_rect(Rect2(4,-2,4,4),Color("#d6dfd9"))
		draw_rect(Rect2(-8,-3,3,6),Color("#81bda6"))
	else:
		draw_rect(Rect2(-5,-3,10,6),Color("#487b67"))
		draw_rect(Rect2(-3,-5,6,10),Color("#8fdba3"))
		draw_rect(Rect2(-2,-2,4,4),Color("#edf4be"))
