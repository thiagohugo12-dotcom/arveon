extends ActorView
## Build-time rig only. Original atlases and ActorView remain unchanged.
## All measurements below are in the approved 32x40 source-pixel grid.
const ARM := [Rect2(21,24,4,7), Rect2(9,24,4,7), Rect2(16,26,5,6), Rect2(11,26,5,6)]
const SHOULDER := [Vector2(22,24), Vector2(11,24), Vector2(18,26), Vector2(13,26)]
const GRIP := [Vector2(22,29), Vector2(10,29), Vector2(18,30), Vector2(13,30)]
const ARM_ANGLES := [Vector4(-1.4,-0.65,0.45,0), Vector4(1.4,0.65,-0.45,0), Vector4(-0.8,1.45,0.85,0), Vector4(0.8,-1.45,-0.85,0)]
const DIRECTIONS := [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
const SWORD_GRIP := Vector2(23,51)
var sword_row := 0
var pose_override := 0
var bake_release := 1.0

func phase() -> int:
	return pose_override

func _draw() -> void:
	var key := phase()
	if key < 0:
		super._draw()
		return
	# Upper body only; runtime supplies the approved legs and planted shadow.
	var row := sword_row
	var frame := anim_frame if walking or settle_left > 0.0 else 0
	var source_origin := Vector2(frame*32,row*40)
	var tint := Color(2.0,1.75,1.35) if flash_left > 0.0 else Color.WHITE
	var lean := Vector2.ZERO
	if key == 0: lean = -DIRECTIONS[row]
	elif key < 3: lean = DIRECTIONS[row]
	# Integer translations, feet never move with the upper-body rig.

	var rotation: float = ARM_ANGLES[row][key]

	if key == 3:
		var release := bake_release
		rotation = lerpf(ARM_ANGLES[row][2],0.0,release)
		lean = DIRECTIONS[row] if release < 0.35 else Vector2.ZERO
	var blade_offset := [-1.45,-0.05,0.9,1.2][key] as float
	if key == 3:
		blade_offset = lerpf(0.9,1.2,bake_release)
	var blade_angle: float = DIRECTIONS[row].angle()+blade_offset
	var shoulder: Vector2 = SHOULDER[row]+lean
	var hand: Vector2 = (shoulder+(GRIP[row]-SHOULDER[row]).rotated(rotation)).round()
	# Canvas is converted once to the original source-pixel grid (2x in gameplay).
	draw_set_transform(Vector2(-32,-64),0,Vector2(2,2))
	if row == 1: _draw_arm_weapon(source_origin,row,shoulder,hand,rotation,blade_angle,tint)
	# Reuse the exact approved walking legs, independently of the torso posture.
	var arm: Rect2 = ARM[row]
	_region(source_origin,Rect2(0,0,32,arm.position.y),lean,tint)
	_region(source_origin,Rect2(0,arm.position.y,arm.position.x,arm.size.y),lean,tint)
	_region(source_origin,Rect2(arm.end.x,arm.position.y,32-arm.end.x,arm.size.y),lean,tint)
	_region(source_origin,Rect2(0,arm.end.y,32,32-arm.end.y),lean,tint)
	# Profile arms overlap the shirt; reuse a shirt strip under the lifted arm.
	if row >= 2:
		draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(Vector2(arm.position.x+1,arm.position.y)+lean,Vector2(3,5)),Rect2(source_origin+Vector2(15 if row == 2 else 17,25),Vector2(1,5)),tint)
	if row != 1: _draw_arm_weapon(source_origin,row,shoulder,hand,rotation,blade_angle,tint)
	draw_set_transform(Vector2.ZERO)
	_draw_hit_feedback()

func _region(origin: Vector2, rect: Rect2, shift: Vector2, tint: Color) -> void:
	if rect.size.x <= 0 or rect.size.y <= 0: return
	draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(rect.position+shift,rect.size),Rect2(origin+rect.position,rect.size),tint)

func _draw_arm_weapon(origin: Vector2, row: int, shoulder: Vector2, hand: Vector2, rotation: float, blade_angle: float, tint: Color) -> void:
	var key := phase()
	# Short warm trail, attached to this hand, not a line to a distant target.
	if key == 1 or key == 2:
		for i in range(7):
			var mark: Vector2 = (hand+Vector2.RIGHT.rotated(blade_angle-0.55+i*0.12)*18).round()
			draw_rect(Rect2(mark,Vector2(2,2)),Color("#f5d888") if i < 4 else Color("#fff1c1"))
	var transform := Transform2D(rotation,shoulder)
	draw_set_transform_matrix(Transform2D(0,Vector2(-32,-64)).scaled_local(Vector2(2,2))*transform)
	var arm: Rect2 = ARM[row]
	draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(arm.position-SHOULDER[row],arm.size),Rect2(origin+arm.position,arm.size),tint)
	# Hilt pivot is the approved icon's grip. Rotation/scale apply to both ends.
	var weapon_transform := Transform2D(blade_angle+PI/4,hand).scaled_local(Vector2(0.36,0.36))
	draw_set_transform_matrix(Transform2D(0,Vector2(-32,-64)).scaled_local(Vector2(2,2))*weapon_transform)
	draw_texture_rect_region(DiaryArt.ITEMS,Rect2(-SWORD_GRIP,Vector2(64,64)),Rect2(0,0,64,64),tint)
	# Keep the approved hand over the hilt; otherwise it looks pasted over the arm.
	draw_set_transform_matrix(Transform2D(0,Vector2(-32,-64)).scaled_local(Vector2(2,2))*transform)
	var grip_rect := Rect2(GRIP[row]-Vector2(1,1),Vector2(3,3))
	draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(grip_rect.position-SHOULDER[row],grip_rect.size),Rect2(origin+grip_rect.position,grip_rect.size),tint)
	draw_set_transform(Vector2(-32,-64),0,Vector2(2,2))
