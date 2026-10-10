extends Node2D

const ARENA_SCENE := preload("res://scenes/world/tower_arena.tscn")
var trial := TowerTrial.new()
var tower_guardian: TowerGuardian
var victory_first := false
const TOWER_GUARDIAN_SCRIPT = preload("res://scripts/actors/tower_guardian.gd")
const TOWER_GUARDIAN_VIEW = preload("res://scripts/presentation/tower_guardian_view.gd")
var arena: Node2D
var transitioning := false
var autosave_left := 30.0
var pending_import := ""
var save_dialog: FileDialog
@onready var world: Node2D = $Andar1

const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/enemy.tscn")
const PROJECTILE_SCRIPT := preload("res://scripts/components/enemy_projectile.gd")
const GUARDIAN_SCRIPT = preload("res://scripts/actors/root_guardian.gd")
const GUARDIAN_VIEW = preload("res://scripts/presentation/guardian_view.gd")
const GUARDIAN_ALTAR := Vector2(1060, 155)
var guardian: EnemyActor

const MAX_ENEMIES := 5
const SPAWN_INTERVAL := 2.8
const ENEMY_POSITIONS := [
	Vector2(850, 400), Vector2(930, 440), Vector2(610, 750),
	Vector2(180, 460), Vector2(630, 135), Vector2(955, 665)
]

@onready var player: PlayerActor = $Player
@onready var enemy: EnemyActor = $Enemy
@onready var input_driver: InputDriver = $InputDriver
@onready var hud: GameHUD = $Interface/HUD
@onready var exploration_view: ExplorationView = $Andar1/ExploreView
@onready var tower_view: TowerView = $Andar1/TowerView

var spawn_remaining: float = SPAWN_INTERVAL
var spawn_count: int = 0
var defeated_count: int = 0
var earned_xp: int = 0
var earned_gold: int = 0
var collected_materials: Dictionary = {}
var loot_rng := RandomNumberGenerator.new()
var mission := CommonMission.new()
var mission_reward_message: String = ""
var progress := GameProgress.new()
var station_nearby := ""
var activity_remaining := 0.0
var exploration_refresh := 0.0
var rpg_refresh := 0.0
var known_level := 1

func _ready() -> void:
	var test_save := OS.get_environment("GRANDE_ARVORE_SAVE_PATH")
	if not test_save.is_empty():
		progress.save_path = test_save
	if progress.load_save():
		earned_xp = progress.xp
		earned_gold = progress.gold
		defeated_count = progress.kills
		mission.mission_index = progress.mission_index
		mission.progress = progress.mission_progress
		mission.completed_count = progress.mission_completed
	collected_materials = progress.bag
	hud.minimap.progress = progress
	hud.minimap.player_position = player.global_position
	hud.minimap.queue_redraw()
	exploration_view.progress = progress
	exploration_view.current_time = int(Time.get_unix_time_from_system())
	exploration_view.queue_redraw()
	mission.completed.connect(_on_mission_completed)
	loot_rng.randomize()
	hud.tower_trial = trial
	player.input_driver = input_driver
	player.view.damage_occluders = hud.damage_occluders
	enemy.view.damage_occluders = hud.damage_occluders
	enemy.target = player
	_register_enemy_defeat(enemy)
	enemy.projectile_requested.connect(_on_enemy_projectile)
	hud.movement_changed.connect(input_driver.set_touch_direction)
	hud.dash_pressed.connect(input_driver.request_dash)
	hud.interact_pressed.connect(_interact)
	hud.inventory_toggled.connect(_toggle_inventory)
	hud.save_requested.connect(_open_record)
	hud.save_panel.action_requested.connect(_save_action)
	hud.character_toggled.connect(_toggle_character)
	hud.map_toggled.connect(_toggle_map)
	hud.skill_pressed.connect(_use_skill)
	hud.rpg_action.connect(_rpg_action)
	hud.station_action.connect(_station_action)
	hud.panel_closed.connect(func():
		input_driver.reset()
		input_driver.blocked = false
		station_nearby = ""
	)
	hud.restart_pressed.connect(func(): get_tree().reload_current_scene())
	player.health.changed.connect(hud.set_health)
	player.health.died.connect(hud.show_death)
	player.health.died.connect(_on_player_died)
	player.apply_progression(progress, true)
	known_level = progress.level()
	hud.set_health(player.health.current, player.health.maximum)
	hud.set_progress(earned_xp, earned_gold, defeated_count, "")
	_refresh_mission()
	get_window().size_changed.connect(_adapt_orientation)
	_adapt_orientation()
	tower_view.set_state(progress.ascension.entrance_unlocked(), TowerEntrance.is_near(player.global_position))
	_save_progress()
	if OS.has_feature("web"):
		progress.browser.watch_hidden(_save_progress)
	if progress.save_blocked:
		hud.show_notice(progress.save_status)
		hud.notice_left = 12.0

