extends SceneTree

# Marco 6 · oito espaços de equipamento: itens de conjunto, bônus em combate e compatibilidade de save.
# Rode: godot --headless --path . -s res://tests/equipment_rules_tests.gd
var checks := 0
var failures := 0

func _initialize() -> void:
	create_timer(60.0).timeout.connect(func(): push_error("EQUIP_FAIL: timeout"); quit(1))
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("EQUIP_FAIL: " + message)
	else:
		print("EQUIP_PASS: " + message)

func fresh() -> GameProgress:
	var p := GameProgress.new()
	p.etapa2_enabled = true
	p.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	return p

func _run() -> void:
	check(RPGRules.SLOTS.size() == 8 and RPGRules.slot_title("Acessório") == "Colar" and RPGRules.slot_title("Anel") == "Anel", "eight slots; the old Acessório is shown as Colar")
	var pieces := 0
	var slots_ok := true
	for id: String in RPGRules.EQUIPMENT:
		var item: Dictionary = RPGRules.EQUIPMENT[id]
		slots_ok = slots_ok and RPGRules.SLOTS.has(item.slot)
		if item.has("set_floor"): pieces += 1
	check(pieces == 14 and slots_ok, "14 floor-set pieces (7 per floor) and every item sits in a valid slot")
	check(ArsenalRules.metadata("elmo_mata").rarity == "raro" and ArsenalRules.metadata("elmo_vale").rarity == "epico" and ArsenalRules.metadata("couro").rarity == "comum", "set pieces carry their own rarity; older items keep theirs")
	var base := fresh()
	var plain := base.combat_stats()
	var p := fresh()
	for pair: Array in [["Capacete","elmo_mata"],["Armadura","colete_mata"],["Luvas","luvas_mata"],["Botas","botas_mata"],["Anel","anel_mata"],["Acessório","colar_mata"],["Amuleto","amuleto_mata"]]:
		p.equipment[pair[1]] = 0
		check(p.equip(pair[1]) and p.equipped[pair[0]] == pair[1], "%s equips into its slot" % pair[1])
	var stats := p.combat_stats()
	check(stats.hp == plain.hp + 16 + 19 + 13, "Capacete, Armadura and Colar add their Vida (%d)" % stats.hp)
	check(stats.armor == plain.armor + 2 + 2 + 2, "Capacete, Armadura and Botas add Defesa (%d)" % stats.armor)
	check(stats.physical == plain.physical + 3, "Luvas add Ataque")
	check(is_equal_approx(stats.critical_chance,plain.critical_chance + 0.008 + 0.016) and is_equal_approx(stats.critical_multiplier,plain.critical_multiplier + 0.05), "Luvas and Anel add Crítico and Dano crítico")
	check(is_equal_approx(stats.resistance,plain.resistance + 0.008 + 0.008) and stats.spirit == plain.spirit + 2, "Colar and Amuleto add Resistência; Amuleto adds Espírito")
	check(stats.speed > plain.speed, "Botas raise Velocidade")
	check(not p.equip("elmo_mata"), "equipping the piece that is already worn does nothing")
	check(p.unequip("Anel") and p.equipped.Anel == "" and p.combat_stats().critical_chance < stats.critical_chance, "unequipping a slot removes its bonus")
	check(RPGRules.bonus_text("anel_mata",0).contains("Crítico") and not RPGRules.bonus_text("couro",0).contains("Crítico"), "bonus text lists the new stats only for items that have them")
	# Save: formato novo, antigo com 3 espaços e itens no espaço errado.
	var restored := GameProgress.new()
	check(restored.load_text(p.to_json()) and restored.equipped.Capacete == "elmo_mata" and restored.equipped.Amuleto == "amuleto_mata" and restored.equipped.size() == 8, "the eight equipped slots survive save and load")
	var parsed: Dictionary = JSON.parse_string(p.to_json())
	var old_equipped := {"Arma": parsed.rpg.equipped.Arma, "Armadura": "", "Acessório": ""}
	parsed.rpg.equipped = old_equipped
	var legacy := GameProgress.new()
	check(legacy.load_text(JSON.stringify(parsed)) and legacy.equipped.size() == 8 and legacy.equipped.Capacete == "", "a save with only the three old slots still loads and fills the new slots empty")
	parsed = JSON.parse_string(p.to_json())
	parsed.rpg.equipped.Capacete = "botas_mata"
	check(not GameProgress.new().load_text(JSON.stringify(parsed)), "an item in the wrong slot is rejected")
	parsed = JSON.parse_string(p.to_json())
	parsed.rpg.equipped.Anel = "anel_nao_existe"
	check(not GameProgress.new().load_text(JSON.stringify(parsed)), "an unknown item id is rejected")
	print("EQUIP_RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
