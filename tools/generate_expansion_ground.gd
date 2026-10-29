extends SceneTree

# Paints the new ground at the same 2x pixel scale and palette as hub_v3/ground.png.
const FLOOR := preload("res://scripts/presentation/floor_view.gd")
const OUTPUT := "res://assets/art/hub_v3/expansion_ground.png"
const SURROUND_OUTPUT := "res://assets/art/hub_v3/grass_surround.png"
const WORLD_SIZE := Vector2i(850,675)
const BASE := Color("#b5c953")
const DARK := Color("#a9c04d")
const LIGHT := Color("#bdce5d")
const DIRT := Color("#f4ce7e")
const DIRT_LIGHT := Color("#f8d589")
const DIRT_DARK := Color("#e9bd70")

var canvas: Image
var dirt: PackedByteArray
var size := WORLD_SIZE
var paint_all := false

func _init() -> void:
	size = Vector2i(1450,1275)
	paint_all = true
	canvas = Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
	canvas.fill(Color.TRANSPARENT)
	_paint_grass()
	var surround := canvas
	var surround_result := surround.save_png(SURROUND_OUTPUT)
	print("Surrounding grass: ", SURROUND_OUTPUT, " (", surround_result, ")")
	size = WORLD_SIZE
	paint_all = false
	canvas = Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
	canvas.fill(Color.TRANSPARENT)
	for y in range(size.y):
		for x in range(size.x):
			if _is_new(x,y): canvas.set_pixel(x,y,surround.get_pixel(x+300,y+300))
	dirt.resize(size.x*size.y)
	_paint_paths()
	var result := canvas.save_png(OUTPUT)
	print("Expansion ground: ", OUTPUT, " (", result, ")")
	quit(0 if result == OK and surround_result == OK else 1)

func _is_new(x: int,y: int) -> bool:
	return paint_all or x>=600 or y>=450

func _paint_grass() -> void:
	for y in range(size.y):
		for x in range(size.x):
			if _is_new(x,y): canvas.set_pixel(x,y,BASE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 181026
	# Soft, uneven meadow islands echo the broad shapes on the original ground.
	for i in range(55 if not paint_all else 140):
		var center := Vector2i(rng.randi_range(0,size.x-1),rng.randi_range(0,size.y-1))
		if not _is_new(center.x,center.y): continue
		var rx := rng.randi_range(20,54)
		var ry := rng.randi_range(15,40)
		var shade := DARK if i%3!=0 else LIGHT
		for y in range(maxi(0,center.y-ry-2),mini(size.y,center.y+ry+3)):
			for x in range(maxi(0,center.x-rx-2),mini(size.x,center.x+rx+3)):
				if not _is_new(x,y): continue
				var norm := pow(float(x-center.x)/rx,2)+pow(float(y-center.y)/ry,2)
				var edge := float(_hash(x/3,y/3,i)%13-6)/80.0
				if norm<1.0+edge: canvas.set_pixel(x,y,shade)
	# Sparse one-pixel fragments have the same restraint as the authored grass.
	for i in range(2600 if not paint_all else 8500):
		var x := rng.randi_range(0,size.x-1)
		var y := rng.randi_range(0,size.y-1)
		if not _is_new(x,y): continue
		var color := canvas.get_pixel(x,y)
		canvas.set_pixel(x,y,color.lightened(0.035) if i%2==0 else color.darkened(0.035))

func _paint_paths() -> void:
	for route: Dictionary in FLOOR.EXPANSION_TRAILS:
		var points: Array = route.points
		var curve := Curve2D.new()
		for i in range(points.size()):
			var before: Vector2 = points[maxi(0,i-1)]
			var after: Vector2 = points[mini(points.size()-1,i+1)]
			var tangent := (after-before)/6.0
			curve.add_point(points[i]/2.0,-tangent/2.0,tangent/2.0)
		curve.bake_interval = 2.0
		var centers := curve.get_baked_points()
		var distance := 0.0
		var length := curve.get_baked_length()
		for i in range(centers.size()):
			if i>0: distance += centers[i-1].distance_to(centers[i])
			var start_fade := 1.0 if _shared_endpoint(points[0]) else smoothstep(0.0,20.0,distance)
			var end_fade := 1.0 if _shared_endpoint(points[-1]) else smoothstep(0.0,20.0,length-distance)
			var radius := float(route.width)*0.25*maxf(0.18,minf(start_fade,end_fade))
			_stamp_path(centers[i],radius)
	for y in range(size.y):
		for x in range(size.x):
			if dirt[y*size.x+x]==0: continue
			var variation := _hash(x,y,491)%31
			var color := DIRT_LIGHT if variation==0 else DIRT_DARK if variation==1 else DIRT
			canvas.set_pixel(x,y,color)
			if variation==2 and x+1<size.x and dirt[y*size.x+x+1]!=0:
				canvas.set_pixel(x+1,y,DIRT_DARK)

func _stamp_path(center: Vector2,radius: float) -> void:
	var min_x := maxi(0,floori(center.x-radius-2))
	var max_x := mini(size.x-1,ceili(center.x+radius+2))
	var min_y := maxi(0,floori(center.y-radius-2))
	var max_y := mini(size.y-1,ceili(center.y+radius+2))
	for y in range(min_y,max_y+1):
		for x in range(min_x,max_x+1):
			if not _is_new(x,y): continue
			var rough := float(_hash(x/2,y/2,72)%9-4)*0.23
			if Vector2(x,y).distance_to(center)<=radius+rough:
				dirt[y*size.x+x]=1

func _shared_endpoint(point: Vector2) -> bool:
	for route: Dictionary in FLOOR.EXPANSION_TRAILS:
		for candidate: Vector2 in route.points:
			if point==candidate and candidate!=route.points[0] and candidate!=route.points[-1]: return true
	return false

func _hash(x: int,y: int,salt: int) -> int:
	var value := x*73856093 ^ y*19349663 ^ salt*83492791
	return absi(value)
