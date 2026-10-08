class_name TouchActionButton
extends Control

signal activated
var enabled: bool = false
var touch_index: int = -1
var title: String = ""
var caption: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	caption = Label.new()
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 12)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)
	set_caption(title)

func set_caption(value: String) -> void:
	if is_instance_valid(caption):
		caption.text = value
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and enabled and is_visible_in_tree() and touch_index == -1 and get_global_rect().has_point(event.position):
			touch_index = event.index
			activated.emit()
			get_viewport().set_input_as_handled()
		elif event.index == touch_index and not event.pressed:
			touch_index = -1
			get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if enabled:
			activated.emit()
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		touch_index = -1

func _draw() -> void:
	draw_style_box(_style(), Rect2(Vector2.ZERO, size))

func _style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.36, 0.3, 0.9) if enabled else Color(0.1, 0.14, 0.16, 0.85)
	style.set_border_width_all(2)
	style.border_color = Color(0.6, 0.9, 0.7) if enabled else Color(0.3, 0.4, 0.35)
	style.set_corner_radius_all(12)
	return style
