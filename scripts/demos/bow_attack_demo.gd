extends Control
## Isolated visual review. Never instantiates Main, loads a save or calls save().
const NEW_VIEW := preload("res://scripts/demos/bow_demo_view.gd")
const NEW_PLAYER := preload("res://scripts/demos/bow_demo_player.gd")
const TARGET := preload("res://scripts/demos/bow_training_target.gd")
const PROJECTILE := preload("res://scripts/demos/bow_demo_projectile.gd")
const DIRECTIONS := [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]
const LABELS := ["Frente","Costas","Esquerda","Direita"]
var players: Array[PlayerActor] = []
var targets: Array[Node2D] = []
var drivers: Array[InputDriver] = []
var origins: Array[Vector2] = []
var viewports: Array[SubViewport] = []
var cameras: Array[Camera2D] = []
var panels: Array[Control] = []
var heading: Label
var subtitle: Label
var status: Label
var footnote: Label
var joystick: VirtualJoystick
var buttons: Array[Button] = []
var direction_buttons: Array[Button] = []
var walk_button: Button
var attack_button: Button
var dex_button: Button
var zoom_button: Button
var direction_index := 3
var automatic_walk := false
var attacks_enabled := true
var dexterity := 0
var inspection_zoom := true
var walk_time := 0.0
var qa_bridge_left := 0.0

