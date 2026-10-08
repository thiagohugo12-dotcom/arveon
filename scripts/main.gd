extends Node2D

const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/enemy.tscn")
const PROJECTILE_SCRIPT := preload("res://scripts/components/enemy_projectile.gd")
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
	player.input_driver = input_driver
	enemy.target = player
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.projectile_requested.connect(_on_enemy_projectile)
	hud.movement_changed.connect(input_driver.set_touch_direction)
	hud.dash_pressed.connect(input_driver.request_dash)
	hud.interact_pressed.connect(_interact)
	hud.inventory_toggled.connect(_toggle_inventory)
	hud.character_toggled.connect(_toggle_character)
	hud.skill_pressed.connect(_use_skill)
	hud.rpg_action.connect(_rpg_action)
	hud.station_action.connect(_station_action)
	hud.panel_closed.connect(func():
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
	hud.set_mission(mission.summary())
	get_window().size_changed.connect(_adapt_orientation)
	_adapt_orientation()

func _process(delta: float) -> void:
	hud.set_dash_cooldown(player.dash.cooldown_left)
	rpg_refresh -= delta
	if rpg_refresh <= 0.0:
		rpg_refresh = 0.1
		hud.set_rpg_status(progress, player)
	if not player.health.is_alive():
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
	if near != station_nearby and not hud.station_panel.visible:
		station_nearby = near
		hud.set_nearby_station(near)
	spawn_remaining -= delta
	if spawn_remaining <= 0.0:
		spawn_remaining = SPAWN_INTERVAL
		if get_tree().get_nodes_in_group("damageable_enemies").size() < MAX_ENEMIES:
			_spawn_enemy()

func _spawn_enemy() -> void:
	var actor := ENEMY_SCENE.instantiate() as EnemyActor
	actor.kind = (spawn_count + 1) % 3
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
	actor.position = ENEMY_POSITIONS[spawn_count % ENEMY_POSITIONS.size()]
	actor.target = player
	actor.defeated.connect(_on_enemy_defeated)
	actor.projectile_requested.connect(_on_enemy_projectile)
	add_child(actor)
	spawn_count += 1

func _on_enemy_projectile(origin: Vector2, direction: Vector2, damage: int) -> void:
	var projectile := Area2D.new()
	projectile.set_script(PROJECTILE_SCRIPT)
	add_child(projectile)
	projectile.setup(origin, direction, damage, player)

func _on_enemy_defeated(kind: int) -> void:
	defeated_count += 1
	var gained_xp: int = [12, 10, 16][kind]
	var gained_gold := loot_rng.randi_range(2, 5)
	earned_xp += gained_xp
	earned_gold += gained_gold
	var material: String = ["Couro", "Seda", "Essência"][kind]
	collected_materials[material] = int(collected_materials.get(material, 0)) + 1
	var drop_text := "+%d XP · +%d ouro · +1 %s" % [gained_xp, gained_gold, material]
	mission.record_defeat()
	mission.record_material()
	if loot_rng.randf() < 0.01:
		collected_materials["Broto Ancestral"] = int(collected_materials.get("Broto Ancestral", 0)) + 1
		drop_text += " · Broto Ancestral raro!"
	if not mission_reward_message.is_empty():
		drop_text += " · " + mission_reward_message
		mission_reward_message = ""
	hud.set_progress(earned_xp, earned_gold, defeated_count, drop_text)
	hud.set_mission(mission.summary())
	_save_progress()

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
	if progress.level() > known_level:
		known_level = progress.level()
		hud.show_notice("Level Up! Nível %d · %d pontos de atributo · %d de habilidade" % [known_level, progress.attribute_points(), progress.skill_points()])
		player.view.flash()
	if hud.inventory_open:
		hud.refresh_inventory(progress)
	if not progress.save():
		push_warning("Não foi possível salvar o progresso local.")
	hud.set_rpg_status(progress, player)

func _on_player_died() -> void:
	input_driver.reset()
	input_driver.blocked = false
	var lost := progress.death_loss()
	hud.set_progress(earned_xp, earned_gold, defeated_count,
		"Perdeu 1 " + lost + " da mochila; baú protegido" if not lost.is_empty() else "Baú protegido · sem material na mochila")
	_save_progress()

func _toggle_inventory() -> void:
	if hud.inventory_open:
		hud.close_inventory()
		input_driver.blocked = false
		station_nearby = ""
	elif player.health.is_alive() and not hud.station_panel.visible and not hud.rpg_panel.visible:
		input_driver.reset()
		input_driver.blocked = true
		hud.show_inventory(progress)

func _interact() -> void:
	if not player.health.is_alive() or hud.station_panel.visible or hud.inventory_open or hud.rpg_panel.visible:
		return
	var found := _interaction_target()
	match found.get("kind", ""):
		"station":
			input_driver.reset()
			input_driver.blocked = true
			hud.show_station(found.id, progress)
		"resource":
			var item := progress.collect_resource(found.id, int(Time.get_unix_time_from_system()))
			if item.is_empty():
				return
			mission.record_material()
			var resource_text := "Coletou +1 " + item
			if not mission_reward_message.is_empty():
				resource_text += " · " + mission_reward_message
				mission_reward_message = ""
			_save_progress()
			hud.set_progress(earned_xp, earned_gold, defeated_count, resource_text)
			hud.set_mission(mission.summary())
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
			hud.set_mission(mission.summary())
			exploration_view.queue_redraw()
			station_nearby = ""

func _interaction_target() -> Dictionary:
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
	if event.is_echo():
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
		if hud.rpg_panel.visible:
			_toggle_character()
		elif hud.inventory_open:
			_toggle_inventory()
		elif hud.station_panel.visible:
			hud.close_station()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		if hud.rpg_panel.visible:
			_toggle_character()
		elif hud.inventory_open:
			_toggle_inventory()
		elif hud.station_panel.visible:
			hud.close_station()
		else:
			_interact()
		get_viewport().set_input_as_handled()

func _use_skill(index: int) -> void:
	player.use_skill(index)
	hud.set_rpg_status(progress, player)

func _toggle_character() -> void:
	if hud.rpg_panel.visible:
		hud.close_character()
		input_driver.blocked = false
		station_nearby = ""
	elif player.health.is_alive() and not hud.inventory_open and not hud.station_panel.visible:
		input_driver.reset()
		input_driver.blocked = true
		hud.show_character(progress)

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

