extends RefCounted

static func run(suite: SceneTree) -> void:
	var p := GameProgress.new()
	p.xp = RPGRules.xp_floor(20)
	var original := p.to_json()
	suite.check(not p.learn_talent("espada","vigor"),"talent cannot be purchased before weapon proficiency")
	suite.check(not p.talents.record_hit("unknown") and p.to_json() == original,"unknown proficiency cannot mutate state")
	for i in range(TalentRules.xp_floor(18)): p.talents.record_hit("espada")
	suite.check(p.talents.level("espada") == 18 and p.talents.level("arco") == 1,"real use advances only its weapon category")
	suite.check(not p.learn_talent("espada","guarda"),"talent branch requires its parent")
	var points := p.skill_points()
	suite.check(p.learn_talent("espada","vigor") and p.skill_points() == points-1,"level point buys passive exactly once")
	suite.check(not p.learn_talent("espada","vigor") and p.skill_points() == points-1,"double purchase cannot spend another point")
	suite.check(p.combat_stats().hp == 108,"learned passive applies with its weapon equipped")
	p.equipment.arco = 0
	p.equip("arco")
	suite.check(p.combat_stats().hp == 100 and p.talents.owns("espada","vigor"),"weapon switch suspends bonus and preserves learned tree")
	p.equip("espada")
	suite.check(p.learn_talent("espada","corte") and p.skill_rank(0) == 2,"technique node improves existing combat rank for its category")
	p.skills["Corte Circular"] = 3
	suite.check(p.skill_rank(0) == 4,"tree technique remains useful with maximum legacy skill rank")
	p.skills["Corte Circular"] = 1
	suite.check(p.learn_talent("espada","guarda") and p.combat_stats().armor == 1,"passive branch applies real defense")
	suite.check(p.improve_skill("Investida") and p.skill_points() == points-4,"old skill improvements and tree share one level point budget")
	var saved := p.to_json()
	var restored := GameProgress.new()
	suite.check(restored.load_text(saved) and restored.to_json() == saved,"v7 preserves proficiency trees equipment and old skills")
	var payload: Dictionary = JSON.parse_string(saved)
	payload.version = 6
	payload.erase("talents")
	suite.check(restored.load_text(JSON.stringify(payload)) and restored.talents.spent() == 0 and restored.skills == p.skills and restored.equipment == p.equipment,"v6 migrates without losing any acquired skill or gear")
	restored.load_text(saved)
	var before := restored.to_json()
	for corruption: String in ["negative","fractional","unknown","duplicate","parent","budget","requirement"]:
		payload = JSON.parse_string(saved)
		match corruption:
			"negative": payload.talents.xp.espada = -1
			"fractional": payload.talents.xp.espada = 2.5
			"unknown": payload.talents.learned.espada.append("unknown")
			"duplicate": payload.talents.learned.espada.append("vigor")
			"parent": payload.talents.learned.espada.erase("vigor")
			"budget": payload.xp = RPGRules.xp_floor(3)
			"requirement": payload.talents.xp.espada = 0
		suite.check(not restored.load_text(JSON.stringify(payload)) and restored.to_json() == before,"invalid talent save rejected atomically: "+corruption)
	var poor := GameProgress.new()
	poor.xp = RPGRules.xp_floor(2)
	poor.talents.xp.espada = TalentRules.xp_floor(12)
	suite.check(poor.learn_talent("espada","vigor") and not poor.learn_talent("espada","guarda") and not poor.improve_skill("Investida"),"no point duplication across old skill menu and tree")
	p.talents.xp.espada = TalentRules.xp_floor(30)
	suite.check(not p.talents.record_hit("espada") and p.talents.level("espada") == 30,"proficiency caps at thirty without overflowing XP")

static func run_world(suite: SceneTree) -> void:
	var previous := OS.get_environment("GRANDE_ARVORE_SAVE_PATH")
	var path := "user://qa_talents_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",path)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	suite.root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.enemy.set_physics_process(false)
	main.enemy.position = Vector2(850,400)
	main.enemy.awake = true
	var combat_xp := int(main.progress.talents.xp.espada)
	main.enemy.receive_damage(0,"espada")
	suite.check(main.progress.talents.xp.espada == combat_xp,"zero damage awards no weapon proficiency")
	main.enemy.receive_damage(1,"espada")
	suite.check(main.progress.talents.xp.espada == combat_xp+1,"confirmed damage is wired to real weapon proficiency")
	main.enemy.receive_damage(1,"arco")
	suite.check(main.progress.talents.xp.arco == 1 and main.progress.talents.xp.espada == combat_xp+1,"projectile hit category is independent of currently equipped weapon")
	var old: String = main.progress.to_json()
	main.progress.xp = RPGRules.xp_floor(10)
	main.earned_xp = main.progress.xp
	main.progress.talents.xp.espada = TalentRules.xp_floor(5)
	main.hud._open_diary(1)
	await suite.frames()
	var panel: RPGPanel = main.hud.rpg_panel
	panel.talent_selection = "corte"
	panel.refresh(main.progress)
	await suite.frames()
	var node: Button = panel.talent_tree.buttons.vigor
	panel.scroll.ensure_control_visible(node)
	await suite.frames()
	var scroll_before := panel.scroll.scroll_vertical
	var touch := InputEventScreenTouch.new()
	touch.index = 94
	touch.pressed = true
	touch.position = node.get_global_rect().get_center()
	main.hud._input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 94
	drag.relative = Vector2(0,-30)
	drag.position = touch.position+drag.relative
	main.hud._input(drag)
	touch.pressed = false
	touch.position = drag.position
	main.hud._input(touch)
	await suite.frames()
	suite.check(panel.talent_selection == "corte" and panel.scroll.scroll_vertical > scroll_before,"swiping over talent scrolls without opening details")
	panel.scroll.ensure_control_visible(node)
	await suite.frames()
	preload("res://tests/tower_trial_tests.gd")._tap(main.hud,node)
	await suite.frames()
	suite.check(panel.talent_selection == "vigor" and main.input_driver.blocked and not panel.talent_buy.disabled and panel.scroll.get_global_rect().has_point(panel.talent_buy.get_global_rect().get_center()),"touch inspects talent reveals purchase action and blocks gameplay")
	var hp_before := main.player.health.current
	preload("res://tests/tower_trial_tests.gd")._tap(main.hud,panel.talent_buy)
	await suite.frames()
	suite.check(main.progress.talents.owns("espada","vigor") and main.player.health.maximum == 108 and main.player.health.current == hp_before and panel.talent_buy.disabled,"touch learns passive applies HP maximum without healing and prevents double purchase")
	var loaded := GameProgress.new()
	loaded.save_path = main.progress.save_path
	suite.check(loaded.load_save() and loaded.talents.owns("espada","vigor"),"talent touch transaction persists across process load")
	main._toggle_character()
	main.progress.load_text(old)
	main.earned_xp = main.progress.xp
	main.player.apply_progression(main.progress)
	main.queue_free()
	await suite.frames()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",previous)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
