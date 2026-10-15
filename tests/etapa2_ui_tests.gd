extends RefCounted
const TOUCH = preload("res://tests/tower_trial_tests.gd")
static func run_world(suite: SceneTree) -> void:
	var previous := OS.get_environment("GRANDE_ARVORE_SAVE_PATH")
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH","user://qa_etapa2_ui.json")
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	suite.root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in suite.get_nodes_in_group("damageable_enemies"): actor.set_physics_process(false)
	var p: GameProgress = main.progress
	p.xp = RPGRules.xp_floor(100)
	main.earned_xp = p.xp
	for category: String in AbilityRules.CATEGORIES:
		p.talents.xp[category] = TalentRules.xp_floor(30)
		p.equipment[category] = 0
	var panel: RPGPanel = main.hud.rpg_panel
	for resolution: Vector2i in [Vector2i(360,640),Vector2i(390,844),Vector2i(640,360),Vector2i(960,540)]:
		suite.root.size = resolution
		suite.root.content_scale_size = resolution
		await suite.frames()
		main.hud.size = Vector2(resolution)
		main.hud._layout()
		for category: String in AbilityRules.CATEGORIES:
			var catalog: Dictionary = AbilityRules.CATEGORIES[category]
			main.player.position = SafeCamp.RESPAWN
			p.equipped.Arma = category
			main.player.apply_progression(p)
			main.player.health.current = 70
			panel.tab = 1
			panel.talent_weapon = category
			main._toggle_character()
			await suite.frames()
			suite.check(panel.ability_buttons.size() == 3*catalog.normal.size()+2 and panel.passive_buttons.size() == 2*catalog.passives.size() and panel.specialization_buttons.size() == 2 and panel.category_buttons.size() == 5,"complete class skills/passives/spec UI "+category+str(resolution))
			var before := p.skill_points()
			var id: String = catalog.normal[0].id
			var button: Button = panel.ability_buttons[id+":0"]
			panel.scroll.ensure_control_visible(button)
			await suite.frames()
			suite.check(button.size.y >= 44 and panel.scroll.get_global_rect().has_point(button.get_global_rect().get_center()),"class selection touch target scrolls into viewport "+category+str(resolution))
			TOUCH._tap(main.hud,button)
			await suite.frames()
			suite.check(p.abilities.loadouts[category].skills[0] == id and p.skill_points() == before,"touch selects free category technique "+category)
			main._rpg_action("equip_skill",category+":"+catalog.ultimate.id,0)
			main._rpg_action("equip_skill",category+":"+id,1)
			main._rpg_action("equip_passive",category+":"+catalog.passives[0].id,0)
			main._rpg_action("equip_passive",category+":"+catalog.passives[1].id,1)
			main._rpg_action("specialization",category+":"+catalog.specializations[0],0)
			main._rpg_action("specialization",category+":"+catalog.specializations[1],0)
			suite.check(p.abilities.loadouts[category].specialization == catalog.specializations[1] and p.abilities.loadouts[category].passives.size() == 2 and main.player.health.current == 70 and p.skill_points() == before,"free loadout and spec transactions preserve HP and points "+category)
			p.abilities.charge[category] = 100
			main._toggle_character()
			main.hud.set_rpg_status(p,main.player)
			suite.check(main.hud.actions[1].legend == "Ultimate" and main.hud.actions[1].charge_fraction == 1.0 and main.hud.actions[1].caption.text == "100%","HUD maps optional Ultimate to its actual slot "+category+str(resolution))
			main.player.position = Vector2(850,400)
			panel.tab = 1
			main._toggle_character()
			await suite.frames()
			var saved := p.to_json()
			main._rpg_action("equip_skill",category+":",0)
			main._rpg_action("skill",category+":"+id,1)
			main._rpg_action("specialization",category+":"+catalog.specializations[0],0)
			suite.check(panel.ability_buttons[id+":grade"].disabled and panel.specialization_buttons[catalog.specializations[0]].disabled and p.to_json() == saved,"exploration blocks UI and forged personalization commands "+category+str(resolution))
			suite.check(panel.get_global_rect().end.x <= resolution.x+1 and panel.get_global_rect().end.y <= resolution.y+1 and panel.close_button.size.y >= 44,"complete class diary and close fit both orientations "+category+str(resolution))
			main._toggle_character()
	var restored := GameProgress.new()
	suite.check(restored.load_text(p.to_json()) and restored.abilities.to_save() == p.abilities.to_save(),"five configured class interfaces persist exactly")
	main.queue_free()
	await suite.frames()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",previous)
