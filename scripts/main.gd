extends Node2D

var launch_new_game := false

const ARENA_SCENE := preload("res://scenes/world/tower_arena.tscn")
var trial := TowerTrial.new()
var tower_guardian: TowerGuardian
var victory_first := false
const TOWER_GUARDIAN_SCRIPT = preload("res://scripts/actors/tower_guardian.gd")
const TOWER_GUARDIAN_VIEW = preload("res://scripts/presentation/tower_guardian_view.gd")
const SANDSTONE_TOWER_GUARDIAN_VIEW = preload("res://scripts/presentation/sandstone_tower_guardian_view.gd")
var arena: Node2D
var transitioning := false
var floor_epoch := 0
var autosave_left := 30.0
var pending_import := ""
var save_dialog: FileDialog
var _ui2_browser_death_callback: Variant
@onready var world: Node2D = $Andar1

const ENEMY_SCENE: PackedScene = preload("res://scenes/actors/enemy.tscn")
const FLOOR2_ENEMY_SCENE: PackedScene = preload("res://scenes/actors/floor2_enemy.tscn")
const PROJECTILE_SCRIPT := preload("res://scripts/components/enemy_projectile.gd")
const GUARDIAN_SCRIPT = preload("res://scripts/actors/root_guardian.gd")
const GUARDIAN_VIEW = preload("res://scripts/presentation/guardian_view.gd")
const SANDSTONE_COLOSSUS_SCRIPT = preload("res://scripts/actors/sandstone_colossus.gd")
const SANDSTONE_COLOSSUS_VIEW = preload("res://scripts/presentation/sandstone_colossus_view.gd")
const GUARDIAN_ALTAR: Vector2 = FloorCatalog.FLOORS[1]["guardian_altar"]
var guardian: EnemyActor
# Andar 3 · Pântano das Vozes: inimigos comuns, mini-chefe e Guardiã.
const FLOOR3_ENEMY_SCENE: PackedScene = preload("res://scenes/actors/floor3_enemy.tscn")
const FLOOR3_CAIMAN_SCENE: PackedScene = preload("res://scenes/actors/floor3_caiman.tscn")
const WHISPERS_SCRIPT = preload("res://scripts/actors/mother_of_whispers.gd")
const WHISPERS_VIEW = preload("res://scripts/presentation/mother_of_whispers_view.gd")
const WHISPERS_TOWER_VIEW = preload("res://scripts/presentation/whispers_tower_guardian_view.gd")
var mini_boss: EnemyActor
var mini_boss_respawn_left := 0.0

const MAX_ENEMIES := 5
const SPAWN_INTERVAL := 2.8
const ENEMY_POSITIONS: Array = FloorCatalog.FLOORS[1]["enemy_spawn_groups"][0]
const ANDAR1_ENEMY_POSITIONS: Array = FloorCatalog.FLOORS[1]["enemy_spawn_groups"][1]

@onready var player: PlayerActor = $Player
@onready var enemy: EnemyActor = $Enemy
@onready var input_driver: InputDriver = $InputDriver
@onready var hud: GameHUD = $Interface/HUD
@onready var exploration_view: ExplorationView = $Andar1/ExploreView
@onready var tower_view: TowerView = $Andar1/TowerView

var spawn_remaining: float = SPAWN_INTERVAL
var spawn_count: int = 0
var encounter_camps := EncounterCamps.new()
var camps_mode := false
var defeated_count: int = 0
var earned_xp: int = 0
var earned_gold: int = 0
var test_build_notice := false
var collected_materials: Dictionary = {}
var loot_rng := RandomNumberGenerator.new()
var mission := CommonMission.new()
var mission_reward_message: String = ""
var progress := GameProgress.new()
var mining_rng := RandomNumberGenerator.new()
var mining_active := false
var mining_token := 0
var station_nearby := ""
var activity_remaining := 0.0
var exploration_refresh := 0.0
var rpg_refresh := 0.0
var known_level := 1

func _ready() -> void:
	var test_save := OS.get_environment("ARVEON_SAVE_PATH")
	if test_save.is_empty():
		test_save = OS.get_environment("GRANDE_ARVORE_SAVE_PATH")
	if not test_save.is_empty():
		progress.save_path = test_save
	if launch_new_game:
		if OS.has_feature("web"):
			progress.browser.read()
		progress.begin_new_character()
	elif progress.load_save():
		earned_xp = progress.xp
		earned_gold = progress.gold
		defeated_count = progress.kills
		mission.mission_index = progress.mission_index
		mission.progress = progress.mission_progress
		mission.completed_count = progress.mission_completed
	elif not progress.save_blocked:
		progress.begin_new_character()
	SafeCamp.active_floor = progress.ascension.current_floor
	var start_floor := progress.ascension.current_floor
	if FloorConfig.world_scene(start_floor) != FloorConfig.WORLD_SCENE:
		remove_child(world)
		world.free()
		world = (load(FloorConfig.world_scene(start_floor)) as PackedScene).instantiate()
		add_child(world)
		move_child(world, 0)
		exploration_view = world.get_node("ExploreView") as ExplorationView
		tower_view = world.get_node("TowerView") as TowerView
		player.position = SafeCamp.respawn_for_floor(start_floor)
		var old_enemy := enemy
		remove_child(old_enemy)
		old_enemy.free()
		var encounters_enabled := _floor_encounters_enabled(start_floor)
		enemy = _make_enemy(FloorCatalog.first_enemy_kind(start_floor)) if encounters_enabled else _make_enemy(0)
		enemy.position = FloorCatalog.first_enemy_position(start_floor) if encounters_enabled else SafeCamp.respawn_for_floor(start_floor) + Vector2(80, 0)
		add_child(enemy)
		if not encounters_enabled: _disable_preview_enemy(enemy)
	mission.enabled = not progress.introduction_active()
	collected_materials = progress.bag
	hud.minimap.progress = progress
	hud.minimap.player_position = player.global_position
	hud.minimap.queue_redraw()
	exploration_view.progress = progress
	exploration_view.current_time = int(Time.get_unix_time_from_system())
	exploration_view.queue_redraw()
	mission.completed.connect(_on_mission_completed)
	loot_rng.randomize()
	mining_rng.randomize()
	hud.tower_trial = trial
	player.input_driver = input_driver
	player.attack.projectile_requested.connect(_on_player_projectile)
	player.view.damage_occluders = hud.damage_occluders
	enemy.view.damage_occluders = hud.damage_occluders
	enemy.target = player
	_apply_floor_stats(enemy)
	if _floor_encounters_enabled(start_floor):
		_register_enemy_defeat(enemy)
		enemy.projectile_requested.connect(_on_enemy_projectile)
	hud.movement_changed.connect(func(value: Vector2):
		input_driver.set_touch_direction(value)
		if OS.has_feature("web") and bool(JavaScriptBridge.eval("window.__ARVEON_UI2_TEST__ === true", true)):
			var movement_state := {"direction":[value.x,value.y],"position":[player.global_position.x,player.global_position.y],"blocked":input_driver.blocked}
			var message := "ARVEON_UI2_MOVE "+JSON.stringify(movement_state)
			JavaScriptBridge.eval("console.log("+JSON.stringify(message)+")")
	)
	hud.dash_pressed.connect(input_driver.request_dash)
	hud.interact_pressed.connect(_interact)
	hud.inventory_toggled.connect(_toggle_inventory)
	hud.save_requested.connect(_open_record)
	hud.save_panel.action_requested.connect(_save_action)
	hud.character_toggled.connect(_toggle_character)
	hud.map_toggled.connect(_toggle_map)
	hud.skill_pressed.connect(_use_skill)
	hud.rpg_action.connect(_rpg_action)
	hud.equipment_loadout_action.connect(_equipment_loadout_action)
	hud.equipment_expansion_requested.connect(_equipment_expansion_action)
	hud.station_action.connect(_station_action)
	hud.panel_closed.connect(func():
		(world.get_node("FloorView") as FloorView).set_chest_open(false)
		input_driver.reset()
		input_driver.blocked = false
		station_nearby = ""
	)
	hud.restart_pressed.connect(func(): get_tree().reload_current_scene())
	player.health.changed.connect(hud.set_health)
	player.health.died.connect(_on_player_died)
	player.apply_progression(progress, true)
	known_level = progress.level()
	hud.set_health(player.health.current, player.health.maximum)
	hud.set_progress(earned_xp, earned_gold, defeated_count, "")
	_refresh_mission()
	get_window().size_changed.connect(_adapt_orientation)
	_adapt_orientation()
	tower_view.set_state(progress.ascension.entrance_unlocked(), TowerEntrance.is_near(player.global_position,progress.ascension.current_floor))
	_update_floor_identity()
	_setup_encounters()
	_save_progress()
	if OS.has_feature("web"):
		progress.browser.watch_hidden(_save_progress)
		# Narrow test-only bridge: the Chromium suite requests a real Health death
		# after exercising the world controls. No UI or gameplay path calls it.
		if bool(JavaScriptBridge.eval("window.__ARVEON_UI2_TEST__ === true", true)):
			_ui2_browser_death_callback = JavaScriptBridge.create_callback(_ui2_browser_trigger_death)
			var browser_window := JavaScriptBridge.get_interface("window")
			browser_window.ui2TriggerDeath = _ui2_browser_death_callback
	if progress.save_blocked:
		hud.show_notice(progress.save_status)
		hud.notice_left = 12.0


