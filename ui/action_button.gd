class_name TouchActionButton
extends Control

signal activated
var enabled: bool = false
var touch_index: int = -1
var title: String = ""
var caption: Label
var icon := ""
var recharge := 0.0
var active := false
var style: StyleBoxFlat

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	style = StyleBoxFlat.new()
	style.set_border_width_all(2)
	caption = Label.new()
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 12)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)
	set_caption(title)

func set_caption(value: String) -> void:
	if is_instance_valid(caption):
		caption.text = value
		caption.visible = icon.is_empty() or not value.is_empty()
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

func set_recharge(left: float, total: float, glowing: bool = false) -> void:
	var fraction := snappedf(clampf(left / maxf(total, 0.001), 0.0, 1.0), 0.01)
	var label := "%.1fs" % snappedf(left, 0.1) if left > 0.0 else ""
	if recharge != fraction or active != glowing or caption.text != label:
		recharge = fraction
		active = glowing
		set_caption(label)

func _draw() -> void:
	if style == null:
		return
	style.bg_color = Color("#244b3deb") if enabled else Color("#182a25eb")
	style.border_color = Color("#f2c26b") if active else Color("#b2c99a") if enabled else Color("#53685b")
	draw_style_box(style, Rect2(Vector2.ZERO, size))
	draw_rect(Rect2(4, 4, size.x - 8, 2), Color("#57755b"))
	if not icon.is_empty():
		PixelIcon.paint(self, icon, Rect2(Vector2(12, 8), size - Vector2(24, 16)), Color("#e4dca6") if enabled or active else Color("#778e7d"))
		if recharge > 0.0:
			draw_rect(Rect2(4, 4, size.x - 8, (size.y - 8) * recharge), Color("#0a171ec7"))
			draw_rect(Rect2(4, size.y - 6, (size.x - 8) * (1.0 - recharge), 2), Color("#e2b969"))
		caption.add_theme_color_override("font_color", Color("#fff0ce"))
		caption.add_theme_color_override("font_outline_color", Color("#14231d"))
		caption.add_theme_constant_override("outline_size", 3)