func _process(delta: float) -> void:
	autosave_left -= delta
	if autosave_left <= 0.0:
		autosave_left = 30.0
		_save_progress()
	if transitioning:
		return
	hud.set_dash_cooldown(player.dash.cooldown_left)
	rpg_refresh -= delta
	if rpg_refresh <= 0.0:
		rpg_refresh = 0.1
		hud.set_rpg_status(progress, player)
	if not player.health.is_alive():
		return
	if trial.active():
		_process_trial(delta)
		return
	exploration_refresh -= delta
	if exploration_refresh <= 0.0:
		exploration_refresh = 1.0
		exploration_view.current_time = int(Time.get_unix_time_from_system())
		exploration_view.queue_redraw()
	activity_remaining -= delta
	if activity_remaining <= 0.0:
		activity_remaining = 0.25
		if progress.discover_nearby(player.global_position):
			_save_progress()
			hud.minimap.queue_redraw()
		hud.minimap.update_player(player.global_position)
		for actor in get_tree().get_nodes_in_group("damageable_enemies"):
			if actor is EnemyActor:
				actor.update_activity(player.global_position)
	var near := _interaction_target().get("label", "") as String
	tower_view.set_state(progress.ascension.entrance_unlocked(), TowerEntrance.is_near(player.global_position))
	if near != station_nearby and not hud.station_panel.visible:
		station_nearby = near
		hud.set_nearby_station(near)
	spawn_remaining -= delta
	if spawn_remaining <= 0.0:
		spawn_remaining = SPAWN_INTERVAL
		if get_tree().get_nodes_in_group("damageable_enemies").size() < MAX_ENEMIES:
			_spawn_enemy()

func _make_enemy(kind: int) -> EnemyActor:
	var actor := ENEMY_SCENE.instantiate() as EnemyActor
	actor.kind = kind
	# Duplicating the resource ensures variants never mutate the original enemy template.
	actor.stats = actor.stats.duplicate() as ActorData
	match actor.kind:
		1:
			actor.stats.max_hp = 30
			actor.stats.move_speed = 92.0
			actor.stats.contact_damage = 5
		2:
			actor.stats.max_hp = 64
			actor.stats.move_speed = 48.0
			actor.stats.contact_damage = 10
		3:
			actor.stats.max_hp = 120
			actor.stats.move_speed = 60.0
			actor.stats.contact_damage = 12
	return actor

func _spawn_enemy() -> void:
	if trial.active() or transitioning:
		return
	var actor := _make_enemy(3 if spawn_count % 8 == 7 else (spawn_count + 1) % 3)
	actor.position = ENEMY_POSITIONS[spawn_count % ENEMY_POSITIONS.size()]
	actor.target = player
	_register_enemy_defeat(actor)
	actor.projectile_requested.connect(_on_enemy_projectile)
	add_child(actor)
	actor.view.damage_occluders = hud.damage_occluders
	spawn_count += 1

func _on_enemy_projectile(origin: Vector2, direction: Vector2, damage: int) -> void:
	if transitioning or not player.health.is_alive():
		return
	if trial.active() and (input_driver.blocked or not TowerTrial.BOUNDS.has_point(origin)):
		return
	var projectile := Area2D.new()
	projectile.set_script(PROJECTILE_SCRIPT)
	add_child(projectile)
	projectile.setup(origin, direction, damage, player)
	if trial.active():
		projectile.arena_bounds = TowerTrial.BOUNDS

func _register_enemy_defeat(actor: EnemyActor) -> void:
	actor.set_meta("floor_id", 1)
	actor.defeated.connect(_on_enemy_defeated.bind(actor), CONNECT_ONE_SHOT)

