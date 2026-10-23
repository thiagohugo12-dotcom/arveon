extends SceneTree
var output := ""
var failures := 0
func _initialize() -> void:
	create_timer(90).timeout.connect(func():quit(1))
	call_deferred("_run")
func capture(name: String) -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output.path_join(name+".png")) != OK: failures += 1
func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	OS.set_environment("ARVEON_SAVE_PATH","user://etapa2_capture_%d.json" % Time.get_ticks_usec())
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"): actor.set_physics_process(false)
	main.progress.xp = RPGRules.xp_floor(100)
	main.earned_xp = main.progress.xp
	var panel: RPGPanel = main.hud.rpg_panel
	for resolution: Vector2i in [Vector2i(390,844),Vector2i(960,540)]:
		root.size = resolution
		main._adapt_orientation()
		for category: String in AbilityRules.CATEGORIES:
			var p: GameProgress = main.progress
			var catalog: Dictionary = AbilityRules.CATEGORIES[category]
			p.equipment[category] = 3
			p.equipped.Arma = category
			p.talents.xp[category] = TalentRules.xp_floor(30)
			p.configure_ability("equip_skill",category,catalog.normal[0].id,0,true)
			p.configure_ability("equip_skill",category,catalog.ultimate.id,0,true)
			p.configure_ability("equip_passive",category,catalog.passives[0].id,0,true)
			p.configure_ability("equip_passive",category,catalog.passives[1].id,1,true)
			p.configure_ability("specialization",category,catalog.specializations[0],0,true)
			p.abilities.charge[category] = 75
			p.learn_talent(category,AbilityRules.TALENTS[category][0].id,true)
			main.player.position = SafeCamp.RESPAWN
			main.player.apply_progression(p)
			main.hud.set_rpg_status(p,main.player)
			var prefix := "%s_%dx%d_" % [category,resolution.x,resolution.y]
			await capture(prefix+"hud")
			panel.tab = 1
			panel.skill_section = 0
			panel.skill_choice = catalog.normal[0].id
			panel.talent_weapon = category
			main._toggle_character()
			panel.scroll.scroll_vertical = 0
			await capture(prefix+"habilidades")
			panel.skill_section = 2
			panel.skill_choice = catalog.specializations[0]
			panel.refresh(p)
			await process_frame
			panel.scroll.ensure_control_visible(panel.specialization_buttons[catalog.specializations[0]])
			await capture(prefix+"especializacao")
			panel.tab = 2
			panel.prof_section = 1
			panel.refresh(p)
			panel.scroll.scroll_vertical = 0
			await capture(prefix+"talentos")
			main._toggle_character()
	print("ETAPA2_RENDER_RESULT: %d failures" % failures)
	quit(1 if failures > 0 else 0)

