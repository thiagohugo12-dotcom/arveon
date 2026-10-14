class_name BowProjectile
extends PlayerProjectile
## Basic bow drawing offset. The original projectile owns all physics and damage.
const VIEW := preload("res://scripts/presentation/bow_actor_view.gd")
var visual_start := Vector2.ZERO
var visual_end := Vector2(0,-27)
var visual_direction := Vector2.RIGHT
var start_distance := 1.0
var start_budget := 300.0

func setup(player: PlayerActor, selected: Node2D, specification: Dictionary, bounds: Rect2) -> void:
	super.setup(player,selected,specification,bounds)
	visual_start = VIEW.MUZZLES[VIEW.direction_row(direction)]
	visual_direction = (selected.global_position+visual_end-(player.global_position+visual_start)).normalized()
	start_distance = player.global_position.distance_to(selected.global_position)
	start_budget = distance_left
	queue_redraw()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	queue_redraw()

func visual_offset() -> Vector2:
	return visual_start.lerp(visual_end,clampf((start_budget-distance_left)/maxf(1,start_distance),0,1))

func _draw() -> void:
	var offset := visual_offset().rotated(-rotation)
	draw_set_transform(offset.round(),visual_direction.angle()-rotation)
	draw_rect(Rect2(-15,-1,5,2),Color("#e5d4a570"))
	draw_rect(Rect2(-8,-1,13,2),Color("#b18b56"))
	draw_rect(Rect2(4,-2,4,4),Color("#d6dfd9"))
	draw_rect(Rect2(-8,-3,3,6),Color("#81bda6"))
	draw_set_transform(Vector2.ZERO)
