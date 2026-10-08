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
	hud.station_action.connect(_station_action)
	hud.panel_closed.connect(func():
		input_driver.blocked = false
		station_nearby = ""
	)
	hud.restart_pressed.connect(func(): get_tree().reload_current_scene())
	player.health.changed.connect(hud.set_health)
	player.health.died.connect(hud.show_death)
	player.health.died.connect(_on_player_died)
	hud.set_health(player.health.current, player.health.maximum)
	hud.set_progress(earned_xp, earned_gold, defeated_count, "")
	hud.set_mission(mission.summary())
	get_window().size_changed.connect(_adapt_orientation)
	_adapt_orientation()

func _process(delta: float) -> void:
	hud.set_dash_cooldown(player.dash.cooldown_left)
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
	earned_xp += [12, 10, 16][kind]
	earned_gold += loot_rng.randi_range(2, 5)
	var material: String = ["Couro", "Seda", "Essência"][kind]
	collected_materials[material] = int(collected_materials.get(material, 0)) + 1
	var drop_text := "+1 " + material
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
	_save_progress()

func _save_progress() -> void:
	progress.xp = earned_xp
	progress.gold = earned_gold
	progress.kills = defeated_count
	progress.mission_index = mission.mission_index
	progress.mission_progress = mission.progress
	progress.mission_completed = mission.completed_count
	if not progress.save():
		push_warning("Não foi possível salvar o progresso local.")

func _on_player_died() -> void:
	input_driver.reset()
	input_driver.blocked = false
	var lost := progress.death_loss()
	hud.set_progress(earned_xp, earned_gold, defeated_count,
		"Perdeu 1 " + lost + " da mochila; baú protegido" if not lost.is_empty() else "Baú protegido · sem material na mochila")
	_save_progress()

func _interact() -> void:
	if not player.health.is_alive() or hud.station_panel.visible:
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
			_save_progress()
			hud.set_progress(earned_xp, earned_gold, defeated_count, "Coletou +1 " + item)
			hud.set_mission(mission.summary())
			exploration_view.queue_redraw()
			station_nearby = ""
		"cache":
			var reward := progress.open_exploration_chest(found.id)
			if reward.is_empty():
				return
			earned_gold = progress.gold
			mission.record_material()
			_save_progress()
			hud.set_progress(earned_xp, earned_gold, defeated_count,
				"Baú escondido: +%d ouro, +1 %s" % [reward.gold, reward.item])
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
		hud.set_progress(earned_xp, earned_gold, defeated_count, "%s: 1 %s" % [action, item])
	hud.refresh_station(progress)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo():
		if hud.station_panel.visible:
			hud.close_station()
		else:
			_interact()
		get_viewport().set_input_as_handled()

func _adapt_orientation() -> void:
	var window := get_window()
	# Logical short side 360 keeps touch targets readable in either orientation.
	var desired := Vector2i(360, 640) if window.size.y > window.size.x else Vector2i(640, 360)
	if window.content_scale_size != desired:
		window.content_scale_size = desired
	hud.call_deferred("_layout")