func _process(delta: float) -> void:
	if TestBuild.active() and not progress.training_mode: _apply_test_build()
	autosave_left -= delta
	if autosave_left <= 0.0:
		autosave_left = 30.0
		_save_progress()
	if transitioning:
		return
	if FloorCatalog.feature(progress.ascension.current_floor,"mining") and world is Andar2World:
		(world.get_node("FloorView") as Floor2View).set_mining_state(progress, int(Time.get_unix_time_from_system()))
	hud.set_dash_cooldown(player.dash.cooldown_left)
	rpg_refresh -= delta
	if rpg_refresh <= 0.0:
		rpg_refresh = 0.1
		hud.set_rpg_status(progress, player)
	if not player.health.is_alive():
		return
	if progress.training_mode:
		hud.minimap.update_player(player.global_position)
		if FloorCatalog.feature(progress.ascension.current_floor,"mining"):
			var training_near: String = _interaction_target().get("label", "")
			if training_near != station_nearby and not hud.station_panel.visible:
				station_nearby = training_near
				hud.set_nearby_station(training_near)
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
		if progress.discover_nearby(player.global_position,progress.ascension.current_floor):
			_save_progress()
			hud.minimap.queue_redraw()
		var floor_view := world.get_node("FloorView") as FloorView
		var secret_revealed := progress.discovered_pois.has("secretwood_wood_southeast")
		if floor_view.secret_path_revealed != secret_revealed:
			floor_view.secret_path_revealed = secret_revealed
			floor_view.queue_redraw()
			hud.minimap.queue_redraw()
		hud.minimap.update_player(player.global_position)
		for actor in get_tree().get_nodes_in_group("damageable_enemies"):
			if actor is EnemyActor:
				actor.update_activity(player.global_position)
	var near := _interaction_target().get("label", "") as String
	tower_view.set_state(progress.ascension.entrance_unlocked(), TowerEntrance.is_near(player.global_position,progress.ascension.current_floor))
	if near != station_nearby and not hud.station_panel.visible:
		station_nearby = near
		hud.set_nearby_station(near)
	if not _floor_encounters_enabled(progress.ascension.current_floor):
		return
	_update_mini_boss(delta)
	if camps_mode:
		encounter_camps.update(delta, player.global_position)
		return
	spawn_remaining -= delta
	if spawn_remaining <= 0.0:
		spawn_remaining = SPAWN_INTERVAL
		if get_tree().get_nodes_in_group("damageable_enemies").size() < MAX_ENEMIES:
			_spawn_enemy()

func _make_enemy(kind: int) -> EnemyActor:
	var scene: PackedScene = FLOOR3_CAIMAN_SCENE if kind == 11 else FLOOR3_ENEMY_SCENE if kind >= 8 else FLOOR2_ENEMY_SCENE if kind >= 5 else ENEMY_SCENE
	var actor := scene.instantiate() as EnemyActor
	actor.kind = kind
	if kind >= 5 and kind < 8:
		(actor.get_node("View") as Floor2MonsterView).monster_index = kind - 5
	# Duplicating the resource ensures variants never mutate the original enemy template.
	actor.stats = actor.stats.duplicate() as ActorData
	var definition := FloorCatalog.monster(FloorCatalog.monster_id_for_kind(kind))
	if not definition.is_empty():
		actor.stats.max_hp = int(definition.hp)
		actor.stats.move_speed = float(definition.speed)
		actor.stats.contact_damage = int(definition.contact)
	_apply_floor_stats(actor)
	return actor

# Mini-chefe de campo (Jacaré Ancião no Andar 3): opcional e repetível. Reaparece em casa
# depois do intervalo do catálogo, só quando o jogador está longe da arena.
func _update_mini_boss(delta: float) -> void:
	var definition := FloorCatalog.mini_boss(progress.ascension.current_floor)
	if definition.is_empty() or trial.active() or transitioning: return
	if is_instance_valid(mini_boss) and mini_boss.get_parent() == self: return
	mini_boss_respawn_left = maxf(0.0, mini_boss_respawn_left - delta)
	var home: Vector2 = definition.home
	if mini_boss_respawn_left > 0.0 or player.global_position.distance_to(home) < 420.0: return
	mini_boss = _make_enemy(int(definition.kind))
	mini_boss.position = home
	mini_boss.target = player
	if mini_boss is AncientCaiman: (mini_boss as AncientCaiman).arena = definition.arena
	_register_enemy_defeat(mini_boss)
	mini_boss.defeated.connect(func(_kind: int): mini_boss_respawn_left = float(definition.respawn), CONNECT_ONE_SHOT)
	add_child(mini_boss)
	mini_boss.view.damage_occluders = hud.damage_occluders

func _floor_encounters_enabled(floor_id: int) -> bool:
	return floor_id <= 2 or FloorCatalog.feature(floor_id,"encounters_enabled")

func _disable_preview_enemy(actor: EnemyActor) -> void:
	# Mantem a referencia legado de Main sem deixar o placeholder participar do combate.
	actor.hide()
	actor.remove_from_group("damageable_enemies")
	actor.collision_layer = 0
	actor.collision_mask = 0
	actor.set_physics_process(false)

func _apply_floor_stats(actor: EnemyActor) -> void:
	if actor.has_meta("scaled_floor"):
		return
	actor.stats = actor.stats.duplicate() as ActorData
	var multiplier := FloorConfig.difficulty(progress.ascension.current_floor)
	var base_contact := actor.stats.contact_damage
	actor.stats.max_hp = roundi(actor.stats.max_hp * multiplier)
	actor.stats.contact_damage = roundi(base_contact * multiplier)
	actor.damage_scale = multiplier
	actor.projectile_damage_override = roundi(maxi(4, base_contact - 2) * multiplier)
	actor.set_meta("scaled_floor", progress.ascension.current_floor)
	if actor.is_node_ready():
		actor.health.initialize(actor.stats.max_hp)

# Modo "acampamentos" (opt-in): ver EncounterCamps. O padrão continua o spawn contínuo.
func _setup_encounters() -> void:
	var floor_id := progress.ascension.current_floor
	camps_mode = GameOptions.encounter_mode() == GameOptions.MODE_CAMPS and not FloorCatalog.camps(floor_id).is_empty()
	if camps_mode:
		encounter_camps.setup(self, floor_id)
	else:
		encounter_camps.camps.clear()

func _spawn_camp_member(kind: int, at: Vector2, camp_id: String) -> EnemyActor:
	var actor := _make_enemy(kind)
	actor.position = at
	actor.target = player
	actor.set_meta("camp_id", camp_id)
	_register_enemy_defeat(actor)
	actor.projectile_requested.connect(_on_enemy_projectile)
	add_child(actor)
	actor.view.damage_occluders = hud.damage_occluders
	return actor

