extends Node2D

# An isolated visual study; never instantiate GameProgress or touch user://.
const PROPS := preload("res://assets/art/mata_sample/props.png")
const FLOOR := preload("res://assets/art/mata_sample/floor.png")
const PLAYER := preload("res://scenes/actors/player.tscn")
const AREA := Rect2(704,256,384,384)
const TREE_FEET := [Vector2(811,364),Vector2(931,406)]
var player: PlayerActor
var driver: InputDriver
var joystick: VirtualJoystick
var dash_button: TouchActionButton
var heading: Label

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	RenderingServer.set_default_clear_color(Color("#b5ce61"))
	var ground := Sprite2D.new()
	ground.texture = FLOOR
	ground.centered = false
	ground.position = AREA.position
	add_child(ground)
	var objects := Node2D.new()
	objects.y_sort_enabled = true
	add_child(objects)
	for i in range(2):
		_prop(objects,TREE_FEET[i],Rect2(0 if i == 0 else 104,0,96 if i == 0 else 84,108))
		_circle(objects,TREE_FEET[i],9)
	# Existing stone footprint and position in this slice of the Mata.
	_prop(objects,Vector2(805,608),Rect2(192,0,44,34),Vector2(2,2))
	_box(objects,Rect2(760,520,90,110))
	for point in [Vector2(747,385),Vector2(1026,535)]:
		_prop(objects,point,Rect2(192,40,44,28))
	for point in [Vector2(767,453),Vector2(973,331),Vector2(992,597),Vector2(846,583),Vector2(1021,399)]:
		_prop(objects,point,Rect2(192,76,14,10))
	# Demonstration boundaries only. The actual 1200x900 Mata is untouched.
	for wall in [Rect2(AREA.position-Vector2(16,16),Vector2(416,16)),Rect2(704,640,384,16),Rect2(688,256,16,384),Rect2(1088,256,16,384)]:
		_box(objects,wall)
	driver = InputDriver.new()
	add_child(driver)
	player = PLAYER.instantiate() as PlayerActor
	player.input_driver = driver
	player.position = Vector2(870,470)
	objects.add_child(player)
	var camera: Camera2D = player.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	camera.enabled = false
	var study_camera := Camera2D.new()
	study_camera.position = Vector2(896,432)
	add_child(study_camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	heading = Label.new()
	heading.text = "AMOSTRA DA MATA\nJoystick · WASD / setas"
	heading.add_theme_font_size_override("font_size",13)
	heading.add_theme_color_override("font_color",Color("#fff4d1"))
	heading.add_theme_color_override("font_outline_color",Color("#243d25"))
	heading.add_theme_constant_override("outline_size",5)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(heading)
	joystick = VirtualJoystick.new()
	joystick.direction_changed.connect(driver.set_touch_direction)
	canvas.add_child(joystick)
	dash_button = TouchActionButton.new()
	dash_button.title = "Dash"
	dash_button.enabled = true
	dash_button.activated.connect(driver.request_dash)
	canvas.add_child(dash_button)
	get_viewport().size_changed.connect(_layout)
	_layout()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.title='Mata — amostra artística';document.documentElement.dataset.mataSample='ready';",true)

func _layout() -> void:
	var viewport := get_viewport()
	var size := Vector2(viewport.size)
	# One world pixel per logical pixel, same scale as ActorView (48px).
	get_tree().root.content_scale_size = viewport.size
	heading.position = Vector2(16,16)
	joystick.position = Vector2(16,size.y-124)
	joystick.size = Vector2(108,108)
	dash_button.position = Vector2(size.x-88,size.y-88)
	dash_button.size = Vector2(72,72)

func _prop(parent: Node2D, feet: Vector2, region: Rect2, scale_value := Vector2.ONE) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = PROPS
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.position = feet
	sprite.offset = Vector2(0,-region.size.y*0.5)
	sprite.scale = scale_value
	parent.add_child(sprite)

func _circle(parent: Node2D, center: Vector2, radius: float) -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	_body(parent,center,shape)

func _box(parent: Node2D, rectangle: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = rectangle.size
	_body(parent,rectangle.get_center(),shape)

func _body(parent: Node2D, center: Vector2, shape: Shape2D) -> void:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
