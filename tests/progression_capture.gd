extends SceneTree
var output := ""
var failures := 0

func _initialize() -> void:
	create_timer(90).timeout.connect(func(): quit(1))
	call_deferred("_run")

func capture(name: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output.path_join(name+".png")) != OK: failures += 1

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH","user://progression_capture_%d.json" % Time.get_ticks_usec())
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for enemy in get_nodes_in_group("damageable_enemies"): enemy.set_physics_process(false)
	main.progress.xp = RPGRules.xp_floor(20)
	main.progress.attributes = {"Força":4,"Vitalidade":4,"Resistência":6,"Mobilidade":5,"Destreza":5,"Espírito":4}
	for category: String in ArsenalRules.CATEGORIES:
		main.progress.equipment[category] = 0
		main.progress.talents.xp[category] = TalentRules.xp_floor(18)
		main.progress.talents.mastery[category] = {"Dano":3,"Dano Especial":2,"Crítico":2,"Dano Crítico":2}
	main.progress.learn_talent("espada","sequencia_precisa",true)
	main.progress.learn_talent("espada","guarda_aperfeicoada",true)
	main.player.apply_progression(main.progress)
	main.hud.set_rpg_status(main.progress,main.player)
	var panel: RPGPanel = main.hud.rpg_panel
	for resolution: Vector2i in [Vector2i(960,540),Vector2i(390,844),Vector2i(640,360),Vector2i(360,640)]:
		root.size = resolution
		main._adapt_orientation()
		panel.tab = 0
		main._toggle_character()
		var prefix := "%dx%d_" % [resolution.x,resolution.y]
		await capture(prefix+"atributos")
		panel.tab = 2
		panel.prof_section = 0
		panel.refresh(main.progress)
		panel.scroll.scroll_vertical = 0
		await capture(prefix+"dominio")
		panel.scroll.ensure_control_visible(panel.mastery_buttons["Dano Crítico"])
		await capture(prefix+"dominio-retorno-fixo")
		panel.scroll.ensure_control_visible(panel.mastery_buttons["Dano"])
		await capture(prefix+"dominio-distribuir")
		panel.prof_section = 1
		panel.refresh(main.progress)
		panel.scroll.scroll_vertical = 0
		await capture(prefix+"talentos")
		panel.tab = 1
		panel.refresh(main.progress)
		panel.scroll.scroll_vertical = 0
		await capture(prefix+"skills")
		main._toggle_character()
	print("PROGRESSION_QA_RESULT: %d failures" % failures)
	quit(1 if failures > 0 else 0)