# Fase 3 de um chefe: até "limit" asseclas vivas por vez, que somem junto com o chefe.
func _on_boss_summon(kinds: Array, limit: int, boss: EnemyActor) -> void:
	if not is_instance_valid(boss) or not boss.health.is_alive() or boss.get_parent() != self:
		return
	var alive := 0
	for node in get_tree().get_nodes_in_group("damageable_enemies"):
		if node.get_meta("boss_minion_of",null) == boss: alive += 1
	var spawned := 0
	for kind in kinds:
		if alive + spawned >= limit: break
		var at := boss.global_position + Vector2(-70.0 if spawned % 2 == 0 else 70.0,45.0)
		if boss is TowerGuardian: at = at.clamp(TowerTrial.BOUNDS.position + Vector2(40,40),TowerTrial.BOUNDS.end - Vector2(40,40))
		var minion := _make_enemy(int(kind))
		minion.position = at
		minion.target = player
		minion.set_meta("boss_minion_of",boss)
		if boss.has_meta("tower_attempt"): minion.set_meta("tower_attempt",boss.get_meta("tower_attempt"))
		_register_enemy_defeat(minion)
		minion.projectile_requested.connect(_on_enemy_projectile)
		add_child(minion)
		minion.view.damage_occluders = hud.damage_occluders
		spawned += 1
	if spawned > 0:
		hud.show_notice("O chefe chama reforços!")
		if not boss.defeated.is_connected(_clear_boss_minions):
			boss.defeated.connect(_clear_boss_minions.bind(boss),CONNECT_ONE_SHOT)

func _clear_boss_minions(_kind: int, boss: EnemyActor) -> void:
	for node in get_tree().get_nodes_in_group("damageable_enemies"):
		if node.get_meta("boss_minion_of",null) == boss and node is EnemyActor and (node as EnemyActor).health.is_alive():
			(node as EnemyActor).queue_free()

func _spawn_enemy() -> void:
	if trial.active() or transitioning or not _floor_encounters_enabled(progress.ascension.current_floor):
		return
	var spawn_position := Vector2.ZERO
	var kind := 3 if spawn_count % 8 == 7 else (spawn_count + 1) % 3
	if FloorCatalog.has_floor(progress.ascension.current_floor):
		var candidates: Array[int] = []
		var positions: Array = FloorCatalog.enemy_spawns(progress.ascension.current_floor)
		for index in range(positions.size()):
			var at: Vector2 = positions[index]
			if SafeCamp.in_clearance(at) or at.distance_to(player.global_position) > EnemyActor.SLEEP_ENTER-40.0:
				continue
			var occupied := false
			for other in get_tree().get_nodes_in_group("damageable_enemies"):
				if other is EnemyActor and other.health.is_alive() and other.global_position.distance_to(at) < 82.0:
					occupied = true
					break
			if not occupied: candidates.append(index)
		if candidates.is_empty(): return
		var selected: int = candidates[spawn_count % candidates.size()]
		spawn_position = positions[selected]
		var fixed_kinds := FloorCatalog.enemy_spawn_kinds(progress.ascension.current_floor)
		if not fixed_kinds.is_empty():
			kind = fixed_kinds[selected]
	else:
		spawn_position = ENEMY_POSITIONS[spawn_count % ENEMY_POSITIONS.size()]
	var actor := _make_enemy(kind)
	actor.position = spawn_position
	actor.target = player
	_register_enemy_defeat(actor)
	actor.projectile_requested.connect(_on_enemy_projectile)
	add_child(actor)
	actor.view.damage_occluders = hud.damage_occluders
	spawn_count += 1

func _on_enemy_projectile(origin: Vector2, direction: Vector2, damage: int, source_name: String) -> void:
	if transitioning or not player.health.is_alive():
		return
	if trial.active() and (input_driver.blocked or not TowerTrial.BOUNDS.has_point(origin)):
		return
	var projectile := Area2D.new()
	projectile.set_script(PROJECTILE_SCRIPT)
	add_child(projectile)
	projectile.setup(origin, direction, damage, player,source_name)
	if trial.active():
		projectile.arena_bounds = TowerTrial.BOUNDS

func _register_enemy_defeat(actor: EnemyActor) -> void:
	(actor.get_node("View") as ActorView).village_scale = FloorCatalog.feature(progress.ascension.current_floor,"modern_art")
	actor.set_meta("floor_id", progress.ascension.current_floor)
	actor.set_meta("floor_epoch", floor_epoch)
	actor.defeated.connect(_on_enemy_defeated.bind(actor), CONNECT_ONE_SHOT)
	var impact := preload("res://scripts/presentation/skill1_game_impact.gd").new()
	actor.get_node("View").add_child(impact)
	actor.weapon_hit.connect(impact.show_hit.bind(actor))
	actor.weapon_hit.connect(_on_weapon_hit.bind(actor))

func _on_weapon_hit(category: String, effective: int, event: int, actor: EnemyActor) -> void:
	if transitioning or input_driver.blocked or not player.health.is_alive() or not ArsenalRules.CATEGORIES.has(category) or actor.get_parent() != self or not actor.is_targetable() or actor.get_meta("floor_id",0) != progress.ascension.current_floor: return
	if actor.get_meta("floor_epoch",-1) != floor_epoch or (trial.active() and actor.get_meta("tower_attempt",-1) != trial.attempt_id): return
	var details := actor.hit_details(event)
	if not actor.consume_hit_receipt(category,effective,event): return
	if not details.get("ultimate",false): progress.abilities.add_ultimate_damage(category,int(details.get("charge",effective)),progress.active_category())
	if category == progress.active_category(): player.class_combat.record_hit(actor,details.get("source","basic"),details.get("critical",false))
	var before := progress.talents.level(category)
	if progress.talents.record_damage(category,effective) and progress.talents.level(category) > before:
		player.apply_progression(progress)
		hud.show_notice("%s · Proficiência %d" % [ArsenalRules.CATEGORIES[category].name,progress.talents.level(category)])

# Marco 5: drops com nome, troféu do Guardião e proteção contra azar. Chamadas sem criatura real
# (testes antigos) continuam na tabela original.
func _roll_loot(kind: int, source: EnemyActor) -> Array[Dictionary]:
	if source == null: return EquipmentEconomy.roll_drops(kind,loot_rng)
	if source is RootGuardian: return LootRules.field_boss(progress.ascension.current_floor,loot_rng,progress.pity)
	return LootRules.roll(kind,loot_rng,progress.pity)

func _on_enemy_defeated(kind: int, source: EnemyActor = null) -> void:
	if transitioning:
		return
	if source != null:
		# A defeat must come from a registered, actually dead creature in this
		# world. The per-life guard also rejects manual/reentrant duplicate events.
		if source.get_parent() != self or source.health.is_alive() or source.get_meta("defeat_recorded", false):
			return
		if source.get_meta("floor_epoch", -1) != floor_epoch or source.get_meta("floor_id", 0) != progress.ascension.current_floor:
			return
		if trial.active() and source.get_meta("tower_attempt", -1) != trial.attempt_id:
			return
		source.set_meta("defeat_recorded", true)
		if source.get_meta("floor_id", 0) == progress.ascension.current_floor:
			progress.ascension.record_defeat(progress.ascension.current_floor)
	defeated_count += 1
	var gained_xp := FloorConfig.reward(FloorCatalog.xp_for_kind(kind), progress.ascension.current_floor)
	var gained_gold := FloorConfig.reward(loot_rng.randi_range(FloorCatalog.GOLD_RANGE.x, FloorCatalog.GOLD_RANGE.y), progress.ascension.current_floor)
	earned_xp += gained_xp
	earned_gold += gained_gold
	var drop_text := "+%d XP · +%d ouro" % [gained_xp, gained_gold]
	for drop: Dictionary in _roll_loot(kind,source):
		progress.add_item(drop.key)
		if progress.overflowed: drop_text += " (Baú)"
		drop_text += " · +1 %s" % drop.item if drop.get("named",false) else " · +1 %s %s" % [drop.item,ArsenalRules.RARITIES[drop.rarity].name]
		mission.record_material()
	if kind == 3:
		_record_adventure("elite")
	elif kind == 4:
		if not bool(progress.floor_states[str(progress.ascension.current_floor)].guardian_defeated):
			progress.grant_gems(10)
			drop_text += " · +10 gemas"
		progress.floor_states[str(progress.ascension.current_floor)].guardian_defeated = true
		_record_adventure("guardiao")
	mission.record_defeat()
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

