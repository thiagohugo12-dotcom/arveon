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
	# Receitas das peças de conjunto.
	var recipe := LootRules.set_recipe(1,"elmo_mata")
	check(recipe.gold == 90 and recipe.materials["Presa de Javali"] == 4 and recipe.materials["Couro|incomum"] == 2 and recipe.rarity == "comum", "Elmo da Mata costs 4 Presa de Javali, 2 Couro Incomum and 90 gold")
	var vale := LootRules.set_recipe(2,"anel_vale")
	check(vale.gold == 180 and vale.materials["Pepita Dourada"] == 4 and vale.materials["Seda|raro"] == 2 and vale.rarity == "comum", "Anel do Vale costs 4 Pepita Dourada, 2 Seda Rara and 180 gold")
	check(LootRules.set_recipe(1,"anel_vale").is_empty() and LootRules.valid_recipe_id("piece:2:anel_vale") and not LootRules.valid_recipe_id("piece:1:anel_vale"), "a piece only has a recipe on its own floor")
	var crafter := fresh()
	crafter.gold = 500
	crafter.add_item("Presa de Javali",4)
	crafter.add_item("Couro|incomum",2)
	check(not crafter.can_craft_set(1,"elmo_mata") and crafter.craft_set(1,"elmo_mata") == "", "piece recipes start locked")
	crafter.add_item("Fragmento de Receita")
	check(crafter.use_fragment(1,"elmo_mata") and crafter.recipe_unlocked(1,"elmo_mata") and not crafter.recipe_unlocked(1,"luvas_mata"), "a Fragmento unlocks one piece recipe")
	check(crafter.craft_set(1,"elmo_mata") == "elmo_mata" and crafter.equipment.has("elmo_mata") and crafter.gold == 410 and crafter.bag.is_empty(), "crafting a piece pays and adds it to the equipment")
	check(crafter.equipment_rarity("elmo_mata") == "comum", "new set pieces start Common")
	var rarity_steps := ["incomum", "raro", "epico", "lendario", "mitico"]
	for target_rarity: String in rarity_steps:
		var evolution := EquipmentEconomy.rarity_recipe(crafter.equipment_rarity("elmo_mata"))
		crafter.gold += int(evolution.gold)
		for material: String in evolution.materials:
			crafter.add_item(material,int(evolution.materials[material]))
		check(crafter.can_evolve_equipment("elmo_mata"), "piece can pay the next rarity recipe for " + target_rarity)
		check(crafter.evolve_equipment("elmo_mata") and crafter.equipment_rarity("elmo_mata") == target_rarity, "piece evolves to " + target_rarity)
	check(not crafter.can_evolve_equipment("elmo_mata") and not crafter.evolve_equipment("elmo_mata"), "Mythic is the final piece rarity")
	check(ArsenalRules.RARITIES.mitico.color == "#e53935", "Mythic rarity uses the approved red border")
	check(not crafter.can_craft_set(1,"elmo_mata") and crafter.equip("elmo_mata"), "a piece is unique and can then be worn")
	var saved := GameProgress.new()
	check(saved.load_text(crafter.to_json()) and saved.recipes == ["piece:1:elmo_mata"] and saved.equipped.Capacete == "elmo_mata" and saved.equipment_rarity("elmo_mata") == "mitico", "an unlocked piece recipe and the worn piece survive the save")
	# Mochila com limite, excedente no Baú, expansão e gemas.
	var bag_test := fresh()
	check(bag_test.bag_capacity() == 40 and bag_test.used_slots() == 0 and bag_test.has_room(), "the bag starts with 40 slots")
	for index in range(40): bag_test.bag["lote_%d" % index] = 1
	check(bag_test.used_slots() == 40 and not bag_test.has_room(), "stacks fill the slots")
	check(bag_test.add_item("Couro") and bag_test.overflowed and bag_test.chest.get("Couro",0) == 1 and not bag_test.bag.has("Couro"), "a new item that does not fit goes to the chest, not lost")
	bag_test.bag["Seda"] = 1
	bag_test.bag.erase("lote_0")
	check(bag_test.add_item("Seda") and not bag_test.overflowed and bag_test.bag["Seda"] == 2, "adding to an existing stack never needs a free slot")
	bag_test.bag["lote_x"] = 1
	check(not bag_test.transfer("Couro",false) and bag_test.chest["Couro"] == 1, "taking a new item out of the chest needs a free slot")
	check(not bag_test.can_craft_weapon("espada","comum"), "crafting needs a free slot")
	bag_test.gold = 8000
	bag_test.gems = 100
	check(bag_test.expand_bag(false) and bag_test.bag_capacity() == 50 and bag_test.gold == 7500, "the first expansion costs 500 gold for 10 more slots")
	check(bag_test.expand_bag(true) and bag_test.bag_capacity() == 60 and bag_test.gems == 90, "the second expansion paid with gems costs 10 gems")
	check(bag_test.expand_bag(false) and bag_test.expand_bag(false) and bag_test.bag_capacity() == 80 and not bag_test.can_expand_bag(false) and not bag_test.can_expand_bag(true), "the bag stops at 80 slots")
	var cheap := fresh()
	cheap.gold = 499
	cheap.gems = 4
	check(not cheap.expand_bag(false) and not cheap.expand_bag(true), "an expansion needs the full price")
	cheap.grant_gems(15)
	check(cheap.gems == 19, "gems can be granted")
	var saver := fresh()
	saver.gold = 8000
	saver.gems = 100
	for expansion in range(4): saver.expand_bag(expansion % 2 == 1)
	var bag_restored := GameProgress.new()
	check(bag_restored.load_text(saver.to_json()) and bag_restored.bag_expansions == 4 and bag_restored.gems == saver.gems, "expansions and gems survive the save")
	var bag_parsed: Dictionary = JSON.parse_string(saver.to_json())
	bag_parsed["bag_expansions"] = 9
	check(not GameProgress.new().load_text(JSON.stringify(bag_parsed)), "an invalid expansion count is rejected")
	bag_parsed.erase("bag_expansions")
	check(GameProgress.new().load_text(JSON.stringify(bag_parsed)), "a save without the expansion field still loads")
	# Conjuntos de equipamento.
	var sets := fresh()
	for pair: Array in [["Capacete","elmo_mata"],["Luvas","luvas_mata"],["Acessório","colar_mata"]]:
		sets.equipment[pair[1]] = 0
		sets.equip(pair[1])
	var sword_uid: String = sets._create_weapon("espada","raro")
	sets.equip_weapon_instance(sword_uid)
	check(not sets.has_loadout(0) and not sets.apply_loadout(0), "an empty set cannot be applied")
	check(sets.save_loadout(0) and sets.has_loadout(0) and not sets.has_loadout(1), "the current equipment can be saved in set 1")
	sets.unequip("Capacete")
	sets.unequip("Luvas")
	sets.equipped.Acessório = ""
	check(sets.apply_loadout(0) and sets.equipped.Capacete == "elmo_mata" and sets.equipped.Luvas == "luvas_mata" and sets.equipped.Acessório == "colar_mata", "applying a set puts every saved piece back on")
	var axe_uid: String = sets._create_weapon("machado","comum")
	sets.equip_weapon_instance(axe_uid)
	check(sets.save_loadout(1) and sets.apply_loadout(0) and sets.equipped_weapon_uid == sword_uid and sets.equipped.Arma == "espada", "a set also restores the saved weapon copy")
	sets.equipment.erase("luvas_mata")
	sets.equipped.Luvas = ""
	check(sets.apply_loadout(0) and sets.equipped.Luvas == "", "a piece that no longer exists is skipped instead of breaking the set")
	var sets_restored := GameProgress.new()
	check(sets_restored.load_text(sets.to_json()) and sets_restored.has_loadout(0) and sets_restored.has_loadout(1) and not sets_restored.has_loadout(2), "saved sets survive the save")
	var sets_parsed: Dictionary = JSON.parse_string(sets.to_json())
	sets_parsed.loadouts[0].slots["Capacete"] = "botas_mata"
	check(not GameProgress.new().load_text(JSON.stringify(sets_parsed)), "a saved set with a piece in the wrong slot is rejected")
	sets_parsed = JSON.parse_string(sets.to_json())
	sets_parsed.erase("loadouts")
	check(GameProgress.new().load_text(JSON.stringify(sets_parsed)), "a save without sets still loads")
	print("EQUIP_RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
