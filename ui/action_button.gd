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
var legend := ""
var charge_fraction := -1.0
var style: StyleBoxTexture
var active_style: StyleBoxTexture

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	style = DiaryTheme.piece("wood",0)
	active_style = DiaryTheme.piece("green",0)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	caption = Label.new()
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 12)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.add_theme_color_override("font_color", Color("#fff0ce"))
	caption.add_theme_color_override("font_outline_color", Color("#14231d"))
	caption.add_theme_constant_override("outline_size", 3)
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
	draw_style_box(active_style if active else style, Rect2(Vector2.ZERO, size))
	if not icon.is_empty():
		var color: Color = {"cut":Color("#cbd7d0"),"charge":Color("#82c78c"),"fury":Color("#f1c655"),"dash":Color("#f1d9a0"),"potion":Color("#e3a58e")}.get(icon,Color("#e4dca6"))
		var area := Rect2(Vector2(10,5),size-Vector2(20,22))
		if icon in AbilityRules.CATEGORIES: DiaryArt.icon(self,icon,area)
		elif icon == "cut": DiaryArt.icon(self,"espada",area)
		else: PixelIcon.illustrate(self,icon,area,color if enabled or active else color.darkened(0.3))
		var text: String = legend if not legend.is_empty() else {"cut":"Corte","charge":"Investida","fury":"Fúria","dash":"Dash","potion":"Poção"}.get(icon,"")
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
		draw_string(font,Vector2((size.x-width)/2,size.y-6),text,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#fff0ce"))
		if recharge > 0.0:
			draw_rect(Rect2(4, 4, size.x - 8, (size.y - 8) * recharge), Color("#0a171ec7"))
			draw_rect(Rect2(4, size.y - 6, (size.x - 8) * (1.0 - recharge), 2), Color("#e2b969"))
		if charge_fraction >= 0:
			draw_rect(Rect2(4,size.y-5,(size.x-8)*charge_fraction,3),Color("#f0ca69"))
		if not enabled and not active:
			draw_rect(Rect2(4,4,size.x-8,size.y-8),Color(0.20,0.16,0.10,0.26))