# Versão de TESTE: ouro sempre cheio; a viagem livre fica em AscensionProgress.can_travel.
func _apply_test_build() -> void:
	if progress.gold < TestBuild.GOLD or earned_gold < TestBuild.GOLD:
		progress.gold = TestBuild.GOLD
		earned_gold = TestBuild.GOLD
		hud.set_progress(earned_xp, earned_gold, defeated_count, "")
	if not test_build_notice and not progress.introduction_active():
		test_build_notice = true
		hud.show_notice("Versão de teste · ouro infinito e viagem livre pela Torre")

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

func _ui2_browser_trigger_death(_args: Array) -> void:
	if not OS.has_feature("web") or not bool(JavaScriptBridge.eval("window.__ARVEON_UI2_TEST__ === true", true)):
		return
	if not is_instance_valid(player) or not player.health.is_alive():
		return
	player.last_damage_source = "Inimigo de teste"
	player.last_damage_time_msec = Time.get_ticks_msec()
	player.health.damage(player.health.current)

func _on_player_died() -> void:
	if player.health.is_alive() or transitioning:
		return
	mining_token += 1
	mining_active = false
	input_driver.reset()
	input_driver.blocked = false
	if progress.training_mode:
		hud.set_progress(earned_xp, earned_gold, defeated_count, "Treino encerrado · Reiniciar retorna ao personagem")
		hud.show_death({"enemy":"Treino encerrado","gold_lost":0,"xp_lost":0,"item_lost":"","item_count":0,"floor":progress.ascension.current_floor})
		return
	# Report the outcome of the existing penalty transaction. The view receives
	# deltas from the saved model and never reimplements penalty rules.
	var gold_before := progress.gold
	var xp_before := progress.xp
	var bag_before: Dictionary = progress.bag.duplicate(true)
	var equipment_before: Dictionary = progress.equipment.duplicate(true)
	var equipped_before: Dictionary = progress.equipped.duplicate(true)
	var lost := progress.death_loss()
	var lost_count := maxi(0,int(bag_before.get(lost,0))-int(progress.bag.get(lost,0))) if not lost.is_empty() else 0
	var equipment_lost: Array[String] = []
	for slot: String in equipment_before:
		if int(equipment_before[slot]) != int(progress.equipment.get(slot,0)):
			equipment_lost.append(slot)
	for slot: String in equipped_before:
		if str(equipped_before[slot]) != str(progress.equipped.get(slot,"")) and not equipment_lost.has(slot):
			equipment_lost.append(slot)
	hud.set_progress(earned_xp, earned_gold, defeated_count,
		"Perdeu 1 " + lost + " da mochila; baú protegido" if not lost.is_empty() else "Baú protegido · sem material na mochila")
	var last_attacker := player.last_damage_source if Time.get_ticks_msec()-player.last_damage_time_msec <= 10000 else ""
	hud.show_death({"enemy":last_attacker if not last_attacker.is_empty() else "Inimigo não identificado",
		"gold_lost":maxi(0,gold_before-progress.gold),"xp_lost":maxi(0,xp_before-progress.xp),
		"item_lost":lost,"item_count":lost_count,"equipment_lost":equipment_lost,
		"floor":progress.ascension.current_floor})
	_save_progress()
	if trial.active():
		_return_from_trial(true)

func _toggle_inventory() -> void:
	if transitioning or hud.save_panel.visible:
		return
	if hud.equipment_screen.visible:
		hud.close_equipment_screen()
	elif hud.inventory_open:
		hud.close_inventory()
		input_driver.blocked = false
		station_nearby = ""
	elif player.health.is_alive() and not hud.station_panel.visible and not hud.rpg_panel.visible and not hud.map_panel.visible:
		input_driver.reset()
		input_driver.blocked = true
		hud.show_equipment_screen(progress)

func _interact() -> void:
	if transitioning or mining_active:
		return
	if not player.health.is_alive() or hud.station_panel.visible or hud.inventory_open or hud.equipment_screen.visible or hud.rpg_panel.visible or hud.map_panel.visible:
		return
	var found := _interaction_target()
	if not found.is_empty():
		hud.dismiss_interaction()
	match found.get("kind", ""):
		"mining":
			_start_mining(found.id)
		"mining_exhausted":
			var seconds: int = maxi(1, int(found.get("ready_at", 0)) - int(Time.get_unix_time_from_system()))
			hud.show_notice("Depósito esgotado · volta em %d min" % ceili(seconds / 60.0))
		"arena_exit":
			input_driver.reset()
			input_driver.blocked = true
			hud.show_station(TowerEntrance.NAME, progress)
		"tower":
			if not progress.ascension.entrance_unlocked():
				hud.show_notice("A Torre exige 50 criaturas derrotadas. Progresso: %d/50." % progress.ascension.defeats[str(progress.ascension.current_floor)])
			input_driver.reset()
			input_driver.blocked = true
			hud.show_station(TowerEntrance.NAME, progress)
		"guardian":
			_start_guardian()
		"station":
			(world.get_node("FloorView") as FloorView).set_chest_open(found.id == "Baú")
			input_driver.reset()
			input_driver.blocked = true
			if found.id == "Ferreiro" and progress.meet_smith():
				_save_progress()
			hud.show_station(found.id, progress)
		"resource":
			var item := progress.collect_resource(found.id, int(Time.get_unix_time_from_system()),progress.ascension.current_floor)
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
			var reward := progress.open_exploration_chest(found.id,progress.ascension.current_floor)
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
	if mining_active: return {}
	if trial.active():
		if player.global_position.distance_to(TowerTrial.EXIT) <= 68.0:
			return {"kind": "arena_exit", "label": "Retornar ao %s" % FloorConfig.tower_return_name(trial.floor_id) if trial.phase == TowerTrial.Phase.VICTORY else "Abandonar Prova"}
		return {}
	if TowerEntrance.is_near(player.global_position,progress.ascension.current_floor):
		return {"kind": "tower", "label": progress.ascension.summary()}
	var deposit: Dictionary = MiningRules.near(progress.ascension.current_floor, player.global_position) if FloorCatalog.feature(progress.ascension.current_floor,"mining") else {}
	if player.global_position.distance_to(_guardian_altar_position()) <= 58.0 and not progress.floor_states[str(progress.ascension.current_floor)].guardian_defeated and not is_instance_valid(guardian):
		return {"kind": "guardian", "label": str(FloorCatalog.def_or_default(progress.ascension.current_floor).field_guardian.challenge_label)}
	var station := SafeCamp.nearest_station(player.global_position,FloorCatalog.feature(progress.ascension.current_floor,"village_camp"))
	if not station.is_empty():
		return {"kind": "station", "id": station, "label": station}
	var now := int(Time.get_unix_time_from_system())
	var floor_id := progress.ascension.current_floor
	var resource := Exploration.resource_at(player.global_position, progress.harvested_until, now, floor_id)
	var cache := Exploration.chest_at(player.global_position, progress.opened_caches, floor_id)
	# The quarry cache overlaps a mineral interaction radius. Pick the closest
	# physical object so neither chest nor deposit masks the other.
	if not deposit.is_empty():
		var deposit_distance := player.global_position.distance_squared_to(deposit.position)
		if (resource.is_empty() or deposit_distance < player.global_position.distance_squared_to(resource.position)) and (cache.is_empty() or deposit_distance < player.global_position.distance_squared_to(cache.position)):
			var state := progress.mining_snapshot(2, deposit.id, now)
			return {"kind": "mining", "id": deposit.id, "label": "Minerar"} if state.remaining > 0 else {"kind": "mining_exhausted", "id": deposit.id, "label": "Depósito esgotado", "ready_at": state.ready_at}
	if not resource.is_empty() and (cache.is_empty() or player.global_position.distance_squared_to(resource.position) <= player.global_position.distance_squared_to(cache.position)):
		return {"kind": "resource", "id": resource.id, "label": "Coletar " + resource.item}
	if not cache.is_empty():
		return {"kind": "cache", "id": cache.id, "label": "Baú escondido"}
	return {}

