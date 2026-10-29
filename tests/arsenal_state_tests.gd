extends RefCounted

static func run(suite) -> void:
	var p := GameProgress.new()
	for id: String in ArsenalRules.CATEGORIES:
		p.equipment[id] = 3
		p.equip(id)
		var serialized := p.to_json()
		var restored := GameProgress.new()
		suite.check(restored.load_text(serialized) and restored.equipment == p.equipment and restored.equipped == p.equipped and restored.equipment_metadata() == p.equipment_metadata(), "five category metadata equipped ID and +3 roundtrip " + id)
		var archive := p.export_backup()
		var candidate: GameProgress = p.preview_backup(archive)
		suite.check(candidate != null and candidate.equipped.Arma == id and candidate.equipment[id] == 3, "weapon backup checksum and metadata validate " + id)
		var legacy := JSON.parse_string(serialized) as Dictionary
		legacy.rpg.erase("equipment_meta")
		suite.check(GameProgress.new().load_text(JSON.stringify(legacy)), "missing metadata migrates owned equipment without removal " + id)
		var invalid := JSON.parse_string(serialized) as Dictionary
		invalid.rpg.equipment_meta[id].rarity = "mitico"
		suite.check(not restored.load_text(JSON.stringify(invalid)) and restored.equipped.Arma == id, "mismatched rarity rejected atomically " + id)
		invalid = JSON.parse_string(serialized) as Dictionary
		invalid.rpg.equipment_meta[id].category = "unknown"
		suite.check(not restored.load_text(JSON.stringify(invalid)), "invalid category cannot change loaded attack " + id)
		var rarity_before: String = ArsenalRules.metadata(id).rarity
		p.equipment[id] = 0
		suite.check(ArsenalRules.metadata(id).rarity == rarity_before, "rarity remains independent from enhancement " + id)
	for id: String in ArsenalRules.RARITIES:
		suite.check(not ArsenalRules.RARITIES[id].name.is_empty() and Color(ArsenalRules.RARITIES[id].color).a == 1.0, "rarity has legible text and independent visual identity " + id)
	var before := p.to_json()
	var values := ArsenalRules.effective(p,"machado")
	suite.check(p.to_json() == before and values.interval == 0.9 and values.reach == 80, "comparison is read-only and uses effective candidate attributes")
	p.gold = 100
	p.bag = {"Madeira":6,"Seda":2,"Essência":2}
	p.equipment.erase("arco")
	p.equipment.erase("cajado")
	p.equipped.Arma = "espada"
	suite.check(p.forge("arco",-1) and p.forge("cajado",-1) and p.gold == 35 and p.bag.is_empty(), "new ranged weapons obtained through existing smith resources and wallet")
	suite.check(not p.forge("arco",-1) and p.equipment.size() == 5, "repeated ranged recipe cannot duplicate ownership")
	suite.check(p.equip("arco") and p.unequip("Arma") and p.equipment.has("arco") and p.equip("cajado"), "equip unequip changes slot without losing owned ranged items")
	# Isolated fixture consumed by the real exported Web engine, never a player save.
	p.equipment.arco = 3
	p.equipment.cajado = 2
	DirAccess.make_dir_recursive_absolute("res://build")
	var file := FileAccess.open("res://build/arsenal-save-fixture.json",FileAccess.WRITE)
	file.store_string(p.export_backup())
	file.close()
