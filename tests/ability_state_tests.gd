extends RefCounted

static func run(suite: SceneTree) -> void:
	var state := AbilityState.new()
	var sword := AbilityRules.CATEGORIES.espada
	var mage := AbilityRules.CATEGORIES.cajado
	suite.check(AbilityRules.CATEGORIES.size() == 5 and sword.normal.size() == 3 and mage.passives.size() == 3,"etapa2 catalog has five classes, three normals and passives")
	suite.check(AbilityRules.skill1("espada").id == "talho_agil" and AbilityRules.skill1("cajado").type == "magical","skill1 identity and magical damage by individual starter weapon")
	suite.check(not state.select_skill("espada",0,"corte_crescente",30,false) and not state.select_skill("espada",0,"guarda_reativa",3,true),"loadout edits require camp and proficiency")
	suite.check(state.select_skill("espada",0,"corte_crescente",30,true) and state.select_skill("espada",1,"danca_laminas",30,true),"two selectable category skills, including optional ultimate")
	suite.check(not state.select_skill("espada",0,"danca_laminas",30,true),"duplicate skill across slots rejected")
	suite.check(state.select_passive("espada",0,"fio_afiado",30,true) and not state.select_passive("espada",1,"fio_afiado",30,true),"passives unique and constrained to two slots")
	suite.check(not state.set_specialization("espada","duelista",17,true) and state.set_specialization("espada","duelista",18,true),"specialization unlock at 18, only safe camp")
	suite.check(not state.improve("espada","corte_crescente",30,1,false) and state.improve("espada","corte_crescente",30,1,true),"normal grade spends a point only at safe camp")
	suite.check(not state.learn_talent("espada","contra_ataque_fatal",30,1,true) and state.learn_talent("espada","sequencia_precisa",30,1,true),"talents enforce prerequisites")
	suite.check(state.spent() == 2 and state.refund("espada",true) and state.spent() == 0 and state.loadouts.espada.specialization == "duelista","respec refunds investments but preserves specialization")
	suite.check(state.start_normal("espada","corte_crescente",30) and not state.start_normal("espada","corte_crescente",30),"same skill cannot bypass cooldown by changing slot")
	state.tick(2.0,"espada")
	suite.check(is_equal_approx(state.cooldowns.espada.corte_crescente,5.0),"active category cooldown progresses")
	state.tick(2.0,"machado")
	suite.check(is_equal_approx(state.cooldowns.espada.corte_crescente,5.0),"inactive category cooldown pauses")
	suite.check(state.start_skill1("espada",6.0) and not state.start_skill1("espada",9.0),"all weapons in one category share skill1 cooldown")
	state.tick(2.0,"espada")
	suite.check(is_equal_approx(state.skill1_cooldowns.espada,4.0),"switching swords keeps remaining skill1 cooldown")
	suite.check(state.add_ultimate_damage("espada",999,"espada") and state.charge.espada == 99 and state.charge_remainder.espada == 9,"damage converts to ultimate charge preserving fractional HP")
	state.select_skill("espada",1,"",30,true)
	suite.check(not state.add_ultimate_damage("espada",100,"espada") and state.charge.espada == 99,"unequipped ultimate charge freezes")
	state.select_skill("espada",1,"danca_laminas",30,true)
	state.add_ultimate_damage("espada",1,"espada")
	suite.check(state.charge.espada == 100 and state.charge_remainder.espada == 0,"ultimate charge caps at full")
	suite.check(state.use_ultimate("espada","espada") and not state.use_ultimate("espada","espada") and state.global_ultimate_cooldown == 10.0,"ultimate consumes charge and starts global interval")
	var before_save := state.to_save()
	var levels := {}
	for category: String in AbilityRules.CATEGORIES:
		levels[category] = 30
	var restored := AbilityState.from_save(JSON.parse_string(JSON.stringify(before_save)),levels,99)
	suite.check(restored != null and restored.to_save() == before_save,"five-class loadouts, cooldown and ultimate state survive JSON round trip")
	restored.tick(3.0,"machado")
	suite.check(is_equal_approx(restored.global_ultimate_cooldown,7.0) and is_equal_approx(restored.skill1_cooldowns.espada,4.0),"global ultimate cooldown advances while inactive normal cooldown pauses")
	var tampered: Dictionary = JSON.parse_string(JSON.stringify(before_save))
	tampered.loadouts.espada.skills = ["danca_laminas","danca_laminas"]
	suite.check(AbilityState.from_save(tampered,levels,99) == null,"invalid duplicated skills rejected before loading")
	var overspent: Dictionary = JSON.parse_string(JSON.stringify(before_save))
	overspent.grades.espada["corte_crescente"] = 4
	suite.check(AbilityState.from_save(overspent,levels,0) == null,"invalid point budget rejected before loading")
	state.death_reset()
	suite.check(state.charge.espada == 0 and state.global_ultimate_cooldown == 0.0 and state.cooldowns.espada.is_empty() and state.skill1_cooldowns.espada == 0.0,"death clears all normal cooldowns and charges")

	var protected := AbilityState.new()
	suite.check(not protected.start_skill1("espada",NAN) and not protected.start_skill1("espada",INF),"non-finite cooldown input rejected")
	protected.select_skill("espada",0,"danca_laminas",30,true)
	protected.select_skill("cajado",0,"tempestade_arcana",30,true)
	protected.charge.espada = 100
	protected.charge.cajado = 100
	suite.check(protected.use_ultimate("espada","espada") and not protected.use_ultimate("cajado","cajado"),"cross-category ultimate interval enforced")
	protected.charge.espada = 100
	suite.check(protected.use_ultimate("espada","espada"),"global interval concerns different categories only")
	protected.tick(10.0,"cajado")
	suite.check(protected.use_ultimate("cajado","cajado"),"other ultimate enabled after ten active seconds")
	var invalid := protected.to_save()
	invalid.grades.espada[5] = 2
	suite.check(AbilityState.from_save(invalid,levels,99) == null,"non-string ability key rejected without a runtime error")
	var paused := protected.to_save()
	protected.tick(NAN,"cajado")
	suite.check(protected.to_save() == paused,"non-finite frame delta cannot corrupt persistent timers")
