extends SceneTree

# Revisão de jogabilidade (31/10/2026): recuperação de vida na área segura, barra de HP dos
# chefes de campo na HUD e missão comum de coleta no andar sem materiais (Pântano).
# Uso: godot --path . --resolution 360x800 -s res://tests/revisao_jogabilidade_tests.gd
# Com QA_RENDER_DIR=<pasta> salva capturas reais 360x800 (precisa de janela).
var failures := 0
var checks := 0
var out := ""
var main: Node2D

func _initialize() -> void:
	create_timer(240.0).timeout.connect(func():
		push_error("REVISAO FALHA: tempo limite do teste")
		quit(1))
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("REVISAO OK: " + label)
	else:
		failures += 1
		push_error("REVISAO FALHA: " + label)

func _frames(count: int) -> void:
	for _i in range(count): await process_frame

func _shot(name: String) -> void:
	if out.is_empty(): return
	await _frames(4)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.get_size() == Vector2i(360, 800), "captura real 360x800: " + name)
	image.save_png(out.path_join("revisao-%s.png" % name))

func _place_player(at: Vector2) -> void:
	main.player.global_position = at
	main.player.velocity = Vector2.ZERO
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.reset_smoothing()
	camera.force_update_scroll()

func _clear_enemies() -> void:
	for actor in get_nodes_in_group("damageable_enemies"):
		if actor is EnemyActor and actor != main.enemy: actor.queue_free()