func _on_enemy_defeated(kind: int, source: EnemyActor = null) -> void:
	if transitioning:
		return
	if source != null:
		# A defeat must come from a registered, actually dead creature in this
		# world. The per-life guard also rejects manual/reentrant duplicate events.
		if source.get_parent() != self or source.health.is_alive() or source.get_meta("defeat_recorded", false):
			return
		if trial.active() and source.get_meta("tower_attempt", -1) != trial.attempt_id:
			return
		source.set_meta("defeat_recorded", true)
		if progress.ascension.current_floor == 1 and source.get_meta("floor_id", 0) == 1:
			progress.ascension.record_defeat(1)
	defeated_count += 1
	var gained_xp: int = [12, 10, 16, 35, 80][kind]
	var gained_gold := loot_rng.randi_range(2, 5)
	earned_xp += gained_xp
	earned_gold += gained_gold
	var material: String = ["Couro", "Seda", "Essência", "Couro", "Essência"][kind]
	collected_materials[material] = int(collected_materials.get(material, 0)) + 1
	var drop_text := "+%d XP · +%d ouro · +1 %s" % [gained_xp, gained_gold, material]
	if kind == 3:
		_record_adventure("elite")
	elif kind == 4:
		_record_adventure("guardiao")
	mission.record_defeat()
	mission.record_material()
	if loot_rng.randf() < 0.01:
		collected_materials["Broto Ancestral"] = int(collected_materials.get("Broto Ancestral", 0)) + 1
		drop_text += " · Broto Ancestral raro!"
	if not mission_reward_message.is_empty():
		drop_text += " · " + mission_reward_message
		mission_reward_message = ""
	hud.set_progress(earned_xp, earned_gold, defeated_count, drop_text)
	_refresh_mission()
	_save_progress()
	if source != null and trial.active() and trial.record_defeat(source.get_instance_id(), not source.health.is_alive(), int(source.get_meta("tower_attempt", -1))):
		for node in get_children():
			if node is EnemyProjectile:
				node.set_physics_process(false)
				node.queue_free()
		if trial.phase == TowerTrial.Phase.INTERVAL:
			var restored := player.health.heal(ceili(player.health.maximum * 0.15))
			hud.show_notice("Horda %d superada! +%d HP · próxima em 4s" % [trial.wave, restored])
		else:
			hud.show_notice("Três hordas superadas! O Guardião desperta em 4s.")
		_refresh_mission()

func _on_mission_completed(xp_reward: int, gold_reward: int) -> void:
	earned_xp += xp_reward
	earned_gold += gold_reward
	mission_reward_message = "Missão concluída! +%d XP, +%d ouro" % [xp_reward, gold_reward]
	hud.show_notice(mission_reward_message)
	_save_progress()

func _save_progress() -> void:
	progress.xp = earned_xp
	player.apply_progression(progress)
	progress.gold = earned_gold
	progress.kills = defeated_count
	progress.mission_index = mission.mission_index
	progress.mission_progress = mission.progress
	progress.mission_completed = mission.completed_count
	_refresh_mission()
	if progress.level() > known_level:
		known_level = progress.level()
		hud.show_notice("Level Up! Nível %d · %d pontos de atributo · %d de habilidade" % [known_level, progress.attribute_points(), progress.skill_points()])
		player.view.flash()
	if hud.inventory_open:
		hud.refresh_inventory(progress)
	if not progress.save():
		push_warning("Não foi possível salvar o progresso local.")
		hud.show_notice(progress.save_status if not progress.save_status.is_empty() else "Falha no save local. Abra Mochila → Registro e exporte um backup.")
	hud.set_rpg_status(progress, player)

func _on_player_died() -> void:
	if player.health.is_alive() or transitioning:
		return
	input_driver.reset()
	input_driver.blocked = false
	var lost := progress.death_loss()
	hud.set_progress(earned_xp, earned_gold, defeated_count,
		"Perdeu 1 " + lost + " da mochila; baú protegido" if not lost.is_empty() else "Baú protegido · sem material na mochila")
	_save_progress()
	if trial.active():
		_return_from_trial(true)

