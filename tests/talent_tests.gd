extends RefCounted

static func run(suite: SceneTree) -> void:
	var p := GameProgress.new()
	p.xp = RPGRules.xp_floor(20)
	var original := p.to_json()
	suite.check(not p.learn_talent("espada","sequencia_precisa",true),"talent locked before proficiency ten")
	suite.check(not p.talents.record_damage("unknown",1) and p.to_json() == original,"unknown proficiency cannot mutate state")
	p.talents.record_damage("espada",TalentRules.xp_floor(20)*TalentRules.DAMAGE_PER_XP)
	suite.check(p.talents.level("espada") == 20 and p.talents.level("arco") == 1,"real use advances only its category")
	suite.check(not p.learn_talent("espada","contra_ataque_fatal",true),"category branch requires its parent")
	var points := p.skill_points()
	suite.check(p.learn_talent("espada","sequencia_precisa",true) and p.skill_points() == points-1,"shared point buys one category talent")
	suite.check(not p.learn_talent("espada","sequencia_precisa",true) and p.skill_points() == points-1,"duplicate purchase cannot spend another point")
	suite.check(p.configure_ability("equip_passive","espada","fio_afiado",0,true) and p.skill_points() == points-1,"passive selection is free")
	p.equipment.arco = 0
	p.equip("arco")
	suite.check(p.abilities.talents.espada.has("sequencia_precisa") and p.active_category() == "arco","switch preserves inactive category tree")
	p.equip("espada")
	suite.check(p.learn_talent("espada","contra_ataque_fatal",true),"second talent unlocks after parent")
	suite.check(p.improve_skill("espada:corte_crescente",true) and p.skill_points() == points-3,"normal grades and tree share one point budget")
	var saved := p.to_json()
	var restored := GameProgress.new()
	suite.check(restored.load_text(saved) and restored.to_json() == saved,"v10 roundtrip preserves category tree loadout and grades")
	var before := restored.to_json()
	for corruption: String in ["negative","fractional","unknown","duplicate","parent","budget","requirement"]:
		var payload: Dictionary = JSON.parse_string(saved)
		match corruption:
			"negative": payload.talents.xp.espada = -1
			"fractional": payload.talents.xp.espada = 2.5
			"unknown": payload.abilities.talents.espada.append("unknown")
			"duplicate": payload.abilities.talents.espada.append("sequencia_precisa")
			"parent": payload.abilities.talents.espada.erase("sequencia_precisa")
			"budget": payload.xp = RPGRules.xp_floor(3); payload.rpg.level = 3
			"requirement": payload.talents.xp.espada = 0
		suite.check(not restored.load_text(JSON.stringify(payload)) and restored.to_json() == before,"invalid talent save rejected atomically: "+corruption)
	var poor := GameProgress.new()
	poor.xp = RPGRules.xp_floor(2)
	poor.talents.xp.espada = TalentRules.xp_floor(20)
	suite.check(poor.learn_talent("espada","sequencia_precisa",true) and not poor.learn_talent("espada","contra_ataque_fatal",true) and not poor.improve_skill("espada:corte_crescente",true),"no point duplication across grades and talents")
	p.talents.xp.espada = TalentRules.xp_floor(30)
	suite.check(not p.talents.record_damage("espada",1),"proficiency still caps at thirty")

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
	main.enemy.receive_damage(10,"espada")
	suite.check(main.progress.talents.xp.espada == combat_xp+1,"confirmed damage is wired to real weapon proficiency")
	main.enemy.receive_damage(10,"arco")
	suite.check(main.progress.talents.xp.arco == 1 and main.progress.talents.xp.espada == combat_xp+1,"projectile hit category is independent of currently equipped weapon")
	var old: String = main.progress.to_json()
	main.progress.xp = RPGRules.xp_floor(10)
	main.earned_xp = main.progress.xp
	main.progress.talents.xp.espada = TalentRules.xp_floor(10)
	main.hud._open_diary(1)
	await suite.frames()
	var panel: RPGPanel = main.hud.rpg_panel
	panel.prof_section = 1
	panel.talent_selection = "sequencia_precisa"
	panel.refresh(main.progress)
	await suite.frames()
	var node: Button = panel.talent_tree.buttons.guarda_aperfeicoada
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
	suite.check(panel.talent_selection == "sequencia_precisa" and panel.scroll.scroll_vertical > scroll_before,"swiping over talent scrolls without opening details")
	panel.scroll.ensure_control_visible(node)
	await suite.frames()
	preload("res://tests/tower_trial_tests.gd")._tap(main.hud,node)
	await suite.frames()
	suite.check(panel.talent_selection == "guarda_aperfeicoada" and main.input_driver.blocked and not panel.talent_buy.disabled and panel.scroll.get_global_rect().has_point(panel.talent_buy.get_global_rect().get_center()),"touch inspects talent reveals purchase action and blocks gameplay")
	var hp_before: int = main.player.health.current
	preload("res://tests/tower_trial_tests.gd")._tap(main.hud,panel.talent_buy)
	await suite.frames()
	suite.check(main.progress.abilities.talents.espada.has("guarda_aperfeicoada") and main.player.health.maximum == 100 and main.player.health.current == hp_before and panel.talent_buy.disabled,"touch learns passive applies HP maximum without healing and prevents double purchase")
	var loaded := GameProgress.new()
	loaded.save_path = main.progress.save_path
	suite.check(loaded.load_save() and loaded.abilities.talents.espada.has("guarda_aperfeicoada"),"talent touch transaction persists across process load")
	main._toggle_character()
	main.progress.load_text(old)
	main.earned_xp = main.progress.xp
	main.player.apply_progression(main.progress)
	main.queue_free()
	await suite.frames()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",previous)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
