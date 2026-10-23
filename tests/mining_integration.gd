extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if value: print("MINING OK: " + label)
	else:
		failures += 1
		push_error("MINING FAIL: " + label)

func _run() -> void:
	var config := MiningRules.definition(2, "vale_ferro_1")
	check(MiningRules.deposits(2).size() == 4 and Floor2Layout.DEPOSITS.size() == 4, "quatro depósitos configurados sobre a arte existente")
	for index in range(4):
		check(MiningRules.deposits(2)[index].position == Floor2Layout.DEPOSITS[index], "depósito %d coincide com o sprite aprovado" % (index + 1))
	check(config.chance == 0.75 and config.rarities.comum == 0.9 and config.rarities.raro == 0.1 and config.uses == 3 and config.respawn_seconds == 300, "probabilidades e recarga provisórias")
	check(EquipmentEconomy.roll_entry(config, 0.75, 0.0).is_empty(), "primeiro sorteio pode não fornecer material")
	check(EquipmentEconomy.roll_entry(config, 0.1, 0.89).rarity == "comum" and EquipmentEconomy.roll_entry(config, 0.1, 0.91).rarity == "raro", "segundo sorteio condicional separa comum e raro")
	var rng := RandomNumberGenerator.new()
	var probe := RandomNumberGenerator.new()
	rng.seed = 124
	probe.seed = 124
	var first := probe.randf()
	var roll := MiningRules.roll(config, rng)
	if first >= config.chance:
		check(roll.is_empty() and rng.randf() == probe.randf(), "falha no primeiro sorteio não consome o segundo")
	else:
		var second := probe.randf()
		check(roll == EquipmentEconomy.roll_entry(config, first, second) and rng.randf() == probe.randf(), "sorteios independentes usam a regra de drops existente")
	var save_path := "user://qa_mining_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for enemy in get_nodes_in_group("damageable_enemies"): enemy.set_physics_process(false)
	main.progress.ascension.defeats["1"] = 50
	main.progress.ascension.complete_forest_trial()
	await main._travel_floor(2)
	main.set_process(false)
	main.player.set_physics_process(false)
	for enemy in get_nodes_in_group("damageable_enemies"): enemy.set_physics_process(false)
	var now := int(Time.get_unix_time_from_system())
	for deposit: Dictionary in MiningRules.deposits(2):
		# The fourth deposit shares an interaction radius with the quarry cache;
		# approach from the east so the mineral remains the nearest object.
		main.player.position = deposit.position + (Vector2(40, 0) if deposit.id == "vale_ferro_4" else Vector2(0, 53))
		check(main._interaction_target().get("kind", "") == "mining" and main._interaction_target().get("id", "") == deposit.id, "interação real do depósito " + deposit.id)
		main.hud.set_nearby_station("Minerar")
		check(main.hud.interact_button.visible and main.hud.interact_button.enabled, "botão mobile habilitado perto do depósito " + deposit.id)
		var original := int(main.progress.mining_snapshot(2, deposit.id, now).remaining)
		main.hud.interact_pressed.emit()
		main.hud.interact_pressed.emit()
		check(main.mining_active and main.input_driver.blocked and main.progress.mining_snapshot(2, deposit.id, now).remaining == original, "animação bloqueia toques duplicados " + deposit.id)
		await create_timer(MiningRules.DURATION + 0.12).timeout
		check(not main.mining_active and main.progress.mining_snapshot(2, deposit.id, now).remaining == original - 1, "uma tentativa concluída consome uma carga " + deposit.id)
	check(MiningRules.near(2, Vector2(1000,1000)).is_empty(), "fora do alcance não oferece Minerar")
	main.player.position = Vector2(1000,1000)
	check(main._interaction_target().get("kind", "") != "mining", "botão de mineração some longe da pedreira")
	main.player.position = MiningRules.deposits(2)[2].position + Vector2(0,53)
	main.transitioning = true
	main._interact()
	check(not main.mining_active and main.progress.mining_snapshot(2, MiningRules.deposits(2)[2].id, now).remaining == 2, "transição bloqueia novas extrações")
	main.transitioning = false
	var first_id: String = MiningRules.deposits(2)[0].id
	var second_id: String = MiningRules.deposits(2)[1].id
	main.progress.mine_deposit(2, first_id, now, rng)
	main.progress.mine_deposit(2, first_id, now, rng)
	check(main.progress.mining_snapshot(2, first_id, now).remaining == 0 and main.progress.mining_snapshot(2, second_id, now).remaining == 2, "depósitos esgotam de forma independente")
	main.player.position = MiningRules.definition(2, first_id).position + Vector2(0,53)
	check(main._interaction_target().get("kind", "") == "mining_exhausted" and main.progress.mine_deposit(2, first_id, now, rng).is_empty(), "depósito esgotado não gera minério")
	check(main.progress.mining_snapshot(2, first_id, now + 299).remaining == 0 and main.progress.mining_snapshot(2, first_id, now + 300).remaining == 3, "reaparece após cinco minutos")
	main.progress.mine_deposit(2, first_id, now, rng)
	main.progress.mine_deposit(2, first_id, now, rng)
	main.progress.mine_deposit(2, first_id, now, rng)
	main.progress.add_item(EquipmentEconomy.key("Minério de Ferro", "comum"), 4)
	main.progress.add_item(EquipmentEconomy.key("Minério de Ferro", "raro"), 3)
	check(main.progress.bag["Minério de Ferro"] >= 4 and main.progress.bag["Minério de Ferro|raro"] >= 3, "pilhas de comum e raro são separadas")
	check(main.progress.transfer("Minério de Ferro|raro", true) and main.progress.chest["Minério de Ferro|raro"] == 1 and main.progress.transfer("Minério de Ferro|raro", false), "baú transfere raridade sem misturar pilhas")
	main.progress.gold = 1000
	main.progress.add_item("Madeira", 2)
	var common_before := int(main.progress.bag["Minério de Ferro"])
	var rare_before := int(main.progress.bag["Minério de Ferro|raro"])
	var common_uid: String = main.progress.craft_vale_iron("comum")
	var rare_uid: String = main.progress.craft_vale_iron("raro")
	check(not common_uid.is_empty() and not rare_uid.is_empty() and main.progress.weapon(common_uid).rarity == "comum" and main.progress.weapon(rare_uid).rarity == "raro", "Ferreiro fabrica duas raridades com minério")
	check(int(main.progress.bag["Minério de Ferro"]) == common_before - 2 and int(main.progress.bag["Minério de Ferro|raro"]) == rare_before - 2, "receitas consomem a pilha correta")
	main.earned_gold = main.progress.gold
	main._save_progress()
	await main._travel_floor(1)
	check(main.progress.mining_snapshot(2, first_id, now).remaining == 0 and main.world.scene_file_path == FloorConfig.WORLD_SCENE, "sair do Vale mantém esgotamento e Andar 1")
	await main._travel_floor(2)
	check(main.progress.mining_snapshot(2, first_id, now).remaining == 0, "retorno ao Vale preserva depósito")
	var disk_before := FileAccess.get_file_as_string(save_path)
	main._start_training()
	check(main.progress.training_mode and main.progress.ascension.current_floor == 2 and main.world is Andar2World, "treino mantém cenário e andar do Vale")
	main.player.position = MiningRules.deposits(2)[0].position + Vector2(0,53)
	main._process(0.016)
	check(main.hud.interact_button.enabled and main.hud.interact_button.visible, "treino mostra botão Minerar no Vale")
	main.progress.floor_states["2"].mining[first_id] = {"remaining":0,"ready_at":now+300}
	main._rpg_action("training_mining_reset", "", 0)
	main._rpg_action("training_mining_common", "", 0)
	main._rpg_action("training_mining_rare", "", 0)
	check(main.progress.mining_snapshot(2, first_id, now).remaining == 3 and main.progress.bag["Minério de Ferro"] >= 5 and main.progress.bag["Minério de Ferro|raro"] >= 5, "ações de treino restauram e fornecem os dois minérios")
	check(FileAccess.get_file_as_string(save_path) == disk_before, "ações de treino não alteram o save real")
	main.queue_free()
	await process_frame
	var restored := GameProgress.new()
	restored.save_path = save_path
	check(restored.load_save() and restored.floor_states["2"].mining[first_id].remaining == 0 and int(restored.bag.get("Minério de Ferro",0)) > 0, "save recarrega estado e pilhas de minério")
	var training := TrainingMode.create(2)
	training.reset_mining_for_training(2)
	training.add_item("Minério de Ferro|raro", 5)
	check(training.training_mode and training.ascension.current_floor == 2 and training.bag["Minério de Ferro|raro"] >= 5 and not training.floor_states["2"].mining.has(first_id), "treino de mineração é descartável")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("ARVEON_SAVE_PATH")
	print("MINING RESULT: %d failures" % failures)
	quit(1 if failures else 0)