func _toggle_inventory() -> void:
	if transitioning or hud.save_panel.visible:
		return
	if hud.inventory_open:
		hud.close_inventory()
		input_driver.blocked = false
		station_nearby = ""
	elif player.health.is_alive() and not hud.station_panel.visible and not hud.rpg_panel.visible and not hud.map_panel.visible:
		input_driver.reset()
		input_driver.blocked = true
		hud.show_inventory(progress)

func _interact() -> void:
	if transitioning:
		return
	if not player.health.is_alive() or hud.station_panel.visible or hud.inventory_open or hud.rpg_panel.visible or hud.map_panel.visible:
		return
	var found := _interaction_target()
	match found.get("kind", ""):
		"arena_exit":
			input_driver.reset()
			input_driver.blocked = true
			hud.show_station(TowerEntrance.NAME, progress)
		"tower":
			if not progress.ascension.entrance_unlocked():
				hud.show_notice("A Torre exige 50 criaturas derrotadas. Progresso: %d/50." % progress.ascension.defeats["1"])
				hud.notice_left = 5.0
				return
			input_driver.reset()
			input_driver.blocked = true
			hud.show_station(TowerEntrance.NAME, progress)
		"guardian":
			_start_guardian()
		"station":
			input_driver.reset()
			input_driver.blocked = true
			hud.show_station(found.id, progress)
		"resource":
			var item := progress.collect_resource(found.id, int(Time.get_unix_time_from_system()))
			if item.is_empty():
				return
			_record_adventure("explorar")
			mission.record_material()
			var resource_text := "Coletou +1 " + item
			if not mission_reward_message.is_empty():
				resource_text += " · " + mission_reward_message
				mission_reward_message = ""
			_save_progress()
			hud.set_progress(earned_xp, earned_gold, defeated_count, resource_text)
			_refresh_mission()
			exploration_view.queue_redraw()
			station_nearby = ""
		"cache":
			var reward := progress.open_exploration_chest(found.id)
			if reward.is_empty():
				return
			earned_gold = progress.gold
			mission.record_material()
			var cache_text := "Baú escondido: +%d ouro, +1 %s" % [reward.gold, reward.item]
			if not mission_reward_message.is_empty():
				cache_text += " · " + mission_reward_message
				mission_reward_message = ""
			_save_progress()
			hud.minimap.queue_redraw()
			hud.set_progress(earned_xp, earned_gold, defeated_count, cache_text)
			_refresh_mission()
			exploration_view.queue_redraw()
			station_nearby = ""

func _interaction_target() -> Dictionary:
	if trial.active():
		if player.global_position.distance_to(TowerTrial.EXIT) <= 68.0:
			return {"kind": "arena_exit", "label": "Retornar à Mata" if trial.phase == TowerTrial.Phase.VICTORY else "Abandonar Prova"}
		return {}
	if TowerEntrance.is_near(player.global_position):
		return {"kind": "tower", "label": progress.ascension.summary()}
	if player.global_position.distance_to(GUARDIAN_ALTAR) <= 58.0 and progress.adventures.guardiao == 0 and not is_instance_valid(guardian):
		return {"kind": "guardian", "label": "Desafiar Guardião (opcional)"}
	var station := SafeCamp.nearest_station(player.global_position)
	if not station.is_empty():
		return {"kind": "station", "id": station, "label": station}
	var now := int(Time.get_unix_time_from_system())
	var resource := Exploration.resource_at(player.global_position, progress.harvested_until, now)
	var cache := Exploration.chest_at(player.global_position, progress.opened_caches)
	if not resource.is_empty() and (cache.is_empty() or player.global_position.distance_squared_to(resource.position) <= player.global_position.distance_squared_to(cache.position)):
		return {"kind": "resource", "id": resource.id, "label": "Coletar " + resource.item}
	if not cache.is_empty():
		return {"kind": "cache", "id": cache.id, "label": "Baú escondido"}
	return {}

