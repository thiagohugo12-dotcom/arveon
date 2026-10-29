extends Node2D
## Build-time only: approved torso pixels, articulated arms and an actual bowstring.
const PEOPLE := preload("res://assets/art/actors_v4/people.png")
const AIM := [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]
const CENTRES := [Vector2(19,29),Vector2(12,22),Vector2(10,26),Vector2(21,26)]
const SHOULDERS := [[Vector2(22,27),Vector2(10,27)],[Vector2(9,24),Vector2(22,24)],[Vector2(17,26),Vector2(19,25)],[Vector2(14,26),Vector2(12,25)]]
var row := 0
var frame := 0

func line(a: Vector2,b: Vector2,color: Color,width: float = 1.0) -> void:
	draw_line(a.round(),b.round(),color,width,false)

func arm(shoulder: Vector2,elbow: Vector2,hand: Vector2) -> void:
	line(shoulder,elbow,Color("#382b25"),4)
	line(elbow,hand,Color("#382b25"),4)
	line(shoulder,elbow,Color("#ce673b"),2)
	line(elbow,hand,Color("#efbd84"),2)
	draw_rect(Rect2(hand.round()-Vector2.ONE,Vector2(3,3)),Color("#f7d39b"))

func bow_parts() -> void:
	var direction: Vector2 = AIM[row]
	var side := direction.orthogonal()
	var settle := maxi(0,frame-5)
	var centre: Vector2 = CENTRES[row]+Vector2(0,settle)
	var pull: float = [1,3,6,8,0,0,1,0][frame]
	pull *= 0.5 if row == 0 else 0.75 # Compact reach; keep the same draw/release phases.
	var tip_a := centre+side*11
	var tip_b := centre-side*11
	var grip := centre+direction*4
	var nock := centre-direction*pull
	var shape := [tip_a,centre+side*7+direction*3,grip,centre-side*7+direction*3,tip_b]
	for i in range(4):
		line(shape[i],shape[i+1],Color("#382b25"),3)
		line(shape[i],shape[i+1],Color("#ca9150"),1)
	line(tip_a,nock,Color("#f1d5a2"))
	line(nock,tip_b,Color("#f1d5a2"))
	# Arrow is nocked only before the release. Flight belongs to PlayerProjectile.
	if frame < 4:
		line(nock,centre+direction*10,Color("#d9b16f"))
		line(centre+direction*10,centre+direction*8+side*2,Color("#e4ead7"))
		line(centre+direction*10,centre+direction*8-side*2,Color("#e4ead7"))
		line(nock+side*2,nock-direction*2,Color("#72af9c"))
	var bow_shoulder: Vector2 = SHOULDERS[row][0]
	var draw_shoulder: Vector2 = SHOULDERS[row][1]
	arm(bow_shoulder,(bow_shoulder+grip)*0.5+side,grip)
	var draw_hand := nock if frame < 4 else centre-direction*6+side*2 if frame == 4 else draw_shoulder+Vector2(0,6-settle)
	arm(draw_shoulder,(draw_shoulder+draw_hand)*0.5-side*2,draw_hand)

func _draw() -> void:
	draw_set_transform(Vector2(-16,-32))
	if row == 1: bow_parts()
	# Keep original hair, face, scarf, backpack, belt and torso without recolouring.
	var holes: Array = [Rect2(7,24,6,8),Rect2(21,24,5,8)] if row < 2 else [Rect2(16 if row == 2 else 11,26,5,6)]
	for y in range(32):
		for x in range(32):
			var removed := false
			for hole in holes: removed = removed or hole.has_point(Vector2(x,y))
			if not removed:
				draw_texture_rect_region(PEOPLE,Rect2(x,y,1,1),Rect2(x,row*40+y,1,1))
	if row >= 2:
		var x: int = 17 if row == 2 else 12
		draw_texture_rect_region(PEOPLE,Rect2(x,26,3,5),Rect2(15 if row == 2 else 17,row*40+25,1,5))
	if row != 1: bow_parts()
	draw_set_transform(Vector2.ZERO)
