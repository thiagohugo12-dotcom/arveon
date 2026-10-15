extends RefCounted
static func run(suite: SceneTree) -> void:
	var p := GameProgress.new()
	p.etapa2_enabled = true
	p.xp = RPGRules.xp_floor(50)
	var total := p.skill_points()
	for category: String in AbilityRules.CATEGORIES:
		var catalog: Dictionary = AbilityRules.CATEGORIES[category]
		p.equipment[category] = 0
		p.equipped.Arma = category
		var points := p.skill_points()
		for rule: Dictionary in catalog.normal:
			p.talents.xp[category] = TalentRules.xp_floor(int(rule.prof)-1)
			suite.check(not p.configure_ability("equip_skill",category,rule.id,0,true),"normal unlock locked before milestone "+rule.id)
			p.talents.xp[category] = TalentRules.xp_floor(int(rule.prof))
			suite.check(p.configure_ability("equip_skill",category,rule.id,0,true) and p.skill_points() == points,"normal grade one unlock is free "+rule.id)
		p.configure_ability("equip_skill",category,"",0,true)
		for passive: Dictionary in catalog.passives:
			p.talents.xp[category] = TalentRules.xp_floor(int(passive.prof)-1)
			suite.check(not p.configure_ability("equip_passive",category,passive.id,0,true),"passive locked before milestone "+passive.id)
			p.talents.xp[category] = TalentRules.xp_floor(int(passive.prof))
			suite.check(p.configure_ability("equip_passive",category,passive.id,0,true) and p.skill_points() == points,"basic passive unlock and selection are free "+passive.id)
		p.talents.xp[category] = TalentRules.xp_floor(18)
		for id: String in catalog.specializations:
			suite.check(not p.configure_ability("specialization",category,id,0,false) and p.configure_ability("specialization",category,id,0,true) and p.skill_points() == points,"specialization is free and camp-only "+id)
		p.talents.xp[category] = TalentRules.xp_floor(60 if category == "espada" else 30)
		p.configure_ability("equip_skill",category,catalog.normal[0].id,0,true)
		p.abilities.start_normal(category,catalog.normal[0].id,30)
		for id: String in AbilityRules.talent_tree(category):
			suite.check(not p.learn_talent(category,id,false) and p.learn_talent(category,id,true),"talent progression uses approved camp prerequisite "+id)
		for i in range(3): suite.check(p.improve_skill(category+":"+catalog.normal[0].id,true),"normal improvement consumes one shared point "+category+str(i))
		suite.check(p.skill_points() == points-3-AbilityRules.talent_tree(category).size() and p.skill_rank(1) == 4 and not p.improve_skill(category+":"+catalog.normal[0].id,true),"three paid grades and four talents consume exact budget "+category)
		var timers: Dictionary = p.abilities.cooldowns[category].duplicate()
		suite.check(p.configure_ability("equip_skill",category,catalog.normal[0].id,1,true) and p.abilities.loadouts[category].skills[0] == "" and p.abilities.cooldowns[category] == timers,"moving equipped skill is atomic and keeps timer "+category)
		var combat := ClassCombat.new()
		combat.progress = p
		combat.category = category
		suite.check(combat.mastery() and not p.abilities.loadouts[category].skills.has(catalog.ultimate.id),"Maestria 30 is automatic without equipping Ultimate "+category)
		var invested := p.skill_points()
		suite.check(not p.configure_ability("reset_tree",category,"",0,false) and p.configure_ability("reset_tree",category,"",0,true) and p.skill_points() == invested+3+AbilityRules.talent_tree(category).size() and p.abilities.cooldowns[category] == timers,"free respec returns only investments and preserves recargas "+category)
		p.configure_ability("reset_tree",category,"",0,true)
		suite.check(p.skill_points() == total,"repeated redistributions cannot mint points "+category)