func _station_action(action: String, item: String) -> void:
	if transitioning:
		return
	if hud.station_name == TowerEntrance.NAME and hud.station_panel.visible:
		if action == "Entrar" and not trial.active() and TowerEntrance.is_near(player.global_position):
			_enter_trial()
		elif action == "Retornar" and trial.active():
			_return_from_trial(false)
		return
	if not player.health.is_alive() or hud.station_panel.visible == false:
		return
	var success := false
	match [hud.station_name, action]:
		["Baú", "Guardar"]: success = progress.transfer(item, true)
		["Baú", "Retirar"]: success = progress.transfer(item, false)
		["Vendedor", "Comprar"]: success = progress.buy(item)
		["Vendedor", "Vender"]: success = progress.sell(item)
	if success:
		earned_gold = progress.gold
		_save_progress()
		var trade_text := "%s: 1 %s" % [action, item]
		if action == "Vender":
			trade_text += " · +%d ouro" % GameProgress.SELL_PRICE
		elif action == "Comprar":
			trade_text += " · -%d ouro" % GameProgress.BUY_PRICE
		hud.set_progress(earned_xp, earned_gold, defeated_count, trade_text)
	hud.refresh_station(progress)

func _input(event: InputEvent) -> void:
	if hud.save_panel.visible:
		if event.is_action_pressed("ui_cancel"):
			_save_action("cancel" if not pending_import.is_empty() else "close")
		if event is InputEventKey:
			get_viewport().set_input_as_handled()
		return
	if transitioning:
		return
	if event.is_echo():
		return
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_M:
		_toggle_map()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("character"):
		_toggle_character()
		get_viewport().set_input_as_handled()
		return
	for i in range(3):
		if event.is_action_pressed(["skill_1", "skill_2", "ultimate"][i]):
			_use_skill(i)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_cancel"):
		if hud.map_panel.visible:
			_toggle_map()
		elif hud.rpg_panel.visible:
			_toggle_character()
		elif hud.inventory_open:
			_toggle_inventory()
		elif hud.station_panel.visible:
			hud.close_station()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		if hud.map_panel.visible:
			_toggle_map()
		elif hud.rpg_panel.visible:
			_toggle_character()
		elif hud.inventory_open:
			_toggle_inventory()
		elif hud.station_panel.visible:
			hud.close_station()
		else:
			_interact()
		get_viewport().set_input_as_handled()

func _use_skill(index: int) -> void:
	if transitioning or hud.save_panel.visible:
		return
	player.use_skill(index)
	hud.set_rpg_status(progress, player)

func _toggle_character() -> void:
	if transitioning or hud.save_panel.visible:
		return
	if hud.rpg_panel.visible:
		hud.close_character()
		input_driver.blocked = false
		station_nearby = ""
	elif player.health.is_alive() and not hud.inventory_open and not hud.station_panel.visible and not hud.map_panel.visible:
		input_driver.reset()
		input_driver.blocked = true
		hud.show_character(progress)

func _toggle_map() -> void:
	if transitioning or hud.save_panel.visible:
		return
	if hud.map_panel.visible:
		hud.close_map()
		input_driver.blocked = false
		station_nearby = ""
	elif player.health.is_alive() and not hud.inventory_open and not hud.station_panel.visible and not hud.rpg_panel.visible:
		input_driver.reset()
		input_driver.blocked = true
		hud.show_map(progress)

func _rpg_action(action: String, id: String, expected: int) -> void:
	if not player.health.is_alive():
		return
	var success := false
	if hud.rpg_panel.visible:
		if action == "attribute":
			success = progress.allocate_attribute(id)
		elif action == "skill":
			success = progress.improve_skill(id)
	elif hud.station_panel.visible and hud.station_name == "Ferreiro" and action == "forge":
		success = progress.forge(id, expected)
	elif hud.inventory_open and hud.inventory_category == 1:
		if action == "equip":
			success = progress.equip(id)
		elif action == "unequip":
			success = progress.unequip(id)
	if not success:
		return
	if action == "forge":
		earned_gold = progress.gold
		_record_adventure("forjar")
	earned_gold = progress.gold
	player.apply_progression(progress)
	_save_progress()
	if hud.rpg_panel.visible:
		hud.rpg_panel.refresh(progress)
	elif hud.station_panel.visible:
		hud.refresh_station(progress)
	hud.show_notice("Equipamento fabricado/aprimorado" if action == "forge" else "Personagem atualizado")

func _adapt_orientation() -> void:
	var window := get_window()
	# Logical short side 360 keeps touch targets readable in either orientation.
	var desired := Vector2i(360, 640) if window.size.y > window.size.x else Vector2i(640, 360)
	if window.content_scale_size != desired:
		window.content_scale_size = desired
	hud.call_deferred("_layout")


