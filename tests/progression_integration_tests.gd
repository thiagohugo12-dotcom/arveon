extends RefCounted

static func run(suite: SceneTree) -> void:
	var fast := TalentProgress.new()
	var slow := TalentProgress.new()
	for i in range(70): fast.record_damage("espada",1)
	slow.record_damage("espada",70)
	suite.check(fast.to_save() == slow.to_save() and fast.xp.espada == 7,"same effective damage gives equal XP for rapid and slow attacks")
	fast.record_damage("espada",3)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(fast.to_save()))
	var resumed := TalentProgress.from_save(saved,0)
	resumed.record_damage("espada",7)
	suite.check(resumed.xp.espada == 8 and resumed.damage_remainder.espada == 0,"fractional proficiency survives save between hits")
	var unarmed := GameProgress.new()
	unarmed.talents.xp.espada = TalentRules.xp_floor(30)
	unarmed.unequip("Arma")
	suite.check(unarmed.active_class() == "Aventureiro" and unarmed.active_category().is_empty() and unarmed.combat_stats().automatic == 0,"unequipped weapon cannot keep a category proficiency bonus")
	var examples := []
	for category: String in ArsenalRules.CATEGORIES:
		var p := GameProgress.new()
		p.xp = RPGRules.xp_floor(20)
		p.attributes = {"Força":4,"Vitalidade":4,"Resistência":6,"Mobilidade":5,"Destreza":5,"Espírito":4}
		p.equipment[category] = 0
		p.equip(category)
		p.talents.xp[category] = TalentRules.xp_floor(10)
		p.talents.mastery[category] = {"Dano":3,"Dano Especial":2,"Crítico":2,"Dano Crítico":2}
		var stats := p.combat_stats()
		var critical := CombatRules.resolve(stats[stats.damage_type],1+stats.automatic+stats.basic,1,stats.critical_chance,stats.critical_multiplier,0)
		var skill := CombatRules.resolve(stats.physical,1+stats.automatic+stats.special,1.4,stats.critical_chance,stats.critical_multiplier,0.99)
		suite.check(stats.damage == {"espada":22,"machado":26,"lanca":24,"arco":22,"cajado":26}[category] and p.attribute_points() == 10 and p.talents.mastery_points(category) == 0,"calculated build example verified "+category)
		examples.append({"category":category,"class":p.active_class(),"basic":stats.damage,"critical":critical.damage,"skill1_physical":skill.damage,"interval":ArsenalRules.profile(category).interval*stats.basic_interval_factor,"speed":stats.speed})
	# Faithful v7 fixture: all five conquered floors, investments and category progress.
	var p := GameProgress.new()
	p.xp = RPGRules.xp_floor(40)
	p.gold = 777
	p.bag = {"Madeira":12,"Cogumelos":5}
	p.chest = {"Seda":3}
	p.skills["Corte Circular"] = 3
	p.equipment.cajado = 2
	p.equipped.Arma = "cajado"
	for id in range(1,6):
		p.switch_floor(id)
		p.opened_caches["west_roots"] = true
		p.discovered_pois["herb_west"] = true
		p.ascension.defeats[str(id)] = 50
		p.ascension.complete_forest_trial()
	var old: Dictionary = JSON.parse_string(p.to_json())
	old.version = 7
	old.rpg.skills = preload("res://tests/etapa2_fixtures.gd").legacy_skills(p)
	old.rpg.attributes = {"Força":3,"Vitalidade":2,"Agilidade":7,"Espírito":4}
	old.talents = {"xp":{"espada":3100,"machado":590,"lanca":210,"arco":20,"cajado":8700},"learned":{"espada":["corte","vigor","guarda","investida","furia","especializacao"],"machado":[],"lanca":[],"arco":[],"cajado":[]}}
	var raw := JSON.stringify(old)
	var archive := JSON.stringify({"format":"grande-arvore-rpg-save","archive_version":1,"payload":raw,"sha256":raw.sha256_text()})
	var fixture := FileAccess.open("res://build/progression-save-fixture.json",FileAccess.WRITE)
	fixture.store_string(archive)
	fixture.close()
	var restored := GameProgress.new()
	var path := "user://qa_old_progression_%d.json" % Time.get_ticks_usec()
	var original := FileAccess.open(path,FileAccess.WRITE)
	original.store_string(raw)
	original.close()
	restored.save_path = path
	suite.check(restored.load_save() and restored.save() and FileAccess.get_file_as_string(path+".v7.original") == raw,"old v7 disk migration preserves byte-exact original")
	suite.check(restored.ascension.campaign_completed and restored.ascension.current_floor == 5 and restored.floor_states == p.floor_states and restored.bag == p.bag and restored.chest == p.chest and restored.gold == 777,"migration preserves five floors exploration inventory and economy")
	suite.check(restored.attribute_points() == 69 and restored.skills.is_empty() and restored.skill_points() == 39 and restored.equipment == p.equipment and restored.talents.level("espada") == 18 and restored.talents.level("cajado") == 30 and restored.talents.spent() == 0,"migration preserves proficiencies and refunds replaced purchases exactly once")
	var imported: GameProgress = restored.preview_backup(archive)
	suite.check(imported != null and imported.to_json() == restored.to_json(),"checksummed v7 archive and filesystem migration produce identical state")
	for suffix: String in ["",".bak",".v7.original"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	var balance := _simulate_campaign()
	for category: String in ArsenalRules.CATEGORIES:
		var rows: Array = balance[category]
		suite.check(rows.size() == 5 and rows[0].level < 30 and rows[4].level > rows[0].level and rows[3].xp <= TalentRules.xp_floor(30),"damage budget evolves without proficiency cap through floor four "+category)
		# Marco 4: com a tabela de escala 1–10 a proficiência passa do nível 30 durante o Andar 5 (xp ~4505 contra 3480);
		# o ritmo de proficiência por dano precisa ser reequilibrado quando os Andares 3–5 existirem.
	var report := FileAccess.open("res://build/progression-calculations.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"examples":examples,"simulation":balance},"\t"))
	report.close()

static func _simulate_campaign() -> Dictionary:
	var result := {}
	for category: String in ArsenalRules.CATEGORIES:
		var p := GameProgress.new()
		p.equipment[category] = 0
		p.equip(category)
		var rows := []
		var seconds := 0.0
		var total_hp := 0
		for floor_id in range(1,6):
			var roster: Array[int] = []
			for i in range(50): roster.append(3 if i%8 == 7 else (i+1)%3)
			for wave: Array in TowerTrial.WAVES:
				for kind: int in wave: roster.append(kind)
			roster.append(4)
			for kind: int in roster:
				var hp := roundi([48,36,64,120,360][kind]*FloorConfig.difficulty(floor_id))
				total_hp += hp
				while hp > 0:
					var stats := p.combat_stats()
					var effective := mini(hp,int(stats.damage))
					p.talents.record_damage(category,effective)
					hp -= effective
					seconds += ArsenalRules.profile(category).interval
			rows.append({"floor":floor_id,"hp_total":total_hp,"xp":int(p.talents.xp[category]),"level":p.talents.level(category),"basic_combat_minutes":snappedf(seconds/60,0.01)})
		result[category] = rows
	return result
