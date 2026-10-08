extends Node2D

const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/enemy.tscn")
const PROJECTILE_SCRIPT := preload("res://scripts/components/enemy_projectile.gd")
const MAX_ENEMIES := 5
const SPAWN_INTERVAL := 2.8
const ENEMY_POSITIONS := [
	Vector2(760, 400), Vector2(930, 440), Vector2(610, 650),
	Vector2(250, 460), Vector2(630, 185), Vector2(955, 665)
]

@onready var player: PlayerActor = $Player
@onready var enemy: EnemyActor = $Enemy
@onready var input_driver: InputDriver = $InputDriver
@onready var hud: GameHUD = $Interface/HUD

var spawn_remaining: float = SPAWN_INTERVAL
var spawn_count: int = 0
var defeated_count: int = 0
var earned_xp: int = 0
var earned_gold: int = 0
var collected_materials: Dictionary = {}
var loot_rng := RandomNumberGenerator.new()
var mission := CommonMission.new()
var mission_reward_message: String = ""

func _ready() -> void:
	mission.completed.connect(_on_mission_completed)
	loot_rng.randomize()
	player.input_driver = input_driver
	enemy.target = player
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.projectile_requested.connect(_on_enemy_projectile)
	hud.movement_changed.connect(input_driver.set_touch_direction)
	hud.dash_pressed.connect(input_driver.request_dash)
	hud.restart_pressed.connect(func(): get_tree().reload_current_scene())
	player.health.changed.connect(hud.set_health)
	player.health.died.connect(hud.show_death)
	hud.set_health(player.health.current, player.health.maximum)
	hud.set_progress(earned_xp, earned_gold, defeated_count, "")
	hud.set_mission(mission.summary())
	get_window().size_changed.connect(_adapt_orientation)
	_adapt_orientation()

func _process(delta: float) -> void:
	hud.set_dash_cooldown(player.dash.cooldown_left)
	if not player.health.is_alive():
		return
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

func _on_mission_completed(xp_reward: int, gold_reward: int) -> void:
	earned_xp += xp_reward
	earned_gold += gold_reward
	mission_reward_message = "Missão concluída! +%d XP, +%d ouro" % [xp_reward, gold_reward]

func _adapt_orientation() -> void:
	var window := get_window()
	# Logical short side 360 keeps touch targets readable in either orientation.
	var desired := Vector2i(360, 640) if window.size.y > window.size.x else Vector2i(640, 360)
	if window.content_scale_size != desired:
		window.content_scale_size = desired
	hud.call_deferred("_layout")