func _record_adventure(id: String) -> void:
	progress.xp = earned_xp
	progress.gold = earned_gold
	var reward := progress.record_adventure(id)
	earned_xp = progress.xp
	earned_gold = progress.gold
	if not reward.is_empty():
		hud.show_notice("Desafio concluído! +%d XP · +%d ouro" % [reward.xp, reward.gold])

func _start_guardian() -> void:
	if trial.active() or transitioning:
		return
	if is_instance_valid(guardian) or progress.adventures.guardiao > 0:
		return
	if get_tree().get_nodes_in_group("damageable_enemies").size() >= MAX_ENEMIES:
		hud.show_notice("Elimine uma criatura antes de desafiar o Guardião")
		return
	guardian = ENEMY_SCENE.instantiate() as EnemyActor
	var template := guardian.stats.duplicate() as ActorData
	guardian.set_script(GUARDIAN_SCRIPT)
	guardian.get_node("View").set_script(GUARDIAN_VIEW)
	guardian.kind = 4
	guardian.stats = template
	guardian.stats.max_hp = 320
	guardian.stats.move_speed = 45.0
	guardian.position = GUARDIAN_ALTAR + Vector2(0, 80)
	guardian.target = player
	_register_enemy_defeat(guardian)
	guardian.projectile_requested.connect(_on_enemy_projectile)
	add_child(guardian)
	guardian.view.damage_occluders = hud.damage_occluders
	hud.show_notice("Guardião: evite as áreas douradas. Desafio opcional!")

func _refresh_mission() -> void:
	hud.set_mission(trial.summary() if trial.active() else mission.summary() + "\n" + progress.adventure_summary())

func _clear_combat_actors() -> void:
	for node in get_children():
		if node is EnemyActor or node is EnemyProjectile:
			if node is EnemyActor:
				node.remove_from_group("damageable_enemies")
				node.collision_layer = 0
				node.collision_mask = 0
			node.set_physics_process(false)
			node.queue_free()

func _camera_bounds(bounds: Rect2) -> void:
	var camera := player.get_node("Camera2D") as Camera2D
	camera.limit_left = roundi(bounds.position.x)
	camera.limit_top = roundi(bounds.position.y)
	camera.limit_right = roundi(bounds.end.x)
	camera.limit_bottom = roundi(bounds.end.y)
	camera.reset_smoothing()
	camera.force_update_scroll()

func _enter_trial() -> void:
	if transitioning or trial.active() or not player.health.is_alive() or not progress.ascension.entrance_unlocked():
		return
	transitioning = true
	hud.close_station()
	input_driver.reset()
	input_driver.blocked = true
	hud.transition_active = true
	hud._sync_controls()
	_pause_combat()
	await hud.fade_transition(true)
	_clear_combat_actors()
	remove_child(world) # Remove Mata physics, retain its unchanged scene and resources.
	arena = ARENA_SCENE.instantiate()
	add_child(arena)
	move_child(arena, 0) # Floor stays behind the existing protagonist and creatures.
	player.global_position = TowerTrial.ENTRY
	player.velocity = Vector2.ZERO
	player.charge_left = 0.0
	player.dash.time_left = 0.0
	trial.start()
	hud.heading.text = "Torre · Andar 1"
	hud.minimap.arena_bounds = TowerTrial.BOUNDS
	hud.minimap.update_player(player.global_position)
	_camera_bounds(TowerTrial.BOUNDS)
	_refresh_mission()
	_save_progress() # Saves only existing permanent progression, no attempt checkpoint.
	await hud.fade_transition(false)
	transitioning = false
	hud.transition_active = false
	input_driver.reset()
	input_driver.blocked = false
	hud._sync_controls()

func _process_trial(delta: float) -> void:
	var paused := input_driver.blocked
	for node in get_children():
		if node is EnemyActor and node.health.is_alive():
			node.set_physics_process(not paused)
			if paused:
				node.view.set_moving(false)
		elif node is EnemyProjectile:
			node.set_physics_process(not paused)
	if not paused and trial.tick(delta):
		if trial.phase == TowerTrial.Phase.GUARDIAN:
			_spawn_tower_guardian()
		else:
			_spawn_trial_wave()
	hud.set_boss(tower_guardian if is_instance_valid(tower_guardian) and tower_guardian.health.is_alive() else null)
	hud.minimap.update_player(player.global_position)
	var label: String = _interaction_target().get("label", "")
	if label != station_nearby and not hud.station_panel.visible:
		station_nearby = label
		hud.set_nearby_station(label)
	_refresh_mission()

