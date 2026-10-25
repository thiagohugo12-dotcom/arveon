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
	check(items_ok and LootRules.named_items().size() == 9, "every named item is a valid bag item (6 materials, 2 trophies, 1 fragment)")
	var recipes_ok := true
	for floor_id: int in FloorCatalog.LOOT.sets:
		for category: String in ArsenalRules.CATEGORIES:
			var recipe := LootRules.set_recipe(floor_id,category)
			recipes_ok = recipes_ok and not recipe.is_empty() and recipe.materials.size() == 3 and LootRules.valid_recipe_id(LootRules.recipe_id(floor_id,category))
	check(recipes_ok and LootRules.set_recipe(1,"espada").rarity == "raro" and LootRules.set_recipe(2,"espada").rarity == "epico" and LootRules.set_recipe(3,"espada").is_empty(), "every floor-set recipe is complete; floor 1 gives Raro and floor 2 gives Épico")
	var spada := LootRules.set_recipe(1,"espada")
	check(spada.gold == 120 and spada.materials["Presa de Javali"] == 6 and spada.materials["Couro|incomum"] == 3 and spada.materials["Coração da Mata"] == 1, "Espada da Mata costs 6 Presa de Javali, 3 Couro Incomum, 1 Coração da Mata and 120 gold")
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
	check(uid != "" and p.weapon(uid).rarity == "raro" and p.weapon(uid).category == "espada" and p.gold == gold_before - 120 and not p.bag.has("Presa de Javali") and not p.bag.has("Coração da Mata"), "crafting pays the materials and gold and creates a Raro sword")
	check(not p.can_use_fragment(2,"espada") and not p.use_fragment(2,"espada"), "a Fragmento is required to unlock a locked recipe")
	p.add_item("Fragmento de Receita")
	check(p.can_use_fragment(2,"espada") and p.use_fragment(2,"espada") and p.recipe_unlocked(2,"espada") and not p.recipe_unlocked(2,"arco") and p.fragments() == 0, "one Fragmento unlocks exactly one recipe and is consumed")
	check(not p.can_use_fragment(1,"espada"), "a recipe that is already open does not waste a Fragmento")
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