func _start_mining(id: String) -> void:
	if mining_active or transitioning or trial.active() or not FloorCatalog.feature(progress.ascension.current_floor,"mining") or not player.health.is_alive(): return
	var config := MiningRules.definition(2, id)
	if config.is_empty() or player.global_position.distance_to(config.position) > MiningRules.RANGE: return
	var now := int(Time.get_unix_time_from_system())
	if progress.mining_snapshot(2, id, now).remaining <= 0: return
	mining_active = true
	mining_token += 1
	var token := mining_token
	var start_position := player.global_position
	input_driver.reset()
	input_driver.blocked = true
	hud.set_nearby_station("")
	player.view.set_facing(Vector2.RIGHT if config.position.x >= player.position.x else Vector2.LEFT)
	(world.get_node("FloorView") as Floor2View).play_mining(start_position, config.position)
	await get_tree().create_timer(MiningRules.DURATION).timeout
	if not is_inside_tree() or token != mining_token: return
	mining_active = false
	input_driver.blocked = false
	if transitioning or trial.active() or not player.health.is_alive() or not FloorCatalog.feature(progress.ascension.current_floor,"mining") or player.global_position.distance_to(config.position) > MiningRules.RANGE or player.global_position.distance_to(start_position) > 25.0:
		return
	var outcome := progress.mine_deposit(2, id, int(Time.get_unix_time_from_system()), mining_rng)
	if outcome.is_empty(): return
	(world.get_node("FloorView") as Floor2View).set_mining_state(progress, int(Time.get_unix_time_from_system()))
	var drop: Dictionary = outcome.drop
	if drop.is_empty():
		hud.show_notice("Nenhum minério desta vez")
	else:
		var name: String = drop.item + " " + ArsenalRules.RARITIES[drop.rarity].name
		var tint := Color(ArsenalRules.RARITIES[drop.rarity].color)
		hud.show_notice("+1 " + name, tint)
	if int(outcome.remaining) == 0:
		hud.show_notice("Depósito esgotado · volta em 5 min" if drop.is_empty() else "+1 %s · depósito esgotado" % (drop.item + " " + ArsenalRules.RARITIES[drop.rarity].name), Color(ArsenalRules.RARITIES[drop.rarity].color) if not drop.is_empty() else Color("#fff0ce"))
	_save_progress()

func _station_action(action: String, item: String) -> void:
	if transitioning:
		return
	if hud.station_name == TowerEntrance.NAME and hud.station_panel.visible:
		if action == "Entrar" and not trial.active() and TowerEntrance.is_near(player.global_position,progress.ascension.current_floor):
			_enter_trial()
		elif action == "Viajar" and item.is_valid_int() and FloorCatalog.has_floor(int(item)) and TowerEntrance.is_near(player.global_position,progress.ascension.current_floor):
			_travel_floor(int(item))
		elif action == "Retornar" and trial.active():
			_return_from_trial(false)
		return
	if not player.health.is_alive() or hud.station_panel.visible == false:
		return
	var success := false
	match [hud.station_name, action]:
		["Ferreiro", "first_weapon"]:
			var at_smith := not trial.active() and SafeCamp.nearest_station(player.global_position,FloorCatalog.feature(progress.ascension.current_floor,"village_camp")) == "Ferreiro"
			if progress.claim_first_weapon(item,at_smith):
				mission.enabled = true
				player.apply_progression(progress)
				_refresh_mission()
				hud.minimap.queue_redraw()
				hud.expanded_map.queue_redraw()
				hud.first_weapon_page = 0
				hud.first_weapon_selected = ""
				hud.show_notice("O Primeiro Passo concluído · " + RPGRules.EQUIPMENT[item].name)
				hud.set_rpg_status(progress,player)
			else:
				hud.show_notice(progress.save_status if not progress.save_status.is_empty() else "Escolha indisponível. Nenhuma arma concedida.")
		["Ferreiro", "buy_starter"]:
			var at_smith := not trial.active() and SafeCamp.nearest_station(player.global_position,FloorCatalog.feature(progress.ascension.current_floor,"village_camp")) == "Ferreiro"
			success = progress.purchase_starter_weapon(item,at_smith)
			if success:
				player.apply_progression(progress)
				hud.smith_shop_selected = ""
			else:
				hud.show_notice(progress.save_status if progress.save_blocked else "Compra indisponível: confira seu ouro e as armas possuídas.")
		["Ferreiro", "craft_weapon"]:
			if progress.training_mode or not trial.active() and SafeCamp.nearest_station(player.global_position,FloorCatalog.feature(progress.ascension.current_floor,"village_camp")) == "Ferreiro":
				var parts := item.split("|")
				if parts.size() == 2:
					var uid := progress.craft_weapon(parts[0],parts[1])
					success = uid != ""
					if success: hud.smith_instance_selected = uid
		["Ferreiro", "craft_vale_iron"]:
			if progress.training_mode or not trial.active() and SafeCamp.nearest_station(player.global_position,FloorCatalog.feature(progress.ascension.current_floor,"village_camp")) == "Ferreiro":
				var uid := progress.craft_vale_iron(item)
				success = uid != ""
				if success: hud.smith_instance_selected = uid
		["Ferreiro", "craft_set"]:
			if progress.training_mode or not trial.active() and SafeCamp.nearest_station(player.global_position,FloorCatalog.feature(progress.ascension.current_floor,"village_camp")) == "Ferreiro":
				var set_parts := item.split("|")
				if set_parts.size() == 2 and set_parts[0].is_valid_int():
					var set_uid := progress.craft_set(int(set_parts[0]),set_parts[1])
					success = set_uid != ""
					if success and progress.weapon_instances.has(set_uid): hud.smith_instance_selected = set_uid
		["Ferreiro", "use_fragment"]:
			if progress.training_mode or not trial.active() and SafeCamp.nearest_station(player.global_position,FloorCatalog.feature(progress.ascension.current_floor,"village_camp")) == "Ferreiro":
				var fragment_parts := item.split("|")
				if fragment_parts.size() == 2 and fragment_parts[0].is_valid_int(): success = progress.use_fragment(int(fragment_parts[0]),fragment_parts[1])
		["Ferreiro", "evolve_weapon"]:
			if progress.training_mode or not trial.active() and SafeCamp.nearest_station(player.global_position,FloorCatalog.feature(progress.ascension.current_floor,"village_camp")) == "Ferreiro": success = progress.evolve_weapon(item)
		["Ferreiro", "evolve_equipment"]:
			if progress.training_mode or not trial.active() and SafeCamp.nearest_station(player.global_position,FloorCatalog.feature(progress.ascension.current_floor,"village_camp")) == "Ferreiro": success = progress.evolve_equipment(item)
		["Ferreiro", "enhance_weapon"]:
			if progress.training_mode or not trial.active() and SafeCamp.nearest_station(player.global_position,FloorCatalog.feature(progress.ascension.current_floor,"village_camp")) == "Ferreiro":
				var outcome := progress.enhance_weapon(item,hud.smith_use_seal)
				success = not outcome.is_empty()
				if success: hud.show_notice("Aprimoramento +%d %s" % [outcome.level,"concluído" if outcome.success else "falhou"])
		["Ferreiro", "weapon_bonus"]:
			if progress.training_mode or not trial.active() and SafeCamp.nearest_station(player.global_position,FloorCatalog.feature(progress.ascension.current_floor,"village_camp")) == "Ferreiro":
				var parts := item.split("|")
				if parts.size() == 3 and parts[1].is_valid_int(): success = progress.choose_weapon_bonus(parts[0],int(parts[1]),parts[2])
		["Baú", "Guardar"]: success = progress.transfer(item, true)
		["Baú", "Retirar"]: success = progress.transfer(item, false)
		["Vendedor", "Comprar"]: success = progress.buy(item)
		["Vendedor", "Vender"]: success = progress.sell(item)
	if success:
		if action in ["craft_weapon","craft_vale_iron","evolve_weapon","enhance_weapon","weapon_bonus"]: player.apply_progression(progress)
		earned_gold = progress.gold
		_save_progress()
		var trade_text := "%s: 1 %s" % [action, item]
		if action == "buy_starter":
			trade_text = "%s comprada e equipada · -%d ouro" % [RPGRules.EQUIPMENT[item].name,GameProgress.starter_weapon_price(item)]
		if action == "Vender":
			trade_text += " · +%d ouro" % GameProgress.sell_price(item)
		elif action == "Comprar":
			trade_text += " · -%d ouro" % GameProgress.buy_price(item)
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
	for i in range(2):
		if event.is_action_pressed(["skill_1", "skill_2"][i]):
			_use_skill(i)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ultimate"):
		_use_skill(3)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		if hud.map_panel.visible:
			_toggle_map()
		elif hud.equipment_screen.visible:
			hud.close_equipment_screen()
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
		elif hud.equipment_screen.visible:
			hud.close_equipment_screen()
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
	if hud.equipment_screen.visible: return
	if hud.rpg_panel.visible:
		hud.close_character()
		input_driver.blocked = false
		station_nearby = ""
	elif player.health.is_alive() and not hud.inventory_open and not hud.station_panel.visible and not hud.map_panel.visible:
		input_driver.reset()
		input_driver.blocked = true
		hud.rpg_panel.allow_respec = progress.training_mode or not trial.active() and SafeCamp.in_clearance(player.global_position)
		hud.show_character(progress)

