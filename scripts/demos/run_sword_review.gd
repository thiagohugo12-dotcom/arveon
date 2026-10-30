extends Control
## Local review of the live presentation, using real combat and memory-only progress.
const PLAYER := preload("res://scenes/actors/player.tscn")
const ENEMY := preload("res://scenes/actors/enemy.tscn")
const ACTIONS := ["Básico", "Estocada Precisa", "Guarda Reativa", "Kamusari"]
var player: PlayerActor
var enemy: EnemyActor
var world: Node2D
var runners: Array[ActorView] = []
var status: Label
var action := 0
var direction := Vector2.RIGHT
var elapsed := 0.0
var started := false
var blocked := false
var paused := false
var rate := 1.0
var impacts := 0
var stage: SubViewport
var action_choice: OptionButton
var running_choice: CheckButton
var capture := false
var capture_frame := 0
var attack_running := false

func label_at(text: String, at: Vector2, dimensions: Vector2, font_size: int = 16) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = dimensions
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label

func _ready() -> void:
	get_window().size = Vector2i(360,800)
	get_window().content_scale_size = Vector2i(360,800)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	CombatRules.random_roll_source = func(): return 0.99
	var bg := ColorRect.new()
	bg.color = Color("202b26")
	bg.size = Vector2(360,800)
	add_child(bg)
	label_at("ARVÉON · Corrida e espada",Vector2(8,8),Vector2(344,28),20)
	label_at("Prévia local • personagem original\nProgresso temporário, sem salvar",Vector2(8,40),Vector2(344,42),14)
	var moving_choice := CheckButton.new()
	running_choice = moving_choice
	moving_choice.text = "Atacar correndo"
	moving_choice.position = Vector2(8,82)
	moving_choice.toggled.connect(func(value: bool): attack_running=value; reset_cast())
	add_child(moving_choice)
	var pause_button := Button.new()
	pause_button.text = "Pausar"
	pause_button.position = Vector2(262,82)
	pause_button.size = Vector2(86,32)
	pause_button.pressed.connect(func(): paused=not paused; pause_button.text="Continuar" if paused else "Pausar")
	add_child(pause_button)
	for index in range(4):
		var view := ActorView.new()
		view.village_scale = true
		view.position = Vector2(90+180*(index%2),176+126*(index/2))
		add_child(view)
		view.set_process(false)
		view.set_facing(SwordActorView.DIRECTIONS[index])
		view.set_moving(true)
		runners.append(view)
		label_at(["Frente","Costas","Esquerda","Direita"][index],view.position+Vector2(-60,18),Vector2(120,24),14)
	var select := OptionButton.new()
	action_choice = select
	for name in ACTIONS: select.add_item(name)
	select.position = Vector2(12,350)
	select.size = Vector2(208,40)
	select.item_selected.connect(func(index: int): action=index; reset_cast())
	add_child(select)
	var speed := Button.new()
	speed.text = "0,5× / 1×"
	speed.position = Vector2(226,350)
	speed.size = Vector2(122,40)
	speed.pressed.connect(func(): rate=0.5 if rate==1.0 else 1.0)
	add_child(speed)
	var container := SubViewportContainer.new()
	container.position = Vector2(0,398)
	container.size = Vector2(360,286)
	add_child(container)
	stage = SubViewport.new()
	stage.size = Vector2i(360,286)
	stage.own_world_3d = false
	stage.world_2d = World2D.new()
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(stage)
	world = Node2D.new()
	stage.add_child(world)
	var camera := Camera2D.new()
	camera.position = Vector2(1100,450)
	camera.zoom = Vector2(0.8,0.8)
	world.add_child(camera)
	for index in range(4):
		var button := Button.new()
		button.text = ["Frente","Costas","Esq.","Dir."][index]
		button.position = Vector2(8+86*index,692)
		button.size = Vector2(82,38)
		button.pressed.connect(func(): direction=SwordActorView.DIRECTIONS[index]; reset_cast())
		add_child(button)
	status = label_at("",Vector2(8,738),Vector2(344,58),14)
	reset_cast()
	capture = OS.get_environment("ARVEON_ANIMATION_CAPTURE") == "1"
	if capture:
		set_process(false)
		capture_review.call_deferred()

