extends RefCounted

static func legacy_attributes(value: Dictionary) -> Dictionary:
	return {"Força":value["Força"],"Vitalidade":value["Vitalidade"],"Espírito":value["Espírito"],"Agilidade":value.get("Destreza",0)}

static func run(suite: SceneTree) -> void:
	var p := GameProgress.new()
	p.xp = RPGRules.xp_floor(100)
	suite.check(p.attributes.size() == 6 and p.attribute_points() == 198 and p.skill_points() == 99,"six attributes use the same level budgets")
	p.attributes["Espírito"] = 5
	suite.check(p.combat_stats().physical == 12 and p.combat_stats().magical == 22 and p.combat_stats().hp == 100,"Spirit affects magic only, never physical damage or HP")
	p.attributes["Força"] = 3
	p.attributes["Resistência"] = 70
	p.attributes["Mobilidade"] = 30
	p.attributes["Destreza"] = 30
	var stats := p.combat_stats()
	suite.check(stats.physical == 18 and stats.magical == 22 and stats.speed == 216 and is_equal_approx(stats.basic_interval_factor,0.85) and stats.resistance == 0.25,"independent offensive and capped defensive and speed attributes")
	suite.check(stats.cooldown == 1.0 and stats.accuracy == 130,"Dexterity derives accuracy without skill cooldown bonus or misses")
	suite.check(RPGRules.received_damage(40,"physical",8,0.25) == 24 and RPGRules.received_damage(40,"magical",8,0.25) == 30,"armor is physical flat reduction; resistance applies to both types")
	suite.check(RPGRules.received_damage(0,"physical",0,0.25) == 0 and RPGRules.received_damage(2,"physical",50,0.25) == 1,"damage zero and minimum positive damage remain bounded")
	for version in [4,5,6,7]:
		var old: Dictionary = JSON.parse_string(p.to_json())
		old.version = version
		var attrs := {"Força":3,"Vitalidade":2,"Agilidade":7,"Espírito":5}
		if version == 4: old.attributes = attrs
		else: old.rpg.attributes = attrs
		var restored := GameProgress.new()
		suite.check(restored.load_text(JSON.stringify(old)) and restored.attributes["Força"] == 3 and restored.attributes["Vitalidade"] == 2 and restored.attributes["Espírito"] == 5 and restored.attributes["Mobilidade"] == 0 and restored.attributes["Destreza"] == 0 and restored.attribute_points() == 188,"legacy attributes refunded exactly once v%d" % version)
		var again := GameProgress.new()
		suite.check(again.load_text(restored.to_json()) and again.attribute_points() == 188 and again.preview_backup(restored.export_backup()) != null,"migration export and reload preserve refund v%d" % version)
