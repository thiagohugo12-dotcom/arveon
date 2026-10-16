class_name TalentTree
extends Control

signal selected(id: String)
var progress: GameProgress
var weapon := "espada"
var selection := "corte"
var buttons: Dictionary = {}
var captions: Dictionary = {}
var origin: PixelItemIcon
var rules: Dictionary = {}

func _init(value: GameProgress, category: String, node: String) -> void:
	progress = value
	weapon = category
	selection = node
	rules = AbilityRules.talent_tree(category)
	custom_minimum_size = Vector2(240,310)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	origin = PixelItemIcon.new(weapon)
	origin.custom_minimum_size = Vector2(44,44)
	add_child(origin)
	for id: String in rules:
		var rule: Dictionary = rules[id]
		var button := Button.new()
		button.name = id
		button.custom_minimum_size = Vector2(56,56)
		button.size = Vector2(56,56)
		button.tooltip_text = "%s · %s\nProficiência %d\n%s" % [rule.name,rule.kind,rule.prof,rule.description]
		button.pressed.connect(func():
			selection = id
			_refresh_styles()
			selected.emit(id)
		)
		add_child(button)
		buttons[id] = button
		var icon := PixelItemIcon.new(rule.icon)
		icon.position = Vector2(6,6)
		icon.size = Vector2(44,44)
		button.add_child(icon)
		var label := DiaryTheme.label("%s\nProf. %d" % [rule.name,rule.prof],11)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size = Vector2(112,42)
		add_child(label)
		captions[id] = label
	resized.connect(_layout)
	_refresh_styles()

func _ready() -> void:
	_layout()

func _refresh_styles() -> void:
	for id: String in buttons:
		var learned: bool = progress.abilities.talents[weapon].has(id)
		var available: bool = progress.skill_points() > 0 and progress.talents.level(weapon) >= int(rules[id].prof) and (rules[id].parent.is_empty() or progress.abilities.talents[weapon].has(rules[id].parent))
		var fill := DiaryTheme.GREEN if learned else Color("#f9eac8") if available else Color("#d5c49b")
		buttons[id].add_theme_stylebox_override("normal",DiaryTheme.box(fill,DiaryTheme.GREEN if selection == id else DiaryTheme.WOOD,4,3 if selection == id else 1))
		buttons[id].get_child(0).modulate = Color.WHITE if learned or available else Color(0.8,0.75,0.65,0.65)
	queue_redraw()

func _point(id: String) -> Vector2:
	var position: Vector2 = rules[id].position
	return Vector2(roundf(size.x*position.x),position.y+28)

func _layout() -> void:
	origin.position = Vector2(roundf(size.x/2)-22,0)
	origin.size = Vector2(44,44)
	for id: String in buttons:
		buttons[id].position = _point(id)-Vector2(28,28)
		captions[id].position = _point(id)+Vector2(-56,30)
	queue_redraw()

func _draw() -> void:
	for id: String in buttons:
		var parent: String = rules[id].parent
		var start := _point(parent)+Vector2(0,28) if not parent.is_empty() else Vector2(roundf(size.x/2),44)
		var finish := _point(id)-Vector2(0,28)
		var color := DiaryTheme.GREEN if progress.abilities.talents[weapon].has(id) else Color("#b59b68")
		var middle := roundf((start.y+finish.y)/2)
		draw_polyline(PackedVector2Array([start,Vector2(start.x,middle),Vector2(finish.x,middle),finish]),color,2,false)
