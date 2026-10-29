extends "res://tools/skill1_rig.gd"
## Source-grid rasterizer. Every hair/face/shirt pixel comes from PEOPLE.
var technique_id := "estocada_precisa"
const TRAVEL := {"estocada_precisa":[-1,-2,0,3,2,0],"danca_laminas":[-1,-2,0,2,1,0],"guarda_reativa":[0,-1,-1,-2,1,0]}
const CROUCH := {"estocada_precisa":[0,1,1,0,1,0],"danca_laminas":[0,2,1,0,1,0],"guarda_reativa":[0,1,1,2,1,0]}
func source_point(p: Vector2) -> Vector2:
	var weight := clampf((32-p.y)/24.0,0,0.65)
	var lean: float = TRAVEL[technique_id][frame]
	return (p+AIM[row]*lean+Vector2(AIM[row].x*weight*lean,CROUCH[technique_id][frame])).round()
func foot(p: Vector2) -> Vector2:
	var leading := (p.x >= 16) if row in [0,3] else (p.x < 16)
	var step: float = [0,-1,0,2,1,0][frame] if leading else 0
	return (p+AIM[row]*step).round()
func pixel(x: int,y: int,legs: bool=false) -> void:
	var p := foot(Vector2(x,y)) if legs else source_point(Vector2(x,y))
	draw_texture_rect_region(PEOPLE,Rect2(p,Vector2.ONE),Rect2(x,row*40+y,1,1))
func _draw() -> void:
	draw_set_transform(Vector2(-16,-32))
	for x in [14,19]:
		var hip := source_point(Vector2(x,31))
		var ankle := foot(Vector2(x,37))
		draw_line(hip,ankle,Color("#382b25"),4,false)
		draw_line(hip,ankle,Color("#805330"),2,false)
	for y in range(36,40):
		for x in range(32): pixel(x,y,true)
	if row == 1: bow_parts()
	var holes: Array = [Rect2(7,24,6,8),Rect2(21,24,5,8)] if row < 2 else [Rect2(16 if row == 2 else 11,26,5,6)]
	for y in range(32):
		for x in range(32):
			var removed := false
			for hole: Rect2 in holes: removed = removed or hole.has_point(Vector2(x,y))
			if not removed: pixel(x,y)
	if row != 1: bow_parts()
	# Original head/scarf on top of the articulated shoulders.
	for y in range(27):
		for x in range(32):
			if y < 24 or (x >= 13 and x < 20): pixel(x,y)
	draw_set_transform(Vector2.ZERO)
func bow_parts() -> void:
	var shoulder: Vector2 = preload("res://scripts/demos/melee_pose_data.gd").SHOULDERS[row][0]
	var aim: Vector2 = AIM[row]
	var hand: Vector2
	var axis: Vector2
	if technique_id == "estocada_precisa":
		hand = shoulder+aim*[-1,-3,0,8,5,1][frame]+Vector2(0,3)
		axis = aim.rotated([-0.55,-0.30,-0.08,0,0.05,0.60][frame])
	elif technique_id == "danca_laminas":
		axis = aim.rotated([-1.5,-1.9,-0.7,0.3,1.2,0.8][frame]*(-1 if row == 2 else 1))
		hand = shoulder+axis*5+Vector2(0,2)
	else:
		axis = aim.rotated([-0.6,-0.9,-0.9,-1.1,0.4,0.7][frame])
		hand = shoulder+aim*[2,1,1,-1,5,2][frame]+Vector2(0,2)
	arm(shoulder,(shoulder+hand)*0.5,hand)
	var other: Vector2 = preload("res://scripts/demos/melee_pose_data.gd").SHOULDERS[row][1]
	var free_hand := other+Vector2(0,5)-aim*(2 if frame in [1,3] else 0)
	arm(other,other.lerp(free_hand,0.5),free_hand)
	# Same approved inventory sword and compact grip, rasterized to source pixels.
	var transform := Transform2D(axis.angle()+PI/4,source_point(hand)).scaled_local(Vector2(0.36,0.36))
	draw_set_transform_matrix(Transform2D(0,Vector2(-16,-32))*transform)
	draw_texture_rect_region(DiaryArt.ITEMS,Rect2(-Vector2(23,51),Vector2(64,64)),Rect2(0,0,64,64))
	draw_set_transform(Vector2(-16,-32))
	pixel_mark(Rect2(hand-Vector2.ONE,Vector2(3,3)),Color("#f7d39b"))