func _run() -> void:
	out = OS.get_environment("QA_RENDER_DIR")
	if not out.is_empty(): DirAccess.make_dir_recursive_absolute(out)
	_mission_unit()
	OS.set_environment("ARVEON_SAVE_PATH", "user://qa_revisao_jogabilidade_%d.json" % Time.get_ticks_usec())
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	root.size = Vector2i(360, 800)
	root.content_scale_size = Vector2i(360, 800)
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	main.player.set_physics_process(false)
	_clear_enemies()
	await _frames(2)
	_camp_regeneration()
	await _field_boss_bar_floor1()
	main.progress.ascension.defeats["1"] = 50
	main.progress.ascension.complete_forest_trial()
	await main._travel_floor(2)
	main.progress.ascension.defeats["2"] = 50
	main.progress.ascension.complete_forest_trial()
	await main._travel_floor(3)
	main.set_process(false)
	main.player.set_physics_process(false)
	_clear_enemies()
	await _frames(2)
	_floor3_mission()
	await _floor3_bosses()
	print("REVISAO_RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)

func _mission_unit() -> void:
	var mission := CommonMission.new()
	mission.mission_index = 1
	mission.record_defeat()
	_check(mission.progress == 0, "com materiais no andar, derrotas não contam para a coleta")
	mission.materials_available = false
	_check(mission.summary().contains("Derrote criaturas 0/5"), "sem materiais, a coleta vira derrotas com o mesmo alvo")
	var rewards: Array = []
	mission.completed.connect(func(xp: int, gold: int): rewards.append([xp, gold]))
	for _i in range(5): mission.record_defeat()
	_check(rewards == [[30, 10]] and mission.mission_index == 0 and mission.progress == 0, "substituta paga a recompensa da coleta e segue o ciclo")
	mission.record_defeat()
	_check(mission.progress == 1, "missão de derrotas continua igual")

func _camp_regeneration() -> void:
	var player: PlayerActor = main.player
	_place_player(SafeCamp.respawn_for_floor(1))
	var maximum := player.health.maximum
	player.health.current = maxi(1, maximum / 4)
	var start := player.health.current
	main._regenerate_in_camp(1.0)
	var gained := player.health.current - start
	_check(gained == floori(maximum * main.CAMP_REGEN_PER_SECOND), "acampamento recupera %d HP em 1 s (12%% de %d)" % [gained, maximum])
	for _i in range(60): main._regenerate_in_camp(1.0 / 60.0)
	_check(player.health.current - start - gained >= floori(maximum * main.CAMP_REGEN_PER_SECOND) - 1, "passos de quadro acumulam a fração sem perder cura")
	for _i in range(20): main._regenerate_in_camp(1.0)
	_check(player.health.current == maximum, "recuperação para no HP máximo")
	main.input_driver.blocked = true
	player.health.current = start
	main._regenerate_in_camp(1.0)
	_check(player.health.current == start, "menu aberto pausa a recuperação")
	main.input_driver.blocked = false
	_place_player(Vector2(1300, 300))
	_check(not SafeCamp.in_clearance(main.player.global_position), "ponto de teste fora da área segura")
	main._regenerate_in_camp(5.0)
	_check(player.health.current == start, "fora da área segura não há recuperação")
	player.health.initialize(maximum)

func _field_boss_bar_floor1() -> void:
	main._update_field_boss_bar()
	_check(not main.hud.boss_name.visible and main.hud.mission_label.visible, "sem chefe por perto a HUD mostra a missão")
	main.progress.floor_states["1"].guardian_defeated = false
	main._start_guardian()
	var boss: EnemyActor = main.guardian
	_check(is_instance_valid(boss), "Guardião da Mata desafiado no campo")
	if not is_instance_valid(boss): return
	boss.set_physics_process(false)
	_place_player(boss.global_position + Vector2(0, 200))
	main._update_field_boss_bar()
	_check(main.hud.boss_name.visible and main.hud.boss_bar.visible and not main.hud.mission_label.visible, "chefe engajado ocupa o painel da missão")
	_check(main.hud.boss_name.text.contains("Guardião da Mata · Fase 1") and main.hud.boss_name.text.contains("HP %d/%d" % [boss.health.current, boss.health.maximum]), "barra mostra nome, fase e HP do chefe de campo")
	_check(main.hud.boss_bar.max_value == boss.health.maximum and main.hud.boss_bar.value == boss.health.current, "barra usa a vida real do chefe")
	_check(not main.hud.mission_toggle.visible, "botão de missão continua oculto")
	_check(not (main.hud.mission_back as MissionBanner).show_compass, "bússola da missão sai de baixo do texto do chefe")
	_place_player(boss.global_position + Vector2(0, 600))
	main._update_field_boss_bar()
	_check(not main.hud.boss_name.visible and main.hud.mission_label.visible and (main.hud.mission_back as MissionBanner).show_compass, "longe do chefe a missão volta, com a bússola")
	boss.queue_free()
	main.guardian = null
	await _frames(2)
	main._update_field_boss_bar()
	_check(not main.hud.boss_name.visible, "chefe removido não deixa barra presa")

func _floor3_mission() -> void:
	main._refresh_mission()
	_check(main.progress.ascension.current_floor == 3 and not main.mission.materials_available, "Pântano sem coletas nem drops marca a missão como substituída")
	main.mission.mission_index = 1
	main.mission.progress = 0
	main.mission.record_defeat()
	_check(main.mission.progress == 1, "no Pântano a missão de coleta avança com derrotas")
	main._refresh_mission()
	_check(main.hud.mission_label.text.contains("Derrote criaturas 1/5"), "HUD mostra a missão substituta (%s)" % main.hud.mission_label.text.replace("\n", " | "))

func _floor3_bosses() -> void:
	main.progress.floor_states["3"].guardian_defeated = false
	main._start_guardian()
	var mother: EnemyActor = main.guardian
	_check(mother is MotherOfWhispers, "Mãe dos Sussurros desafiada no campo")
	if mother is MotherOfWhispers:
		mother.set_physics_process(false)
		_place_player(mother.global_position + Vector2(0, 230))
		main._update_field_boss_bar()
		_check(main.hud.boss_name.text.begins_with("Mãe dos Sussurros · Fase 1"), "HUD identifica a Mãe dos Sussurros (%s)" % main.hud.boss_name.text.replace("\n", " | "))
		await _shot("mae-barra-hud")
		mother.queue_free()
		main.guardian = null
		await _frames(2)
	var definition := FloorCatalog.mini_boss(3)
	var caiman: EnemyActor = main._make_enemy(int(definition.kind))
	caiman.position = definition.home
	caiman.target = main.player
	main._register_enemy_defeat(caiman)
	main.add_child(caiman)
	caiman.set_physics_process(false)
	main.mini_boss = caiman
	_place_player(caiman.global_position + Vector2(0, 160))
	main._update_field_boss_bar()
	_check(main.hud.boss_name.text.begins_with("Jacaré Ancião\nHP"), "Jacaré Ancião aparece sem fase inventada")
	await _shot("jacare-barra-hud")
	caiman.queue_free()
	main.mini_boss = null
	await _frames(2)
	main._update_field_boss_bar()
	_check(not main.hud.boss_name.visible, "barra some com o Jacaré")
