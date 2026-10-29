extends SceneTree

# Marco 4: chefes em fases (100/66/33%), pausa invulnerável na troca, golpes extras,
# asseclas na fase 3 e a tabela de escala 1–10. Rode: godot --headless --path . -s res://tests/boss_phase_tests.gd
var checks := 0
var failures := 0

func _initialize() -> void:
	create_timer(60.0).timeout.connect(func(): push_error("BOSS_FAIL: timeout"); quit(1))
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("BOSS_FAIL: " + message)
	else:
		print("BOSS_PASS: " + message)

func minions(boss: Node) -> Array:
	var result: Array = []
	for node in get_nodes_in_group("damageable_enemies"):
		if node.get_meta("boss_minion_of", null) == boss: result.append(node)
	return result

func _run() -> void:
	# Tabela de escala: cresce sem buracos e preserva os Andares 1 e 2.
	var last := 0.0
	var last_reward := 0.0
	var table_ok := true
	for id in range(1, 11):
		table_ok = table_ok and FloorCatalog.valid_scale(id) and FloorCatalog.difficulty(id) > last and float(FloorCatalog.SCALE[str(id)].rewards) > last_reward
		last = FloorCatalog.difficulty(id)
		last_reward = float(FloorCatalog.SCALE[str(id)].rewards)
	check(table_ok and not FloorCatalog.valid_scale(11), "scale table covers floors 1-10 and always grows")
	check(FloorCatalog.difficulty(1) == 1.0 and FloorCatalog.difficulty(2) == 1.5 and FloorCatalog.reward(10,2) == 11 and is_equal_approx(FloorCatalog.difficulty(10),9.0), "floors 1 and 2 keep their values; floor 10 is 9.0")
	for id in range(3, 11):
		check(is_equal_approx(float(FloorCatalog.SCALE[str(id)].rewards), snappedf(FloorCatalog.difficulty(id) * 1.25, 0.1)) or id == 3, "reward is difficulty x1.25 on floor %d" % id)
		check(FloorCatalog.planned_boss_hp(id,"field") > 0 and FloorCatalog.planned_boss_hp(id,"tower") > 0, "planned boss HP exists for floor %d" % id)
	check(BossPhases.phase_for(1.0) == 1 and BossPhases.phase_for(0.67) == 1 and BossPhases.phase_for(0.66) == 2 and BossPhases.phase_for(0.34) == 2 and BossPhases.phase_for(0.33) == 3 and BossPhases.phase_for(0.0) == 3, "phase thresholds are 66% and 33%")
	check(FloorCatalog.boss_minions(1,"field") == [1,1] and FloorCatalog.boss_minions(2,"tower") == [5,5], "minion kinds come from the catalog")
	var path := "user://boss_phase_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.progress.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	for floor_id in [1, 2]:
		main.progress.ascension.current_floor = floor_id
		main.guardian = null
		main._start_guardian()
		var boss: RootGuardian = main.guardian
		var tag := " floor %d" % floor_id
		boss.global_position = main._guardian_altar_position() + Vector2(0, 80)
		main.player.global_position = boss.global_position + Vector2(160, 0)
		var maximum := boss.health.maximum
		check(boss.phases.phase == 1 and boss._cycle_size() == 3, "starts in phase 1 with the three original attacks" + tag)
		boss.health.damage(maximum - int(maximum * 0.66))
		boss._physics_process(0.0)
		check(boss.phases.phase == 2 and boss.invulnerable and boss.phases.transitioning(), "crossing 66% starts phase 2 with an invulnerable pause" + tag)
		var before := boss.health.current
		boss.receive_damage(50)
		check(boss.health.current == before, "no damage is taken during the transition pause" + tag)
		boss._physics_process(1.05)
		boss._physics_process(0.0)
		check(not boss.invulnerable and boss._cycle_size() == 4 and is_equal_approx(boss.phases.windup_scale(),0.9), "phase 2 ends the pause and adds a fourth attack" + tag)
		check(minions(boss).is_empty(), "no minions before phase 3" + tag)
		boss.health.damage(boss.health.current - int(maximum * 0.33))
		boss._physics_process(0.0)
		var helpers := minions(boss)
		check(boss.phases.phase == 3 and helpers.size() == 2, "crossing 33% starts phase 3 and summons two helpers" + tag)
		boss._physics_process(1.05)
		boss._physics_process(0.0)
		check(boss._cycle_size() == 5 and is_equal_approx(boss.phases.speed_scale(),1.2), "phase 3 adds the fifth attack and speeds the boss up" + tag)
		main._on_boss_summon([1,1], 2, boss)
		check(minions(boss).size() == 2, "helpers never exceed two alive at once" + tag)
		# Golpes extras: área marcada (3) e pisão furioso (4).
		main.player.health.initialize(100)
		boss.attack_index = 3
		boss.aim_point = main.player.global_position
		boss._resolve_extra()
		check(main.player.health.current == 100 - roundi(18 * boss.damage_scale), "attack 3 hits the marked area" + tag)
		main.player.health.initialize(100)
		boss.aim_point = main.player.global_position + Vector2(400, 0)
		boss._resolve_extra()
		check(main.player.health.current == 100, "attack 3 misses when the player left the marked area" + tag)
		main.player.global_position = boss.global_position + Vector2(120, 0)
		boss.attack_index = 4
		boss._resolve_extra()
		check(main.player.health.current == 100 - roundi(26 * boss.damage_scale), "attack 4 stomps around the boss" + tag)
		var kept := minions(boss)
		boss.receive_damage(100000)
		await process_frame
		var gone := true
		for node in kept: gone = gone and (not is_instance_valid(node) or node.is_queued_for_deletion() or not node.health.is_alive())
		check(gone, "helpers disappear with the boss" + tag)
		if is_instance_valid(boss): boss.free()
		main.guardian = null
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("BOSS_RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
