extends RefCounted

static func run(suite, main) -> void:
	var p := GameProgress.new()
	suite.check(p.record_adventure("unknown").is_empty() and p.xp == 0, "unknown challenge cannot grant rewards")
	p.record_adventure("explorar")
	p.record_adventure("explorar")
	var reward := p.record_adventure("explorar")
	suite.check(reward.xp == 30 and p.gold == 10 and p.record_adventure("explorar").is_empty(), "exploration mission rewards once after three gatherings")
	p.save_path = "user://qa_challenges_%d.json" % Time.get_ticks_usec()
	p.save()
	var restored := GameProgress.new()
	restored.save_path = p.save_path
	suite.check(restored.load_save() and restored.record_adventure("explorar").is_empty() and restored.gold == 10, "reloading cannot reclaim completed adventure reward")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p.save_path))
	main.set_process(false)
	for actor in suite.get_nodes_in_group("damageable_enemies"):
		actor.queue_free()
	await suite.frames()
	main.player.set_physics_process(false)
	main.input_driver.blocked = false
	main.hud.close_inventory()
	main.hud.close_character()
	main.hud.close_station()
	main.spawn_count = 7
	main._spawn_enemy()
	var elite: EnemyActor = suite.get_nodes_in_group("damageable_enemies")[0]
	elite.set_physics_process(false)
	suite.check(elite.kind == 3 and elite.health.maximum == 120 and elite.view.elite, "delayed elite spawn has actual stronger stats and visible rank")
	elite.receive_damage(1000)
	suite.check(main.progress.adventures.elite == 1, "elite defeat updates persistent side mission")
	elite.queue_free()
	await suite.frames()
	main.player.health.initialize(100)
	main.player.position = main.GUARDIAN_ALTAR
	suite.check(main._interaction_target().kind == "guardian", "optional guardian altar exposes explicit challenge interaction")
	main._interact()
	var boss: RootGuardian = main.guardian
	boss.set_physics_process(false)
	suite.check(is_instance_valid(boss) and boss.health.maximum == 320 and boss.view is GuardianView, "altar creates optional guardian with custom pixel view")
	main._interact()
	suite.check(suite.get_nodes_in_group("damageable_enemies").size() == 1, "repeated altar tap cannot create duplicate bosses")
	main.player.position = boss.position + Vector2(0, 50)
	boss.recover = 0.0
	var hp: int = main.player.health.current
	boss._physics_process(0.0)
	suite.check(boss.windup == 0.8 and boss.view.warning and main.player.health.current == hp, "boss telegraphs first attack before damage")
	boss._physics_process(0.8)
	suite.check(main.player.health.current < hp and boss.attack_index == 1, "boss slam resolves after warning and rotates attack")
	main.player.position = boss.position + Vector2(0, 250)
	boss.attack_index = 0
	hp = main.player.health.current
	boss._resolve_attack()
	suite.check(main.player.health.current == hp, "dodging outside slam radius avoids damage")
	main.player.position = boss.position + Vector2(60, 40)
	boss.attack_index = 1
	boss.aim = Vector2.DOWN
	boss._resolve_attack()
	suite.check(main.player.health.current == hp, "sidestepping root lane avoids strike")
	var before: int = main.get_child_count()
	boss.attack_index = 2
	boss._resolve_attack()
	suite.check(main.get_child_count() == before + 3, "third boss attack fires three projectiles")
	main.player.position = SafeCamp.RESPAWN
	boss.windup = 0.2
	boss._physics_process(0.1)
	suite.check(boss.windup == 0.0 and not boss.view.warning, "retreat into camp cancels boss windup")
	main.player.position = boss.position + Vector2(0, 50)
	boss.receive_damage(1000)
	suite.check(main.progress.adventures.guardiao == 1 and not boss.is_targetable(), "boss death grants persistent completion and removes target")
	var earned: int = main.earned_xp
	boss.receive_damage(1000)
	suite.check(main.earned_xp == earned, "repeated boss death cannot repeat reward")
	await suite.frames(16)
	main._start_guardian()
	suite.check(not is_instance_valid(main.guardian), "completed guardian cannot respawn on altar interaction")

	main.progress.xp = main.progress.xp_for_level(100)
	main.hud.set_rpg_status(main.progress, main.player)
	suite.check(main.hud.progress_label.text.begins_with("Nv 100"), "HUD reflects preserved level 100 cap")
	for resolution: Vector2 in [Vector2(360, 640), Vector2(640, 360)]:
		main.hud.size = resolution
		main.hud._layout()
		main.hud.set_nearby_station("Desafiar Guardião (opcional)")
		suite.check(main.hud.interact_button.size.x == 120 and main.hud.interact_button.caption.text == "E · Guardião\nOpcional", "optional guardian interaction stays legible %s" % resolution)
		suite.check(main.hud.mission_label.get_rect().end.y <= main.hud.loot_label.position.y, "expanded mission text avoids reward text %s" % resolution)
