extends SceneTree
func _initialize() -> void:
	var rows := []
	for category: String in AbilityRules.CATEGORIES:
		var p := GameProgress.new()
		p.xp = RPGRules.xp_floor(20)
		p.attributes = {"Força":4,"Vitalidade":4,"Resistência":6,"Mobilidade":5,"Destreza":5,"Espírito":4}
		p.equipment[category] = 0
		p.equipped.Arma = category
		p.talents.xp[category] = TalentRules.xp_floor(10)
		p.talents.mastery[category] = {"Dano":3,"Dano Especial":2,"Crítico":2,"Dano Crítico":2}
		var stats := p.combat_stats()
		var profile := ArsenalRules.profile(category)
		var weapon := AbilityRules.skill1(category)
		var basic := CombatRules.resolve(stats[stats.damage_type],1+stats.automatic+stats.basic,1,stats.critical_chance,stats.critical_multiplier,0.99)
		var skill := CombatRules.resolve(stats[stats.damage_type],1+stats.automatic+stats.special,weapon.power,stats.critical_chance,stats.critical_multiplier,0.99)
		rows.append({"category":category,"class":p.active_class(),"basic_damage":basic.damage,"basic_interval":profile.interval*stats.basic_interval_factor,"basic_dps":snappedf(basic.damage/(profile.interval*stats.basic_interval_factor),0.01),"skill1":weapon.name,"skill1_damage":skill.damage,"skill1_cooldown":weapon.cooldown,"reach":profile.reach,"hp":stats.hp,"speed":stats.speed})
	var output := FileAccess.open("res://build/etapa2-balance.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(rows,"\t"))
	output.close()
	print(JSON.stringify(rows))
	quit()
