class_name StaffProjectile
extends BowProjectile
## Reuse existing physical/homing projectile and shared visual-origin interpolation.
const STAFF_POSES := preload("res://scripts/demos/staff_pose_data.gd")
func setup(player: PlayerActor, selected: Node2D, specification: Dictionary, bounds: Rect2) -> void:
	super.setup(player,selected,specification,bounds)
	visual_start = STAFF_POSES.muzzle(BowActorView.direction_row(direction))
	queue_redraw()
func _draw() -> void:
	# Cancel orb rotation: a fixed pixel shape tracks the physical homing path.
	var world_origin := (global_position+visual_offset()).round()
	draw_set_transform(to_local(world_origin),-rotation)
	draw_rect(Rect2((-direction*14).round()-Vector2.ONE,Vector2(2,2)),Color("#65c7b144"))
	draw_rect(Rect2((-direction*10).round()-Vector2.ONE,Vector2(3,2)),Color("#65c7b188"))
	draw_rect(Rect2(-6,-4,12,8),Color("#65c7b133"))
	draw_rect(Rect2(-4,-6,8,12),Color("#65c7b133"))
	draw_rect(Rect2(-5,-3,10,6),Color("#295f55"))
	draw_rect(Rect2(-3,-5,6,10),Color("#295f55"))
	draw_rect(Rect2(-4,-2,8,4),Color("#65c7b1"))
	draw_rect(Rect2(-2,-4,4,8),Color("#65c7b1"))
	draw_rect(Rect2(-2,-2,4,4),Color("#e3f6be"))
	var side := direction.orthogonal()
	var flicker := 1 if int((start_budget-distance_left)/12)%2 else -1
	for sign_value in [-1,1]:
		var mote: Vector2 = (side*sign_value*7-direction*(3+flicker*sign_value)).round()
		draw_rect(Rect2(mote,Vector2.ONE),Color("#a9e4c2"))
	draw_set_transform(Vector2.ZERO)
