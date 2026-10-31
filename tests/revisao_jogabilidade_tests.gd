extends SceneTree

# Revisão de jogabilidade (31/10/2026): recuperação de vida na área segura, barra de HP dos
# chefes de campo na HUD e missão comum de coleta no andar sem materiais (Pântano).
# Uso: godot --path . --resolution 360x800 -s res://tests/revisao_jogabilidade_tests.gd
# Com QA_RENDER_DIR=<pasta> salva capturas reais 360x800 (precisa de janela).
var failures := 0
var checks := 0
var out := ""
var main: Node2D

func _initialize() -> void:
	create_timer(240.0).timeout.connect(func():
		push_error("REVISAO FALHA: tempo limite do teste")
		quit(1))
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("REVISAO OK: " + label)
	else:
		failures += 1
		push_error("REVISAO FALHA: " + label)

func _frames(count: int) -> void:
	for _i in range(count): await process_frame

func _shot(name: String) -> void:
	if out.is_empty(): return
	await _frames(4)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.get_size() == Vector2i(360, 800), "captura real 360x800: " + name)
	image.save_png(out.path_join("revisao-%s.png" % name))

func _place_player(at: Vector2) -> void:
	main.player.global_position = at
	main.player.velocity = Vector2.ZERO
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.reset_smoothing()
	camera.force_update_scroll()

func _clear_enemies() -> void:
	for actor in get_nodes_in_group("damageable_enemies"):
		if actor is EnemyActor and actor != main.enemy: actor.queue_free()

