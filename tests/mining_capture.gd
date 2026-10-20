extends SceneTree

var output := ""

func _initialize() -> void:
	call_deferred("_run")

func _capture(name: String) -> void:
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	if picture.save_png(output.path_join(name + ".png")) != OK:
		push_error("Falha ao salvar mineração: " + name)

func _seed_for(rarity: String) -> int:
	for seed in range(1, 100000):
		var probe := RandomNumberGenerator.new()
		probe.seed = seed
		var result := MiningRules.roll(MiningRules.definition(2,"vale_ferro_1"),probe)
		if not result.is_empty() and result.rarity == rarity: return seed
	return 1

func _place(main: Node2D, at: Vector2) -> void:
	main.player.position = at
	main.player.velocity = Vector2.ZERO
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled = false
	camera.reset_smoothing()
	camera.force_update_scroll()
	main.hud.minimap.update_player(at)
	main.hud.set_nearby_station(main._interaction_target().get("label", ""))

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	if output.is_empty(): quit(1); return
	DirAccess.make_dir_recursive_absolute(output)
	var save_path := "user://qa_mining_capture_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.progress.ascension.defeats["1"] = 50
	main.progress.ascension.complete_forest_trial()
	await main._travel_floor(2)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"):
		actor.hide()
		actor.set_physics_process(false)
	root.size = Vector2i(960,540)
	root.content_scale_size = Vector2i(960,540)
	var first: Dictionary = MiningRules.deposits(2)[0]
	var second: Dictionary = MiningRules.deposits(2)[1]
	_place(main, first.position + Vector2(-65,-30))
	await _capture("01-proximo-deposito")
	main.mining_rng.seed = _seed_for("comum")
	main._interact()
	await create_timer(0.23).timeout
	await _capture("02-animacao-mineracao")
	await create_timer(0.31).timeout
	await _capture("03-minerio-comum")
	_place(main, second.position + Vector2(-61,-35))
	main.mining_rng.seed = _seed_for("raro")
	main._interact()
	await create_timer(0.52).timeout
	await _capture("04-minerio-raro")
	var now := int(Time.get_unix_time_from_system())
	var extra_rng := RandomNumberGenerator.new()
	main.progress.mine_deposit(2, first.id, now, extra_rng)
	main.progress.mine_deposit(2, first.id, now, extra_rng)
	(main.world.get_node("FloorView") as Floor2View).set_mining_state(main.progress, now)
	_place(main, first.position + Vector2(-65,-30))
	main._interact()
	await _capture("05-deposito-esgotado")
	main.progress.add_item("Minério de Ferro", 4)
	main.progress.add_item("Minério de Ferro|raro", 2)
	main._toggle_inventory()
	main.hud.inventory_category = 0
	main.hud.refresh_inventory(main.progress)
	await _capture("06-mochila-minerios")
	main._toggle_inventory()
	_place(main, Floor2Layout.STATIONS["Ferreiro"] + Vector2(0,30))
	main._interact()
	main.progress.gold = 100
	main.progress.add_item("Madeira", 2)
	main.hud.smith_tab = 1
	main.hud.refresh_station(main.progress)
	await process_frame
	main.hud.station_scroll.scroll_vertical = 780
	await _capture("08-ferreiro-ferro")
	main.hud.close_station()
	root.size = Vector2i(390,844)
	root.content_scale_size = Vector2i(390,844)
	main.progress.reset_mining_for_training(2) if main.progress.training_mode else main.progress.floor_states["2"].mining.erase(first.id)
	(main.world.get_node("FloorView") as Floor2View).set_mining_state(main.progress, now)
	_place(main, first.position + Vector2(-65,-30))
	main.hud.notice_left = 0.0
	main.hud.loot_label.hide()
	await _capture("07-celular-vertical")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("GRANDE_ARVORE_SAVE_PATH")
	print("MINING_CAPTURE: oito capturas reais em " + output)
	quit()
