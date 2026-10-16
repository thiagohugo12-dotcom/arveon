extends "res://scripts/main.gd"

# This scene inherits the existing world/Player/HUD but DOES NOT execute the
# campaign's _ready, _process or save lifecycle. No campaign file is read.
const LOADOUT := preload("res://scripts/training/training_loadout.gd")
const MENU_SCRIPT := preload("res://ui/training_menu.gd")
var training_menu: TrainingMenu
var targets: Array[EnemyActor] = []
var training_refresh := 0.0

func _ready() -> void:
	progress = LOADOUT.build()
	earned_xp = progress.xp
	earned_gold = progress.gold
	player.position = Vector2(850, 750)
	player.last_direction = Vector2.RIGHT
	player.input_driver = input_driver
	player.attack.projectile_requested.connect(_on_player_projectile)
	player.view.damage_occluders = hud.damage_occluders
	player.health.changed.connect(hud.set_health)
	player.health.died.connect(func(): _refill())
	hud.movement_changed.connect(input_driver.set_touch_direction)
	hud.dash_pressed.connect(input_driver.request_dash)
	hud.skill_pressed.connect(_use_skill)
	hud.minimap.progress = progress
	hud.minimap.player_position = player.position
	exploration_view.progress = progress
	exploration_view.current_time = int(Time.get_unix_time_from_system())
	tower_view.set_state(false, false)
	player.apply_progression(progress, true)
	_update_floor_identity()
	hud.heading.text = "TREINO · SEM SAVE"
	hud.set_progress(progress.xp, progress.gold, 0, "Treine sem consumir recursos")
	hud.set_mission("Arena de treinamento\nAtaque os três alvos imóveis.")
	hud.set_health(player.health.current,player.health.maximum)
	hud.inventory_button.hide()
	hud.character_button.hide()
	hud.map_button.hide()
	hud.mission_toggle.hide()
	hud.minimap.hide()
	hud.record_button.hide()
	hud._layout()
	_register_target(enemy,Vector2(920,750))
	for i in range(2):
		var target := _make_enemy(i+1)
		add_child(target)
		_register_target(target,Vector2(995 if i == 0 else 1035,705 if i == 0 else 795))
	training_menu = MENU_SCRIPT.new() as TrainingMenu
	hud.add_child(training_menu)
	training_menu.loadout_requested.connect(_equip)
	training_menu.refill_requested.connect(_refill)
	training_menu.exit_requested.connect(_leave)
	training_menu.menu_toggled.connect(_toggle_menu)
	training_menu.initialize(progress)
	get_window().size_changed.connect(_adapt_orientation)
	_adapt_orientation()

func _register_target(actor: EnemyActor, at: Vector2) -> void:
	actor.position = at
	actor.target = player
	actor.collision_layer = 0
	actor.collision_mask = 0
	actor.set_physics_process(false) # Targets cannot move, attack or retaliate.
	actor.health.initialize(1000000)
	_register_enemy_defeat(actor) # Reuse the real damage, hit and visual feedback.
	actor.view.damage_occluders = hud.damage_occluders
	targets.append(actor)

func _process(delta: float) -> void:
	# Physical combat and PlayerActor.use_skill stay real. Only their sandbox
	# state is replenished, with no disk/network persistence.
	LOADOUT.refill(progress)
	if is_instance_valid(player):
		hud.set_dash_cooldown(player.dash.cooldown_left)
	training_refresh -= delta
	if training_refresh <= 0.0:
		training_refresh = 0.1
		hud.set_rpg_status(progress,player)
		hud.heading.text = "TREINO · SEM SAVE"

func _toggle_menu(opened: bool) -> void:
	input_driver.reset()
	input_driver.blocked = opened
	if opened:
		hud.joystick.reset()

func _equip(category: String, skill2: String, skill3: String, passive1: String, passive2: String, specialization: String) -> void:
	if not LOADOUT.equip(progress,category,skill2,skill3,passive1,passive2,specialization):
		hud.show_notice("Escolha inválida. Selecione técnicas/passivas diferentes.")
		return
	for projectile in get_tree().get_nodes_in_group("player_projectiles"):
		if is_instance_valid(projectile): projectile.queue_free()
	player.class_combat.clear_effects()
	player.apply_progression(progress)
	player.health.initialize(player.health.maximum)
	player._cancel_skill1()
	player.attack.cooldown_left = 0
	player.attack.search_left = 0
	training_menu.show_menu(false)
	hud.set_rpg_status(progress,player)
	hud.show_notice("%s: todas as técnicas disponíveis" % ArsenalRules.CATEGORIES[category].name)

func _refill() -> void:
	LOADOUT.reset_combat(progress)
	if is_instance_valid(player):
		player.class_combat.clear_effects()
		player.health.initialize(player.health.maximum)
		player.attack.cooldown_left = 0
		player.attack.search_left = 0
	for target in targets:
		if is_instance_valid(target):
			target.health.initialize(1000000)
			target.control_left = 0.0
			target.mark_left = 0.0
	hud.show_notice("Alvos restaurados · vida e carga completas")

func _leave() -> void:
	# The only way back is a fresh normal scene, which loads the untouched save.
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo(): return
	if event.is_action_pressed("ui_cancel"):
		if training_menu.active: training_menu.show_menu(false)
		else: training_menu.show_menu(true)
		get_viewport().set_input_as_handled()
		return
	if training_menu.active or input_driver.blocked: return
	for i in range(3):
		if event.is_action_pressed(["skill_1","skill_2","ultimate"][i]):
			_use_skill(i)
			get_viewport().set_input_as_handled()
			return

func _save_progress() -> void:
	pass # Explicitly block parent autosaves, notifications, and station callbacks.

func _notification(_what: int) -> void:
	pass # Never read/write actual campaign data on pause, blur or close.

func _on_enemy_defeated(_kind: int, _source: EnemyActor = null) -> void:
	pass # No campaign XP, drops, quests or floor progression.

func _on_player_died() -> void:
	_refill() # Death never costs items inside training.
