extends "res://tools/skill1_rig.gd"
const MELEE_DATA := preload("res://scripts/demos/melee_pose_data.gd")
func bow_parts() -> void:
	var shoulder: Vector2 = MELEE_DATA.SHOULDERS[row][0]
	var hand: Vector2 = MELEE_DATA.AXE_HANDS[row][frame]
	var aim: Vector2 = AIM[row]
	var angle: float = [-1.9,-1.8,-1.4,-0.3,0.65,1.0,0.1,-0.9][frame]
	# On the back row, sweep outside the hair silhouette instead of behind it.
	var axis := aim.rotated(angle*(-1 if row in [1,2] else 1))
	line(hand-axis*3,hand+axis*18,Color("#382b25"),4)
	line(hand,hand+axis*17,Color("#82969b"),3)
	line(hand+axis*3+axis.orthogonal(),hand+axis*17,Color("#edf2d5"),1)
	line(hand-axis.orthogonal()*3,hand+axis.orthogonal()*3,Color("#c99645"),2)
	if frame >= 3 and frame <= 5:
		for i in range(7):
			var point := hand+axis.rotated(-0.8+i*0.13)*23
			draw_rect(Rect2(point.round(),Vector2(2,2)),Color("#fff0b9") if i % 2 else Color("#f2ce77"))
	arm(shoulder,(shoulder+hand)*0.5,hand)
	var other: Vector2 = MELEE_DATA.SHOULDERS[row][1]
	arm(other,other+Vector2(0,2),other+Vector2(-1,5))