func _equipment_loadout_action(action: String, index: int) -> void:
	if not hud.equipment_screen.visible or not player.health.is_alive():
		return
	if action == "select":
		hud.equipment_selected_set = index
		hud.refresh_equipment_screen(progress)
		return
	var success := false
	if action == "save":
		success = progress.save_loadout(index)
	elif action == "apply":
		success = progress.apply_loadout(index)
	if not success:
		hud.show_notice("Conjunto indisponível")
		return
	hud.equipment_selected_set = index
	if action == "apply": player.apply_progression(progress)
	_save_progress()
	hud.refresh_equipment_screen(progress)
	hud.show_notice("Conjunto salvo" if action == "save" else "Conjunto equipado")

func _equipment_expansion_action(with_gems: bool) -> void:
	if not hud.equipment_screen.visible or not player.health.is_alive(): return
	if not progress.expand_bag(with_gems):
		hud.show_notice("Expansão indisponível")
		return
	earned_gold = progress.gold
	_save_progress()
	hud.refresh_equipment_screen(progress)
	hud.set_progress(earned_xp, earned_gold, defeated_count, "Mochila ampliada para %d espaços" % progress.bag_capacity())

func _toggle_map() -> void:
	if transitioning or hud.save_panel.visible:
		return
	if hud.equipment_screen.visible: return
	if hud.map_panel.visible:
		hud.close_map()
		input_driver.blocked = false
		station_nearby = ""
	elif player.health.is_alive() and not hud.inventory_open and not hud.station_panel.visible and not hud.rpg_panel.visible:
		input_driver.reset()
		input_driver.blocked = true
		hud.show_map(progress)


func _rpg_action(action: String, id: String, expected: int) -> void:
	if progress.training_mode and FloorCatalog.feature(progress.ascension.current_floor,"mining") and action.begins_with("training_mining_"):
		match action:
			"training_mining_reset": progress.reset_mining_for_training(2)
			"training_mining_common": progress.add_item(EquipmentEconomy.key("Minério de Ferro", "comum"), 5)
			"training_mining_rare": progress.add_item(EquipmentEconomy.key("Minério de Ferro", "raro"), 5)
		(world.get_node("FloorView") as Floor2View).set_mining_state(progress, int(Time.get_unix_time_from_system()))
		hud.rpg_panel.refresh(progress)
		hud.show_notice("Treino de mineração atualizado")
		return
	if action == "training_smith" and progress.training_mode:
		hud.close_character()
		input_driver.reset()
		input_driver.blocked = true
		hud.show_station("Ferreiro",progress)
		return
	if action == "training_start":
		_start_training()
		return
	if action == "training_exit" and progress.training_mode:
		get_tree().reload_current_scene()
		return
	if action == "training_refill" and progress.training_mode:
		TrainingMode.refill(progress)
		player._cancel_skill1()
		player._sync_skill_cooldowns()
		hud.rpg_panel.refresh(progress)
		hud.show_notice("Skills e Ultimates recarregadas no treino")
		return
	if not player.health.is_alive():
		return
	var success := false
	if hud.equipment_screen.visible and action in ["equip", "unequip"]:
		if action == "equip": success = progress.equip_weapon_instance(id) if progress.weapon_instances.has(id) else progress.equip(id)
		else: success = progress.unequip(id)
	elif hud.rpg_panel.visible:
		var at_camp := progress.training_mode or not trial.active() and SafeCamp.in_clearance(player.global_position)
		if not at_camp: return
		if action == "attribute": success = progress.allocate_attribute(id)
		elif action == "skill":
			var parts := id.split(":")
			if parts.size() == 2 and int(progress.abilities.grades.get(parts[0],{}).get(parts[1],1)) == expected: success = progress.improve_skill(id,true)
		elif action == "talent":
			var parts := id.split(":")
			if parts.size() == 2: success = progress.learn_talent(parts[0],parts[1],true)
		elif action == "mastery":
			var parts := id.split(":")
			if parts.size() == 2: success = progress.talents.allocate_mastery(parts[0],parts[1],expected)
		elif action in ["reset_mastery","reset_tree"]: success = progress.configure_ability(action,id,"",0,true)
		elif action in ["equip_skill","equip_ultimate","equip_passive","specialization"]:
			var parts := id.split(":")
			if parts.size() == 2: success = progress.configure_ability(action,parts[0],parts[1],expected,true)
	elif hud.station_panel.visible and hud.station_name == "Ferreiro" and action == "forge":
		success = progress.forge(id, expected)
	elif hud.inventory_open and hud.inventory_category == 1:
		if action == "equip":
			success = progress.equip_weapon_instance(id) if progress.weapon_instances.has(id) else progress.equip(id)
		elif action == "equip_instance":
			success = progress.equip_weapon_instance(id)
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
	if hud.equipment_screen.visible:
		hud.refresh_equipment_screen(progress)
	elif hud.rpg_panel.visible:
		hud.rpg_panel.refresh(progress)
	elif hud.station_panel.visible:
		hud.refresh_station(progress)
	hud.show_notice("Equipamento fabricado/aprimorado" if action == "forge" else "Personagem atualizado")


func _start_training() -> void:
	if progress.training_mode or transitioning or trial.active() or not player.health.is_alive(): return
	# Checkpoint the real character before switching to a disposable build.
	_save_progress()
	if not progress.save() or progress.save_blocked:
		hud.show_notice("Salve seu personagem antes de iniciar o treino")
		return
	progress.browser.detach()
	var training_floor := progress.ascension.current_floor
	progress = TrainingMode.create(training_floor)
	earned_xp = progress.xp
	earned_gold = progress.gold
	defeated_count = 0
	known_level = progress.level()
	mission.enabled = false
	collected_materials = progress.bag
	hud.close_character()
	input_driver.reset()
	input_driver.blocked = false
	# The east clearing keeps the explorer and target visible below the canopies.
	player.position = FloorCatalog.def_or_default(training_floor).training_spawn
	player.last_direction = Vector2.RIGHT
	player.view.set_facing(Vector2.RIGHT)
	player.apply_progression(progress,true)
	enemy.set_physics_process(false)
	enemy.awake = true
	enemy.position = player.position+Vector2(65,0)
	enemy.home_position = enemy.position
	enemy.health.initialize(1000000)
	for actor in get_tree().get_nodes_in_group("damageable_enemies"):
		if actor != enemy: actor.queue_free()
	hud.minimap.progress = progress
	exploration_view.progress = progress
	hud.set_health(player.health.current,player.health.maximum)
	hud.set_progress(earned_xp,earned_gold,defeated_count,"Alvo de treino à direita")
	_update_floor_identity()
	_refresh_mission()
	hud.set_rpg_status(progress,player)
	hud.show_notice("Modo treino · 5 armas e proficiência 60 · nada será salvo")

