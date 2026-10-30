extends SceneTree

# Movimento do Sapo Venenoso (Andar 3): folha aprovada de 4 quadros (saltos curtos e
# pesados), em loop enquanto anda e um ciclo por salto rápido de reposição.
# Uso: godot --path . --resolution 360x800 -s res://tests/andar3_sapo_movimento_tests.gd
# Com QA_RENDER_DIR=<pasta>, grava também a prévia (<pasta>/sapo_movimento/NNN.png).
const SOURCE := "res://art_source/andar3/12_SAPO_MOVIMENTO_4_QUADROS.png"
var out := ""
var main: Node
var failures := 0
var checks := 0
var save_path := ""
var _spot_cache := Vector2.INF

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition: print("SAPO_MOVIMENTO OK: " + label)
	else:
		failures += 1
		push_error("SAPO_MOVIMENTO FALHA: " + label)

func _run() -> void:
	out = OS.get_environment("QA_RENDER_DIR")
	save_path = "user://qa_sapo_movimento_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	root.size = Vector2i(360, 800)
	root.content_scale_size = Vector2i(360, 800)
	_sheet_checks()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	main.player.set_physics_process(false)
	main.progress.ascension.defeats["1"] = 50
	main.progress.ascension.complete_forest_trial()
	await main._travel_floor(2)
	main.progress.ascension.defeats["2"] = 50
	main.progress.ascension.complete_forest_trial()
	await main._travel_floor(3)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"):
		if actor is EnemyActor: actor.queue_free()
	await physics_frame
	_check(main.progress.ascension.current_floor == 3 and main.world is Andar3World, "Sapo testado dentro do Pântano das Vozes (Andar 3)")
	await _states()
	await _walk_in_game()
	await _hop_in_game()
	if not out.is_empty(): await _record_preview()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("ARVEON_SAVE_PATH")
	print("SAPO_MOVIMENTO_RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)

func _lowest(image: Image, frame: int, cell: Vector2i) -> int:
	var lowest := -1
	for y in range(cell.y):
		for x in range(cell.x):
			if image.get_pixel(frame * cell.x + x, y).a > 0.5: lowest = maxi(lowest, y)
	return lowest

# Folha original preservada; 4 células; nada cortado; chão das poses 1 e 4 na mesma linha;
# pose 3 (salto) acima do chão, como desenhada; mesma largura do Sapo parado.
func _sheet_checks() -> void:
	var original := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	_check(original != null and original.get_size() == Vector2i(2172, 724), "folha original aprovada preservada em art_source (2172x724)")
	var sheet := Floor3MonsterView.TOAD_MOVE_SHEET
	var cell := Floor3MonsterView.TOAD_MOVE_CELL
	_check(sheet != null and sheet.get_size() == Vector2(cell.x * 4, cell.y), "folha de movimento carregada: 4 células de %dx%d" % [cell.x, cell.y])
	var image := sheet.get_image()
	var edges_clear := true
	for frame in range(4):
		for y in range(cell.y):
			if image.get_pixel(frame * cell.x, y).a > 0.0 or image.get_pixel(frame * cell.x + cell.x - 1, y).a > 0.0: edges_clear = false
		for x in range(cell.x):
			if image.get_pixel(frame * cell.x + x, 0).a > 0.0 or image.get_pixel(frame * cell.x + x, cell.y - 1).a > 0.0: edges_clear = false
	_check(edges_clear, "nenhuma pose cortada pela borda da célula (patas, espinhos, cabeça)")
	var lows: Array[int] = []
	for frame in range(4): lows.append(_lowest(image, frame, cell))
	_check(absi(lows[0] - lows[3]) <= 2 and lows[0] >= Floor3MonsterView.TOAD_MOVE_ANCHOR.y, "poses 1 e 4 apoiadas no mesmo chão (linhas %s)" % str(lows))
	_check(lows[2] < lows[0] - 10 and lows[1] < lows[0], "salto desenhado preservado: pose 2 sobe e pose 3 sai do chão (%d px)" % (lows[0] - lows[2]))
	var spit := Floor3MonsterView.TOAD_SHEET.get_image()
	var spit_rect := spit.get_region(Rect2i(0, 0, Floor3MonsterView.TOAD_CELL.x, Floor3MonsterView.TOAD_CELL.y)).get_used_rect()
	var move_rect := image.get_region(Rect2i(0, 0, cell.x, cell.y)).get_used_rect()
	_check(absi(spit_rect.size.x - move_rect.size.x) <= 3, "pose 1 do movimento com a largura do Sapo parado (%d x %d px)" % [move_rect.size.x, spit_rect.size.x])

func _toad_at(at: Vector2) -> SwampEnemy:
	var toad := main._make_enemy(9) as SwampEnemy
	toad.position = at
	toad.target = main.player
	main._register_enemy_defeat(toad)
	toad.projectile_requested.connect(main._on_enemy_projectile)
	main.add_child(toad)
	return toad

func _place_player(at: Vector2) -> void:
	main.player.global_position = at
	main.player.velocity = Vector2.ZERO
	main.player.health.initialize(99999)
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled = false
	camera.reset_smoothing()
	camera.force_update_scroll()

# Trecho de trilha livre e longo, para o sapo andar na direção do jogador sem obstáculo.
func _spot() -> Vector2:
	if _spot_cache != Vector2.INF: return _spot_cache
	var decor := Floor3Layout.decor()
	var blockers: Array = []
	for entry: Array in [["trees", 80.0], ["bushes", 36.0], ["reeds", 22.0]]:
		for at: Vector2 in decor[entry[0]]: blockers.append([at, entry[1]])
	for structure: Dictionary in Floor3Layout.STRUCTURES: blockers.append([structure.feet, 50.0])
	for span: Dictionary in Floor3Layout.bridge_spans(): blockers.append([span.center, 70.0])
	var best := Floor3Layout.RESPAWN + Vector2(520, -40)
	var best_gap := -INF
	for y in range(140, 1520, 20):
		for x in range(140, 1980, 20):
			var start := Vector2(x, y)
			var finish := start + Vector2(320, 0)
			if not (Floor3Layout.is_path(start) and Floor3Layout.is_path(finish) and Floor3Layout.is_path(start + Vector2(110, 0)) and Floor3Layout.is_path(start + Vector2(220, 0))): continue
			if SafeCamp.in_clearance(start) or SafeCamp.in_clearance(finish): continue
			var gap := INF
			for blocker: Array in blockers:
				var at: Vector2 = blocker[0]
				gap = minf(gap, Geometry2D.get_closest_point_to_segment(at, start - Vector2(40, 0), finish).distance_to(at) - float(blocker[1]))
			if gap > best_gap:
				best_gap = gap
				best = start
	_spot_cache = best
	return best

# Estados sem física: parado, loop, salto, Cuspida e dano por cima do movimento.
func _states() -> void:
	var toad := _toad_at(_spot() + Vector2(0, 300))
	toad.set_physics_process(false)
	await process_frame
	var view := toad.view as Floor3MonsterView
	view.set_process(false)
	_check(view.toad_move_frame() == -1 and view.toad_frame() == 0, "parado: quadro 1 da folha aprovada (pose neutra)")
	view.walking = true
	var loop: Array[int] = []
	for i in range(6):
		view.toad_move_time = i * Floor3MonsterView.TOAD_MOVE_STEP + 0.01
		loop.append(view.toad_move_frame())
	_check(loop == [0, 1, 2, 3, 0, 1], "andando: loop dos 4 quadros na ordem (%s)" % str(loop))
	var hop: Array[int] = []
	for left: float in [0.3, 0.22, 0.14, 0.06, 0.01]:
		toad.hop_left = left
		hop.append(view.toad_move_frame())
	_check(hop == [0, 1, 2, 3, 3], "salto rápido: um ciclo acompanhando o salto (%s)" % str(hop))
	toad.hop_left = 0.0
	toad.spit_time = 0.2
	_check(view.toad_move_frame() == -1, "Cuspida em andamento tem prioridade sobre o movimento")
	toad.spit_time = -1.0
	toad.receive_damage(10)
	_check(view.toad_hurt_frame() == 0 and view.toad_move_frame() >= 0, "dano aparece por cima do movimento (prioridade no desenho)")
	view.walking = false
	view.toad_hurt_time = -1.0
	view._process(0.0)
	_check(view.toad_move_frame() == -1 and view.toad_move_time == 0.0, "ao parar volta ao Sapo parado e o loop recomeça do quadro 1")
	toad.queue_free()
	await process_frame

# Sapo que já notou o jogador (a 240 px, dentro do alcance de 245) e o persegue depois que
# o jogador se afasta para 320 px (ele só solta em 375 e para em 210).
func _chasing_toad(at: Vector2) -> SwampEnemy:
	_place_player(at + Vector2(240, 0))
	var toad := _toad_at(at)
	toad.attack_cooldown = 9.0
	toad.reposition_left = 9.0
	await physics_frame
	await physics_frame
	_place_player(at + Vector2(320, 0))
	return toad

# Com a física do jogo: longe do jogador ele anda e passa pelos 4 quadros, sem deslizar parado.
func _walk_in_game() -> void:
	var at := _spot()
	var toad := await _chasing_toad(at)
	var view := toad.view as Floor3MonsterView
	var seen := {}
	var start := toad.global_position
	for _i in range(60):
		await physics_frame
		await process_frame
		if view.walking: seen[view.toad_move_frame()] = true
	toad.set_physics_process(false)
	_check(toad.global_position.distance_to(start) > 40.0, "sapo andou em direção ao jogador (%.0f px)" % toad.global_position.distance_to(start))
	_check(seen.has(0) and seen.has(1) and seen.has(2) and seen.has(3), "andando, os 4 quadros de salto aparecem (%s)" % str(seen.keys()))
	toad.queue_free()
	await process_frame

# Jogador perto: o sapo salta para trás e o salto toca um ciclo.
func _hop_in_game() -> void:
	var at := _spot() + Vector2(100, 0)
	_place_player(at + Vector2(70, 0))
	var toad := _toad_at(at)
	toad.attack_cooldown = 1.0
	toad.reposition_left = 9.0
	var view := toad.view as Floor3MonsterView
	var frames: Array[int] = []
	for _i in range(30):
		await physics_frame
		if toad.hop_left > 0.0:
			var frame := view.toad_move_frame()
			if frames.is_empty() or frames.back() != frame: frames.append(frame)
	toad.set_physics_process(false)
	_check(frames.size() >= 4 and frames.slice(0, 4) == [0, 1, 2, 3], "salto de reposição: cada salto vai da pose 1 à pose 4 (%s)" % str(frames))
	toad.queue_free()
	await process_frame

# Prévia (30 fps): o sapo vem aos saltos na direção do jogador (fora do quadro), para na
# distância dele (parado) e, com o jogador chegando perto, dá os saltos de reposição.
func _record_preview() -> void:
	var folder := out.path_join("sapo_movimento")
	DirAccess.make_dir_recursive_absolute(folder)
	await create_timer(1.3).timeout
	var at := _spot()
	Engine.max_physics_steps_per_frame = 1
	var toad := await _chasing_toad(at)
	# Câmera fixa sobre o caminho do sapo, mesmo quando o jogador muda de lugar.
	var view_center := at + Vector2(110, -20)
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.offset = view_center - main.player.global_position
	camera.force_update_scroll()
	await physics_frame
	var index := 0
	for step in range(220):
		if step == 150:
			_place_player(toad.global_position + Vector2(80, 0))
			camera.offset = view_center - main.player.global_position
			camera.force_update_scroll()
		await physics_frame
		if step % 2 == 1: continue
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if index == 0: _check(image.get_size() == Vector2i(360, 800), "prévia gravada no jogo em 360x800")
		var screen: Vector2 = (main.get_viewport().get_canvas_transform() * view_center).round()
		var area := Rect2i(Vector2i(0, int(screen.y) - 95), Vector2i(360, 150)).intersection(Rect2i(0, 0, 360, 800))
		var crop := image.get_region(area)
		crop.resize(area.size.x * 2, area.size.y * 2, Image.INTERPOLATE_NEAREST)
		crop.save_png(folder.path_join("%03d.png" % index))
		index += 1
	toad.set_physics_process(false)
	_check(index == 110, "prévia: %d quadros" % index)
