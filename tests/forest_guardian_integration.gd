extends SceneTree

var failures := 0

func _initialize() -> void:
	create_timer(30.0).timeout.connect(func(): quit(1))
	call_deferred("_run")

func _check(value: bool, description: String) -> void:
	if value:
		print("FOREST_GUARDIAN OK: " + description)
	else:
		failures += 1
		push_error("FOREST_GUARDIAN FAIL: " + description)

func _actors(main: Node2D) -> Array[EnemyActor]:
	var result: Array[EnemyActor] = []
	for node in main.get_children():
		if node is EnemyActor and node.health.is_alive() and node.get_meta("tower_attempt", -1) == main.trial.attempt_id:
			result.append(node)
	return result

func _run() -> void:
	var save_path := "user://qa_forest_guardian_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.progress.ascension.defeats["1"] = 50
	await main._enter_trial()
	main.set_process(false)
	main.player.set_physics_process(false)
	_check(main.trial.active() and main.trial.floor_id == 1, "prova original do Andar 1 abre")
	for wave in range(3):
		main._process_trial(4.0)
		var actors := _actors(main)
		_check(not actors.is_empty(), "horda %d permanece funcional" % (wave + 1))
		for actor in actors:
			actor.set_physics_process(false)
			actor.receive_damage(100000)
		await create_timer(0.26).timeout
	main._process_trial(4.0)
	var boss: TowerGuardian = main.tower_guardian
	_check(is_instance_valid(boss) and boss.view is TowerGuardianView, "Guardião da Mata aparece após as três hordas")
	if is_instance_valid(boss):
		boss.set_physics_process(false)
		_check(boss.position.distance_to(main.player.position) >= 170.0 and boss.position.y >= TowerTrial.ORIGIN.y + 245.0, "surgimento mantém distância e deixa a copa visível")
		_check(boss.health.maximum == 360 and (boss.get_node("Collision").shape as CircleShape2D).radius == 26.0, "HP e colisão não mudaram")
		var sheet := TowerGuardianView.FOREST_SHEET.get_image()
		for action in range(5):
			boss.action = action
			boss._begin_attack()
			_check(boss.state == TowerGuardian.State.WINDUP and boss.view.warning, "ação %d avisa antes do contato" % action)
			var source: Rect2 = boss.view._forest_frame()
			_check(Rect2(Vector2.ZERO, sheet.get_size()).encloses(source) and sheet.get_region(Rect2i(source)).get_used_rect().has_area(), "ação %d usa quadro visível da folha" % action)
			boss._physics_process(float(TowerGuardian.WINDUPS[action]))
			_check(boss.state == TowerGuardian.State.ACTIVE, "ação %d mantém instante de contato" % action)
			boss._finish_attack()
		boss.receive_damage(100000)
		_check(main.trial.phase == TowerTrial.Phase.VICTORY and main.progress.ascension.can_travel(2), "vitória continua liberando o Andar 2")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("ARVEON_SAVE_PATH")
	print("FOREST_GUARDIAN RESULT: %d failures" % failures)
	quit(1 if failures else 0)
