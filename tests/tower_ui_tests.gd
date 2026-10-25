extends SceneTree

# Torre Ancestral visual: estados reais por andar, seleção, viagem e encaixe em tela.
# Rode em janela: godot --path . --resolution 360x800 -s res://tests/tower_ui_tests.gd
var checks := 0
var failures := 0

func _initialize() -> void:
	create_timer(60.0).timeout.connect(func(): push_error("TOWER_UI_FAIL: timeout"); quit(1))
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("TOWER_UI_FAIL: " + message)
	else:
		print("TOWER_UI_PASS: " + message)

func frames(count := 4) -> void:
	for _i in range(count): await process_frame

func tap(hud: GameHUD, button: Button) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 93
	event.position = button.get_global_rect().get_center()
	event.pressed = true
	hud._input(event)
	event.pressed = false
	hud._input(event)

func resize(main: Node, size: Vector2i) -> void:
	root.size = size
	root.content_scale_size = size
	main.hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	main.hud.size = Vector2(size)
	main.hud._layout()

func _run() -> void:
	var save_path := "user://tower_ui_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"): actor.set_physics_process(false)
	main.progress.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	var ascension: AscensionProgress = main.progress.ascension
	# Andar 1 concluído, Andar 2 atual e concluído, e as regras já liberando o Andar 3,
	# que ainda não existe no jogo.
	ascension.defeats["1"] = 50
	ascension.completed_trials["1"] = true
	ascension.defeats["2"] = 50
	ascension.completed_trials["2"] = true
	ascension.forest_seal = true
	ascension.unlocked_floors = [1,2,3] as Array[int]
	ascension.current_floor = 2
	var hud: GameHUD = main.hud
	for size in [Vector2i(360,800),Vector2i(640,360)]:
		var label := str(size)
		resize(main, size)
		hud.show_station(TowerEntrance.NAME, main.progress)
		var first_size := hud.station_panel.size
		await frames()
		check(first_size.y <= float(size.y) and Rect2(Vector2.ZERO, Vector2(size)).encloses(hud.station_panel.get_global_rect()), "tower panel never grows past the screen, even on the first frame " + label)
		check(hud.floor_buttons.size() == 10, "tower shows ten floor medallions " + label)
		var states: Dictionary = {}
		for node: Button in hud.floor_buttons: states[(node as TowerArtView.Medallion).floor_id] = (node as TowerArtView.Medallion).state
		check(states[1] == "completed" and states[2] == "current", "completed and current floors come from AscensionProgress " + label)
		var no_content := true
		for id in range(3, 11): no_content = no_content and states[id] == "unavailable"
		check(no_content and main.progress.ascension.can_travel(3), "floors without content stay unavailable even when the rules unlock them " + label)
		check(station_panel_contains(hud, hud.tower_action_button) and station_panel_contains(hud, hud.station_close_button) and hud.station_close_button.size.y >= 44, "tower buttons and the 44 px close stay inside the panel " + label)
		# Seleção por toque.
		hud.station_scroll.ensure_control_visible(hud.floor_buttons[0])
		await frames(2)
		tap(hud, hud.floor_buttons[0])
		await frames()
		check(hud.selected_floor == 1 and not hud.travel_button.disabled and hud.travel_button.text == "Viajar ao Andar 1", "touch selects Andar 1 and offers real travel " + label)
		hud.station_scroll.ensure_control_visible(hud.floor_buttons[2])
		await frames(2)
		tap(hud, hud.floor_buttons[2])
		await frames()
		check(hud.selected_floor == 3 and hud.travel_button.disabled, "an unavailable floor can be read but never traveled to " + label)
		var card_text := all_text(hud.station_panel)
		check(card_text.contains("Ainda não existe no jogo") and not card_text.contains("Criaturas derrotadas: 0/"), "unavailable floor shows no invented numbers " + label)
		hud.station_scroll.ensure_control_visible(hud.floor_buttons[1])
		await frames(2)
		tap(hud, hud.floor_buttons[1])
		await frames()
		check(hud.selected_floor == 2 and hud.travel_button.disabled and all_text(hud.station_panel).contains("Criaturas derrotadas: 50/50"), "current floor shows its real progress " + label)
		hud.close_station()
		await frames()
	# Viajar a um andar sem conteúdo é ignorado pela ação do HUD.
	resize(main, Vector2i(360,800))
	main.player.position = TowerEntrance.position_for_floor(2) + Vector2(0,35)
	hud.show_station(TowerEntrance.NAME, main.progress)
	await frames()
	main._station_action("Viajar", "3")
	await frames(8)
	check(main.progress.ascension.current_floor == 2 and not main.transitioning, "travel action ignores a floor that does not exist yet")
	hud.close_station()
	# Outras estações recuperam os botões padrão.
	hud.show_station("Vendedor", main.progress)
	await frames()
	check(hud.station_close_button.icon == null and hud.station_close_button.text == "Fechar", "other stations get the default close button back")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print("TOWER_UI_RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func station_panel_contains(hud: GameHUD, button: Button) -> bool:
	return hud.station_panel.get_global_rect().encloses(button.get_global_rect())

func all_text(node: Node) -> String:
	var result := ""
	if node is Label: result += (node as Label).text + "\n"
	for child in node.get_children(): result += all_text(child)
	return result
