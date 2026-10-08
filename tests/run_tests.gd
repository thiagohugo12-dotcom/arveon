extends SceneTree

var failures: int = 0
var checks: int = 0
var deaths: int = 0

func _initialize() -> void:
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
	player.position = Vector2(600, 400)
	enemy.position = Vector2(900, 400)
	await frames()
	check(player.attack.select_target(player) == null, "out of range excluded")
	enemy.position = Vector2(720, 400)
	await frames()
	check(player.attack.select_target(player) == enemy, "target at reach boundary valid")
	var second := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as EnemyActor
	main.add_child(second)
	second.set_physics_process(false)
	second.position = Vector2(650, 400)
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
	main.mission.record_material()
	check(main.mission.progress == 0, "irrelevant material events do not advance hunt")
	main.queue_free()
	await frames()
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
