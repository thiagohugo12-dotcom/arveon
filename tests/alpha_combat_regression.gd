extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if condition:
		print("ALPHA COMBAT OK: " + message)
	else:
		failures += 1
		push_error("ALPHA COMBAT FAIL: " + message)

func frames(count: int = 2) -> void:
	for _i in range(count):
		await process_frame
	await physics_frame

func _run() -> void:
	await preload("res://tests/tower_guardian_tests.gd").run_world(self)
	await preload("res://tests/campaign_tests.gd").run_world(self)
	print("ALPHA COMBAT RESULT: %d falhas" % failures)
	quit(1 if failures > 0 else 0)
