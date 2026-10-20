extends SceneTree

var failures := 0

func _initialize() -> void:
	create_timer(60.0).timeout.connect(func(): quit(1))
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if ok:
		print("VALE_GUARDIAN OK: " + message)
	else:
		failures += 1
		push_error("VALE_GUARDIAN FAIL: " + message)

func _wave_actors(main: Node2D) -> Array[EnemyActor]:
	var found: Array[EnemyActor] = []
	for node in main.get_children():
		if node is EnemyActor and node.health.is_alive() and node.get_meta("tower_attempt", -1) == main.trial.attempt_id:
			found.append(node)
	return found

func _run() -> void:
	var forest_trial := TowerTrial.new()
	forest_trial.start(1)
	_check(forest_trial.wave_kinds() == TowerTrial.WAVES[0] and FloorConfig.tower_guardian_name(1) == "Guardião da Mata", "prova original da Mata permanece igual")
	var path := "user://qa_vale_guardian_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH", path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.enemy.set_physics_process(false)
	main.progress.ascension.defeats["1"] = 50
	_check(main.progress.ascension.complete_forest_trial(), "Andar 1 abre o Vale")
	await main._travel_floor(2)
	main.set_process(false)
	main.player.set_physics_process(false)
	_check(main.world is Andar2World and main.tower_view is Floor2TowerView, "Torre propria no mapa real do Vale")
	main.player.position = Floor2Layout.GUARDIAN_ALTAR
	_check(main._interaction_target().get("kind", "") == "guardian", "arena oferece o Colosso por proximidade")
	main._interact()
	_check(is_instance_valid(main.guardian) and main.guardian is SandstoneColossus and main.guardian.view is SandstoneColossusView, "Colosso opcional usa ator e spritesheet do Vale")
	if is_instance_valid(main.guardian):
		main.guardian.set_physics_process(false)
		_check((main.guardian.get_node("Collision").shape as CircleShape2D).radius == 34.0, "colisao acompanha o corpo do golem")
		main.guardian.receive_damage(100000)
	_check(main.progress.floor_states["2"].guardian_defeated, "vitoria opcional persiste no estado do Andar 2")
	main.progress.ascension.defeats["2"] = 50
	main.player.position = Floor2Layout.TOWER_POSITION + Vector2(0, 42)
	_check(main._interaction_target().get("kind", "") == "tower", "entrada da Torre continua interativa")
	main._interact()
	_check(main.hud.station_panel.visible and main.hud.tower_action_button.text == "Entrar na Prova", "menu mobile permite entrar")
	await main._enter_trial()
	main.set_process(false)
	main.player.set_physics_process(false)
	_check(main.trial.active() and main.trial.floor_id == 2 and (main.arena.get_node("Floor") as TowerArenaView).floor_id == 2, "prova carrega arena de arenito")
	for wave in range(1, 4):
		main._process_trial(4.0)
		var actors := _wave_actors(main)
		var expected: Array = TowerTrial.VALE_WAVES[wave - 1]
		var actual: Array = []
		for actor in actors:
			actor.set_physics_process(false)
			actual.append(actor.kind)
		_check(actual == expected, "horda %d usa monstros exclusivos do Vale" % wave)
		for actor in actors:
			actor.receive_damage(100000)
		await create_timer(0.26).timeout
	main._process_trial(4.0)
	var boss: TowerGuardian = main.tower_guardian
	_check(is_instance_valid(boss) and boss.view is SandstoneTowerGuardianView, "guardiao da Torre usa animacao do golem")
	if is_instance_valid(boss):
		boss.set_physics_process(false)
		_check(boss.position.y >= TowerTrial.ORIGIN.y + 190.0, "guardiao aparece dentro da arena, longe da borda superior")
		_check(boss.health.maximum >= 520 and (boss.get_node("Collision").shape as CircleShape2D).radius == 34.0, "HP e colisao proprios do Andar 2")
		_check(main.hud.boss_name.text.contains("Guardião de Arenito"), "HUD identifica o guardiao correto")
		boss._begin_attack()
		_check(boss.view.warning and boss.state == TowerGuardian.State.WINDUP, "ataque avisa antes do dano")
		boss.receive_damage(100000)
	_check(main.trial.phase == TowerTrial.Phase.VICTORY and main.progress.ascension.completed_trials["2"] and main.progress.ascension.can_travel(3), "vitoria libera o proximo andar uma unica vez")
	_check(main.hud.tower_action_button.text == "Retornar ao Vale", "retorno da prova usa o destino correto")
	main._save_progress()
	var loaded := GameProgress.new()
	loaded.save_path = path
	_check(loaded.load_save() and loaded.ascension.completed_trials["2"] and loaded.floor_states["2"].guardian_defeated, "save preserva prova e Colosso")
	await main._return_from_trial()
	_check(main.world is Andar2World and main.player.position == Floor2Layout.RESPAWN and not main.trial.active(), "retorno seguro ao Vale")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.unset_environment("GRANDE_ARVORE_SAVE_PATH")
	print("VALE_GUARDIAN RESULT: %d failures" % failures)
	quit(1 if failures > 0 else 0)
