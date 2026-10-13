extends RefCounted

static func run(suite: SceneTree) -> void:
	var legacy := GameProgress.new()
	legacy.etapa2_enabled = false
	legacy.xp = RPGRules.xp_floor(40)
	legacy.gold = 777
	legacy.bag = {"Madeira":8,"Essência":2}
	legacy.chest = {"Couro":9}
	legacy.attributes["Força"] = 5
	legacy.skills["Corte Circular"] = 3
	legacy.skills["Investida"] = 2
	legacy.skills["Fúria Ancestral"] = 3
	legacy.equipment = {"espada":3,"cajado":2,"arco":1}
	legacy.equipped.Arma = "cajado"
	for category: String in AbilityRules.CATEGORIES:
		legacy.talents.xp[category] = TalentRules.xp_floor(30)
		legacy.talents.learned[category] = ["corte","vigor","investida","guarda","furia","especializacao","maestria"]
		legacy.talents.mastery[category]["Dano Especial"] = 4
	# 35 category nodes plus 5 global ranks would exceed level 40: reject first.
	var invalid := legacy.to_json()
	var target := GameProgress.new()
	target.etapa2_enabled = true
	var before := target.to_json()
	suite.check(not target.load_text(invalid) and target.to_json() == before,"over-budget legacy save rejected atomically without partial mutation")
	legacy.xp = RPGRules.xp_floor(60)
	var source := legacy.to_json()
	suite.check(target.load_text(source) and target.etapa2_enabled and target.skills.is_empty(),"validated v9 migrates to independent v10 abilities")
	suite.check(target.migration_refund == 40 and target.skill_points() == 59,"global skill refund counted once, category nodes counted exactly once")
	suite.check(target.gold == 777 and target.attributes == legacy.attributes and target.talents.mastery == legacy.talents.mastery and target.talents.xp == legacy.talents.xp and target.equipment == legacy.equipment and target.bag == legacy.bag and target.chest == legacy.chest,"migration preserves wallet attributes proficiency Domain and all storage")
	var migrated := target.to_json()
	var parsed: Dictionary = JSON.parse_string(migrated)
	suite.check(parsed.version == 10 and parsed.rpg.skills.is_empty() and parsed.abilities.loadouts.size() == 5,"v10 snapshot replaces legacy active fields and contains all categories")
	var reloaded := GameProgress.new()
	suite.check(reloaded.load_text(migrated) and reloaded.to_json() == migrated and reloaded.skill_points() == 59,"v10 reload is exact and idempotent")
	suite.check(reloaded.load_text(source) and reloaded.to_json() == migrated and reloaded.skill_points() == 59,"repeated v9 migration never adds points or rewards")
	var envelope := target.export_backup()
	var path := "user://etapa2-migration-integrity.json"
	reloaded.save_path = path
	suite.check(reloaded.import_backup(envelope,true) and reloaded.import_backup(envelope,true) and reloaded.to_json() == migrated,"export import and repeat import preserve v10 exactly")
	var bad: Dictionary = JSON.parse_string(migrated)
	bad.abilities.charge.espada = 101
	suite.check(not reloaded.load_text(JSON.stringify(bad)) and reloaded.to_json() == migrated,"corrupt abilities rejected without modifying valid progress")
	bad = JSON.parse_string(migrated)
	bad.rpg.skills["Corte Circular"] = 3
	suite.check(not reloaded.load_text(JSON.stringify(bad)),"v10 cannot smuggle old investments back into active progression")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	# Actual on-disk migration keeps the byte-exact legacy source forever.
	suite.check(legacy._write_file(path,source),"write legacy fixture for atomic file migration")
	var disk := GameProgress.new()
	disk.etapa2_enabled = true
	disk.save_path = path
	suite.check(disk.load_save() and disk.save() and disk._read_file(path+".v9.original") == source,"atomic save creates immutable original v9 backup")
	suite.check(disk.save() and disk._read_file(path+".v9.original") == source,"subsequent saves cannot replace migration original")
	for suffix: String in ["",".bak",".v9.original"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
