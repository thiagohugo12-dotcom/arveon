extends "res://tools/skill1_rig.gd"
func bow_parts() -> void:
	var aim: Vector2 = AIM[row]
	var side := aim.orthogonal()
	var centre: Vector2 = CENTRES[row]
	var grip := centre+aim*4
	var pull: float = [1,3,6,0,0,0,0,0][frame]
	var nock := centre-aim*pull
	var tip_a := centre+side*12
	var tip_b := centre-side*12
	var shape := [tip_a,centre+side*7+aim*3,grip,centre-side*7+aim*3,tip_b]
	for index in range(4):
		line(shape[index],shape[index+1],Color("#382b25"),3)
		line(shape[index],shape[index+1],Color("#ca9150"),1)
	line(tip_a,nock,Color("#fff0b9"))
	line(nock,tip_b,Color("#fff0b9"))
	if frame < 3:
		line(nock,centre+aim*12,Color("#d9b16f"))
		line(centre+aim*12,centre+aim*9+side*2,Color("#edf4d5"))
		line(centre+aim*12,centre+aim*9-side*2,Color("#edf4d5"))
		line(nock+side*2,nock-aim*2,Color("#76bfb0"))
		if frame == 2:
			for offset: Vector2 in [side*4,-side*4,aim*3]: draw_rect(Rect2((centre+aim*12+offset).round(),Vector2.ONE),Color("#fff0b9"))
	var shoulder: Vector2 = SHOULDERS[row][0]
	var other: Vector2 = SHOULDERS[row][1]
	var hand := nock if frame < 3 else centre-aim*6+side if frame <= 4 else other+Vector2(0,4)
	arm(shoulder,(shoulder+grip)*0.5+side,grip)
	arm(other,(other+hand)*0.5-side,hand)
