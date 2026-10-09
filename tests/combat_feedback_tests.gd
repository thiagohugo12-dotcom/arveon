extends RefCounted

static func run(suite: SceneTree) -> void:
	var arena := Node2D.new()
	suite.root.add_child(arena)
	var player := (load("res://scenes/actors/player.tscn") as PackedScene).instantiate() as PlayerActor
	arena.add_child(player)
	player.set_physics_process(false)
	player.position = Vector2(150, 120)
	var driver := InputDriver.new()
	arena.add_child(driver)
	player.input_driver = driver
	var enemy := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as EnemyActor
	arena.add_child(enemy)
	enemy.set_physics_process(false)
	var second := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as EnemyActor
	arena.add_child(second)
	second.set_physics_process(false)
	second.position = Vector2(1500, 1500)
	for direction: Vector2 in [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]:
		enemy.position = player.position + direction * 120.0
		enemy.health.initialize(48)
		await suite.frames()
		player.view.set_facing(-direction)
		player.last_direction = -direction
		player.attack.cooldown_left = 0.0
		player.attack.search_left = 0.0
		player.attack.tick(0.0, player)
		suite.check(enemy.health.current == 36, "basic attack retains 12 damage at 120px boundary %s" % direction)
		suite.check(player.view.attack_direction.is_equal_approx(direction) and is_equal_approx(player.view.attack_distance, 120.0), "strike snapshot points to selected enemy %s" % direction)
		suite.check(player.view.facing.is_equal_approx(-direction) and player.last_direction.is_equal_approx(-direction), "auto aim preserves movement and dash direction %s" % direction)
		player.view.set_facing(Vector2(1, 1))
		suite.check(player.view.attack_direction.is_equal_approx(direction), "active strike does not rotate with subsequent movement %s" % direction)
		enemy.position = player.position + direction * 120.1
		await suite.frames()
		suite.check(player.attack.select_target(player) == null, "basic attack excludes just outside reach %s" % direction)
	# Measure empty-search response through the actual component, in 60Hz-like ticks.
	enemy.position = player.position + Vector2(200, 0)
	enemy.health.initialize(48)
	player.attack.cooldown_left = 0.0
	player.attack.search_left = 0.0
	player.view.attack_left = 0.0
	await suite.frames()
	player.attack.tick(0.0, player)
	suite.check(player.attack.cooldown_left == 0.0 and player.view.attack_left == 0.0, "missed acquisition spends no swing and creates no hit effect")
	enemy.position = player.position + Vector2(70, 0)
	await suite.frames()
	for tick in range(4):
		player.attack.tick(0.016, player)
	suite.check(enemy.health.current == 48, "empty searches remain throttled instead of scanning each frame")
	player.attack.tick(0.016, player)
	suite.check(enemy.health.current == 36 and is_equal_approx(player.attack.cooldown_left, 0.65), "newly reachable target is acquired in 80ms with original hit cooldown")
	player.attack.tick(0.0, player)
	player.attack.tick(0.3, player)
	suite.check(enemy.health.current == 36, "zero and partial ticks cannot duplicate one basic swing")
	player.attack.tick(0.35, player)
	suite.check(enemy.health.current == 24, "next basic swing retains 650ms cadence")
	# A second enemy remains untouched by a single-target strike, even with callback re-entry.
	second.position = player.position + Vector2(90, 0)
	await suite.frames()
	player.attack.attacked.connect(func(_target: Node2D): player.attack.tick(0.0, player), CONNECT_ONE_SHOT)
	player.attack.cooldown_left = 0.0
	player.attack.tick(0.0, player)
	suite.check(enemy.health.current == 12 and second.health.current == 48, "callbacks cannot duplicate damage or hit a second enemy")
	# Block both target rays with a solid on the existing World layer.
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 100)
	collision.shape = shape
	wall.add_child(collision)
	wall.position = player.position + Vector2(35, 0)
	arena.add_child(wall)
	await suite.frames()
	player.attack.cooldown_left = 0.0
	player.attack.search_left = 0.0
	player.view.attack_left = 0.0
	player.attack.tick(0.0, player)
	suite.check(enemy.health.current == 12 and player.view.attack_left == 0.0, "blocked strike applies no damage and emits no successful swing")
	arena.queue_free()
	await suite.frames()
