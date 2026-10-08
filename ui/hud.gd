class_name GameHUD
extends Control

signal dash_pressed
signal restart_pressed
signal movement_changed(value: Vector2)
var joystick: VirtualJoystick
var dash_button: TouchActionButton
var actions: Array[TouchActionButton] = []
var heading: Label
var hp_label: Label
var hp_bar: ProgressBar
var progress_label: Label
var mission_label: Label
var loot_label: Label
var restart: Button
var cooldown: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading = Label.new()
	heading.text = "Andar 1 · Mata dos Primeiros Passos"
	heading.add_theme_font_size_override("font_size", 16)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(heading)
	hp_label = Label.new()
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hp_label)
	hp_bar = ProgressBar.new()
	hp_bar.show_percentage = false
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hp_bar)
	progress_label = Label.new()
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(progress_label)
	mission_label = Label.new()
	mission_label.add_theme_font_size_override("font_size", 12)
	mission_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mission_label)
	loot_label = Label.new()
	loot_label.add_theme_font_size_override("font_size", 11)
	loot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(loot_label)
	joystick = VirtualJoystick.new()
	joystick.size = Vector2(128, 128)
	joystick.direction_changed.connect(func(value: Vector2): movement_changed.emit(value))
	add_child(joystick)
	for title: String in ["Skill 1", "Skill 2", "Ultimate", "Poção", "", "Dash"]:
		var button := TouchActionButton.new()
		button.title = title + "\nEm breve" if title != "Dash" and title != "" else title
		button.enabled = title == "Dash"
		button.size = Vector2(56, 56)
		button.visible = title != ""
		add_child(button)
		actions.append(button)
		if title == "Dash":
			dash_button = button
			button.activated.connect(func(): dash_pressed.emit())
	restart = Button.new()
	restart.text = "Você caiu · Reiniciar"
	restart.visible = false
	restart.pressed.connect(func(): restart_pressed.emit())
	add_child(restart)
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if not is_instance_valid(joystick):
		return
	var margin := Vector2(12, 12)
	var bottom_inset: float = 12.0
	var right_inset: float = 12.0
	if OS.has_feature("android") or OS.has_feature("ios"):
		var safe := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		if screen.x > 0 and screen.y > 0:
			margin.x += float(safe.position.x) / screen.x * size.x
			margin.y += float(safe.position.y) / screen.y * size.y
			bottom_inset += float(screen.y - safe.end.y) / screen.y * size.y
			right_inset += float(screen.x - safe.end.x) / screen.x * size.x
	heading.position = margin
	heading.size = Vector2(size.x - margin.x - right_inset, 44)
	hp_label.position = Vector2(margin.x, margin.y + 46)
	hp_bar.position = Vector2(margin.x, margin.y + 68)
	hp_bar.size = Vector2(minf(220, size.x - margin.x - right_inset), 12)
	progress_label.position = Vector2(margin.x, margin.y + 85)
	progress_label.size = Vector2(size.x - margin.x - right_inset, 20)
	mission_label.position = Vector2(margin.x, margin.y + 106)
	mission_label.size = Vector2(size.x - margin.x - right_inset, 19)
	loot_label.position = Vector2(margin.x, margin.y + 128)
	loot_label.size = Vector2(size.x - margin.x - right_inset, 35)
	joystick.position = Vector2(margin.x, size.y - bottom_inset - joystick.size.y)
	for i in range(actions.size()):
		actions[i].position = Vector2(size.x - right_inset - 184 + (i % 3) * 64, size.y - bottom_inset - 120 + (i / 3) * 64)
	restart.position = Vector2(size.x * 0.5 - 120, size.y * 0.5 - 24)
	restart.size = Vector2(240, 48)

func set_health(current: int, maximum: int) -> void:
	hp_label.text = "HP %d / %d · Ataque automático" % [current, maximum]
	hp_bar.max_value = maximum
	hp_bar.value = current

func set_progress(xp: int, gold: int, kills: int, loot: String) -> void:
	progress_label.text = "XP %d  ·  Ouro %d  ·  Abates %d" % [xp, gold, kills]
	loot_label.text = loot

func set_mission(value: String) -> void:
	mission_label.text = value

func show_death() -> void:
	joystick.reset()
	dash_button.enabled = false
	dash_button.queue_redraw()
	restart.show()

func set_dash_cooldown(value: float) -> void:
	var rounded := snappedf(value, 0.1)
	if rounded != cooldown:
		cooldown = rounded
		dash_button.set_caption("Dash" if value <= 0.0 else "Dash\n%.1fs" % value)
