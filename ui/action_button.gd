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
var slot_number := 0
var touch_margin := 0.0
var empty := false
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
		if event.pressed and enabled and is_visible_in_tree() and touch_index == -1 and get_global_rect().grow(touch_margin).has_point(event.position):
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
	if empty:
		_draw_empty()
		return
	if not icon.is_empty():
		# Poço escuro atrás do ícone: o ícone destaca mais e o aro mostra se o botão está pronto.
		draw_rect(Rect2(5,5,size.x-10,size.y-10),Color("#142319d8"))
		draw_rect(Rect2(5,5,size.x-10,size.y-10),Color("#f0cc72") if enabled or active else Color("#4b4a3a"),false,1.0)
		draw_rect(Rect2(5,size.y-17,size.x-10,12),Color("#0c1a12e6"))
		var color: Color = {"cut":Color("#cbd7d0"),"charge":Color("#82c78c"),"fury":Color("#f1c655"),"dash":Color("#f1d9a0"),"potion":Color("#e3a58e")}.get(icon,Color("#e4dca6"))
		var area := Rect2(Vector2(10,8),size-Vector2(20,28))
		if icon in AbilityRules.CATEGORIES: DiaryArt.icon(self,icon,area)
		elif icon == "cut": DiaryArt.icon(self,"espada",area)
		else: PixelIcon.illustrate(self,icon,area,color if enabled or active else color.darkened(0.3))
		var text: String = legend if not legend.is_empty() else {"cut":"Skill 1","charge":"Técnica","fury":"Ultimate","dash":"Dash","potion":"Poção"}.get(icon,"")
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
		draw_string(font,Vector2((size.x-width)/2,size.y-8),text,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#fff0ce") if enabled or active else Color("#b6ad90"))
		if slot_number > 0:
			draw_rect(Rect2(3,3,14,14),Color("#1d3a28"))
			draw_rect(Rect2(3,3,14,14),Color("#e8c776"),false,1.0)
			draw_string(font,Vector2(7,14),str(slot_number),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#fff0ce"))
		if recharge > 0.0:
			draw_rect(Rect2(5, 5, size.x - 10, (size.y - 22) * recharge), Color("#0a171ec7"))
			draw_rect(Rect2(4, size.y - 6, (size.x - 8) * (1.0 - recharge), 2), Color("#e2b969"))
		if charge_fraction >= 0:
			draw_rect(Rect2(4,size.y-5,(size.x-8)*charge_fraction,3),Color("#f0ca69"))
		if not enabled and not active:
			draw_rect(Rect2(4,4,size.x-8,size.y-8),Color(0.20,0.16,0.10,0.26))

# Espaço de habilidade sem técnica equipada: moldura tracejada com "+" e a legenda "Vazio".
func _draw_empty() -> void:
	draw_rect(Rect2(5,5,size.x-10,size.y-10),Color(0.06,0.10,0.07,0.78))
	var edge := Color(0.78,0.70,0.45,0.55)
	var left := 5.0
	while left < size.x - 5.0:
		var piece := minf(4.0,size.x - 5.0 - left)
		draw_rect(Rect2(left,5,piece,1),edge)
		draw_rect(Rect2(left,size.y-6,piece,1),edge)
		left += 7.0
	var top := 5.0
	while top < size.y - 5.0:
		var piece := minf(4.0,size.y - 5.0 - top)
		draw_rect(Rect2(5,top,1,piece),edge)
		draw_rect(Rect2(size.x-6,top,1,piece),edge)
		top += 7.0
	var middle := Vector2(size.x / 2.0,size.y / 2.0 - 5.0)
	draw_rect(Rect2(middle.x - 7,middle.y - 1,14,3),Color(0.85,0.78,0.52,0.75))
	draw_rect(Rect2(middle.x - 1,middle.y - 7,3,14),Color(0.85,0.78,0.52,0.75))
	var font := ThemeDB.fallback_font
	var text := "Vazio"
	var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
	draw_string(font,Vector2((size.x-width)/2,size.y-9),text,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color(0.80,0.74,0.55,0.8))
	if slot_number > 0:
		draw_string(font,Vector2(8,17),str(slot_number),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(0.80,0.74,0.55,0.8))