func _adapt_orientation() -> void:
	var window := get_window()
	# Logical short side 360 keeps touch targets readable in either orientation.
	var desired := Vector2i(360, 640) if window.size.y > window.size.x else Vector2i(640, 360)
	if window.content_scale_size != desired:
		window.content_scale_size = desired
	hud.call_deferred("_layout")
	# Cap tall embedded views to the world height instead of showing blank land.
	var camera := player.get_node("Camera2D") as Camera2D
	var visible_height := float(desired.x)*window.size.y/window.size.x if window.size.y > window.size.x else float(desired.y)
	var village := progress != null and FloorCatalog.feature(progress.ascension.current_floor,"village_camp") and not trial.active()
	var landscape_village := village and window.size.x >= window.size.y
	camera.zoom = Vector2.ONE * (0.75 if landscape_village else maxf(1.0,visible_height/850.0) if village else 1.0)
	camera.offset = Vector2(0,-35) if landscape_village else Vector2.ZERO


func _record_adventure(id: String) -> void:
	if progress.introduction_active(): return
	progress.xp = earned_xp
	progress.gold = earned_gold
	var reward := progress.record_adventure(id)
	earned_xp = progress.xp
	earned_gold = progress.gold
	if not reward.is_empty():
		hud.show_notice("Desafio concluído! +%d XP · +%d ouro" % [reward.xp, reward.gold])

func _start_guardian() -> void:
	if progress.introduction_active(): return
	if progress.ascension.current_floor >= 3 and not FloorCatalog.feature(progress.ascension.current_floor,"field_guardian_enabled"):
		hud.show_notice("Guardião do andar · conteúdo entra após a aprovação do mapa")
		return
	if trial.active() or transitioning:
		return
	if is_instance_valid(guardian) or progress.floor_states[str(progress.ascension.current_floor)].guardian_defeated:
		return
	if get_tree().get_nodes_in_group("damageable_enemies").size() >= MAX_ENEMIES:
		hud.show_notice("Elimine uma criatura antes de desafiar o Guardião")
		return
	guardian = ENEMY_SCENE.instantiate() as EnemyActor
	var template := guardian.stats.duplicate() as ActorData
	var boss: Dictionary = FloorCatalog.def_or_default(progress.ascension.current_floor).field_guardian
	var vale: bool = boss.variant == "colossus"
	var whispers: bool = boss.variant == "whispers"
	guardian.set_script(WHISPERS_SCRIPT if whispers else SANDSTONE_COLOSSUS_SCRIPT if vale else GUARDIAN_SCRIPT)
	guardian.get_node("View").set_script(WHISPERS_VIEW if whispers else SANDSTONE_COLOSSUS_VIEW if vale else GUARDIAN_VIEW)
	if whispers: (guardian as MotherOfWhispers).arena = Floor3Layout.GUARDIAN_ARENA.grow(30.0)
	guardian.kind = 4
	guardian.stats = template
	guardian.stats.max_hp = int(boss.hp)
	guardian.stats.move_speed = float(boss.speed)
	if float(boss.radius) > 0.0:
		var body := CircleShape2D.new()
		body.radius = float(boss.radius)
		guardian.get_node("Collision").shape = body
	guardian.position = _guardian_altar_position() + Vector2(0, 80)
	(guardian as RootGuardian).phases.setup(progress.ascension.current_floor,"field")
	guardian.target = player
	_apply_floor_stats(guardian)
	guardian.summon_requested.connect(_on_boss_summon.bind(guardian))
	_register_enemy_defeat(guardian)
	guardian.projectile_requested.connect(_on_enemy_projectile)
	add_child(guardian)
	guardian.view.damage_occluders = hud.damage_occluders
	hud.show_notice(str(boss.notice))

func _guardian_altar_position() -> Vector2:
	return FloorCatalog.guardian_altar(progress.ascension.current_floor)

func _refresh_mission() -> void:
	if progress.training_mode:
		hud.set_mission("MODO TREINO · sem salvar\nTroque arma na Mochila · habilidades no Diário")
		return
	hud.set_mission(progress.introduction_summary() if progress.introduction_active() else trial.summary() if trial.active() else mission.summary() + "\n" + progress.adventure_summary())

func _clear_combat_actors() -> void:
	for node in get_children():
		if node is EnemyActor or node is EnemyProjectile or node is PlayerProjectile:
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
	_adapt_orientation()
	camera.reset_smoothing()
	camera.force_update_scroll()

func _enter_trial() -> void:
	if progress.introduction_active(): return
	if progress.ascension.current_floor >= 3 and not FloorCatalog.feature(progress.ascension.current_floor,"tower_enabled"):
		hud.show_notice("Torre do andar · desafios entram após a aprovação do mapa")
		return
	if transitioning or trial.active() or not player.health.is_alive() or not progress.ascension.entrance_unlocked():
		return
	transitioning = true
	RenderingServer.set_default_clear_color(Color("#101c16"))
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
	trial.start(progress.ascension.current_floor)
	(arena.get_node("Floor") as TowerArenaView).floor_id = trial.floor_id
	(arena.get_node("Floor") as TowerArenaView).queue_redraw()
	hud.heading.text = "Torre · Andar %d" % trial.floor_id
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
		elif node is EnemyProjectile or node is PlayerProjectile:
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
	var kinds: Array = trial.wave_kinds()
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
	player.global_position = SafeCamp.respawn_for_floor(progress.ascension.current_floor)
	player.velocity = Vector2.ZERO
	player.charge_left = 0.0
	player.dash.time_left = 0.0
	if died:
		player.health.initialize(player.stats.max_hp) # Same HP recovery as normal restart.
	hud.restart.hide()
	_update_floor_identity()
	hud.minimap.arena_bounds = Rect2()
	hud.minimap.update_player(player.global_position)
	_camera_bounds(Rect2(Vector2.ZERO, FloorConfig.world_size(progress.ascension.current_floor)))
	spawn_remaining = SPAWN_INTERVAL
	if camps_mode: encounter_camps.reset()
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
	hud.show_notice("Retorno ao Andar %d · próxima tentativa começa na Horda 1" % progress.ascension.current_floor)

func _exit_tree() -> void:
	progress.browser.detach()
	# A reload during a trial discards it; free the temporarily detached Mata.
	if is_instance_valid(world) and world.get_parent() == null:
		world.free()