func _run() -> void:
	out = OS.get_environment("QA_RENDER_DIR")
	if not out.is_empty(): DirAccess.make_dir_recursive_absolute(out)
	_mission_unit()
	_high_rarity_enhancement()
	_floor_reward_curve()
	OS.set_environment("ARVEON_SAVE_PATH", "user://qa_revisao_jogabilidade_%d.json" % Time.get_ticks_usec())
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	root.size = Vector2i(360, 800)
	root.content_scale_size = Vector2i(360, 800)
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	main.player.set_physics_process(false)
	_clear_enemies()
	await _frames(2)
	_camp_regeneration()
	await _field_boss_bar_floor1()
	main.progress.ascension.defeats["1"] = 50
	main.progress.ascension.complete_forest_trial()
	await main._travel_floor(2)
	main.progress.ascension.defeats["2"] = 50
	main.progress.ascension.complete_forest_trial()
	await main._travel_floor(3)
	main.set_process(false)
	main.player.set_physics_process(false)
	_clear_enemies()
	await _frames(2)
	await _floor3_mission()
	_pantano_loot()
	await _vendor_ui()
	await _floor3_bosses()
	print("REVISAO_RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)

func _mission_unit() -> void:
	var mission := CommonMission.new()
	mission.mission_index = 1
	mission.record_defeat()
	_check(mission.progress == 0, "com materiais no andar, derrotas não contam para a coleta")
	mission.materials_available = false
	_check(mission.summary().contains("Derrote criaturas 0/5"), "sem materiais, a coleta vira derrotas com o mesmo alvo")
	var rewards: Array = []
	mission.completed.connect(func(xp: int, gold: int): rewards.append([xp, gold]))
	for _i in range(5): mission.record_defeat()
	_check(rewards == [[30, 10]] and mission.mission_index == 0 and mission.progress == 0, "substituta paga a recompensa da coleta e segue o ciclo")
	mission.record_defeat()
	_check(mission.progress == 1, "missão de derrotas continua igual")

# XP por ponto de vida dos inimigos que o andar realmente gera (Mata: ciclo javali/aranha/
# mandacaru com 1 elite a cada 8; Vale: spawns fixos do catálogo).
func _xp_per_hp(floor_id: int) -> float:
	var kinds: Array = FloorCatalog.enemy_spawn_kinds(floor_id).duplicate()
	if kinds.is_empty():
		for count in range(8): kinds.append(3 if count % 8 == 7 else (count + 1) % 3)
	var xp := 0
	var hp := 0
	for kind: int in kinds:
		var scaled := FloorCatalog.scaled(FloorCatalog.monster_id_for_kind(kind), floor_id)
		xp += FloorCatalog.reward(FloorCatalog.xp_for_kind(kind), floor_id)
		hp += int(scaled.hp)
	return float(xp) / float(hp)

func _floor_reward_curve() -> void:
	var mata := _xp_per_hp(1)
	var vale := _xp_per_hp(2)
	_check(is_equal_approx(float(FloorCatalog.SCALE["2"].rewards), 2.0) and is_equal_approx(FloorCatalog.difficulty(2), 1.5), "Vale: recompensa 2,0 e dificuldade preservada 1,5")
	_check(vale > mata, "Vale rende mais XP por HP que a Mata (%.3f > %.3f)" % [vale, mata])
	_check(FloorCatalog.reward(40, 1) == 40 and FloorCatalog.reward(12, 1) == 12, "missão da Mata paga o mesmo de antes")
	var pantano := _xp_per_hp(3)
	_check(is_equal_approx(float(FloorCatalog.SCALE["3"].rewards), 2.6) and is_equal_approx(FloorCatalog.reward_multiplier(3), 2.6 * 1.8) and is_equal_approx(FloorCatalog.enemy_multiplier(3), 2.1 * 1.8), "Pântano: recompensa 2,6 × 1,8 = 4,68 e poder dos monstros preservado (2,1 × 1,8)")
	var growing := true
	for id in range(2, 11): growing = growing and float(FloorCatalog.SCALE[str(id)].rewards) > float(FloorCatalog.SCALE[str(id - 1)].rewards)
	_check(growing and is_equal_approx(FloorCatalog.reward_multiplier(4), 3.5), "escala planejada dos andares continua crescente")
	_check(pantano > vale, "Pântano rende mais XP por HP que o Vale (%.3f > %.3f)" % [pantano, vale])
	print("REVISAO info: XP/HP Mata %.3f · Vale %.3f · Pântano %.3f" % [mata, vale, pantano])

func _high_rarity_enhancement() -> void:
	var totals := {}
	for rarity: String in ["epico", "lendario", "mitico"]:
		var total := 0
		var keys := {}
		for level in range(20):
			var recipe := EquipmentEconomy.enhance_recipe(level, rarity)
			for item: String in recipe.materials:
				keys[item] = true
				total += int(recipe.materials[item])
		totals[rarity] = total
		_check(keys.keys() == ["Essência|epico"], "aprimorar %s usa só Essência Épica" % rarity)
	_check(totals == {"epico": 50, "lendario": 80, "mitico": 100}, "Essência Épica de +0 a +20: Épico 50, Lendário 80, Místico 100 (%s)" % str(totals))
	_check(EquipmentEconomy.enhance_recipe(0, "raro").materials == {"Essência|raro": 1} and EquipmentEconomy.enhance_recipe(19, "comum").materials == {"Essência": 4}, "raridades até Épico seguem a receita original")
	_check(EquipmentEconomy.enhance_recipe(7, "mitico").gold == EquipmentEconomy.enhance_recipe(7, "comum").gold + 50, "ouro do aprimoramento não mudou")
	var smith := GameProgress.new()
	smith.gold = 99999
	smith.add_item("Madeira", 9)
	smith.add_item("Couro|mitico", 7)
	smith.add_item("Essência|mitico", 6)
	var uid := smith.craft_weapon("espada", "mitico")
	smith.add_item("Essência|epico", 2)
	_check(uid != "" and smith.can_enhance_weapon(uid), "arma Mística pode ser aprimorada com Essência Épica")
	var result := smith.enhance_weapon(uid, false, 0.0)
	_check(result.get("success", false) and smith.weapon(uid).level == 1 and not smith.bag.has("Essência|epico"), "+0 → +1 Místico gasta 2 Essências Épicas")

func _camp_regeneration() -> void:
	var player: PlayerActor = main.player
	_place_player(SafeCamp.respawn_for_floor(1))
	var maximum := player.health.maximum
	player.health.current = maxi(1, maximum / 4)
	var start := player.health.current
	main._regenerate_in_camp(1.0)
	var gained := player.health.current - start
	_check(gained == floori(maximum * main.CAMP_REGEN_PER_SECOND), "acampamento recupera %d HP em 1 s (12%% de %d)" % [gained, maximum])
	for _i in range(60): main._regenerate_in_camp(1.0 / 60.0)
	_check(player.health.current - start - gained >= floori(maximum * main.CAMP_REGEN_PER_SECOND) - 1, "passos de quadro acumulam a fração sem perder cura")
	for _i in range(20): main._regenerate_in_camp(1.0)
	_check(player.health.current == maximum, "recuperação para no HP máximo")
	main.input_driver.blocked = true
	player.health.current = start
	main._regenerate_in_camp(1.0)
	_check(player.health.current == start, "menu aberto pausa a recuperação")
	main.input_driver.blocked = false
	_place_player(Vector2(1300, 300))
	_check(not SafeCamp.in_clearance(main.player.global_position), "ponto de teste fora da área segura")
	main._regenerate_in_camp(5.0)
	_check(player.health.current == start, "fora da área segura não há recuperação")
	player.health.initialize(maximum)

func _field_boss_bar_floor1() -> void:
	main._update_field_boss_bar()
	_check(not main.hud.boss_name.visible and main.hud.mission_label.visible, "sem chefe por perto a HUD mostra a missão")
	main.progress.floor_states["1"].guardian_defeated = false
	main._start_guardian()
	var boss: EnemyActor = main.guardian
	_check(is_instance_valid(boss), "Guardião da Mata desafiado no campo")
	if not is_instance_valid(boss): return
	boss.set_physics_process(false)
	_place_player(boss.global_position + Vector2(0, 200))
	main._update_field_boss_bar()
	_check(main.hud.boss_name.visible and main.hud.boss_bar.visible and not main.hud.mission_label.visible, "chefe engajado ocupa o painel da missão")
	_check(main.hud.boss_name.text.contains("Guardião da Mata · Fase 1") and main.hud.boss_name.text.contains("HP %d/%d" % [boss.health.current, boss.health.maximum]), "barra mostra nome, fase e HP do chefe de campo")
	_check(main.hud.boss_bar.max_value == boss.health.maximum and main.hud.boss_bar.value == boss.health.current, "barra usa a vida real do chefe")
	_check(not main.hud.mission_toggle.visible, "botão de missão continua oculto")
	_check(not (main.hud.mission_back as MissionBanner).show_compass, "bússola da missão sai de baixo do texto do chefe")
	_place_player(boss.global_position + Vector2(0, 600))
	main._update_field_boss_bar()
	_check(not main.hud.boss_name.visible and main.hud.mission_label.visible and (main.hud.mission_back as MissionBanner).show_compass, "longe do chefe a missão volta, com a bússola")
	boss.queue_free()
	main.guardian = null
	await _frames(2)
	main._update_field_boss_bar()
	_check(not main.hud.boss_name.visible, "chefe removido não deixa barra presa")

func _floor3_mission() -> void:
	main._refresh_mission()
	_check(main.progress.ascension.current_floor == 3 and main.mission.materials_available, "Pântano com drops próprios mantém a missão de coleta")
	main.mission.mission_index = 1
	main.mission.progress = 0
	main.mission.record_defeat()
	_check(main.mission.progress == 0, "com drops, derrota sozinha não conta como coleta")
	# Drop real de um Vulto: avança a coleta pelo caminho normal de recompensa.
	var gained := 0
	for _attempt in range(40):
		var vulto := _spawn(10, main.player.global_position + Vector2(90, 0))
		vulto.health.damage(vulto.health.maximum)
		await _frames(1)
		gained = main.mission.progress
		if gained > 0: break
	_check(gained > 0, "materiais caídos no Pântano avançam a missão de coleta (%d)" % gained)
	main._refresh_mission()
	_check(main.hud.mission_label.text.contains("Colete materiais"), "HUD mostra a missão de coleta (%s)" % main.hud.mission_label.text.replace("\n", " | "))
	var xp_before: int = main.earned_xp
	var gold_before: int = main.earned_gold
	main._on_mission_completed(30, 10)
	_check(main.earned_xp - xp_before == 140 and main.earned_gold - gold_before == 47 and main.mission_reward_message.contains("+140 XP, +47 ouro"), "missão no Pântano paga ×4,68 (30/10 → 140/47)")
	main.mission_reward_message = ""

func _vendor_ui() -> void:
	main.hud.show_station("Vendedor", main.progress)
	main.hud.vendor_tab = 1
	main.hud.refresh_station(main.progress)
	await _frames(2)
	var keys: Array = main.hud.vendor_buttons.keys()
	var high := keys.filter(func(key: String) -> bool: return key.begins_with("Comprar:") and EquipmentEconomy.split_key(key.trim_prefix("Comprar:")).rarity not in ["comum", "incomum"])
	_check(keys.has("Comprar:Couro") and keys.has("Comprar:Essência|incomum") and keys.has("Comprar:" + EquipmentEconomy.SEAL), "aba Comprar lista Comum, Incomum e Selo")
	_check(high.is_empty(), "aba Comprar não lista Raro ou melhor (%s)" % str(high))
	await _shot("vendedor-comprar")
	main.hud.close_station()
	await _frames(1)

func _spawn(kind: int, at: Vector2) -> EnemyActor:
	var actor: EnemyActor = main._make_enemy(kind)
	actor.position = at
	actor.target = main.player
	main._register_enemy_defeat(actor)
	main.add_child(actor)
	actor.set_physics_process(false)
	return actor

func _pantano_loot() -> void:
	# Tabela: comuns do Pântano dão materiais base; o Jacaré é pool alto e a fonte de Lendário.
	for kind: int in [8, 9, 10, 11]:
		_check(EquipmentEconomy.DROP_TABLE.has(kind), "tipo %d tem material no Pântano" % kind)
	_check(EquipmentEconomy.valid_drop_table(), "pesos de raridade do Pântano somam 100%")
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var counts := {}
	var legendary := 0
	var caiman_ok := true
	for _i in range(2000):
		var pity := LootRules.new_pity()
		var drops := LootRules.roll(11, rng, pity)
		caiman_ok = caiman_ok and drops.size() == 2
		for drop: Dictionary in drops:
			counts[drop.rarity] = int(counts.get(drop.rarity, 0)) + 1
			if drop.rarity == "lendario": legendary += 1
	_check(caiman_ok and not counts.has("comum"), "Jacaré sempre dá Couro e Essência, de Incomum a Místico (%s)" % str(counts))
	_check(legendary > 80 and legendary < 250, "Jacaré: ~4%% de Lendário por material (%d em 4000)" % legendary)
	var mythic := int(counts.get("mitico", 0))
	_check(mythic >= 15 and mythic <= 75, "Jacaré: ~1%% de Místico por material (%d em 4000)" % mythic)
	var mythic_sources := 0
	for kind: int in EquipmentEconomy.DROP_TABLE:
		for entry: Dictionary in EquipmentEconomy.DROP_TABLE[kind]:
			if entry.rarities.has("mitico"): mythic_sources += 1
	_check(mythic_sources == 2 and EquipmentEconomy.DROP_TABLE[11].all(func(entry: Dictionary) -> bool: return entry.rarities.has("mitico")), "Místico só cai do Jacaré")
	var epic_pity := {"raro": 0, "epico": 60}
	var forced := LootRules.roll(11, rng, epic_pity)
	_check(EquipmentEconomy.RARITY_ORDER.find(forced[0].rarity) >= 3, "Jacaré é pool alto: a garantia de Épico vale nele")
	var common_legendary := 0
	for _i in range(3000):
		for drop: Dictionary in LootRules.roll(10, rng, LootRules.new_pity()):
			if EquipmentEconomy.RARITY_ORDER.find(drop.rarity) >= 3: common_legendary += 1
	_check(common_legendary == 0, "Vulto comum nunca dá Épico ou Lendário sem pity")
	var boss_legendary := 0
	var mata_legendary := 0
	for _i in range(400):
		for drop: Dictionary in LootRules.field_boss(3, rng, LootRules.new_pity()):
			if drop.get("rarity", "") == "lendario": boss_legendary += 1
		for drop: Dictionary in LootRules.field_boss(1, rng, LootRules.new_pity()):
			if drop.get("rarity", "") == "lendario": mata_legendary += 1
	_check(boss_legendary > 0 and mata_legendary == 0, "Mãe dos Sussurros pode dar Lendário; Guardiões dos Andares 1–2 não (%d)" % boss_legendary)
	# Vendedor.
	var shop := GameProgress.new()
	shop.gold = 9999
	_check(shop.buy("Couro") and shop.buy("Essência|incomum") and shop.buy(EquipmentEconomy.SEAL), "Vendedor vende Comum, Incomum e Selo")
	var gold := shop.gold
	_check(not shop.buy("Couro|raro") and not shop.buy("Seda|epico") and not shop.buy("Essência|lendario") and not shop.buy("Couro|mitico") and shop.gold == gold, "Vendedor recusa Raro ou melhor sem cobrar")
	shop.add_item("Essência|lendario", 2)
	_check(shop.sell("Essência|lendario") and shop.gold == gold + GameProgress.sell_price("Essência|lendario"), "materiais altos já guardados continuam vendáveis")
	var saved := GameProgress.new()
	_check(saved.load_text(shop.to_json()) and int(saved.bag.get("Essência|lendario", 0)) == 1, "save com material Lendário continua válido")

func _floor3_bosses() -> void:
	main.progress.floor_states["3"].guardian_defeated = false
	main._start_guardian()
	var mother: EnemyActor = main.guardian
	_check(mother is MotherOfWhispers, "Mãe dos Sussurros desafiada no campo")
	if mother is MotherOfWhispers:
		mother.set_physics_process(false)
		_place_player(mother.global_position + Vector2(0, 230))
		main._update_field_boss_bar()
		_check(main.hud.boss_name.text.begins_with("Mãe dos Sussurros · Fase 1"), "HUD identifica a Mãe dos Sussurros (%s)" % main.hud.boss_name.text.replace("\n", " | "))
		await _shot("mae-barra-hud")
		mother.queue_free()
		main.guardian = null
		await _frames(2)
	var definition := FloorCatalog.mini_boss(3)
	var caiman: EnemyActor = main._make_enemy(int(definition.kind))
	caiman.position = definition.home
	caiman.target = main.player
	main._register_enemy_defeat(caiman)
	main.add_child(caiman)
	caiman.set_physics_process(false)
	main.mini_boss = caiman
	_place_player(caiman.global_position + Vector2(0, 160))
	main._update_field_boss_bar()
	_check(main.hud.boss_name.text.begins_with("Jacaré Ancião\nHP"), "Jacaré Ancião aparece sem fase inventada")
	await _shot("jacare-barra-hud")
	caiman.queue_free()
	main.mini_boss = null
	await _frames(2)
	main._update_field_boss_bar()
	_check(not main.hud.boss_name.visible, "barra some com o Jacaré")
