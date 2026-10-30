extends SceneTree

var failures := 0
var checks := 0
var output_dir := ""
var save_path := ""

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("ANDAR3 OK: " + label)
	else:
		failures += 1
		push_error("ANDAR3 FALHA: " + label)

func _walkable_cells(main: Node2D) -> Dictionary:
	const STEP := 20
	var query := PhysicsShapeQueryParameters2D.new()
	var body := CircleShape2D.new()
	body.radius = 13.0
	query.shape = body
	query.collision_mask = 1
	var space: PhysicsDirectSpaceState2D = main.player.get_world_2d().direct_space_state
	var start := Vector2i(roundi(Floor3Layout.RESPAWN.x / STEP), roundi(Floor3Layout.RESPAWN.y / STEP))
	var open: Array[Vector2i] = [start]
	var visited := {start: true}
	var cursor := 0
	while cursor < open.size():
		var cell: Vector2i = open[cursor]
		cursor += 1
		for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := cell + direction
			if next.x <= 1 or next.y <= 1 or next.x >= 108 or next.y >= 81 or visited.has(next):
				continue
			query.transform = Transform2D(0.0, Vector2(next.x * STEP, next.y * STEP))
			if not space.intersect_shape(query, 1).is_empty():
				continue
			visited[next] = true
			open.append(next)
	return visited

func _reachable(cells: Dictionary, point: Vector2) -> bool:
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			if cells.has(Vector2i(roundi(point.x / 20.0) + dx, roundi(point.y / 20.0) + dy)):
				return true
	return false

func _capture(main: Node2D, file_name: String) -> void:
	for _frame in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.get_width() != 360 or image.get_height() != 800:
		_check(false, "%s tem dimensao %dx%d (esperada 360x800)" % [file_name, image.get_width(), image.get_height()])
		return
	var err := image.save_png(output_dir.path_join(file_name))
	_check(err == OK, "captura real 360x800: " + file_name)

func _cleanup_test_saves() -> void:
	var directory := DirAccess.open("user://")
	if directory == null: return
	directory.list_dir_begin()
	var filename := directory.get_next()
	while not filename.is_empty():
		if not directory.current_is_dir() and filename.begins_with("qa_andar3_preview_"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + filename))
		filename = directory.get_next()
	directory.list_dir_end()

