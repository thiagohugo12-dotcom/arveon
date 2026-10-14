extends "res://tools/skill1_rig.gd"
func bow_parts() -> void:
	var hand: Vector2 = MELEE.AXE_HANDS[row][frame]
	if frame <= 2:
		var raised: Vector2 = [Vector2(26,21),Vector2(6,19),Vector2(7,21),Vector2(24,21)][row]
		hand = hand.lerp(raised,[0.6,0.8,1.0][frame]).round()
	elif frame <= 4: hand += AIM[row]
	var axis: Vector2 = Vector2.UP if frame <= 2 or frame == 7 else AIM[row].rotated([-0.2,0.2,0.65,-0.9][frame-3]*(1 if row != 2 else -1))
	var head := hand+axis*13
	var blade := -axis if row in [0,3] else axis
	line(hand-axis*4,head,Color("#382b25"),3)
	line(hand-axis*3,head,Color("#ba884b"),1)
	polygon_at(head,blade,[Vector2(-2,-3),Vector2(2,-3),Vector2(2,1),Vector2(5,2),Vector2(6,8),Vector2(-6,8),Vector2(-5,2),Vector2(-2,1)],Color("#343d42"))
	polygon_at(head,blade,[Vector2(-1,-2),Vector2(1,-2),Vector2(1,2),Vector2(4,3),Vector2(4,6),Vector2(-4,6),Vector2(-4,3),Vector2(-1,2)],Color("#87959a"))
	line(head-blade*5+blade.orthogonal()*7,head+blade*5+blade.orthogonal()*7,Color("#e4e0bd"),1)
	if frame == 4 or frame == 5:
		for offset: Vector2 in [Vector2(-5,3),Vector2(4,4),Vector2(1,6)]:
			draw_rect(Rect2((head+offset).round(),Vector2(2,1)),Color("#d9b77e"))
	var shoulder: Vector2 = MELEE.SHOULDERS[row][0]
	var other: Vector2 = MELEE.SHOULDERS[row][1]
	var support := other.lerp(hand-axis*3,0.45).round()
	arm(shoulder,(shoulder+hand)*0.5,hand)
	arm(other,(other+support)*0.5,support)
