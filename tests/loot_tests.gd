extends SceneTree

# Marco 5: drops com nome, proteção contra azar (25/60), receitas de conjunto bloqueadas até o
# chefe ou um Fragmento, save com campos opcionais e o painel do Ferreiro.
# Rode: godot --headless --path . -s res://tests/loot_tests.gd
var checks := 0
var failures := 0

func _initialize() -> void:
	create_timer(60.0).timeout.connect(func(): push_error("LOOT_FAIL: timeout"); quit(1))
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("LOOT_FAIL: " + message)
	else:
		print("LOOT_PASS: " + message)

func rng(seed_value: int) -> RandomNumberGenerator:
	var generator := RandomNumberGenerator.new()
	generator.seed = seed_value
	return generator

func _run() -> void:
	# Tabelas coerentes.
	var items_ok := true
	for item: String in LootRules.named_items(): items_ok = items_ok and GameProgress.ITEMS.has(item)
	check(items_ok and LootRules.named_items().size() == 15, "every named item is a valid bag item (11 materials, 3 trophies, 1 fragment)")
	var recipes_ok := true
	for floor_id: int in FloorCatalog.LOOT.sets:
		for category: String in FloorCatalog.LOOT.sets[floor_id].named:
			var recipe := LootRules.set_recipe(floor_id,category)
			recipes_ok = recipes_ok and not recipe.is_empty() and recipe.materials.size() == 3 and LootRules.valid_recipe_id(LootRules.recipe_id(floor_id,category))
	check(recipes_ok and LootRules.set_recipe(1,"espada").rarity == "comum" and LootRules.set_recipe(2,"espada").rarity == "comum" and LootRules.set_recipe(3,"espada").rarity == "comum" and LootRules.set_recipe(3,"machado").is_empty(), "every registered floor-set recipe is complete and starts Common")
	var spada := LootRules.set_recipe(1,"espada")
	check(spada.gold == 120 and spada.materials["Presa de Javali"] == 6 and spada.materials["Couro|incomum"] == 3 and spada.materials["Coração da Mata"] == 1, "Espada da Mata costs 6 Presa de Javali, 3 Couro Incomum, 1 Coração da Mata and 120 gold")
	var brejo_piece := LootRules.piece_recipe(3,"elmo_brejo")
	var brejo_sword := LootRules.set_recipe(3,"espada")
	check(brejo_piece.gold == 270 and brejo_piece.materials["Limo Espesso"] == 4 and brejo_piece.materials["Couro|raro"] == 2 and brejo_sword.gold == 360 and brejo_sword.materials["Vesícula Tóxica"] == 6 and brejo_sword.materials["Coração do Brejo"] == 1, "Pântano recipes use the approved costs and named ingredients")
	check(LootRules.piece_recipe(3,"amuleto_brejo").materials["Essência dos Sussurros"] == 1 and LootRules.weapon_title(3,"espada") == "Lâmina do Brejo", "the rare boss essence has a usable recipe and the sword has its Pântano name")
	# Taxas de drop nomeado.
	var pity := LootRules.new_pity()
	var generator := rng(7)
	var named_javali := 0
	var named_elite := 0
	var fragments := 0
	var trials := 4000
	for _i in range(trials):
		for drop: Dictionary in LootRules.roll(0,generator,pity): if drop.get("named",false) and drop.item == "Presa de Javali": named_javali += 1
		for drop: Dictionary in LootRules.roll(3,generator,pity):
			if drop.get("named",false) and drop.item == "Presa de Javali": named_elite += 1
			if drop.get("named",false) and drop.item == "Fragmento de Receita": fragments += 1
	check(absf(float(named_javali) / trials - 0.25) < 0.03, "Javali drops Presa de Javali about 25%% of the time (%.3f)" % (float(named_javali) / trials))
	check(absf(float(named_elite) / trials - 0.60) < 0.03, "Javali Elite drops Presa de Javali about 60%% of the time (%.3f)" % (float(named_elite) / trials))
	check(absf(float(fragments) / trials - 0.02) < 0.01, "only elites drop the Fragmento de Receita, about 2%% (%.3f)" % (float(fragments) / trials))
	var other_ok := true
	var other := rng(11)
	for kind in [0,1,2,5,6,7]:
		for _i in range(300):
			for drop: Dictionary in LootRules.roll(kind,other,LootRules.new_pity()): if drop.get("named",false) and drop.item == "Fragmento de Receita": other_ok = false
	check(other_ok, "ordinary creatures never drop Fragmentos")
	var by_kind := {1:"Teia Reforçada",2:"Espinho Seco",5:"Pepita Dourada",6:"Placa de Tatu",7:"Ferrão da Chapada"}
	var kinds_ok := true
	for kind: int in by_kind:
		var seen := false
		var source := rng(kind)
		for _i in range(200):
			for drop: Dictionary in LootRules.roll(kind,source,LootRules.new_pity()): if drop.get("named",false) and drop.item == by_kind[kind]: seen = true
		kinds_ok = kinds_ok and seen
	check(kinds_ok, "each creature drops its own named material")
	var swamp_drop_ok := true
	for kind: int in {8:"Fibra Encharcada",9:"Vesícula Tóxica",10:"Limo Espesso",11:"Dente do Jacaré Ancião"}:
		var found := 0
		for _i in range(200):
			for drop: Dictionary in LootRules.roll(kind,rng(kind * 1000 + _i),LootRules.new_pity()):
				if drop.get("named",false) and drop.item == {8:"Fibra Encharcada",9:"Vesícula Tóxica",10:"Limo Espesso",11:"Dente do Jacaré Ancião"}[kind]: found += 1
		swamp_drop_ok = swamp_drop_ok and found >= 35 and found <= 65
	check(swamp_drop_ok, "Pântano creatures and Jacaré drop their own materials at about 25%")
	var swamp_boss := LootRules.field_boss(3,rng(33),LootRules.new_pity())
	check(swamp_boss.any(func(drop: Dictionary): return drop.item == "Coração do Brejo"), "Mãe dos Sussurros guarantees the Pântano trophy")
	# Proteção contra azar.
	var counters := LootRules.new_pity()
	var forced_at := -1
	for n in range(1,40):
		if LootRules.apply_pity("comum",counters,false) == "raro":
			forced_at = n
			break
	check(forced_at == 26 and counters.raro == 0, "after 25 drops without a Raro the 26th is a Raro (%d)" % forced_at)
	var epic := {"raro": 0, "epico": 60}
	check(LootRules.apply_pity("comum",epic,false) == "comum" and epic.epico == 61, "the Épico guarantee never triggers on ordinary creatures")
	check(LootRules.apply_pity("comum",epic,true) == "epico" and epic.epico == 0 and epic.raro == 0, "after 60 drops without Épico an elite or boss drop is an Épico and resets both counters")
	var lucky := {"raro": 20, "epico": 20}
	check(LootRules.apply_pity("raro",lucky,false) == "raro" and lucky.raro == 0 and lucky.epico == 21, "a natural Raro resets only the Raro counter")
	# Chefes.
	var boss_ok := true
	for floor_id in [1,2]:
		var reward := LootRules.field_boss(floor_id,rng(floor_id),LootRules.new_pity())
		var materials := 0
		var has_trophy := false
		for drop: Dictionary in reward:
			if drop.get("named",false): has_trophy = has_trophy or drop.item == FloorCatalog.LOOT.trophy[floor_id]
			else:
				materials += 1
				boss_ok = boss_ok and EquipmentEconomy.RARITY_ORDER.find(drop.rarity) >= 1
		boss_ok = boss_ok and has_trophy and materials >= 3 and materials <= 5
		var tower := LootRules.tower_boss(floor_id)
		boss_ok = boss_ok and tower.size() == 2 and tower[0].item == FloorCatalog.LOOT.trophy[floor_id] and tower[1].item == "Fragmento de Receita"
	check(boss_ok, "field guardians give a trophy plus 3-5 Incomum-or-better materials; tower guardians give trophy and Fragmento")
	# Receitas, desbloqueio e forja.
	var p := GameProgress.new()
	p.etapa2_enabled = true
	p.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	p.gold = 500
	for item: String in ["Presa de Javali","Coração da Mata"]: p.add_item(item,6 if item == "Presa de Javali" else 1)
	p.add_item("Couro|incomum",3)
	check(not p.recipe_unlocked(1,"espada") and not p.can_craft_set(1,"espada") and p.craft_set(1,"espada") == "", "set recipes start locked and cannot be crafted")
	p.floor_states["1"].guardian_defeated = true
	check(p.recipe_unlocked(1,"espada") and p.recipe_unlocked(1,"arco") and not p.recipe_unlocked(2,"espada"), "defeating a floor's Guardian unlocks that floor's recipes only")
	check(p.can_craft_set(1,"espada"), "an unlocked recipe with every material can be crafted")
	var gold_before := p.gold
	var uid := p.craft_set(1,"espada")
	check(uid != "" and p.weapon(uid).rarity == "comum" and p.weapon(uid).category == "espada" and p.gold == gold_before - 120 and not p.bag.has("Presa de Javali") and not p.bag.has("Coração da Mata"), "crafting pays the materials and gold and creates a Common sword")
	check(not p.can_use_fragment(2,"espada") and not p.use_fragment(2,"espada"), "a Fragmento is required to unlock a locked recipe")
	p.add_item("Fragmento de Receita")
	check(p.can_use_fragment(2,"espada") and p.use_fragment(2,"espada") and p.recipe_unlocked(2,"espada") and not p.recipe_unlocked(2,"arco") and p.fragments() == 0, "one Fragmento unlocks exactly one recipe and is consumed")
	check(not p.can_use_fragment(1,"espada"), "a recipe that is already open does not waste a Fragmento")
	var swamp := GameProgress.new()
	swamp.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	swamp.gold = 1000
	swamp.add_item("Fragmento de Receita",2)
	swamp.add_item("Limo Espesso",4)
	swamp.add_item("Vesícula Tóxica",6)
	swamp.add_item("Couro|raro",5)
	swamp.add_item("Coração do Brejo")
	check(swamp.use_fragment(3,"elmo_brejo") and swamp.use_fragment(3,"espada") and swamp.can_craft_set(3,"elmo_brejo"), "Pântano recipes unlock independently with existing Fragments")
	check(swamp.craft_set(3,"elmo_brejo") == "elmo_brejo" and swamp.equipment_rarity("elmo_brejo") == "comum" and swamp.equip("elmo_brejo"), "Pântano helmet is crafted Common and can be equipped")
	var swamp_uid := swamp.craft_set(3,"espada")
	check(swamp_uid != "" and swamp.weapon(swamp_uid).rarity == "comum" and swamp.weapon(swamp_uid).model == "lamina_brejo" and swamp.gold == 370 and swamp.bag.get("Couro|raro",0) == 0, "Pântano sword pays materials and creates its own Common model")
	var attack_before := int(swamp.combat_stats().damage)
	check(swamp.equip_weapon_instance(swamp_uid) and int(swamp.combat_stats().damage) == attack_before + 3, "Lâmina do Brejo adds only the approved three Attack to the sword category")
	var swamp_loaded := GameProgress.new()
	check(swamp_loaded.load_text(swamp.to_json()) and swamp_loaded.equipped.Capacete == "elmo_brejo" and swamp_loaded.equipment_rarity("elmo_brejo") == "comum" and swamp_loaded.weapon(swamp_uid).model == "lamina_brejo", "Pântano equipment, recipe unlocks and weapon model survive a v13 save")
	var all_recipes := GameProgress.new()
	for floor_id: int in FloorCatalog.LOOT.sets:
		for category: String in FloorCatalog.LOOT.sets[floor_id].named:
			all_recipes.recipes.append(LootRules.recipe_id(floor_id,category))
		for id: String in RPGRules.EQUIPMENT:
			if RPGRules.EQUIPMENT[id].get("set_floor", 0) == floor_id:
				all_recipes.recipes.append(LootRules.recipe_id(floor_id,id))
	var all_loaded := GameProgress.new()
	check(all_recipes.recipes.size() == LootRules.max_recipe_count() and all_loaded.load_text(all_recipes.to_json()) and all_loaded.recipes.size() == all_recipes.recipes.size(), "all 32 recipe unlocks remain valid in the existing v13 save format")
	# Save: campos opcionais.
	p.pity = {"raro": 7, "epico": 12}
	var restored := GameProgress.new()
	check(restored.load_text(p.to_json()) and restored.pity == {"raro": 7, "epico": 12} and restored.recipes == ["set:2:espada"], "pity counters and fragment-unlocked recipes survive save and load")
	var parsed: Dictionary = JSON.parse_string(p.to_json())
	parsed.erase("pity")
	parsed.erase("recipes")
	var legacy := GameProgress.new()
	check(legacy.load_text(JSON.stringify(parsed)) and legacy.pity == {"raro": 0, "epico": 0} and legacy.recipes.is_empty(), "a save without the new fields still loads with zeroed counters")
	parsed["pity"] = {"raro": -3, "epico": 1}
	check(not GameProgress.new().load_text(JSON.stringify(parsed)), "invalid pity values are rejected")
	parsed["pity"] = {"raro": 1, "epico": 1}
	parsed["recipes"] = ["set:9:espada"]
	check(not GameProgress.new().load_text(JSON.stringify(parsed)), "unknown recipe ids are rejected")
	# Painel do Ferreiro.
	var save_path := "user://loot_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.progress.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	var hud: GameHUD = main.hud
	hud.smith_tab = 0
	hud.show_station("Ferreiro",main.progress)
	for _i in range(4): await process_frame
	var text := _all_text(hud.station_panel)
	check(text.contains("RECEITAS DO ANDAR") and text.contains("Receita bloqueada") and text.contains("Usar Fragmento"), "the blacksmith lists the floor-set recipes, locked, with the Fragmento action")
	main.progress.floor_states["1"].guardian_defeated = true
	hud.refresh_station(main.progress)
	for _i in range(4): await process_frame
	text = _all_text(hud.station_panel)
	check(text.contains("Receita desbloqueada") and text.contains("Forjar Espada da Mata"), "the recipe opens after the floor's Guardian is defeated")
	hud.smith_set_category = "elmo_mata"
	hud.refresh_station(main.progress)
	for _i in range(4): await process_frame
	text = _all_text(hud.station_panel)
	check(text.contains("Forjar Elmo da Mata") and text.contains("Capacete") == false or text.contains("Forjar Elmo da Mata"), "the recipe list also offers the floor-set pieces")
	hud.smith_set_floor = 2
	hud.refresh_station(main.progress)
	for _i in range(4): await process_frame
	check(hud.smith_set_category == "espada" and _all_text(hud.station_panel).contains("Elmo do Vale"), "switching floors lists that floor's pieces")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print("LOOT_RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func _all_text(node: Node) -> String:
	var result := ""
	if node is Label: result += (node as Label).text + "\n"
	if node is Button: result += (node as Button).text + "\n"
	for child in node.get_children(): result += _all_text(child)
	return result
