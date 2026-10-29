extends Node2D
## Reuse approved drawing classes without their groups/physics/setup/combat events.
class SpecialDrawing extends "res://scripts/demos/skill1_projectile.gd":
 func _ready() -> void: set_physics_process(false)
class ArrowDrawing extends BowProjectile:
 func _ready() -> void: set_physics_process(false)
class OrbDrawing extends StaffProjectile:
 func _ready() -> void: set_physics_process(false)
var drawing: BowProjectile
var visual_origin := Vector2.ZERO
var visual_target := Vector2.ZERO
func configure_visual(at: Vector2,to: Vector2,weapon: String,special: bool=true) -> void:
 visual_origin=at;visual_target=to
 drawing=SpecialDrawing.new() if special else OrbDrawing.new() if weapon=="cajado" else ArrowDrawing.new()
 add_child(drawing)
 drawing.category=weapon
 drawing.direction=at.direction_to(to);drawing.rotation=drawing.direction.angle()
 drawing.visual_start=preload("res://scripts/demos/staff_pose_data.gd").muzzle(BowActorView.direction_row(drawing.direction)) if weapon=="cajado" else BowActorView.MUZZLES[BowActorView.direction_row(drawing.direction)]
 if special and preload("res://scripts/demos/skill1_catalogue.gd").CONFIGS[weapon].get("body",false):drawing.visual_start=preload("res://scripts/demos/skill1_body_pose.gd").muzzle(weapon,BowActorView.direction_row(drawing.direction))
 drawing.visual_end=Vector2(0,-27)
 drawing.visual_direction=(to+drawing.visual_end-at-drawing.visual_start).normalized()
 drawing.start_distance=at.distance_to(to);drawing.start_budget=drawing.start_distance;drawing.distance_left=drawing.start_distance
 drawing.speed=260 if weapon=="cajado" else 440
 drawing.global_position=at
 drawing.z_index=roundi(at.y)+100
 drawing.queue_redraw()
func advance_visual(delta: float) -> bool:
 drawing.distance_left=maxf(0,drawing.distance_left-drawing.speed*delta)
 drawing.global_position=visual_origin.lerp(visual_target,1-drawing.distance_left/maxf(1,drawing.start_distance))
 drawing.queue_redraw()
 return drawing.distance_left<=0