func _ready() -> void:
	get_window().content_scale_size = get_window().size
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var background := ColorRect.new()
	background.color = Color("#253a2f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	heading = _label("ARCO · PRIMEIRO PASSE",26,Color("#fff0cc"))
	subtitle = _label("1–4: direção · R: repetir · V: caminhar · P: pausar",15,Color("#cccfab"))
	_create_panel(false)
	_create_panel(true)
	for i in range(4):
		var button := _button(LABELS[i],func(): select_direction(i))
		direction_buttons.append(button)
	walk_button = _button("Caminhar: não",_toggle_walk)
	attack_button = _button("Ataque: automático",_toggle_attacks)
	dex_button = _button("Destreza: 0",_toggle_dex)
	zoom_button = _button("Zoom: ampliar",_toggle_zoom)
	joystick = VirtualJoystick.new()
	add_child(joystick)
	joystick.direction_changed.connect(_on_stick)
	var dash_button := _button("Repetir",_repeat)
	dash_button.name = "RepeatButton"
	status = _label("",15,Color("#fff0cc"))
	footnote = _label("WASD / setas ou analógico · Espaço: Dash\nSomente demonstração. Seu save e o TESTE fixo estão preservados.",13,Color("#cccfab"))
	resized.connect(_layout)
	get_viewport().size_changed.connect(_on_window_resized)
	select_direction(direction_index)
	_layout()
	if OS.has_feature("web"):
		# Read-only QA bridge on the isolated entry; no journal or player data.
		JavaScriptBridge.eval("window.BowDemoReady = true;")

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size",15)
	button.add_theme_color_override("font_color",Color("#fff0cc"))
	for state in ["normal","hover","pressed","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#466345") if state == "pressed" or state == "hover" else Color("#354c36")
		style.border_color = Color("#ba975e")
		style.set_border_width_all(2)
		style.set_content_margin_all(6)
		button.add_theme_stylebox_override(state,style)
	button.pressed.connect(callback)
	add_child(button)
	buttons.append(button)
	return button

func _create_panel(updated: bool) -> void:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#ead7a8")
	style.border_color = Color("#9c7546")
	style.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel",style)
	add_child(panel)
	panels.append(panel)
	var label := Label.new()
	label.text = "AGORA · braços, arco e corda" if updated else "ANTES · flecha atual"
	label.position = Vector2(14,9)
	label.add_theme_font_size_override("font_size",16)
	label.add_theme_color_override("font_color",Color("#523b28"))
	panel.add_child(label)
	var container := SubViewportContainer.new()
	container.position = Vector2(5,40)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(container)
	var viewport := SubViewport.new()
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	container.add_child(viewport)
	viewports.append(viewport)
	var origin := Vector2(1800+3000*players.size(),1200)
	origins.append(origin)
	var field := Node2D.new()
	viewport.add_child(field)
	var ground := Polygon2D.new()
	ground.polygon = PackedVector2Array([Vector2(-800,-800),Vector2(800,-800),Vector2(800,800),Vector2(-800,800)])
	ground.color = Color("#b7ca64")
	ground.position = origin
	field.add_child(ground)
	var path := Polygon2D.new()
	path.polygon = PackedVector2Array([Vector2(-800,-8),Vector2(-30,-18),Vector2(800,6),Vector2(800,55),Vector2(-60,35),Vector2(-800,48)])
	path.color = Color("#f3d38b")
	path.position = origin
	field.add_child(path)
	var driver := InputDriver.new()
	field.add_child(driver)
	drivers.append(driver)
	var player := preload("res://scenes/actors/player.tscn").instantiate() as PlayerActor
	if updated:
		player.set_script(NEW_PLAYER)
		player.stats = preload("res://data/actors/player.tres")
		player.get_node("View").set_script(NEW_VIEW)
	else:
		player.get_node("View").set_script(preload("res://scripts/presentation/actor_view.gd"))
	player.position = origin
	player.input_driver = driver
	(player.get_node("View") as ActorView).village_scale = true
	(player.get_node("Camera2D") as Camera2D).enabled = false
	field.add_child(player)
	# A default established character is created in memory only; never load/save.
	var memory := GameProgress.new()
	memory.equipment["arco"] = 0
	memory.equipped.Arma = "arco"
	player.apply_progression(memory,true)
	player.attack.projectile_requested.connect(func(shooter: Node2D, selected: Node2D, spec: Dictionary):
		var arrow := PROJECTILE.new() if updated else PlayerProjectile.new()
		field.add_child(arrow)
		arrow.setup(shooter,selected,spec,Rect2())
	)
	players.append(player)
	var target := preload("res://scenes/actors/enemy.tscn").instantiate()
	target.set_script(TARGET)
	target.stats = preload("res://data/actors/player.tres")
	target.get_node("View").set_script(preload("res://scripts/demos/bow_training_view.gd"))
	target.position = origin+DIRECTIONS[direction_index]*160
	field.add_child(target)
	targets.append(target)
	var camera := Camera2D.new()
	camera.position = origin+Vector2(0,-18)
	field.add_child(camera)
	cameras.append(camera)
	# Same world layer that the player/dash already collides with, outside the stand.
	for rect: Rect2 in [Rect2(-240,-240,480,6),Rect2(-240,234,480,6),Rect2(-240,-240,6,480),Rect2(234,-240,6,480)]:
		var wall := StaticBody2D.new()
		wall.position = origin+rect.get_center()
		wall.collision_layer = 1
		var collider := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collider.shape = shape
		wall.add_child(collider)
		field.add_child(wall)

func select_direction(index: int) -> void:
	for arrow in get_tree().get_nodes_in_group("player_projectiles"):
		arrow.finish()
	direction_index = index
	walk_time = 0
	for i in range(players.size()):
		players[i].position = origins[i]
		players[i].velocity = Vector2.ZERO
		players[i].dash.time_left = 0
		players[i].view.set_moving(false)
		players[i].view.set_facing(DIRECTIONS[index])
		players[i].attack.cooldown_left = players[i].attack.weapon.interval
		players[i].view.attack_left = 0
		if players[i].view is NEW_VIEW:
			players[i].view.bow_time = 0
			players[i].view.cancel_preparation()
		targets[i].position = origins[i]+DIRECTIONS[index]*160
		cameras[i].position = origins[i]+Vector2(0,-18)+DIRECTIONS[index]*70
	for i in range(direction_buttons.size()):
		direction_buttons[i].text = ("• " if i == index else "")+LABELS[i]
	_layout()

func _toggle_walk() -> void:
	automatic_walk = not automatic_walk
	walk_button.text = "Caminhar: sim" if automatic_walk else "Caminhar: não"
	for driver in drivers: driver.reset()

func _toggle_attacks() -> void:
	attacks_enabled = not attacks_enabled
	attack_button.text = "Ataque: automático" if attacks_enabled else "Ataque: pausado"
	for target in targets: target.enabled = attacks_enabled
	if not attacks_enabled:
		for player in players:
			if player.view is NEW_VIEW: player.view.cancel_preparation()

func _toggle_dex() -> void:
	dexterity = 20 if dexterity == 0 else 0
	dex_button.text = "Destreza: %d" % dexterity
	for player in players:
		player.progress.attributes.Destreza = dexterity
		player.apply_progression(player.progress)

func _toggle_zoom() -> void:
	inspection_zoom = not inspection_zoom
	zoom_button.text = "Zoom: ampliar" if inspection_zoom else "Zoom: jogo"
	_layout()

func _on_stick(value: Vector2) -> void:
	if not value.is_zero_approx():
		automatic_walk = false
		walk_button.text = "Caminhar: não"
	for driver in drivers: driver.set_touch_direction(value)

func _physics_process(delta: float) -> void:
	walk_time += delta
	if automatic_walk:
		# Slow sideways travel exercises original gait without chasing the stand.
		var movement: Vector2 = DIRECTIONS[direction_index].orthogonal()*cos(walk_time*3)*0.28
		for driver in drivers: driver.set_touch_direction(movement)

func _process(delta: float) -> void:
	if players.size() < 2: return
	var phase_index: int = players[1].view.phase()
	var description: String = ["Preparação","Tensão","Disparo","Recuperação"][phase_index] if phase_index >= 0 else "Caminhada" if players[1].view.walking else "Repouso"
	status.text = "%s · %s\nIntervalo real: %.3f s · Acertos: %d" % [LABELS[direction_index],description,players[1].attack.weapon.interval,targets[1].hits]
	if OS.has_feature("web"):
		qa_bridge_left -= delta
		if qa_bridge_left <= 0:
			qa_bridge_left = 0.25
			JavaScriptBridge.eval("window.BowDemoState = %s;" % JSON.stringify({"hits":targets[1].hits,"direction":direction_index,"interval":players[1].attack.weapon.interval,"walking":players[1].view.walking,"writes":players[1].progress.disk_writes,"shots":players[1].view.bow_attacks,"phase":phase_index,"projectiles":get_tree().get_nodes_in_group("player_projectiles").size()}))

func _input(event: InputEvent) -> void:
	# Mouse emulation is disabled in this project; touch must activate UI directly.
	if event is InputEventScreenTouch and event.pressed:
		for button in buttons:
			if button.get_global_rect().has_point(event.position):
				button.pressed.emit()
				get_viewport().set_input_as_handled()
				return

func _on_window_resized() -> void:
	var window := get_window()
	if window.content_scale_size != window.size: window.content_scale_size = window.size
	_layout()

func _layout() -> void:
	if viewports.size() < 2 or joystick == null: return
	var area := get_viewport_rect().size
	var portrait := area.x < 700
	var short_landscape := area.y < 520 and not portrait
	heading.position = Vector2(20,14)
	heading.add_theme_font_size_override("font_size",21 if portrait else 26)
	subtitle.position = Vector2(20,45)
	subtitle.add_theme_font_size_override("font_size",11 if portrait else 14)
	var control_y := area.y-220
	var available := control_y-84
	for i in range(2):
		panels[i].position = Vector2(16,76+i*(available/2+6)) if portrait else Vector2(20+i*(area.x/2-12),80)
		panels[i].size = Vector2(area.x-32,available/2-6) if portrait else Vector2(area.x/2-28,available)
		if short_landscape:
			panels[i].position = Vector2(12+i*(area.x-352)/2,76)
			panels[i].size = Vector2((area.x-352)/2-8,area.y-88)
			(panels[i].get_child(0) as Label).text = "AGORA · arco V1" if i == 1 else "ANTES · ataque atual"
		else:
			(panels[i].get_child(0) as Label).text = "AGORA · braços, arco e corda" if i == 1 else "ANTES · flecha atual"
		var container := panels[i].get_child(1) as SubViewportContainer
		container.size = panels[i].size-Vector2(10,45)
		var span := Vector2(330,180) if direction_index >= 2 else Vector2(200,330)
		var zoom := minf(1.6,minf(container.size.x/span.x,container.size.y/span.y)) if inspection_zoom else minf(1.0,minf(container.size.x/span.x,container.size.y/span.y))
		cameras[i].zoom = Vector2.ONE*maxf(0.55,zoom)
	for i in range(4):
		direction_buttons[i].position = Vector2(16+i*(area.x-32)/4,control_y)
		direction_buttons[i].size = Vector2((area.x-32)/4-4,38)
	for i in range(4):
		buttons[4+i].position = Vector2(16+(i%2)*(area.x-32)/2,control_y+46+(i/2)*38)
		buttons[4+i].size = Vector2((area.x-32)/2-4,34)
	joystick.position = Vector2(20,area.y-92)
	joystick.size = Vector2(78,78)
	buttons[8].position = Vector2(110,area.y-77)
	buttons[8].size = Vector2(70,48)
	status.position = Vector2(186,area.y-87)
	status.add_theme_font_size_override("font_size",12 if portrait else 15)
	footnote.position = Vector2(20,area.y-8)
	footnote.visible = false # Header and panel captions explain the scene on mobile.
	if short_landscape:
		for i in range(4):
			direction_buttons[i].position = Vector2(area.x-334+(i%2)*160,24+(i/2)*38)
			direction_buttons[i].size = Vector2(154,34)
			buttons[4+i].position = Vector2(area.x-334+(i%2)*160,106+(i/2)*38)
			buttons[4+i].size = Vector2(154,34)
		joystick.position = Vector2(area.x-334,area.y-98)
		buttons[8].position = Vector2(area.x-240,area.y-82)
		status.position = Vector2(area.x-334,202)

func _repeat() -> void:
	if not attacks_enabled: _toggle_attacks()
	select_direction(direction_index)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_1: select_direction(0)
		KEY_2: select_direction(1)
		KEY_3: select_direction(2)
		KEY_4: select_direction(3)
		KEY_R: _repeat()
		KEY_V: _toggle_walk()
		KEY_P: _toggle_attacks()
		KEY_X: _toggle_dex()
		KEY_Z: _toggle_zoom()
