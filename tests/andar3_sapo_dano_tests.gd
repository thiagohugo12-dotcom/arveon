extends SceneTree

# Reação ao dano do Sapo Venenoso (Andar 3): folha aprovada de 3 quadros (pose neutra,
# impacto, recuperação), tocada sempre que o sapo é ferido e continua vivo.
# Uso: godot --path . --resolution 360x800 -s res://tests/andar3_sapo_dano_tests.gd
# Com QA_RENDER_DIR=<pasta>, grava também a prévia (<pasta>/sapo_dano/NNN.png).
const SOURCE := "res://art_source/andar3/11_SAPO_DANO_3_QUADROS.png"
var out := ""
var main: Node
var failures := 0
var checks := 0
var save_path := ""

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition: print("SAPO_DANO OK: " + label)
	else:
		failures += 1
		push_error("SAPO_DANO FALHA: " + label)

func _run() -> void:
	out = OS.get_environment("QA_RENDER_DIR")
	save_path = "user://qa_sapo_dano_%d.json" % Time.get_ticks_usec()
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
	await _hurt_in_game()
	await _death_during_hurt()
	await _fatal_hit()
	if not out.is_empty(): await _record_preview()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("ARVEON_SAVE_PATH")
	print("SAPO_DANO_RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)

# Folha original preservada; derivada com exatamente 3 células; pés na mesma linha e no
# mesmo lugar; nenhuma pose encostando na borda da célula.
func _sheet_checks() -> void:
	var original := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	_check(original != null and original.get_size() == Vector2i(2172, 724), "folha original aprovada preservada em art_source (2172x724)")
	var sheet := Floor3MonsterView.TOAD_HURT_SHEET
	var cell := Floor3MonsterView.TOAD_HURT_CELL
	_check(sheet != null and sheet.get_size() == Vector2(cell.x * 3, cell.y), "folha de dano carregada: exatamente 3 células de %dx%d" % [cell.x, cell.y])
	var order: Array[int] = []
	var view := Floor3MonsterView.new()
	view.kind = 9
	for time: float in [-1.0, 0.0, 0.05, 0.2, 0.31]:
		view.toad_hurt_time = time
		order.append(view.toad_hurt_frame())
	view.free()
	_check(order == [-1, 0, 1, 2, 2], "quadros na ordem: pose neutra, impacto, recuperação (%s)" % str(order))
	var image := sheet.get_image()
	var lows: Array[int] = []
	var feet: Array[float] = []
	var edges_clear := true
	for frame in range(3):
		var lowest := -1
		for y in range(cell.y):
			for x in range(cell.x):
				if image.get_pixel(frame * cell.x + x, y).a > 0.5: lowest = maxi(lowest, y)
		lows.append(lowest)
		# Centro das patas: pixels sólidos nas 10 linhas de baixo.
		var sum := 0.0
		var count := 0
		for y in range(maxi(0, lowest - 10), lowest + 1):
			for x in range(cell.x):
				if image.get_pixel(frame * cell.x + x, y).a > 0.5:
					sum += x
					count += 1
		feet.append(sum / maxf(1.0, count))
		for y in range(cell.y):
			if image.get_pixel(frame * cell.x, y).a > 0.0 or image.get_pixel(frame * cell.x + cell.x - 1, y).a > 0.0: edges_clear = false
		for x in range(cell.x):
			if image.get_pixel(frame * cell.x + x, 0).a > 0.0 or image.get_pixel(frame * cell.x + x, cell.y - 1).a > 0.0: edges_clear = false
	_check(lows.max() - lows.min() <= 2, "base das patas na mesma linha nos 3 quadros (%s)" % str(lows))
	_check(feet.max() - feet.min() <= 4.0, "patas no mesmo lugar na horizontal (centros %s)" % str(feet.map(func(v: float) -> int: return roundi(v))))
	_check(edges_clear, "nenhuma pose cortada pela borda da célula (patas, cabeça, respingos)")
	# Mesmo tamanho do Sapo parado: a largura da pose neutra bate com a da folha da Cuspida.
	var spit := Floor3MonsterView.TOAD_SHEET.get_image()
	var spit_rect := spit.get_region(Rect2i(0, 0, Floor3MonsterView.TOAD_CELL.x, Floor3MonsterView.TOAD_CELL.y)).get_used_rect()
	var hurt_rect := image.get_region(Rect2i(0, 0, cell.x, cell.y)).get_used_rect()
	_check(absi(spit_rect.size.x - hurt_rect.size.x) <= 3, "pose neutra do dano com a largura do Sapo atual (%d x %d px)" % [hurt_rect.size.x, spit_rect.size.x])

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

# Trecho de trilha livre (sem árvore, moita, junco ou estrutura) para o sapo aparecer inteiro.
var _spot_cache := Vector2.INF

func _spot() -> Vector2:
	if _spot_cache != Vector2.INF: return _spot_cache
	var decor := Floor3Layout.decor()
	var blockers: Array = []
	for entry: Array in [["trees", 80.0], ["bushes", 36.0], ["reeds", 22.0]]:
		for at: Vector2 in decor[entry[0]]: blockers.append([at, entry[1]])
	for structure: Dictionary in Floor3Layout.STRUCTURES: blockers.append([structure.feet, 50.0])
	var best := Floor3Layout.RESPAWN + Vector2(520, -40)
	var best_gap := -INF
	for y in range(140, 1520, 20):
		for x in range(140, 1980, 20):
			var start := Vector2(x, y)
			var finish := start + Vector2(110, 0)
			if not (Floor3Layout.is_path(start) and Floor3Layout.is_path(finish)): continue
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

# Dano real pelo caminho de sempre (receive_damage), sapo vivo: toca e volta ao parado.
func _hurt_in_game() -> void:
	var toad := _toad_at(_spot())
	toad.set_physics_process(false)
	await process_frame
	var view := toad.view as Floor3MonsterView
	_check(toad is SwampEnemy and view is Floor3MonsterView, "Sapo criado pelo mesmo _make_enemy das hordas da Torre e do campo")
	_check(view.toad_hurt_frame() == -1, "Sapo parado antes do dano")
	var hp: int = toad.health.current
	toad.receive_damage(20)
	_check(toad.health.current < hp and toad.health.is_alive(), "Sapo ferido e vivo")
	_check(view.toad_hurt_frame() == 0, "dano inicia a reação pela pose neutra")
	var seen: Array[int] = []
	var started := Time.get_ticks_msec()
	while view.toad_hurt_frame() >= 0 and Time.get_ticks_msec() - started < 2000:
		if seen.is_empty() or seen.back() != view.toad_hurt_frame(): seen.append(view.toad_hurt_frame())
		await process_frame
	_check(seen == [0, 1, 2], "reação toca neutra → impacto → recuperação (%s)" % str(seen))
	_check(view.toad_hurt_frame() == -1 and view.toad_frame() == 0, "termina e volta ao Sapo parado")
	# Golpe novo no meio da reação volta ao impacto.
	toad.receive_damage(10)
	view.toad_hurt_time = 0.25
	toad.receive_damage(10)
	_check(view.toad_hurt_frame() == 1, "golpe durante a reação volta ao quadro de impacto")
	toad.queue_free()
	await process_frame

# Morrer no meio da reação: sai do dano e segue para a morte.
func _death_during_hurt() -> void:
	var toad := _toad_at(_spot())
	toad.set_physics_process(false)
	await process_frame
	var view := toad.view as Floor3MonsterView
	toad.receive_damage(20)
	_check(view.toad_hurt_frame() == 0, "reação em andamento")
	toad.receive_damage(toad.health.current + 100)
	_check(not toad.health.is_alive() and view.toad_hurt_frame() == -1 and view.dying_left > 0.0, "morte no meio da reação: sai do dano e segue para o desaparecimento")
	await process_frame

# Golpe fatal direto: nunca entra no dano.
func _fatal_hit() -> void:
	var toad := _toad_at(_spot())
	toad.set_physics_process(false)
	await process_frame
	var view := toad.view as Floor3MonsterView
	toad.receive_damage(toad.health.current + 100)
	_check(view.toad_hurt_frame() == -1 and view.dying_left > 0.0, "golpe fatal não fica preso no estado de dano")
	for _i in range(5): await process_frame
	_check(view.toad_hurt_frame() == -1, "continua fora do dano até sumir")

# Prévia: três golpes espaçados no Sapo, em 360x800 (30 quadros por segundo).
func _record_preview() -> void:
	var folder := out.path_join("sapo_dano")
	DirAccess.make_dir_recursive_absolute(folder)
	# Os sapos derrotados nos testes acima somem antes da gravação.
	await create_timer(1.3).timeout
	var at := _spot()
	_place_player(at + Vector2(110, 0))
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.offset = Vector2(-55, -20)
	camera.force_update_scroll()
	var toad := _toad_at(at)
	toad.set_physics_process(false)
	toad.health.initialize(99999)
	var view := toad.view as Floor3MonsterView
	view.set_process(false)
	await process_frame
	var index := 0
	for step in range(90):
		if step in [10, 40, 52]: toad.receive_damage(25)
		view._process(1.0 / 30.0)
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if index == 0: _check(image.get_size() == Vector2i(360, 800), "prévia gravada no jogo em 360x800")
		var screen := (main.get_viewport().get_canvas_transform() * toad.global_position).round()
		var area := Rect2i(Vector2i(0, int(screen.y) - 110), Vector2i(360, 150)).intersection(Rect2i(0, 0, 360, 800))
		var crop := image.get_region(area)
		crop.resize(area.size.x * 2, area.size.y * 2, Image.INTERPOLATE_NEAREST)
		crop.save_png(folder.path_join("%03d.png" % index))
		index += 1
	_check(index == 90, "prévia: %d quadros" % index)