func _spawn_trial_wave() -> void:
	if not trial.active() or trial.phase != TowerTrial.Phase.FIGHTING or not trial.pending.is_empty():
		return
	var kinds: Array = TowerTrial.WAVES[trial.wave - 1]
	var positions := trial.spawn_positions(player.global_position, kinds.size())
	assert(positions.size() == kinds.size(), "Arena must always provide separated spawn points")
	for i in range(kinds.size()):
		var actor := _make_enemy(kinds[i])
		actor.position = positions[i]
		actor.target = player
		actor.arena_bounds = TowerTrial.BOUNDS
		actor.set_meta("tower_attempt", trial.attempt_id)
		_register_enemy_defeat(actor)
		actor.projectile_requested.connect(_on_enemy_projectile)
		add_child(actor)
		actor.view.damage_occluders = hud.damage_occluders
		trial.register(actor.get_instance_id())
	hud.show_notice("Horda %d/3 — %s" % [trial.wave, ["Iniciação", "Resistência", "Sobrevivência"][trial.wave - 1]])

func _return_from_trial(died: bool = false) -> void:
	if transitioning or not trial.active():
		return
	transitioning = true
	hud.close_station()
	hud.close_inventory()
	hud.close_character()
	hud.close_map()
	input_driver.reset()
	input_driver.blocked = true
	hud.transition_active = true
	hud._sync_controls()
	_pause_combat()
	await hud.fade_transition(true)
	hud.set_boss(null)
	tower_guardian = null
	trial.end() # Invalidate wave callbacks before removing enemies or arena.
	_clear_combat_actors()
	remove_child(arena)
	arena.queue_free()
	arena = null
	add_child(world)
	move_child(world, 0)
	player.global_position = SafeCamp.RESPAWN
	player.velocity = Vector2.ZERO
	player.charge_left = 0.0
	player.dash.time_left = 0.0
	if died:
		player.health.initialize(player.stats.max_hp) # Same HP recovery as normal restart.
	hud.restart.hide()
	hud.heading.text = "Mata · Andar 1"
	hud.minimap.arena_bounds = Rect2()
	hud.minimap.update_player(player.global_position)
	_camera_bounds(Rect2(Vector2.ZERO, MiniMap.WORLD_SIZE))
	spawn_remaining = SPAWN_INTERVAL
	station_nearby = ""
	hud.set_nearby_station("")
	_refresh_mission()
	_save_progress()
	await hud.fade_transition(false)
	transitioning = false
	hud.transition_active = false
	input_driver.reset()
	input_driver.blocked = false
	hud._sync_controls()
	hud.show_notice("Retorno à Mata · próxima tentativa começa na Horda 1")

func _exit_tree() -> void:
	progress.browser.detach()
	# A reload during a trial discards it; free the temporarily detached Mata.
	if is_instance_valid(world) and world.get_parent() == null:
		world.free()

