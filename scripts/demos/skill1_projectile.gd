extends BowProjectile
## The original projectile owns physical origin, steering, budget, walls and damage.
const STAFF_DATA := preload("res://scripts/demos/staff_pose_data.gd")
func setup(player: PlayerActor,selected: Node2D,spec: Dictionary,bounds: Rect2) -> void:
	super.setup(player,selected,spec,bounds)
	if category == "cajado": visual_start = STAFF_DATA.muzzle(BowActorView.direction_row(direction))
	if preload("res://scripts/demos/skill1_catalogue.gd").CONFIGS[category].get("body",false):
		visual_start = preload("res://scripts/demos/skill1_body_pose.gd").muzzle(category,BowActorView.direction_row(direction))
		visual_direction = (selected.global_position+visual_end-(player.global_position+visual_start)).normalized()
func draw_orb() -> void:
	var point := (global_position+visual_offset()).round()
	draw_set_transform(to_local(point),-rotation)
	draw_rect(Rect2((-direction*18).round()-Vector2.ONE,Vector2(3,3)),Color("#65c7b144"))
	draw_rect(Rect2((-direction*12).round()-Vector2(2,1),Vector2(4,3)),Color("#a9e4c288"))
	draw_rect(Rect2(-8,-5,16,10),Color("#65c7b133"))
	draw_rect(Rect2(-5,-8,10,16),Color("#65c7b133"))
	draw_rect(Rect2(-7,-4,14,8),Color("#295f55"))
	draw_rect(Rect2(-4,-7,8,14),Color("#295f55"))
	draw_rect(Rect2(-5,-3,10,6),Color("#65c7b1"))
	draw_rect(Rect2(-3,-5,6,10),Color("#65c7b1"))
	draw_rect(Rect2(-3,-3,6,6),Color("#eff9d5"))
	var drift := int((start_budget-distance_left)/12)%3
	for sign_value in [-1,1]:
		var mote: Vector2 = (direction.orthogonal()*sign_value*(8+drift)-direction*4).round()
		draw_rect(Rect2(mote,Vector2(2,1)),Color("#a9e4c2"))
	draw_set_transform(Vector2.ZERO)
func _draw() -> void:
	if category == "cajado":
		draw_orb()
		return
	var offset := visual_offset().rotated(-rotation)
	draw_set_transform(offset.round(),visual_direction.angle()-rotation)
	draw_rect(Rect2(-28,-1,10,2),Color("#f4dc9a55"))
	draw_rect(Rect2(-18,-1,7,2),Color("#fff0b999"))
	draw_rect(Rect2(-10,-2,22,4),Color("#42514b"))
	draw_rect(Rect2(-10,-1,22,2),Color("#fff0b9"))
	draw_rect(Rect2(9,-3,5,6),Color("#42514b"))
	draw_rect(Rect2(10,-2,4,4),Color("#edf4d5"))
	draw_rect(Rect2(-10,-4,4,8),Color("#76bfb0"))
	draw_rect(Rect2(-9,-2,3,4),Color("#fff0b9"))
	draw_set_transform(Vector2.ZERO)
