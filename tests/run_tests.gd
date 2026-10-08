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
	player.position = Vector2(700, 400)
	enemy.position = Vector2(900, 400)
	await frames()
	check(player.attack.select_target(player) == null, "out of range excluded")
	enemy.position = Vector2(820, 400)
	await frames()
	check(player.attack.select_target(player) == enemy, "target at reach boundary valid")
	var second := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as EnemyActor
	main.add_child(second)
	second.set_physics_process(false)
	second.position = Vector2(750, 400)
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
	player.position = Vector2(405, 280)
	enemy.position = Vector2(405, 365)
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
	main._interact()
	main._station_action("Vender", "Couro")
	check(main.progress.gold == 19 and main.progress.bag.get("Couro", 0) == 0, "vendor sells existing material into wallet")
	main.hud.close_station()
	main.progress.add_item("Essência", 2)
	player.position = SafeCamp.STATIONS["Baú"] + Vector2(28, 0)
	main._interact()
	main._station_action("Guardar", "Essência")
	check(main.progress.bag.get("Essência", 0) == 1 and main.progress.chest.get("Essência", 0) == 1, "chest transfer preserves total")
	main.hud.close_station()
	main._save_progress()
	var reloaded := GameProgress.new()
	reloaded.save_path = test_path
	check(reloaded.load_save() and reloaded.gold == 19 and reloaded.chest.get("Essência", 0) == 1 and reloaded.mission_completed == 2, "save round-trip includes economy, chest and mission")
	check(reloaded.death_loss() == "Essência" and reloaded.bag.get("Essência", 0) == 0 and reloaded.chest.get("Essência", 0) == 1, "death protects chest and only removes a bag unit")
	check(not reloaded.buy("Broto Ancestral") and not reloaded.transfer("Couro", true), "unavailable purchase and empty transfer do not mutate state")
	player.health.initialize(player.stats.max_hp)
	player.position = SafeCamp.RESPAWN
	var safe_hp := player.health.current
	player.receive_damage(99)
	check(player.health.current == safe_hp and SafeCamp.nearest_station(SafeCamp.STATIONS["Ferreiro"]) == "Ferreiro", "camp prevents damage and exposes smith interaction")
	var guard := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as EnemyActor
	guard.kind = 1
	main.add_child(guard)
	guard.target = player
	guard.position = Vector2(670, 460)
	guard._physics_process(0.016)
	check(guard.velocity.is_zero_approx(), "enemy does not attack a player in camp")
	var projectile := EnemyProjectile.new()
	main.add_child(projectile)
	projectile.setup(Vector2(657, 450), Vector2.LEFT, 8, player)
	projectile._physics_process(0.04)
	check(projectile.is_queued_for_deletion() and player.health.current == safe_hp, "enemy projectile dissolves at camp boundary")
	player.position = Vector2(560, 560)
	guard.position = Vector2(660, 455)
	for step in range(30):
		guard._physics_process(0.016)
	check(not SafeCamp.contains(guard.position), "enemy path cannot enter camp")
	main.mission.record_material()
	check(main.mission.progress == 0, "irrelevant material events do not advance hunt")
	# Enemy roles remain deliberately distinct and lightweight.
	player.health.initialize(player.stats.max_hp)
	var boar := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as EnemyActor
	boar.kind = 0
	boar.stats = boar.stats.duplicate() as ActorData
	main.add_child(boar)
	boar.target = player
	boar.global_position = player.global_position + Vector2(150, 0)
	boar._physics_process(0.016)
	check(boar.charge_windup > 0.0, "boar telegraphs a charge at mid range")
	var spider := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as EnemyActor
	spider.kind = 1
	spider.stats = spider.stats.duplicate() as ActorData
	main.add_child(spider)
	spider.target = player
	spider.global_position = player.global_position + Vector2(55, 0)
	spider._physics_process(0.016)
	check(spider.velocity.x > 0.0, "spider retreats when too close")
	var cactus := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as EnemyActor
	cactus.kind = 2
	cactus.stats = cactus.stats.duplicate() as ActorData
	main.add_child(cactus)
	cactus.target = player
	cactus.global_position = player.global_position + Vector2(180, 0)
	cactus._physics_process(0.016)
	check(cactus.special_left > 0.0 and cactus.velocity.is_zero_approx(), "mandacaru prepares ranged attack at preferred distance")
	main.queue_free()
	await frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	OS.unset_environment("GRANDE_ARVORE_SAVE_PATH")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