func _pause_combat() -> void:
	for node in get_children():
		if node is EnemyActor or node is EnemyProjectile:
			node.set_physics_process(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_instance_valid(hud) and is_instance_valid(player):
			_save_progress()

func _open_record() -> void:
	if transitioning or not player.health.is_alive():
		return
	hud.close_inventory()
	input_driver.reset()
	input_driver.blocked = true
	pending_import = ""
	_save_progress()
	hud.save_panel.open(progress)
	hud._sync_controls()
	hud._layout()

func _save_action(action: String) -> void:
	if not hud.save_panel.visible or transitioning:
		return
	match action:
		"close":
			pending_import = ""
			hud.save_panel.hide()
			input_driver.reset()
			input_driver.blocked = false
			hud._sync_controls()
		"cancel":
			pending_import = ""
			hud.save_panel.open(progress)
		"export":
			_save_progress()
			if OS.has_feature("web"):
				JavaScriptBridge.download_buffer(progress.export_backup().to_utf8_buffer(), "grande-arvore-rpg-save.json", "application/json")
				hud.save_panel.description.text = "Backup solicitado ao navegador. Confira Downloads antes de fechar."
			else:
				_open_save_dialog(true)
		"import":
			if OS.has_feature("web"):
				progress.browser.pick(_preview_import)
			else:
				_open_save_dialog(false)
		"confirm":
			if pending_import.is_empty():
				return
			if progress.import_backup(pending_import, true):
				pending_import = ""
				get_tree().reload_current_scene()
			else:
				hud.save_panel.description.text = "Não foi possível substituir. Progresso atual preservado; exporte um backup."

func _preview_import(text: String) -> void:
	if not is_instance_valid(hud) or not hud.save_panel.visible:
		return
	var candidate = progress.preview_backup(text)
	if candidate == null:
		pending_import = ""
		hud.save_panel.confirmation(false)
		hud.save_panel.description.text = "Arquivo inválido, incompleto ou incompatível. Progresso atual preservado."
		return
	pending_import = text
	hud.save_panel.preview(candidate)

func _open_save_dialog(exporting: bool) -> void:
	if is_instance_valid(save_dialog):
		save_dialog.queue_free()
	save_dialog = FileDialog.new()
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if exporting else FileDialog.FILE_MODE_OPEN_FILE
	save_dialog.filters = PackedStringArray(["*.json ; Save JSON"])
	save_dialog.current_file = "grande-arvore-rpg-save.json" if exporting else ""
	add_child(save_dialog)
	save_dialog.file_selected.connect(func(path: String):
		if exporting:
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_string(progress.export_backup())
				file.close()
				hud.save_panel.description.text = "Backup exportado."
			else:
				hud.save_panel.description.text = "Não foi possível exportar o arquivo."
		else:
			_preview_import(progress._read_file(path))
	)
	save_dialog.popup_centered(Vector2i(500, 350))

func _spawn_tower_guardian() -> void:
	if transitioning or trial.phase != TowerTrial.Phase.GUARDIAN or is_instance_valid(tower_guardian):
		return
	var actor := ENEMY_SCENE.instantiate() as EnemyActor
	var template := actor.stats.duplicate() as ActorData
	actor.set_script(TOWER_GUARDIAN_SCRIPT)
	actor.get_node("View").set_script(TOWER_GUARDIAN_VIEW)
	tower_guardian = actor as TowerGuardian
	var body := CircleShape2D.new()
	body.radius = 26.0
	tower_guardian.get_node("Collision").shape = body
	tower_guardian.kind = 4
	tower_guardian.stats = template
	tower_guardian.stats.max_hp = TowerGuardian.MAX_HP
	tower_guardian.stats.move_speed = 65.0
	tower_guardian.target = player
	tower_guardian.arena_bounds = TowerTrial.BOUNDS
	tower_guardian.position = trial.spawn_positions(player.position, 1)[0]
	tower_guardian.set_meta("tower_attempt", trial.attempt_id)
	tower_guardian.defeated.connect(_on_tower_guardian_defeated.bind(tower_guardian, trial.attempt_id), CONNECT_ONE_SHOT)
	add_child(tower_guardian)
	tower_guardian.view.damage_occluders = hud.damage_occluders
	hud.set_boss(tower_guardian)
	hud.show_notice("Guardião da Mata · desvie dos avisos no chão")

func _on_tower_guardian_defeated(_kind: int, source: EnemyActor, token: int) -> void:
	if transitioning or trial.phase != TowerTrial.Phase.GUARDIAN or token != trial.attempt_id or source != tower_guardian or source.get_parent() != self or source.health.is_alive() or source.get_meta("defeat_recorded", false):
		return
	source.set_meta("defeat_recorded", true)
	trial.phase = TowerTrial.Phase.VICTORY
	victory_first = progress.ascension.complete_forest_trial()
	if victory_first:
		earned_xp += AscensionProgress.GUARDIAN_XP
		earned_gold += AscensionProgress.GUARDIAN_GOLD
	# Snapshot includes reward and claim together; load/import never grants rewards.
	_save_progress()
	hud.set_boss(null)
	input_driver.reset()
	input_driver.blocked = true
	hud.victory_first = victory_first
	hud.show_station(TowerEntrance.NAME, progress)
	_refresh_mission()
