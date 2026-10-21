extends SceneTree

var failures := 0

func _initialize() -> void:
	create_timer(30.0).timeout.connect(func(): quit(1))
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok:
		print("CAMP_TOWER OK: " + label)
	else:
		failures += 1
		push_error("CAMP_TOWER FAIL: " + label)

func _clearance(main: Node2D, center: Vector2, floor_id: int) -> void:
	var player: PlayerActor = main.player
	await physics_frame
	check(not player.test_move(Transform2D(0, center + Vector2(0, 24)), Vector2(0, -48)), "andar %d: porta central livre" % floor_id)
	for side in [-1.0, 1.0]:
		check(player.test_move(Transform2D(0, center + Vector2(side * 43, 24)), Vector2(0, -48)), "andar %d: parede lateral bloqueia" % floor_id)
	check(not player.test_move(Transform2D(0, center + Vector2(0, 24)), Vector2(48, 0)), "andar %d: frente da torre sem obstáculo invisível" % floor_id)
	player.position = center + Vector2(0, 24)
	check(main._interaction_target().get("kind", "") == "tower", "andar %d: torre interativa pela entrada" % floor_id)
	main._interact()
	check(main.hud.station_panel.visible and main.hud.tower_action_button.visible, "andar %d: botão da torre disponível" % floor_id)
	main.hud.station_panel.hide()
	main.input_driver.blocked = false

func _run() -> void:
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH", "user://qa_camp_tower_%d.json" % Time.get_ticks_usec())
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.enemy.set_physics_process(false)
	await process_frame
	var view: FloorView = main.world.get_node("FloorView")
	check(view.visual_v2, "visual novo do Andar 1 ativo na inicialização")
	for station in ["Ferreiro", "Vendedor"]:
		var npc: CampNpcView
		for child in view.get_children():
			if child is CampNpcView and child.kind == (0 if station == "Ferreiro" else 1): npc = child
		check(npc != null, station + " presente")
		if npc == null: continue
		var feet: Vector2 = SafeCamp.DISPLAY_STATIONS[station]
		check(npc.z_index == roundi(feet.y) + 100 and not npc.z_as_relative, station + " desenhado pelos pés")
		check(npc.z_index > (508 if station == "Ferreiro" else 696), station + " à frente do objeto correspondente")
		var position_before := npc.position
		var z_before := npc.z_index
		npc._process(4.0 if station == "Ferreiro" else 2.3)
		check(npc.position == position_before and npc.z_index == z_before and npc.action_frame > 0, station + " permanece visível ao animar")
		main.player.position = feet + Vector2(24, 0)
		check(not main.player.test_move(main.player.transform, Vector2(1, 0)) and main._interaction_target().get("id", "") == station, station + " acessível e interativo")
		main._interact()
		check(main.hud.station_panel.visible, station + " abre interface")
		main.hud.station_panel.hide()
		main.input_driver.blocked = false
	await _clearance(main, TowerEntrance.POSITION, 1)
	main.progress.ascension.defeats["1"] = 50
	main.progress.ascension.complete_forest_trial()
	await main._travel_floor(2)
	main.set_process(false)
	main.player.set_physics_process(false)
	await _clearance(main, Floor2Layout.TOWER_POSITION, 2)
	print("CAMP_TOWER RESULT: %d failures" % failures)
	quit(0 if failures == 0 else 1)
