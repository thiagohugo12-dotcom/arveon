extends SceneTree

var failures: int = 0
var checks: int = 0
var deaths: int = 0

func _initialize() -> void:
	# A runtime error can abort _run before quit; always bound the runner itself.
	create_timer(15.0).timeout.connect(func():
		push_error("FAIL: gameplay tests did not finish within 15 seconds")
		quit(1)
	)
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func frames(count: int = 2) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func _run() -> void:
	var test_path := "user://qa_area_segura_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH", test_path)
	var health := Health.new()
	root.add_child(health)
	health.initialize(10)
	health.died.connect(func(): deaths += 1)
	health.damage(-5)
	check(health.current == 10, "negative damage ignored")
	health.damage(30)
	health.damage(1)
	check(health.current == 0 and deaths == 1, "HP clamps and death emits once")
	health.queue_free()
	var stats: ActorData = load("res://data/actors/player.tres")
	var dash := DashMotor.new()
	root.add_child(dash)
	check(dash.request(Vector2.RIGHT, Vector2.DOWN, stats) and dash.direction == Vector2.RIGHT, "dash uses current direction")
	check(not dash.request(Vector2.UP, Vector2.UP, stats), "dash cooldown rejects repeat")
	dash.tick(2.0)
	check(dash.request(Vector2.ZERO, Vector2.UP, stats) and dash.direction == Vector2.UP, "stationary dash uses last direction")
	dash.queue_free()
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await frames()
	var player := main.get_node("Player") as PlayerActor
	var enemy := main.get_node("Enemy") as EnemyActor
	var driver := main.get_node("InputDriver") as InputDriver
	var hud := main.get_node("Interface/HUD") as GameHUD
	enemy.set_physics_process(false)
	enemy.target = null
	player.set_physics_process(false)
	Input.action_press("move_up")
	Input.action_press("move_right")
	check(is_equal_approx(driver.movement().length(), 1.0), "keyboard diagonal normalized")
	Input.action_release("move_up")
	Input.action_release("move_right")
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2(-1,-1), Vector2(1,-1), Vector2(-1,1), Vector2(1,1)]:
		driver.set_touch_direction(direction)
		check(driver.movement().is_equal_approx(direction.limit_length()), "8 direction input " + str(direction))
	driver.reset()
	player.position = Vector2(810, 400)
	enemy.position = Vector2(1000, 400)
	await frames()
	check(player.attack.select_target(player) == null, "out of range excluded")
	enemy.position = Vector2(930, 400)
	await frames()
	check(player.attack.select_target(player) == enemy, "target at reach boundary valid")
	var second := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as EnemyActor
	main.add_child(second)
	second.set_physics_process(false)
	second.position = Vector2(860, 400)
	await frames()
	check(player.attack.select_target(player) == second, "nearest valid target selected")
	player.attack.cooldown_left = 0.0
	player.attack.tick(0.016, player)
	check(second.health.current == 36 and enemy.health.current == 48, "automatic attack damages selected target only")
	player.attack.tick(0.016, player)
	check(second.health.current == 36, "attack cooldown enforced")
	second.receive_damage(999)
	check(player.attack.select_target(player) == enemy, "dead target excluded immediately")
	await frames()
	player.position = Vector2(805, 510)
	enemy.position = Vector2(805, 630)
	await frames()
	check(player.attack.select_target(player) == null, "world obstacle blocks automatic attack")
	player.position = Vector2(1160, 400)
	enemy.position = Vector2(100, 800)
	driver.set_touch_direction(Vector2.RIGHT)
	driver.request_dash()
	player.set_physics_process(true)
	await frames(12)
	check(player.position.x <= 1171.1 and player.position.x > 1160, "dash respects wall collision")
	driver.reset()
	player.set_physics_process(false)
	hud.size = Vector2(360, 640)
	hud._layout()
	check(hud.dash_button.position.x > hud.size.x * 0.5 and hud.dash_button.get_rect().end.x <= hud.size.x, "portrait dash on right within HUD")
	check(not hud.joystick.get_rect().intersects(hud.dash_button.get_rect()), "portrait controls do not overlap")
	hud.size = Vector2(640, 360)
	hud._layout()
	check(hud.dash_button.position.x > hud.size.x * 0.5 and hud.dash_button.get_rect().end.y <= hud.size.y, "landscape dash on right within HUD")
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = hud.joystick.global_position + hud.joystick.size * 0.5 + Vector2(48, 0)
	hud.joystick._input(touch)
	check(driver.movement().x > 0.5, "simulated joystick touch drives command")
	var action_touch := InputEventScreenTouch.new()
	action_touch.index = 1
	action_touch.pressed = true
	action_touch.position = hud.dash_button.global_position + Vector2(28, 28)
	hud.dash_button._input(action_touch)
	check(driver.consume_dash() and driver.movement().x > 0.5, "second touch requests dash while moving")
	action_touch.pressed = false
	hud.dash_button._input(action_touch)
	touch.pressed = false
	hud.joystick._input(touch)
	check(driver.movement().is_zero_approx(), "touch release clears movement")
	driver.set_touch_direction(Vector2.UP)
	driver.request_dash()
	driver._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(driver.movement().is_zero_approx() and not driver.consume_dash(), "focus loss clears pending commands")
	player.receive_damage(999)
	check(not player.health.is_alive() and hud.restart.visible and not hud.dash_button.enabled, "player death disables gameplay and offers restart")
	# The free contract is always available and immediately renews on completion.
	check(main.mission.summary().contains("Derrote criaturas 0/8"), "common hunt mission active without acceptance")
	for i in range(7):
		main.mission.record_defeat()
	check(main.mission.progress == 7 and main.mission.completed_count == 0, "mission progress counts defeated creatures")
	main.mission.record_defeat()
	check(main.mission.mission_index == 1 and main.mission.progress == 0, "completed hunt automatically creates collection mission")
	check(main.earned_xp == 40 and main.earned_gold == 12, "first free mission grants XP and gold")
	for i in range(5):
		main.mission.record_material()
	check(main.mission.mission_index == 0 and main.mission.completed_count == 2, "collecting materials automatically renews common mission")
	check(main.earned_xp == 70 and main.earned_gold == 22, "second free mission grants reward without spending gold")
	player.health.initialize(player.stats.max_hp)
	hud.restart.hide()
	check(main.progress.buy("Couro") and main.earned_gold == 22 and main.progress.gold == 17, "vendor spends existing gold wallet")
	main._station_action("Comprar", "Couro") # Closed panel must never trade.
	check(main.progress.gold == 17, "shop refuses action outside station")
	player.position = SafeCamp.STATIONS["Vendedor"] + Vector2(-30, 0)
	main._process(0.0)
	var open_touch := InputEventScreenTouch.new()
	open_touch.index = 5
	open_touch.pressed = true
	open_touch.position = hud.interact_button.global_position + hud.interact_button.size * 0.5
	hud.interact_button._input(open_touch)
	open_touch.pressed = false
	hud.interact_button._input(open_touch)
	await frames()
	var vendor_sell := hud.station_content.get_child(2).get_child(2) as Button
	check(hud.station_panel.visible and not vendor_sell.disabled, "vendor exposes an enabled sell button for owned material")
	var shop_touch := InputEventScreenTouch.new()
	shop_touch.index = 6
	shop_touch.pressed = true
	shop_touch.position = vendor_sell.global_position + vendor_sell.size * 0.5
	hud._input(shop_touch)
	check(main.progress.gold == 19 and main.progress.bag.get("Couro", 0) == 0, "vendor sells existing material into wallet")
	await frames()
	var vendor_buy := hud.station_content.get_child(4).get_child(1) as Button
	check(not vendor_buy.disabled, "vendor enables purchase with sufficient gold")
	check(hud.station_scroll.get_global_rect().has_point(vendor_buy.global_position + vendor_buy.size * 0.5), "all vendor buttons fit the mobile viewport")
	shop_touch.position = vendor_buy.global_position + vendor_buy.size * 0.5
	hud._input(shop_touch)
	check(main.progress.gold == 14 and main.progress.bag.get("Essência", 0) == 1, "vendor buy button exchanges gold for real material")
	var overlap_touch := InputEventScreenTouch.new()
	overlap_touch.index = 4
	overlap_touch.pressed = true
	overlap_touch.position = hud.interact_button.global_position + Vector2(40, 25)
	hud.interact_button._input(overlap_touch)
	check(hud.interact_button.touch_index == -1, "hidden interaction hitbox does not steal modal touch")
	shop_touch.position = hud.station_close_button.global_position + hud.station_close_button.size * 0.5
	hud._input(shop_touch)
	check(not hud.station_panel.visible and not driver.blocked, "close button releases movement and closes shop")
	main.progress.add_item("Essência", 2)
	player.position = SafeCamp.STATIONS["Baú"] + Vector2(28, 0)
	main._interact()
	main._station_action("Guardar", "Essência")
	check(main.progress.bag.get("Essência", 0) == 2 and main.progress.chest.get("Essência", 0) == 1, "chest transfer preserves total")
	await frames()
	var last_chest_button := hud.station_content.get_child(3).get_child(2) as Button
	check(hud.station_scroll.get_global_rect().has_point(last_chest_button.global_position + last_chest_button.size * 0.5), "all chest rows fit the mobile viewport")
	var interact_key := InputEventAction.new()
	interact_key.action = "interact"
	interact_key.pressed = true
	main._input(interact_key)
	check(not hud.station_panel.visible, "E closes an open station even with UI focus")
	main._save_progress()
	var reloaded := GameProgress.new()
	reloaded.save_path = test_path
	check(reloaded.load_save() and reloaded.gold == 14 and reloaded.chest.get("Essência", 0) == 1 and reloaded.mission_completed == 2, "save round-trip includes economy, chest and mission")
	check(reloaded.death_loss() == "Essência" and reloaded.bag.get("Essência", 0) == 1 and reloaded.chest.get("Essência", 0) == 1, "death protects chest and only removes a bag unit")
	check(not reloaded.buy("Broto Ancestral") and not reloaded.transfer("Couro", true), "unavailable purchase and empty transfer do not mutate state")
	player.health.initialize(player.stats.max_hp)
	player.position = SafeCamp.RESPAWN
	var safe_hp := player.health.current
	player.receive_damage(99)
	check(player.health.current == safe_hp and SafeCamp.nearest_station(SafeCamp.STATIONS["Ferreiro"]) == "Ferreiro", "camp prevents damage and exposes smith interaction")
	player.attack.cooldown_left = 0.0
	player.attack.tick(0.016, player)
	check(player.attack.cooldown_left == 0.0, "automatic attack stays off inside protected perimeter")
	check(SafeCamp.in_clearance(Vector2(779, 450)) and not SafeCamp.in_clearance(Vector2(790, 450)), "protection has a 130 px outer clearance")
	var guard := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as EnemyActor
	guard.kind = 1
	main.add_child(guard)
	guard.target = player
	guard.position = Vector2(810, 460)
	guard.home_position = guard.position
	guard._physics_process(0.016)
	check(guard.velocity.is_zero_approx(), "enemy does not attack a player in camp")
	var projectile := EnemyProjectile.new()
	main.add_child(projectile)
	projectile.setup(Vector2(657, 450), Vector2.LEFT, 8, player)
	projectile._physics_process(0.04)
	check(projectile.is_queued_for_deletion() and player.health.current == safe_hp, "enemy projectile dissolves at camp boundary")
	player.position = Vector2(560, 560)
	guard.position = Vector2(810, 455)
	for step in range(70):
		guard._physics_process(0.016)
	check(not SafeCamp.in_clearance(guard.position), "enemy path stays beyond the weapon reach of camp")
	main.mission.record_material()
	check(main.mission.progress == 0, "irrelevant material events do not advance hunt")
	# Enemy roles remain deliberately distinct and lightweight.
	player.health.initialize(player.stats.max_hp)
	player.position = Vector2(950, 750)
	var boar := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as EnemyActor
	boar.kind = 0
	boar.stats = boar.stats.duplicate() as ActorData
	main.add_child(boar)
	boar.target = player
	boar.global_position = player.global_position + Vector2(150, 0)
	boar.home_position = boar.global_position
	boar._physics_process(0.016)
	check(boar.charge_windup > 0.0, "boar telegraphs a charge at mid range")
	var spider := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as EnemyActor
	spider.kind = 1
	spider.stats = spider.stats.duplicate() as ActorData
	main.add_child(spider)
	spider.target = player
	spider.global_position = player.global_position + Vector2(55, 0)
	spider.home_position = spider.global_position
	spider._physics_process(0.016)
	check(spider.velocity.x > 0.0, "spider retreats when too close")
	var cactus := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as EnemyActor
	cactus.kind = 2
	cactus.stats = cactus.stats.duplicate() as ActorData
	main.add_child(cactus)
	cactus.target = player
	cactus.global_position = player.global_position + Vector2(180, 0)
	cactus.home_position = cactus.global_position
	cactus._physics_process(0.016)
	check(cactus.special_left > 0.0 and cactus.velocity.is_zero_approx(), "mandacaru prepares ranged attack at preferred distance")
	# AI suspension retains entity, position and HP. Distinct thresholds prevent rapid toggling.
	var persistent := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as EnemyActor
	main.add_child(persistent)
	persistent.position = Vector2(930, 750)
	persistent.home_position = persistent.position
	persistent.target = player
	persistent.receive_damage(7)
	var saved_hp := persistent.health.current
	var saved_position := persistent.position
	persistent.update_activity(saved_position + Vector2(650, 0))
	check(not persistent.awake and not persistent.is_physics_processing() and persistent.position == saved_position and persistent.health.current == saved_hp, "distant enemy sleeps without disappearing or resetting")
	persistent.receive_damage(100)
	check(persistent.health.current == saved_hp and not persistent.is_targetable(), "sleeping enemy cannot be farmed")
	persistent.update_activity(saved_position + Vector2(570, 0))
	check(not persistent.awake, "sleep threshold has hysteresis")
	persistent.update_activity(saved_position + Vector2(510, 0))
	check(persistent.awake and persistent.is_physics_processing() and persistent.health.current == saved_hp, "approaching wakes original enemy with original health")
	persistent.update_activity(saved_position + Vector2(570, 0))
	check(persistent.awake, "awake enemy does not flicker at intermediate distance")
	persistent.set_physics_process(false)
	player.position = saved_position + Vector2(150, 0)
	persistent._physics_process(0.016)
	check(persistent.chasing, "monster acquires target inside territory")
	persistent.position = saved_position + Vector2(90, 0)
	player.position = Vector2(180, 750)
	persistent._physics_process(0.1)
	check(not persistent.chasing and persistent.position.distance_to(saved_position) < 90.0, "monster returns toward home after losing player")
	# Gathering, exploration caches, persistence and the paged mobile station UI.
	player.position = Exploration.RESOURCE_SPOTS[0].position
	main._process(0.0)
	var herbs_before := int(main.progress.bag.get("Ervas", 0))
	main._input(interact_key)
	check(main.progress.bag.get("Ervas", 0) == herbs_before + 1 and hud.loot_label.text.contains("Ervas"), "keyboard gathering adds an existing inventory item with feedback")
	main._input(interact_key)
	check(main.progress.bag.get("Ervas", 0) == herbs_before + 1, "gathering cannot duplicate before five minute cooldown")
	var harvested := GameProgress.new()
	harvested.save_path = test_path
	check(harvested.load_save() and harvested.harvested_until.has("herb_west") and harvested.bag.get("Ervas", 0) == herbs_before + 1, "collected resource and cooldown survive reload")
	var now := int(Time.get_unix_time_from_system())
	check(harvested.collect_resource("herb_west", now + Exploration.RESOURCE_COOLDOWN + 1) == "Ervas", "resource respawns after real time cooldown")
	player.position = Exploration.HIDDEN_CHESTS[0].position
	main._process(0.0)
	var gold_before: int = main.progress.gold
	var leather_before := int(main.progress.bag.get("Couro", 0))
	var cache_touch := InputEventScreenTouch.new()
	cache_touch.index = 8
	cache_touch.pressed = true
	cache_touch.position = hud.interact_button.global_position + hud.interact_button.size * 0.5
	hud.interact_button._input(cache_touch)
	cache_touch.pressed = false
	hud.interact_button._input(cache_touch)
	check(main.progress.gold == gold_before + 6 and main.progress.bag.get("Couro", 0) == leather_before + 1 and hud.loot_label.text.contains("Baú escondido"), "touch opens hidden cache and shows balanced rewards")
	main._input(interact_key)
	check(main.progress.gold == gold_before + 6, "opened cache cannot grant duplicate reward")
	var cached := GameProgress.new()
	cached.save_path = test_path
	check(cached.load_save() and cached.opened_caches.has("west_roots") and cached.open_exploration_chest("west_roots").is_empty(), "opened cache remains claimed after reload")
	player.position = SafeCamp.STATIONS["Baú"] + Vector2(28, 0)
	main._interact()
	await frames()
	var next_page := hud.station_content.get_child(4).get_child(2) as Button
	var page_touch := InputEventScreenTouch.new()
	page_touch.index = 9
	page_touch.pressed = true
	page_touch.position = next_page.global_position + next_page.size * 0.5
	check(hud.station_scroll.get_global_rect().has_point(page_touch.position), "chest pagination fits mobile panel")
	hud._input(page_touch)
	await frames()
	check(hud.station_page == 1 and hud.station_content.get_child(2).get_child(0).text.begins_with("Ervas"), "touch page displays gathered material in storage")
	main._station_action("Guardar", "Ervas")
	check(main.progress.chest.get("Ervas", 0) == 1 and main.progress.bag.get("Ervas", 0) == herbs_before, "gathered resource transfers into protected chest")
	hud.close_station()
	player.position = SafeCamp.STATIONS["Vendedor"] + Vector2(-30, 0)
	main._interact()
	await frames()
	next_page = hud.station_content.get_child(5).get_child(2) as Button
	page_touch.position = next_page.global_position + next_page.size * 0.5
	check(hud.station_scroll.get_global_rect().has_point(page_touch.position), "vendor pagination fits mobile panel")
	hud._input(page_touch)
	await frames()
	check(hud.station_page == 1 and hud.station_content.get_child(2).get_child(0).text.begins_with("Ervas"), "touch page exposes resource sales")
	main.progress.add_item("Ervas")
	var sale_gold: int = main.progress.gold
	main._station_action("Vender", "Ervas")
	check(main.progress.gold == sale_gold + GameProgress.SELL_PRICE and main.progress.bag.get("Ervas", 0) == herbs_before, "vendor sells gathered resources through existing wallet")
	hud.close_station()
	main.queue_free()
	await frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	OS.unset_environment("GRANDE_ARVORE_SAVE_PATH")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