func _run() -> void:
	output_dir = OS.get_environment("QA_RENDER_DIR")
	if output_dir.is_empty():
		push_error("QA_RENDER_DIR e obrigatorio")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	_cleanup_test_saves()
	save_path = "user://qa_andar3_preview_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	root.size = Vector2i(360, 800)
	root.content_scale_size = Vector2i(360, 800)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	main.player.set_physics_process(false)
	main.progress.ascension.defeats["1"] = 50
	_check(main.progress.ascension.complete_forest_trial(), "regra existente da Torre libera o Andar 2")
	await main._travel_floor(2)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.progress.ascension.defeats["2"] = 50
	_check(main.progress.ascension.complete_forest_trial(), "regra existente da Torre libera o Andar 3")
	await main._travel_floor(3)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"):
		actor.set_physics_process(false)
	await physics_frame
	_check(main.progress.ascension.current_floor == 3 and main.world is Andar3World, "viagem real carrega a cena propria do Pantano")
	_check(main.world.scene_file_path == "res://scenes/world/andar_3.tscn" and main.player.position == Floor3Layout.RESPAWN, "entrada e retorno chegam ao acampamento seguro")
	_check(main.hud.minimap._world_size() == Floor3Layout.WORLD_SIZE, "Mapa usa a extensao correta do Andar 3")
	_check(Exploration.resources_for_floor(3).is_empty() and Exploration.chests_for_floor(3).is_empty(), "nenhum item/coleta do Andar 1 e reaproveitado como conteudo oficial")
	# Etapa de 29/10/2026: combate, Guardiã e Torre do Pântano liberados (ver andar3_pantano_tests.gd).
	_check(FloorCatalog.feature(3, "encounters_enabled") and FloorCatalog.feature(3, "field_guardian_enabled") and FloorCatalog.feature(3, "tower_enabled"), "combate, Guardiã e Torre do Pântano liberados")
	_check(Floor3Layout.REGIONS.size() == 4 and Floor3Layout.bridge_spans().size() >= 12, "as quatro regioes estao conectadas por trilhas e pontes")
	var cells := _walkable_cells(main)
	for region: Dictionary in Floor3Layout.REGIONS:
		_check(_reachable(cells, region.center), "rota alcancavel: " + region.name)
	for point: Vector2 in FloorCatalog.enemy_spawns(3):
		_check(_reachable(cells, point), "ponto de spawn alcançavel: %s" % point)
	_check(_reachable(cells, Floor3Layout.CAIMAN_HOME) and _reachable(cells, Floor3Layout.GUARDIAN_ALTAR + Vector2(0, 80)), "arenas do Jacaré e da Guardiã alcançaveis")
	main.player.position = Floor3Layout.TOWER_POSITION + Vector2(0, 20)
	_check(main._interaction_target().get("kind", "") == "tower", "Torre existente e localizada no Andar 3")
	_check(FloorCatalog.waves(3)[0].has(8) and FloorCatalog.def_or_default(3).tower_guardian.variant == "pantano", "provas da Torre usam os monstros e a Guardiã do Pântano")
	main.player.position = FloorCatalog.camp_stations(3).Ferreiro + Vector2(0, 25)
	_check(main._interaction_target().get("kind", "") == "station", "Ferreiro atual permanece acessivel no acampamento")
	var marker: Dictionary = Floor3Layout.REGION_MARKERS[1]
	_check(main.progress.discover_nearby(marker.position, 3) and main.progress.discovered_pois.has(marker.id), "exploracao registra regiao do Pantano no estado do andar")
	var copy := GameProgress.new()
	_check(copy.load_text(main.progress.to_json()) and copy.discovered_pois.has(marker.id), "save existente reabre com o novo marcador de exploracao")
	main.player.position = Floor3Layout.RESPAWN
	main.player.set_physics_process(true)
	main.input_driver.blocked = false
	main.input_driver.set_touch_direction(Vector2.RIGHT)
	for _frame in range(8): await physics_frame
	var moved_by_joystick: bool = main.player.position.x > Floor3Layout.RESPAWN.x + 5.0
	main.input_driver.set_touch_direction(Vector2.ZERO)
	main.input_driver.request_dash()
	await physics_frame
	_check(moved_by_joystick and main.player.dash.active(), "joystick e dash existentes funcionam na entrada do mapa")
	main.player.set_physics_process(false)
	main.input_driver.reset()
	main.player.dash.time_left = 0.0
	main.player.dash.cooldown_left = 0.0
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled = false
	camera.limit_enabled = false
	main.player.position = Floor3Layout.RESPAWN
	main.player.velocity = Vector2.ZERO
	camera.zoom = Vector2.ONE
	camera.reset_smoothing()
	camera.force_update_scroll()
	root.size = Vector2i(360, 800)
	root.content_scale_size = Vector2i(360, 800)
	main.hud._layout()
	main.hud.show_notice("Pântano das Vozes · Andar 3")
	await _capture(main, "pantano-entrada-360x800.png")
	main.hud.show_map(main.progress)
	await _capture(main, "pantano-mapa-360x800.png")
	main.hud.close_map()
	await main._travel_floor(2)
	main.set_process(false)
	main.player.set_physics_process(false)
	_check(main.progress.ascension.current_floor == 2 and main.world.scene_file_path == "res://scenes/world/andar_2.tscn", "viagem de retorno preserva a cena aprovada do Andar 2")
	await main._travel_floor(1)
	_check(main.progress.ascension.current_floor == 1 and main.world.scene_file_path == "res://scenes/world/andar_1.tscn", "viagem de retorno preserva a cena aprovada do Andar 1")
	await main._travel_floor(2)
	_check(main.progress.ascension.current_floor == 2 and main.world.scene_file_path == "res://scenes/world/andar_2.tscn", "reentrada no Andar 2 continua funcionando")
	main.queue_free()
	await process_frame
	_cleanup_test_saves()
	OS.unset_environment("ARVEON_SAVE_PATH")
	print("ANDAR3_MAP: %d verificacoes, %d falhas; capturas em %s" % [checks, failures, output_dir])
	quit(1 if failures > 0 else 0)
