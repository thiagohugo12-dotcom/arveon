extends RefCounted

static func run(suite: SceneTree) -> void:
	var sword := AbilityRules.CATEGORIES.espada
	var ultimate: Dictionary = sword.ultimate
	var wave := AbilityRules.effect(ultimate.id)
	suite.check(ultimate.id == "danca_laminas" and ultimate.name == "Kamusari" and ultimate.prof == 15, "Kamusari is shown at 15 while keeping the legacy v11 Ultimate ID")
	suite.check(wave.shape == "cone" and float(wave.reach) == 320.0 and float(wave.dot) > 0.0 and int(wave.hits) == 1, "Kamusari is one long frontal hit, not the obsolete circular multihit")
	suite.check(AbilityRules.effect("guarda_reativa").duration == 3.0 and AbilityRules.effect("estocada_precisa").shape == "line", "approved Guard and Thrust keep their existing combat rules")
	var state := AbilityState.new()
	suite.check(state.select_skill("espada", 0, "danca_laminas", 30, true), "existing v11 Kamusari slot ID remains equippable")
	var levels := {}
	for category: String in AbilityRules.CATEGORIES: levels[category] = 30
	var saved := state.to_save()
	var restored := AbilityState.from_save(JSON.parse_string(JSON.stringify(saved)), levels, 90)
	suite.check(restored != null and restored.loadouts.espada.skills[0] == "danca_laminas", "legacy Ultimate-equipped saves load without a migration")

	var caster := Node2D.new()
	suite.root.add_child(caster)
	var vfx := SwordSkillVfx.new()
	caster.add_child(vfx)
	vfx.play_skill(SwordSkillVfx.GUARDA, Vector2.RIGHT, AbilityRules.effect("guarda_reativa"), 3.0)
	suite.check(vfx.guard_left == 3.0 and vfx.activations == 1, "Guard visual follows its existing three-second defense state")
	vfx.guard_impact()
	suite.check(vfx.guard_impact_left > 0.0 and vfx.remaining == 0.0, "guard impact sparks do not create offensive hits")
	vfx.play_skill(SwordSkillVfx.ESTOCADA, Vector2.UP, AbilityRules.effect("estocada_precisa"))
	suite.check(vfx.active_id == SwordSkillVfx.ESTOCADA and vfx.direction == Vector2.UP and vfx.reach == 155.0, "thrust effect uses current aim and the exact combat reach")
	vfx.play_skill(SwordSkillVfx.KAMUSARI, Vector2.RIGHT, wave)
	suite.check(vfx.active_id == SwordSkillVfx.KAMUSARI and vfx.reach == 320.0 and vfx.duration > 0.4, "Kamusari animates one frontal red energy wave")
	vfx._process(4.0) # guard lasts 3s; exhaust both timers before asserting cleanup
	suite.check(vfx.active_id.is_empty() and vfx.guard_left == 0.0, "temporary sword presentation completes without leaving persistent state")
	vfx.clear()
	caster.queue_free()

	var view := Skill1GameView.new()
	suite.root.add_child(view)
	view.village_scale = true
	view.play_sword_special(SwordSkillVfx.GUARDA, Vector2.LEFT)
	suite.check(view.sword_special_id == SwordSkillVfx.GUARDA and view.sword_special_row == SwordActorView.direction_row(Vector2.LEFT), "guard pose respects the chosen top-down direction")
	view.play_sword_special(SwordSkillVfx.ESTOCADA, Vector2.UP)
	suite.check(view.sword_special_id == SwordSkillVfx.ESTOCADA and view.sword_special_duration > 0.0, "thrust has a timed full-body frame sequence")
	view.play_sword_special(SwordSkillVfx.KAMUSARI, Vector2.RIGHT)
	suite.check(view.sword_special_id == SwordSkillVfx.KAMUSARI and view.sword_special_left > 0.0, "Ultimate plays dedicated full-body sword frames")
	view.clear_sword_special()
	suite.check(view.sword_special_left == 0.0, "cancelled sword poses return cleanly to walking/idle")
	view.queue_free()
