extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("ANDAR2 OK: " + message)
	else:
		failures += 1
		push_error("ANDAR2 FALHA: " + message)

func _walkable_cells(main: Node2D) -> Dictionary:
	var step := 20
	var body := CircleShape2D.new()
	body.radius = 13.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = body
	query.collision_mask = 1
	var space: PhysicsDirectSpaceState2D = main.player.get_world_2d().direct_space_state
	var start := Vector2i(roundi(Floor2Layout.RESPAWN.x / step), roundi(Floor2Layout.RESPAWN.y / step))
	var open: Array[Vector2i] = [start]
	var visited := {start: true}
	var blocked := {}
	var cursor := 0
	while cursor < open.size():
		var cell: Vector2i = open[cursor]
		cursor += 1
		for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := cell + direction
			if next.x <= 1 or next.y <= 1 or next.x >= 84 or next.y >= 67 or visited.has(next) or blocked.has(next):
				continue
			query.transform = Transform2D(0.0, Vector2(next.x * step, next.y * step))
			if not space.intersect_shape(query, 1).is_empty():
				blocked[next] = true
				continue
			visited[next] = true
			open.append(next)
	return visited

func _near_reachable(cells: Dictionary, goal: Vector2) -> bool:
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			if cells.has(Vector2i(roundi(goal.x / 20.0) + dx, roundi(goal.y / 20.0) + dy)):
				return true
	return false

func _run() -> void:
	var save_path := "user://qa_andar2_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"):
		actor.set_physics_process(false)
	await process_frame
	main.progress.ascension.defeats["1"] = 50
	_check(main.progress.ascension.complete_forest_trial(), "ascensão existente libera Andar 2")
	await main._travel_floor(2)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"):
		actor.set_physics_process(false)
	await process_frame
	_check(main.progress.ascension.current_floor == 2 and main.world.scene_file_path == FloorConfig.ANDAR2_WORLD_SCENE, "viagem carrega cena própria do Vale")
	_check(FloorConfig.world_size(2) == Vector2(1700, 1350) and main.player.position == Floor2Layout.RESPAWN, "limites e chegada usam a planta aprovada")
	_check(main.world is Andar2World and main.world.get_node("FloorView") is Floor2View and main.tower_view is Floor2TowerView, "renderização, colisões e portal são próprios")
	var camp_view := main.world.get_node("FloorView") as Floor2View
	var smith_visible := false
	var seller_visible := false
	for child in camp_view.get_children():
		if child is CampNpcView:
			var station := "Ferreiro" if child.kind == 0 else "Vendedor"
			var anchor: Vector2 = Floor2Layout.STATIONS[station]
			_check(child.position == anchor - Vector2(0, 21) and child.z_index > roundi(anchor.y - 30) + 100, "NPC visível e alinhado com interação: " + station)
			if child.kind == 0: smith_visible = true
			else: seller_visible = true
	_check(smith_visible and seller_visible and Floor2Layout.STATIONS.Ferreiro.x < 300, "ferreiro fora da cobertura da banca e ambos NPCs presentes")
	_check(main.hud.minimap._world_size() == Floor2Layout.WORLD_SIZE and main.hud.minimap._map_point(Vector2(1700, 1350)).distance_to(main.hud.minimap.size - Vector2(4, 4)) < 2, "minimapa cobre o mapa inteiro")
	_check(not main.player.test_move(main.player.transform, Vector2(1, 0)), "chegada não está presa em obstáculo")
	await physics_frame
	var reachable := _walkable_cells(main)
	for region: Dictionary in [
		{"name": "pedreira", "point": Vector2(490, 350)},
		{"name": "ruínas", "point": Vector2(1230, 420)},
		{"name": "campos", "point": Vector2(750, 715)},
		{"name": "região perigosa", "point": Vector2(1250, 785)},
		{"name": "arena", "point": Vector2(1420, 1080)},
		{"name": "passagem discreta", "point": Vector2(1535, 815)}
	]:
		_check(_near_reachable(reachable, region.point), "circulação física alcança " + region.name)
	for station: String in Floor2Layout.STATIONS:
		main.player.position = Floor2Layout.STATIONS[station] + Vector2(0, 31)
		_check(SafeCamp.nearest_station(main.player.position) == station, "serviço acessível: " + station)
	for spot: Dictionary in Exploration.resources_for_floor(2):
		_check(_near_reachable(reachable, spot.position), "coleta alcançável: " + spot.id)
	for cache: Dictionary in Exploration.chests_for_floor(2):
		_check(_near_reachable(reachable, cache.position), "baú alcançável: " + cache.id)
	var herb: Dictionary = Exploration.ANDAR2_RESOURCE_SPOTS[2]
	main.player.position = herb.position
	_check(main._interaction_target().get("id", "") == herb.id, "planta do Vale aparece na interação real")
	var herbs_before: int = int(main.progress.bag.get("Ervas", 0))
	main._interact()
	_check(int(main.progress.bag.get("Ervas", 0)) == herbs_before + 1 and main.progress.harvested_until.has(herb.id), "coleta concede item e registra cooldown")
	var cache_data: Dictionary = Exploration.ANDAR2_HIDDEN_CHESTS[0]
	main.player.position = cache_data.position
	_check(main._interaction_target().get("id", "") == cache_data.id, "baú do Vale aparece na interação real")
	var gold_before: int = main.progress.gold
	main._interact()
	_check(main.progress.gold == gold_before + int(cache_data.gold) and main.progress.opened_caches.has(cache_data.id), "baú concede recompensa e fica aberto")
	main.player.position = Floor2Layout.TOWER_POSITION + Vector2(0, 40)
	_check(main._interaction_target().get("kind", "") == "tower", "portal mantém viagem e Torre")
	_check(Exploration.resources_for_floor(2).size() == 8 and Exploration.chests_for_floor(2).size() == 3, "coletas e baús têm dados próprios")
	main.progress.harvested_until["vale_herb_fields"] = 500
	main.progress.opened_caches["vale_quarry_cache"] = true
	main._save_progress()
	var restored := GameProgress.new()
	restored.save_path = save_path
	_check(restored.load_save() and restored.ascension.current_floor == 2 and restored.harvested_until.has("vale_herb_fields") and restored.opened_caches.has("vale_quarry_cache"), "save preserva exploração do Vale")
	await main._travel_floor(1)
	_check(main.progress.ascension.current_floor == 1 and main.world.scene_file_path == FloorConfig.WORLD_SCENE and main.player.position == SafeCamp.RESPAWN, "retorno preserva o Andar 1")
	await main._travel_floor(2)
	_check(main.progress.ascension.current_floor == 2 and main.world.scene_file_path == FloorConfig.ANDAR2_WORLD_SCENE and main.player.position == Floor2Layout.RESPAWN, "segunda viagem restaura o Vale")
	main.queue_free()
	await process_frame
	var resumed := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(resumed)
	resumed.set_process(false)
	_check(resumed.progress.ascension.current_floor == 2 and resumed.world.scene_file_path == FloorConfig.ANDAR2_WORLD_SCENE and resumed.player.position == Floor2Layout.RESPAWN, "abrir save diretamente no Andar 2 restaura a cena própria")
	var camera := resumed.player.get_node("Camera2D") as Camera2D
	_check(camera.limit_right == 1700 and camera.limit_bottom == 1350, "câmera carregada respeita limites do Vale")
	resumed.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("ARVEON_SAVE_PATH")
	print("ANDAR2 RESULTADO: %d falhas" % failures)
	quit(1 if failures > 0 else 0)
