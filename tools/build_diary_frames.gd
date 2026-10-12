extends SceneTree

# Reproducible UI pieces, drawn offline. Nine-slicing keeps corners at 1:1.
var image: Image

func rect(x: int, y: int, w: int, h: int, color: String) -> void:
	image.fill_rect(Rect2i(x,y,w,h),Color(color))

func inset(n: int, color: String) -> void:
	rect(n,n,96-n*2,96-n*2,color)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/art/diary_v3")
	for kind: String in ["frame","paper","green","wood","slot","empty"]:
		image = Image.create(96,96,false,Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		match kind:
			"frame":
				inset(0,"#352319")
				inset(2,"#b57a40")
				inset(4,"#654026")
				inset(7,"#946037")
				inset(9,"#d4a15c")
				inset(11,"#4b3020")
				inset(13,"#b88e55")
				inset(15,"#fff0cb")
				inset(17,"#c6a774")
				inset(18,"#f4e5bf")
				for y in range(18,78):
					for x in range(18,78):
						var grain := ((x*19+y*31)%7)/2550.0
						var shade := float(y-18)/60.0*0.014+grain
						image.set_pixel(x,y,Color("#f7e9c6").darkened(shade))
				for x in [4,82]:
					for y in [4,82]:
						rect(x,y,10,10,"#503520")
						rect(x+2,y+2,6,6,"#d6a865")
						rect(x+3,y+3,3,3,"#f7d798")
				for y in [6,89]:
					rect(20,y,15,1,"#b67d43")
					rect(61,y,14,1,"#b67d43")
			"paper", "green", "wood":
				var green := kind == "green"
				var wood := kind == "wood"
				inset(0,"#3c291d" if wood else "#22472f" if green else "#b59360")
				inset(2,"#d0a76b" if wood else "#82a66b" if green else "#fff2cf")
				inset(4,"#765031" if wood else "#356743" if green else "#e9d2a3")
				inset(6,"#4c3324" if wood else "#2d5839" if green else "#f2e0b8")
				rect(6,6,84,2,"#a17242" if wood else "#517b4d" if green else "#faeccc")
				rect(6,88,84,2,"#302118" if wood else "#21462f" if green else "#d5b781")
				for x in [4,88]:
					for y in [4,88]: rect(x,y,3,3,"#c99958" if wood else "#64895b" if green else "#d5b781")
			"slot", "empty":
				inset(0,"#b3915d")
				inset(1,"#fff1cb")
				inset(3,"#c5a470")
				inset(5,"#e8d1a5" if kind == "slot" else "#ecdbb6")
				inset(7,"#ead6ae" if kind == "slot" else "#efdfbb")
				rect(5,5,86,2,"#d8bd8b")
				rect(7,88,82,1,"#fff0c9")
		image.save_png("res://assets/art/diary_v3/%s.png" % kind)
	quit()
