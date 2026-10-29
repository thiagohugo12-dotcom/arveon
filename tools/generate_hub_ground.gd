extends SceneTree
# Offline preparation: 2 world pixels per pixel, no runtime image generation.
var image := Image.create(600,450,false,Image.FORMAT_RGBA8)
func hash_at(x: int, y: int) -> int:
	return absi((x*74509+y*53197+19033)^((x*74509+y*53197+19033)>>11))%9973
func _initialize() -> void:
	image.fill(Color("#b5c953"))
	for y in range(450):
		for x in range(600):
			var patch := sin(x*0.031+y*0.009)+sin(y*0.045-x*0.012)+sin(x*0.071+y*0.053)*0.14 + float(hash_at(x/3,y/3)%9-4)*0.026
			if patch > 1.05: image.set_pixel(x,y,Color("#a9c04d"))
			elif patch < -1.3: image.set_pixel(x,y,Color("#bdce5d"))
	# These routes connect the same world destinations, with smooth junctions.
	var trails := [
		[Vector2(40,450),Vector2(240,445),Vector2(360,480),Vector2(545,458),Vector2(720,445),Vector2(880,485),Vector2(1160,455)],
		[Vector2(550,50),Vector2(555,220),Vector2(540,400),Vector2(570,550),Vector2(540,690),Vector2(560,860)],
		[Vector2(240,445),Vector2(205,360),Vector2(170,225),Vector2(95,145)],
		[Vector2(560,390),Vector2(660,250),Vector2(800,165),Vector2(905,90)],
		[Vector2(530,520),Vector2(405,625),Vector2(230,700),Vector2(120,735)],
		[Vector2(690,505),Vector2(830,680),Vector2(1040,740),Vector2(1100,790)],
		[Vector2(890,480),Vector2(1010,360),Vector2(1080,335)]
	]
	for i in range(trails.size()):
		var trail: Array = trails[i]
		for j in range(trail.size()-1):
			var a: Vector2 = trail[maxi(0,j-1)]
			var b: Vector2 = trail[j]
			var c: Vector2 = trail[j+1]
			var d: Vector2 = trail[mini(trail.size()-1,j+2)]
			var steps := ceili(b.distance_to(c)/5.0)
			for n in range(steps+1):
				var t := float(n)/steps
				var p := 0.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)
				stamp(p*0.5,Vector2.ONE*(19 if i == 0 else 17 if i == 1 else 12))
	stamp(Vector2(220,193),Vector2(59,42))
	stamp(Vector2(340,185),Vector2(54,31))
	stamp(Vector2(340,291),Vector2(53,42))
	stamp(Vector2(274,244),Vector2(48,50))
	stamp(Vector2(224,279),Vector2(38,28))
	for y in range(450):
		for x in range(600):
			if image.get_pixel(x,y) == Color("#f4ce7e"):
				var cell := hash_at(x/4,y/3)
				if cell%31 == 0 and (x%4+y%3)>1: image.set_pixel(x,y,Color("#edc374"))
	# Inspect a frozen mask: each bank gets a narrow, irregular grass fringe.
	# Interior paths and all destination anchors remain unchanged.
	var mask := image.duplicate() as Image
	for y in range(3,447):
		for x in range(3,597):
			if mask.get_pixel(x,y) != Color("#f4ce7e") and mask.get_pixel(x,y) != Color("#edc374"): continue
			var bank := false
			for offset: Vector2i in [Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2)]:
				var neighbor := mask.get_pixel(x+offset.x,y+offset.y)
				if neighbor != Color("#f4ce7e") and neighbor != Color("#edc374"): bank = true
			if bank and hash_at(x/2,y/2)%5 < 2:
				image.set_pixel(x,y,Color("#a2b94d") if hash_at(x,y)%3 else Color("#c2ce61"))
	image.save_png("res://assets/art/hub_v3/ground.png")
	quit()
func stamp(center: Vector2, radius: Vector2) -> void:
	for y in range(maxi(0,int(center.y-radius.y-2)),mini(450,int(center.y+radius.y+3))):
		for x in range(maxi(0,int(center.x-radius.x-2)),mini(600,int(center.x+radius.x+3))):
			var p := (Vector2(x,y)-center)/radius
			var edge := 1.0+float(hash_at(x/3,y/3)%7-3)*0.027
			if p.length_squared() < edge: image.set_pixel(x,y,Color("#f4ce7e"))
