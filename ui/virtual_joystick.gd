class_name VirtualJoystick
extends Control

signal direction_changed(value: Vector2)
var touch_index: int = -1
var mouse_drag: bool = false
var direction := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1 and get_global_rect().has_point(event.position):
			touch_index = event.index
			_update_direction(event.position)
			get_viewport().set_input_as_handled()
		elif event.index == touch_index and not event.pressed:
			reset()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == touch_index:
		_update_direction(event.position)
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_drag = event.pressed
		if mouse_drag:
			_update_direction(get_global_mouse_position())
		else:
			reset()
		accept_event()
	elif event is InputEventMouseMotion and mouse_drag:
		_update_direction(get_global_mouse_position())
		accept_event()

func _update_direction(screen_position: Vector2) -> void:
	var radius := size.x * 0.5
	direction = ((screen_position - global_position - size * 0.5) / radius).limit_length()
	if direction.length() < 0.15:
		direction = Vector2.ZERO
	direction_changed.emit(direction)
	queue_redraw()

func reset() -> void:
	touch_index = -1
	mouse_drag = false
	direction = Vector2.ZERO
	direction_changed.emit(direction)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		reset()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center,size.x*0.5,Color(0.14,0.19,0.12,0.40))
	draw_arc(center,size.x*0.5-2,0,TAU,48,Color(0.93,0.85,0.64,0.7),2)
	for offset: Vector2 in [Vector2(0,-45),Vector2(0,45),Vector2(-45,0),Vector2(45,0)]:
		draw_rect(Rect2(center+offset-Vector2(2,2),Vector2(4,4)),Color(0.93,0.85,0.64,0.5))
	var knob := center+direction*size.x*0.32
	draw_circle(knob+Vector2(0,2),size.x*0.19,Color(0.20,0.15,0.09,0.55))
	draw_circle(knob,size.x*0.18,Color(0.88,0.79,0.57,0.85))
	draw_arc(knob,size.x*0.16,PI,TAU,20,Color(1.0,0.93,0.73,0.7),2)
