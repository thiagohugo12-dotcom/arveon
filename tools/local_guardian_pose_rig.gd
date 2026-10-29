extends Node2D
## Authored source-pixel sprite rig inspired by the supplied concept.
## Baked locally into 80px cells, never uses the concept sheet as a texture.
var row := 0
var frame := 0
const AIM := [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]
func box(x: float,y: float,w: float,h: float,color: String) -> void:
	draw_rect(Rect2(x,y,w,h),Color(color))
func polygon(points: Array,color: String,shift := Vector2.ZERO) -> void:
	var vertices := PackedVector2Array()
	for p: Vector2 in points: vertices.append((p+shift).round())
	draw_colored_polygon(vertices,Color(color))
func limb(a: Vector2,b: Vector2,c: Vector2) -> void:
	draw_line(a,b,Color("#302a22"),10,false)
	draw_line(b,c,Color("#302a22"),9,false)
	draw_line(a,b,Color("#765035"),7,false)
	draw_line(b,c,Color("#895c38"),6,false)
	draw_line(a+Vector2(-1,-1),b+Vector2(-1,-1),Color("#b1834d"),2,false)
	for i in [-1,0,1]:
		draw_line(c+Vector2(i*2,0),c+Vector2(i*3,5),Color("#302a22"),3,false)
		draw_line(c+Vector2(i*2,0),c+Vector2(i*3,4),Color("#a17543"),1,false)
func leaves(at: Vector2,small := false) -> void:
	var s := 0.65 if small else 1.0
	var outline := [Vector2(-10,0),Vector2(-12,-6),Vector2(-8,-6),Vector2(-8,-11),Vector2(-3,-11),Vector2(-3,-14),Vector2(3,-14),Vector2(3,-11),Vector2(9,-11),Vector2(9,-7),Vector2(12,-7),Vector2(12,-1),Vector2(8,3),Vector2(-6,3)]
	var pts: Array = []
	for p: Vector2 in outline: pts.append(at+p*s)
	polygon(pts,"#243e31")
	box(at.x-8*s,at.y-8*s,15*s,8*s,"#416b3d")
	box(at.x-5*s,at.y-11*s,10*s,8*s,"#668b43")
	box(at.x-3*s,at.y-11*s,4*s,3*s,"#a0ad50")
	box(at.x+5*s,at.y-7*s,3*s,3*s,"#789b43")
func _draw() -> void:
	var aim: Vector2 = AIM[row]
	var motion: float = [0,0,-1,-2,2,1,0,0][frame]
	var crouch: float = [0,-1,2,4,3,2,1,0][frame]
	var shift := aim*motion+Vector2(0,crouch)
	# Root feet stay planted; front toes flex during preparation/contact.
	for side in [-1,1]:
		var x: float = 40+side*10
		polygon([Vector2(x-5,54),Vector2(x+4,54),Vector2(x+8,65),Vector2(x+2,64),Vector2(x-1,67),Vector2(x-8,65)],"#302a22")
		polygon([Vector2(x-3,55),Vector2(x+2,55),Vector2(x+5,63),Vector2(x-5,63)],"#89603c")
		box(x-2,57,2,6,"#b48a50")
	# Rear arm visible around profile/back; independent joints communicate weight.
	var shoulder_a := Vector2(25,36)+shift
	var shoulder_b := Vector2(54,35)+shift
	var attack := frame == 4
	var windup := frame in [2,3]
	var hand_a := Vector2(16,53)+shift
	var hand_b := Vector2(63,50)+shift
	if windup:
		hand_b -= aim*8
		hand_b.y -= 6
	if attack:
		hand_b = Vector2(49,45)+aim*17
		hand_a += aim*3
	if frame == 5: hand_b = Vector2(53,48)+aim*10
	if frame == 6: hand_b += aim*3
	limb(shoulder_a,Vector2(18,43)+shift,hand_a)
	limb(shoulder_b,Vector2(61,42)+shift,hand_b)
	polygon([Vector2(27,56),Vector2(24,40),Vector2(28,24),Vector2(35,18),Vector2(48,19),Vector2(55,29),Vector2(54,46),Vector2(49,59),Vector2(36,61)],"#302a22",shift)
	polygon([Vector2(30,55),Vector2(28,38),Vector2(32,25),Vector2(39,22),Vector2(47,24),Vector2(51,35),Vector2(49,52),Vector2(43,57)],"#8e613c",shift)
	polygon([Vector2(33,51),Vector2(33,35),Vector2(37,25),Vector2(41,25),Vector2(39,38),Vector2(41,54)],"#b1844d",shift)
	box(45+shift.x,28+shift.y,3,21,"#62452e")
	box(30+shift.x,39+shift.y,3,11,"#67472f")
	# Natural carved brows and amber eyes. Back view has bark, not a pasted face.
	if row != 1:
		var face_x := 0 if row == 0 else (-5 if row == 2 else 5)
		for side in [-1,1]:
			if row == 2 and side == 1 or row == 3 and side == -1: continue
			box(38+side*6+face_x+shift.x,39+shift.y,5,2,"#3b3025")
			box(38+side*6+face_x+shift.x,41+shift.y,4,3,"#d58a32")
			box(39+side*6+face_x+shift.x,41+shift.y,2,2,"#ffe0a0")
		box(38+face_x+shift.x,48+shift.y,6,2,"#493629")
	else:
		box(37+shift.x,31+shift.y,3,22,"#62452e")
		box(42+shift.x,40+shift.y,2,13,"#bb8b4e")
	# Shoulder moss and canopy: restrained clusters, fixed silhouette across states.
	leaves(Vector2(23,34)+shift,true)
	leaves(Vector2(55,32)+shift,true)
	leaves(Vector2(26,22)+shift)
	leaves(Vector2(51,20)+shift)
	leaves(Vector2(38,17)+shift)
	box(29+shift.x,30+shift.y,3,7,"#466c3c")
	box(50+shift.x,29+shift.y,2,5,"#6b8b43")
