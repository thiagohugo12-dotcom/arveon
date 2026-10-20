extends Control
## Interactive, isolated Floor 2 monster art review. Run this scene with F6.

const ACTOR := preload("res://scripts/demos/floor2_monster_actor.gd")
const TERRAIN := preload("res://assets/art/andar2/terreno.png")
const PEOPLE := preload("res://assets/art/actors_v4/people.png")
const LABELS := ["Goblin Garimpeiro", "Tatu Rochoso", "Escorpião da Chapada"]
const STATE_NAMES := {"idle":"Repouso", "walk":"Caminhada", "attack":"Ataque", "throw":"Arremesso", "retreat":"Recuo", "defense":"Defesa", "charge":"Investida", "claws":"Pinças", "lateral":"Lateral", "hit":"Dano", "death":"Morte"}

var actors: Array[Node2D] = []
var selected := 0
var state := "idle"
var isolated := false
var buttons: Array[Button] = []
var header: Label
var subtitle: Label
var scale_label: Label

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for i in range(3):
		var actor: Node2D = ACTOR.new()
		actor.monster_index = i
		actor.name = ACTOR.NAMES[i]
		add_child(actor)
		actors.append(actor)
	header = _label("ANDAR 2  ·  CRIATURAS DO CERRADO", 24, Color("f5de9b"))
	subtitle = _label("Prévia de arte e animação · sem combate e sem spawns", 14, Color("e9e3ca"))
	scale_label = _label("Escala real: aventureiro ao lado das criaturas", 14, Color("f7eed0"))
	_create_buttons()
	get_viewport().size_changed.connect(_layout)
	_layout()

func _label(value: String, size_px: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("312515"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)
	return label

func _button(value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(callback)
	add_child(button)
	buttons.append(button)
	return button

func _create_buttons() -> void:
	for i in range(3): _button(LABELS[i], func(): select_monster(i))
	_button("Isolar / comparar", func(): set_isolated(not isolated))
	for name in ["idle", "walk", "attack", "throw", "retreat", "defense", "charge", "claws", "lateral", "hit", "death"]:
		_button(STATE_NAMES[name], func(): set_state(name))

func select_monster(index: int) -> void:
	selected = clampi(index, 0, 2)
	if not ACTOR.STATE_ROWS[selected].has(state): state = "idle"
	_refresh()

func set_state(value: String) -> void:
	if not ACTOR.STATE_ROWS[selected].has(value): return
	state = value
	_refresh()

func set_isolated(value: bool) -> void:
	isolated = value
	_refresh()

func _refresh() -> void:
	for i in range(3):
		actors[i].call("play_state", state if i == selected else "idle")
	scale_label.text = "%s · %s · escala com o aventureiro" % [LABELS[selected], STATE_NAMES[state]]
	_layout()

func _layout() -> void:
	if actors.is_empty(): return
	var w := size.x
	var h := size.y
	var phone := w < 540.0
	header.position = Vector2(18, 13)
	header.add_theme_font_size_override("font_size", 17 if phone else 24)
	subtitle.position = Vector2(19, 40 if phone else 48)
	subtitle.add_theme_font_size_override("font_size", 11 if phone else 14)
	scale_label.position = Vector2(18, h-329 if phone else h-184)
	scale_label.add_theme_font_size_override("font_size", 11 if phone else 14)
	var tab_y := h-298 if phone else h-110
	var cell_w := (w-36)/3.0
	for i in range(3):
		buttons[i].position = Vector2(18+i*cell_w, tab_y)
		buttons[i].size = Vector2(cell_w-4, 37)
		buttons[i].add_theme_font_size_override("font_size", 11 if phone else 15)
		buttons[i].disabled = i == selected
	buttons[3].position = Vector2(18, h-252 if phone else h-155)
	buttons[3].size = Vector2(w-36 if phone else 160, 34)
	var col_count := 3 if phone else 7
	var state_y := h-210 if phone else h-63
	var state_w := (w-36)/float(col_count)
	for j in range(11):
		var button := buttons[j+4]
		var name: String = ["idle", "walk", "attack", "throw", "retreat", "defense", "charge", "claws", "lateral", "hit", "death"][j]
		button.visible = ACTOR.STATE_ROWS[selected].has(name)
		button.disabled = name == state
		var index: int = ACTOR.STATE_ROWS[selected].find(name)
		if index < 0: continue
		button.position = Vector2(18+(index%col_count)*state_w, state_y+(index/col_count)*38)
		button.size = Vector2(state_w-4, 34)
		button.add_theme_font_size_override("font_size", 12 if phone else 14)
	var stage_y := h*0.40 if phone else h*0.48
	for i in range(3):
		actors[i].visible = (i == selected) if phone or isolated else true
		var display_scale: float = ([2.15, 2.10, 2.10][i] if phone or isolated else [1.65, 1.60, 1.60][i])
		actors[i].scale = Vector2.ONE * display_scale
		actors[i].position = Vector2(w*0.65, stage_y) if phone or isolated else Vector2(w*(0.30+0.23*i), stage_y)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var phone := w < 540.0
	var src := Rect2(175, 35, w/2.0, h/2.0) if phone else Rect2(55, 40, w/2.0, h/2.0)
	src.size = src.size.min(Vector2(850, 675)-src.position)
	draw_texture_rect_region(TERRAIN, Rect2(Vector2.ZERO, Vector2(w, h)), src)
	draw_rect(Rect2(0, 0, w, 74 if phone else 85), Color(0.12, 0.15, 0.10, 0.85))
	draw_rect(Rect2(0, h-343 if phone else h-192, w, 343 if phone else 192), Color(0.13, 0.17, 0.11, 0.88))
	var stage_y := h*0.40 if phone else h*0.48
	var player_x := w*0.30 if phone or isolated else w*0.105
	var player_scale := 3.0 if phone or isolated else 2.35
	var foot := Vector2(player_x, stage_y+48 if phone or isolated else stage_y+34)
	draw_ellipse_shadow(foot, 28*player_scale/2)
	draw_texture_rect_region(PEOPLE, Rect2(foot+Vector2(-16, -40)*player_scale, Vector2(32, 40)*player_scale), Rect2(0, 0, 32, 40))
	for i in range(3):
		if not actors[i].visible: continue
		var p: Vector2 = actors[i].position
		draw_ellipse_shadow(p+Vector2(0, 15*actors[i].scale.x), 28*actors[i].scale.x/2)
		var text: String = LABELS[i] if i == selected or not phone else ""
		if not text.is_empty(): draw_string(ThemeDB.fallback_font, p+Vector2(-68, 75 if phone else 61), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("35291c"))

func draw_ellipse_shadow(at: Vector2, radius: float) -> void:
	var points := PackedVector2Array()
	for i in range(16):
		var angle := TAU*float(i)/16.0
		points.append(at+Vector2(cos(angle)*radius, sin(angle)*radius*0.27))
	draw_colored_polygon(points, Color(0.25, 0.28, 0.15, 0.30))
