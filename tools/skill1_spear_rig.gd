extends "res://tools/skill1_rig.gd"
func bow_parts() -> void:
	var axis: Vector2 = AIM[row]
	var hand := MELEE.hand(1,row,frame)
	if frame <= 2: hand -= axis*2
	elif frame == 3: hand += axis*2
	elif frame == 4: hand += axis
	var length := 16 if row < 2 else 23
	var tip := hand+axis*length
	line(hand-axis*9,tip,Color("#382b25"),3)
	line(hand-axis*8,tip,Color("#ba884b"),1)
	polygon_at(tip,axis,[Vector2(-2,-3),Vector2(6,0),Vector2(-2,3),Vector2(0,0)],Color("#343d42"))
	polygon_at(tip,axis,[Vector2(-1,-1),Vector2(4,0),Vector2(-1,2)],Color("#d9dfcf"))
	line(tip-axis*3-axis.orthogonal(),tip-axis*3+axis.orthogonal(),Color("#4c9c8c"),2)
	if frame == 3 or frame == 4:
		line(tip-axis*12+axis.orthogonal()*3,tip+axis*2+axis.orthogonal()*3,Color("#edf4c9"),1)
		for i in range(3): draw_rect(Rect2((tip-axis*(8+i*4)-axis.orthogonal()*3).round(),Vector2.ONE),Color("#a9c8a3"))
	var shoulder: Vector2 = MELEE.SHOULDERS[row][0]
	var other: Vector2 = MELEE.SHOULDERS[row][1]
	var support := other.lerp(hand-axis*6,0.5).round()
	arm(shoulder,(shoulder+hand)*0.5+Vector2(0,1),hand)
	arm(other,(other+support)*0.5,support)
