extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:
	create_timer(60).timeout.connect(func(): push_error("LOCAL_REGRESSION_TIMEOUT"); quit(1))
	call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; print("FAIL: ",message)
func frames(count: int=2) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func run() -> void:
	CombatRules.random_roll_source=func(): return 0.99
	preload("res://tests/sword_technique_timing_tests.gd").run(self)
	await preload("res://tests/etapa2_combat_tests.gd").run_world(self)
	await preload("res://tests/tower_guardian_tests.gd").run_world(self)
	var path:="user://local_training_regression_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	await preload("res://tests/training_mode_tests.gd").run(self,preload("res://scenes/main.tscn"),path)
	CombatRules.random_roll_source=Callable()
	print("LOCAL_REGRESSION_RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
