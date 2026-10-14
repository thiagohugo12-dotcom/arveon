extends "res://tools/skill1_rig.gd"
const STAFF_DATA := preload("res://scripts/demos/staff_pose_data.gd")
func bow_parts() -> void:
	var pose: int = [0,1,3,4,4,5,6,7][frame]
	var hand: Vector2 = STAFF_DATA.HANDS[row][pose]
	var tip: Vector2 = hand+STAFF_DATA.TIPS[row][pose]
	var tail: Vector2 = hand-STAFF_DATA.TIPS[row][pose].normalized()*2
	line(tail,tip,Color("#382b25"),3)
	line(tail,tip,Color("#ba884b"),1)
	var radius := 3 if frame <= 2 else 2
	draw_rect(Rect2(tip.round()-Vector2.ONE*radius,Vector2.ONE*(radius*2+1)),Color("#295f55"))
	draw_rect(Rect2(tip.round()-Vector2(2,2),Vector2(5,5)),Color("#65c7b1"))
	draw_rect(Rect2(tip.round()-Vector2.ONE,Vector2(3,3)),Color("#eff9d5"))
	if frame <= 4:
		for offset: Vector2 in [Vector2(-5,-2),Vector2(4,-4),Vector2(-3,5),Vector2(5,3)]:
			draw_rect(Rect2(tip.round()+offset,Vector2.ONE),Color("#a9e4c2"))
	var shoulder: Vector2 = STAFF_DATA.SHOULDERS[row][0]
	var other: Vector2 = STAFF_DATA.SHOULDERS[row][1]
	var support: Vector2 = STAFF_DATA.FREE_HANDS[row][pose]
	arm(shoulder,(shoulder+hand)*0.5+Vector2(0,1),hand)
	arm(other,(other+support)*0.5+Vector2(-1,0),support)