func reset_cast() -> void:
	if is_instance_valid(player): player.free()
	if is_instance_valid(enemy): enemy.free()
	player = PLAYER.instantiate()
	player.get_node("Camera2D").enabled = false
	player.position = Vector2(1100,440)-direction*54
	world.add_child(player)
	player.set_physics_process(false)
	player.view.village_scale = true
	player.view.set_process(false)
	player.view.sword_technique.set_process(false)
	var driver := InputDriver.new()
	player.add_child(driver)
	player.input_driver = driver
	var progress := TrainingMode.create()
	progress.abilities.loadouts.espada.skills = ["estocada_precisa","guarda_reativa"]
	progress.abilities.loadouts.espada.ultimate = "danca_laminas"
	player.apply_progression(progress,true)
	player.last_direction = direction
	player.view.set_facing(direction)
	player.attack.cooldown_left = 100
	player.attack.attacked.connect(func(_target: Node2D): impacts+=1)
	player.class_combat.technique_impact.connect(func(_id: String,_time: float): impacts+=1)
	enemy = ENEMY.instantiate()
	enemy.position = Vector2(1100,440)+direction*55
	world.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.view.village_scale = true
	enemy.view.set_process(false)
	enemy.health.initialize(1000000)
	enemy.target = player
	elapsed=0
	started=false
	blocked=false
	impacts=0
	action_choice.select(action)
	running_choice.set_pressed_no_signal(attack_running)

func advance(delta: float) -> void:
	elapsed += delta
	# The review controls displacement only; the live movement speed is read unchanged.
	var approach := elapsed < 0.30 or (elapsed > 2.0 and elapsed < 2.30)
	var strafing := attack_running and elapsed>=0.55 and elapsed<1.1
	var moving := approach or strafing
	var travel := direction.orthogonal() if strafing else direction
	if moving: player.position += travel*player.stats.move_speed*delta
	player.view.set_facing(travel if moving else direction)
	player.view.set_moving(moving)
	for runner in runners:
		runner.set_moving(fmod(elapsed,3.0)<2.4)
		runner.run_distance=fmod(runner.run_distance+player.stats.move_speed*delta,ExplorerRunPose.STRIDE)
		runner.queue_redraw()
	if not started and elapsed >= 0.65:
		started=true
		if action==0:
			player.attack.cooldown_left=0
			player.attack.search_left=0
			player.attack.tick(0,player)
		elif action==1: player.use_skill(1)
		elif action==2: player.use_skill(2)
		else: player.use_skill(3)
	elif not started and elapsed >= 0.58 and action==0:
		player.view.prepare_sword(direction,0.65-elapsed)
	if action==2 and not blocked and elapsed>=1.20:
		blocked=true
		player.receive_damage(8)
	player.class_combat.tick(delta)
	player.view._process(delta)
	# Guard owns its existing independent clock; other sword skills use ClassCombat.
	if action==2: player.view.sword_technique._process(delta)
	enemy.view._process(delta)
	status.text="%s • %s\nDano real no alvo: %d • impactos: %d" % [ACTIONS[action],"bloqueio acionado" if blocked else "reprodução",enemy.health.maximum-enemy.health.current,impacts]

func _process(delta: float) -> void:
	if paused: return
	advance(minf(delta,0.05)*rate)
	if elapsed>4.4: reset_cast()

func capture_review() -> void:
	var output := ProjectSettings.globalize_path("res://build/run-sword-review")
	DirAccess.make_dir_recursive_absolute(output)
	var sequence_count := 1 if OS.get_environment("ARVEON_RUN_ONLY") == "1" else 8
	for sequence in range(sequence_count):
		action=sequence%4
		attack_running=sequence>=4
		reset_cast()
		for frame in range(126):
			advance(1.0/30.0)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(output.path_join("%d_%03d.png" % [sequence,frame]))
	print("RUN_SWORD_CAPTURE_OK: %d frames at 360x800" % (sequence_count*126))
	CombatRules.random_roll_source = Callable()
	player.queue_free()
	enemy.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