func _pause_combat() -> void:
	for node in get_children():
		if node is EnemyActor or node is EnemyProjectile or node is PlayerProjectile:
			node.set_physics_process(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_instance_valid(hud) and is_instance_valid(player):
			_save_progress()

func _open_record() -> void:
	if progress.training_mode:
		hud.show_notice("Treino temporário · registro normal preservado")
		return
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
				JavaScriptBridge.download_buffer(progress.export_backup().to_utf8_buffer(), "arveon-save.json", "application/json")
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
	save_dialog.current_file = "arveon-save.json" if exporting else ""
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
	var tower_boss: Dictionary = FloorCatalog.def_or_default(trial.floor_id).tower_guardian
	actor.get_node("View").set_script(SANDSTONE_TOWER_GUARDIAN_VIEW if tower_boss.variant == "arenito" else WHISPERS_TOWER_VIEW if tower_boss.variant == "pantano" else TOWER_GUARDIAN_VIEW)
	tower_guardian = actor as TowerGuardian
	var body := CircleShape2D.new()
	body.radius = float(tower_boss.radius)
	tower_guardian.get_node("Collision").shape = body
	tower_guardian.kind = 4
	tower_guardian.stats = template
	tower_guardian.stats.max_hp = int(tower_boss.hp)
	tower_guardian.stats.move_speed = float(tower_boss.speed)
	tower_guardian.phases.setup(trial.floor_id,"tower")
	tower_guardian.target = player
	_apply_floor_stats(tower_guardian)
	tower_guardian.summon_requested.connect(_on_boss_summon.bind(tower_guardian))
	tower_guardian.set_meta("floor_id", trial.floor_id)
	tower_guardian.set_meta("floor_epoch", floor_epoch)
	tower_guardian.arena_bounds = TowerTrial.BOUNDS
	tower_guardian.position = trial.guardian_spawn_position(player.position)
	tower_guardian.set_meta("tower_attempt", trial.attempt_id)
	tower_guardian.defeated.connect(_on_tower_guardian_defeated.bind(tower_guardian, trial.attempt_id), CONNECT_ONE_SHOT)
	tower_guardian.weapon_hit.connect(_on_weapon_hit.bind(tower_guardian))
	add_child(tower_guardian)
	tower_guardian.view.damage_occluders = hud.damage_occluders
	hud.set_boss(tower_guardian)
	hud.show_notice("%s · desvie dos avisos no chão" % FloorConfig.tower_guardian_name(trial.floor_id))

func _on_tower_guardian_defeated(_kind: int, source: EnemyActor, token: int) -> void:
	if transitioning or trial.phase != TowerTrial.Phase.GUARDIAN or token != trial.attempt_id or trial.floor_id != progress.ascension.current_floor or source.get_meta("floor_id", 0) != trial.floor_id or source != tower_guardian or source.get_parent() != self or source.health.is_alive() or source.get_meta("defeat_recorded", false):
		return
	source.set_meta("defeat_recorded", true)
	trial.phase = TowerTrial.Phase.VICTORY
	victory_first = progress.ascension.complete_forest_trial()
	var trophy_text := ""
	for drop: Dictionary in LootRules.tower_boss(trial.floor_id):
		progress.add_item(drop.key)
		trophy_text += (" · " if not trophy_text.is_empty() else "") + "+1 %s" % drop.item
	if not trophy_text.is_empty(): hud.show_notice(trophy_text)
	if victory_first:
		progress.grant_gems(5)
		earned_xp += FloorConfig.reward(AscensionProgress.GUARDIAN_XP, trial.floor_id)
		earned_gold += FloorConfig.reward(AscensionProgress.GUARDIAN_GOLD, trial.floor_id)
	# Snapshot includes reward and claim together; load/import never grants rewards.
	_save_progress()
	hud.set_boss(null)
	input_driver.reset()
	input_driver.blocked = true
	hud.victory_first = victory_first
	hud.show_station(TowerEntrance.NAME, progress)
	_refresh_mission()

func _update_floor_identity() -> void:
	var floor_id := progress.ascension.current_floor
	var expanded_first := FloorCatalog.feature(floor_id,"expanded_world")
	var modern_art := FloorCatalog.feature(floor_id,"modern_art")
	SafeCamp.active_floor = floor_id
	player.view.village_scale = modern_art
	player.view.queue_redraw()
	_adapt_orientation()
	var clear_color := Color("#172b27") if floor_id == 3 else Color("#b9cf55") if modern_art else Color("#101c16")
	RenderingServer.set_default_clear_color(clear_color)
	(world.get_node("FloorView") as FloorView).set_visual_v2(expanded_first)
	(world as FloorWorld).set_expanded_world(expanded_first)
	tower_view.visual_v2 = expanded_first
	tower_view.position = TowerEntrance.position_for_floor(floor_id)
	tower_view.queue_redraw()
	exploration_view.visual_v2 = modern_art
	exploration_view.current_floor = floor_id
	if FloorCatalog.feature(floor_id,"mining"): (world.get_node("FloorView") as Floor2View).set_mining_state(progress, int(Time.get_unix_time_from_system()))
	exploration_view.queue_redraw()
	(world.get_node("FloorView") as FloorView).secret_path_revealed = floor_id == 1 and progress.discovered_pois.has("secretwood_wood_southeast")
	_camera_bounds(Rect2(Vector2.ZERO,FloorConfig.world_size(floor_id)))
	hud.heading.text = "TREINO · Andar %d" % floor_id if progress.training_mode else FloorCatalog.heading(floor_id)
	hud.minimap.queue_redraw()

func _travel_floor(destination: int) -> void:
	if progress.introduction_active(): return
	if transitioning or mining_active or trial.active() or not player.health.is_alive() or destination == progress.ascension.current_floor or not progress.ascension.can_travel(destination):
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
	floor_epoch += 1
	remove_child(world)
	world.queue_free()
	progress.switch_floor(destination)
	SafeCamp.active_floor = destination
	world = (load(FloorConfig.world_scene(destination)) as PackedScene).instantiate()
	add_child(world)
	move_child(world, 0)
	exploration_view = world.get_node("ExploreView") as ExplorationView
	tower_view = world.get_node("TowerView") as TowerView
	exploration_view.progress = progress
	exploration_view.current_time = int(Time.get_unix_time_from_system())
	player.position = SafeCamp.respawn_for_floor(destination)
	player.velocity = Vector2.ZERO
	player.charge_left = 0
	player.dash.time_left = 0
	guardian = null
	var encounters_enabled := _floor_encounters_enabled(destination)
	enemy = _make_enemy(FloorCatalog.first_enemy_kind(destination)) if encounters_enabled else _make_enemy(0)
	enemy.position = FloorCatalog.first_enemy_position(destination) if encounters_enabled else SafeCamp.respawn_for_floor(destination) + Vector2(80, 0)
	enemy.target = player
	add_child(enemy)
	if encounters_enabled:
		_register_enemy_defeat(enemy)
		enemy.projectile_requested.connect(_on_enemy_projectile)
	else:
		_disable_preview_enemy(enemy)
	enemy.view.damage_occluders = hud.damage_occluders
	hud.minimap.arena_bounds = Rect2()
	hud.minimap.update_player(player.position)
	_camera_bounds(Rect2(Vector2.ZERO, MiniMap.WORLD_SIZE))
	spawn_remaining = SPAWN_INTERVAL
	_setup_encounters()
	station_nearby = ""
	hud.set_nearby_station("")
	_update_floor_identity()
	_save_progress()
	await hud.fade_transition(false)
	transitioning = false
	hud.transition_active = false
	input_driver.reset()
	input_driver.blocked = false
	hud._sync_controls()
	hud.show_notice("Chegada segura · Andar %d" % destination)

func _on_player_projectile(origin: Node2D, target: Node2D, specification: Dictionary) -> void:
	if origin != player or transitioning or input_driver.blocked or not player.health.is_alive():
		return
	if get_tree().get_nodes_in_group("player_projectiles").size() >= PlayerProjectile.MAX_ACTIVE:
		return
	# Only approved basic ranged attacks use attached pose/muzzle presentation.
	# Approved Skill 1 uses its own presentation; other techniques keep theirs.
	var basic_bow: bool = player.view.village_scale and specification.get("category","") == "arco" and specification.get("kind","") == "flecha" and specification.get("source","basic") == "basic" and not specification.get("ultimate",false)
	var basic_staff: bool = player.view.village_scale and specification.get("category","") == "cajado" and specification.get("kind","") == "orbe" and specification.get("source","basic") == "basic" and not specification.get("ultimate",false)
	var category: String = specification.get("category","")
	var special: bool = player.view.village_scale and category in ["arco","cajado"] and not specification.get("ultimate",false) and specification.get("source","") == AbilityRules.CATEGORIES[category].skill1.id
	if special and player.view is Skill1GameView:
		player.view.skill1_direction = (target.global_position-player.global_position).normalized()
	var shot := Skill1GameProjectile.new() if special else StaffProjectile.new() if basic_staff else BowProjectile.new() if basic_bow else PlayerProjectile.new()
	add_child(shot)
	shot.setup(player, target, specification, TowerTrial.BOUNDS if trial.active() else Rect2(Vector2.ZERO, FloorConfig.world_size(progress.ascension.current_floor)))
