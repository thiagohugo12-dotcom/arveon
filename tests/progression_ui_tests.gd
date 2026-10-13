extends RefCounted
const TOUCH = preload("res://tests/tower_trial_tests.gd")

static func run_world(suite: SceneTree) -> void:
	var previous := OS.get_environment("GRANDE_ARVORE_SAVE_PATH")
	var path := "user://qa_progression_ui_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",path)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	suite.root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in suite.get_nodes_in_group("damageable_enemies"): actor.set_physics_process(false)
	main.progress.xp = RPGRules.xp_floor(40)
	main.earned_xp = main.progress.xp
	for category: String in ArsenalRules.CATEGORIES: main.progress.talents.xp[category] = TalentRules.xp_floor(18)
	var panel: RPGPanel = main.hud.rpg_panel
	for size: Vector2 in [Vector2(360,640),Vector2(390,844),Vector2(640,360),Vector2(960,540)]:
		suite.root.size = Vector2i(size)
		suite.root.content_scale_size = Vector2i(size)
		await suite.frames()
		main.hud.size = size
		main.hud._layout()
		panel.tab = 0
		main._toggle_character()
		await suite.frames()
		suite.check(panel.attribute_buttons.size() == 6 and panel.get_global_rect().end.x <= size.x+1 and panel.close_button.size.y >= 44,"six attribute layout and fixed close fit "+str(size))
		var before: int = main.progress.attribute_points()
		panel.scroll.ensure_control_visible(panel.attribute_buttons["Espírito"])
		await suite.frames()
		TOUCH._tap(main.hud,panel.attribute_buttons["Espírito"])
		await suite.frames()
		suite.check(main.progress.attribute_points() == before-1 and main.input_driver.blocked,"touch allocates sixth attribute without unblocking combat "+str(size))
		panel.tab = 2
		panel.prof_section = 0
		panel.talent_weapon = "espada"
		panel.refresh(main.progress)
		await suite.frames()
		suite.check(panel.category_buttons.size() == 5 and panel.mastery_buttons.size() == 4,"five categories and four mastery attributes available "+str(size))
		for category: String in ArsenalRules.CATEGORIES:
			panel.scroll.ensure_control_visible(panel.category_buttons[category])
			await suite.frames()
			TOUCH._tap(main.hud,panel.category_buttons[category])
			await suite.frames()
			var spent_before: int = main.progress.talents.mastery[category]["Dano"]
			var points_before: int = main.progress.talents.mastery_points(category)
			panel.scroll.ensure_control_visible(panel.mastery_buttons["Dano"])
			await suite.frames()
			var action: Button = panel.mastery_buttons["Dano"]
			var screen_height := action.size.y*action.get_screen_transform().get_scale().y
			suite.check(screen_height >= 43.9 and panel.scroll.get_global_rect().has_point(action.get_global_rect().get_center()),"mastery action visible and physical touch sized "+category+str(size))
			TOUCH._tap(main.hud,panel.mastery_buttons["Dano"])
			await suite.frames()
			main._rpg_action("mastery",category+":Dano",spent_before) # Same stale request.
			suite.check(main.progress.talents.mastery_points(category) == points_before-1 and main.progress.talents.mastery[category]["Dano"] == spent_before+1,"touch distributes only selected mastery; stale tap rejected "+category+str(size))
		main._toggle_character()
		await suite.frames()
		suite.check(not main.input_driver.blocked,"close progression restores gameplay "+str(size))
	var loaded := GameProgress.new()
	loaded.save_path = path
	suite.check(loaded.load_save() and loaded.talents.mastery == main.progress.talents.mastery and loaded.attributes == main.progress.attributes,"all UI allocations persist across full load")
	# Reset is available in camp only, refunds shared talent budget, preserves ranks/XP/mastery.
	main.progress.learn_talent("espada","sequencia_precisa",true)
	var mastery_before: Dictionary = main.progress.talents.mastery.duplicate(true)
	var xp_before: Dictionary = main.progress.talents.xp.duplicate()
	var skills_before: Dictionary = main.progress.skills.duplicate()
	var points: int = main.progress.skill_points()
	main.player.position = Vector2(850,400)
	panel.tab = 2
	main._toggle_character()
	main._rpg_action("reset_tree","espada",0)
	suite.check(main.progress.abilities.talents.espada.has("sequencia_precisa") and main.progress.skill_points() == points,"respec rejected outside safe area")
	main.player.position = SafeCamp.RESPAWN
	main._rpg_action("reset_tree","espada",0)
	suite.check(not main.progress.abilities.talents.espada.has("sequencia_precisa") and main.progress.skill_points() == points+1 and main.progress.talents.mastery == mastery_before and main.progress.talents.xp == xp_before and main.progress.skills == skills_before,"free safe respec refunds only existing learned nodes, preserves other systems")
	main.queue_free()
	await suite.frames()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",previous)
