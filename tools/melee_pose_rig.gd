extends "res://tools/staff_pose_rig.gd"
## Keep the approved torso rasterizer, head layering and compact hand size.
const MELEE := preload("res://scripts/demos/melee_pose_data.gd")
var weapon_kind := 0
func polygon_at(origin: Vector2,axis: Vector2,points: Array,color: Color) -> void:
	var vertices := PackedVector2Array()
	for point: Vector2 in points: vertices.append((origin+axis*point.x+axis.orthogonal()*point.y).round())
	draw_colored_polygon(vertices,color)
func bow_parts() -> void:
	var hand := MELEE.hand(weapon_kind,row,frame)
	var axis := MELEE.axis(weapon_kind,row,frame)
	var shoulder: Vector2 = MELEE.SHOULDERS[row][0]
	var free_shoulder: Vector2 = MELEE.SHOULDERS[row][1]
	var free_hand := free_shoulder+Vector2(0,5)
	if weapon_kind == 0:
		var head := hand+axis*13
		line(hand-axis*4,head,Color("#382b25"),3)
		line(hand-axis*3,head,Color("#ba884b"),1)
		polygon_at(head,axis,[Vector2(-2,-3),Vector2(2,-3),Vector2(2,1),Vector2(5,2),Vector2(6,8),Vector2(-6,8),Vector2(-5,2),Vector2(-2,1)],Color("#343d42"))
		polygon_at(head,axis,[Vector2(-1,-2),Vector2(1,-2),Vector2(1,2),Vector2(4,3),Vector2(4,6),Vector2(-4,6),Vector2(-4,3),Vector2(-1,2)],Color("#87959a"))
		line(head-axis*5+axis.orthogonal()*7,head+axis*5+axis.orthogonal()*7,Color("#e4e0bd"),1)
		# Compact support hand follows the near part of the shaft, never a long arm.
		free_hand = free_shoulder.lerp(hand-axis*3,0.45).round()
		if frame >= 2 and frame <= 4:
			for i in range(3):
				var mark := hand+axis.rotated(-0.18*(i+1))*22
				draw_rect(Rect2(mark.round(),Vector2(2,2)),Color("#efd69b"))
	else:
		var length := 14 if row < 2 else 22
		var tip := hand+axis*length
		line(hand-axis*9,tip,Color("#382b25"),3)
		line(hand-axis*8,tip,Color("#ba884b"),1)
		polygon_at(tip,axis,[Vector2(-2,-3),Vector2(6,0),Vector2(-2,3),Vector2(0,0)],Color("#343d42"))
		polygon_at(tip,axis,[Vector2(-1,-1),Vector2(4,0),Vector2(-1,2)],Color("#d9dfcf"))
		line(tip-axis*3-axis.orthogonal(),tip-axis*3+axis.orthogonal(),Color("#4c9c8c"),2)
		free_hand = free_shoulder.lerp(hand-axis*6,0.5).round()
		if frame == 3 or frame == 4:
			for i in range(3):
				draw_rect(Rect2((tip-axis*(5+i*3)).round()+axis.orthogonal()*3,Vector2.ONE),Color("#e4e0bd"))
	arm(shoulder,(shoulder+hand)*0.5+Vector2(0,1),hand)
	arm(free_shoulder,(free_shoulder+free_hand)*0.5,free_hand)
