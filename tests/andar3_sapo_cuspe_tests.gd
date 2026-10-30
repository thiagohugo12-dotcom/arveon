extends SceneTree

# Cuspida Tóxica do Sapo Venenoso (Andar 3): folha aprovada de 6 quadros, disparo no
# quadro 4 e um único projétil real por ataque, com a lógica existente de projéteis.
# Uso: godot --path . --resolution 360x800 -s res://tests/andar3_sapo_cuspe_tests.gd
# Com QA_RENDER_DIR=<pasta>, grava também a prévia do ataque (<pasta>/sapo_cuspe/NNN.png).
const SOURCE := "res://art_source/andar3/10_SAPO_CUSPE_6_QUADROS.png"
var out := ""
var main: Node
var failures := 0
var checks := 0
var save_path := ""

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition: print("SAPO_CUSPE OK: " + label)
	else:
		failures += 1
		push_error("SAPO_CUSPE FALHA: " + label)

func _run() -> void:
	out = OS.get_environment("QA_RENDER_DIR")
	save_path = "user://qa_sapo_cuspe_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	root.size = Vector2i(360, 800)
	root.content_scale_size = Vector2i(360, 800)
	_sheet_checks()
	_clock_checks()
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
	# As hordas da Torre do Andar 3 criam o Sapo pelo mesmo _make_enemy.
	var made := _toad_at(_spot() + Vector2(0, 300))
	_check(FloorCatalog.waves(3)[0].has(9) and made is SwampEnemy and made.view is Floor3MonsterView, "Sapo das hordas da Torre do Andar 3 usa o mesmo ator e a mesma vista")
	made.queue_free()
	await _attack_in_game()
	await _death_cancels()
	if not out.is_empty(): await _record_preview()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("ARVEON_SAVE_PATH")
	print("SAPO_CUSPE_RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)

# 1 e 3: folha original preservada, derivada carregada, 6 células iguais, pés na mesma
# linha e nenhuma pose encostando na borda da célula (sem cortes).
func _sheet_checks() -> void:
	var original := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	_check(original != null and original.get_size() == Vector2i(2172, 724), "folha original aprovada preservada em art_source (2172x724)")
	var sheet := Floor3MonsterView.TOAD_SHEET
	var cell := Floor3MonsterView.TOAD_CELL
	_check(sheet != null and sheet.get_size() == Vector2(cell.x * 6, cell.y), "folha derivada carregada: 6 células de %dx%d" % [cell.x, cell.y])
	_check(load("res://assets/art/andar3/monsters/sapo_cuspe_projetil.png") is Texture2D, "esfera do projétil carregada")
	var image := sheet.get_image()
	var lows: Array[int] = []
	var edges_clear := true
	for frame in range(6):
		var lowest := -1
		for y in range(cell.y):
			for x in range(cell.x):
				if image.get_pixel(frame * cell.x + x, y).a > 0.5: lowest = maxi(lowest, y)
		lows.append(lowest)
		for y in range(cell.y):
			if image.get_pixel(frame * cell.x, y).a > 0.0 or image.get_pixel(frame * cell.x + cell.x - 1, y).a > 0.0: edges_clear = false
		for x in range(cell.x):
			if image.get_pixel(frame * cell.x + x, 0).a > 0.0 or image.get_pixel(frame * cell.x + x, cell.y - 1).a > 0.0: edges_clear = false
	# Ponta das patas na mesma linha (variação de até 2 px entre poses do próprio desenho).
	_check(lows.max() - lows.min() <= 2 and lows.min() > Floor3MonsterView.TOAD_ANCHOR.y, "pés alinhados nos 6 quadros (ponta das patas nas linhas %s)" % str(lows))
	_check(edges_clear, "nenhuma pose cortada pela borda da célula (patas, espinhos, esfera)")

# 2 e 4: ordem dos quadros e disparo no quadro 4, inclusive com quadros por segundo irregulares.
func _clock_checks() -> void:
	var order: Array[int] = []
	for time: float in [-1.0, 0.0, 0.16, 0.31, 0.46, 0.53, 0.7]:
		order.append(SwampEnemy.spit_frame(time))
	_check(order == [0, 0, 1, 2, 3, 4, 5], "seis quadros na ordem: neutra, preparação, acúmulo, disparo, recuo, recuperação (%s)" % str(order))
	_check(is_equal_approx(float(SwampEnemy.SPIT_FRAME_STARTS[SwampEnemy.SPIT_SHOT_FRAME]), 0.45), "quadro 4 começa em 0,45 s: o mesmo preparo do ataque de antes")
	var shot_frame_length := float(SwampEnemy.SPIT_FRAME_STARTS[4]) - float(SwampEnemy.SPIT_FRAME_STARTS[3])
	_check(is_equal_approx(float(EnemyProjectile.HIDDEN_BY_SOURCE["Sapo Venenoso"]), shot_frame_length), "projétil real só aparece quando a esfera desenhada sai de cena (sem duas esferas)")

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

# Trecho de trilha livre (sem árvore, moita, junco ou estrutura) entre o sapo e o jogador,
# para o projétil ficar visível do começo ao fim.
var _spot_cache := Vector2.INF

func _spot() -> Vector2:
	if _spot_cache != Vector2.INF: return _spot_cache
	var decor := Floor3Layout.decor()
	# [posição dos pés, alcance visual aproximado da peça]
	var blockers: Array = []
	for entry: Array in [["trees", 80.0], ["bushes", 36.0], ["reeds", 22.0]]:
		for at: Vector2 in decor[entry[0]]: blockers.append([at, entry[1]])
	for structure: Dictionary in Floor3Layout.STRUCTURES: blockers.append([structure.feet, 50.0])
	var best := Floor3Layout.RESPAWN + Vector2(520, -40)
	var best_gap := -INF
	for y in range(140, 1520, 20):
		for x in range(140, 1980, 20):
			var start := Vector2(x, y)
			var finish := start + Vector2(170, 0)
			if not (Floor3Layout.is_path(start) and Floor3Layout.is_path(finish) and Floor3Layout.is_path(start + Vector2(85, 0))): continue
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

# 4 a 8 e oscilação de quadros: ataque real com a IA do sapo.
func _attack_in_game() -> void:
	var at := _spot()
	_place_player(at + Vector2(170, 0))
	var toad := _toad_at(at)
	toad.set_physics_process(false)
	await physics_frame
	var shots: Array = []
	var on_shot := func(origin: Vector2, _direction: Vector2, _damage: int, _name: String) -> void:
		shots.append({"frame": (toad.view as Floor3MonsterView).toad_frame(), "time": toad.spit_time, "origin": origin})
	toad.projectile_requested.connect(on_shot)
	# Relógio com passos irregulares (de 8 a 200 ms) e sem física: um disparo, no quadro 4.
	toad.attack_cooldown = 0.0
	var offset: Vector2 = main.player.global_position - toad.global_position
	var steps := [0.016, 0.05, 0.008, 0.2, 0.033, 0.12, 0.016, 0.09, 0.2, 0.1, 0.05, 0.2, 0.2]
	toad._custom_behavior(0.016, offset, offset.length())
	_check(toad.spit_time == 0.0, "o ataque começa pela pose neutra/preparação")
	var hp_before: int = main.player.health.current
	for step: float in steps:
		toad._custom_behavior(step, offset, offset.length())
	_check(shots.size() == 1, "exatamente um projétil por ataque (%d) mesmo com passos irregulares" % shots.size())
	_check(not shots.is_empty() and int(shots[0].frame) == 3, "projétil criado no quadro 4 (índice 3)")
	_check(not shots.is_empty() and is_equal_approx(float(shots[0].time), 0.45), "disparo no primeiro passo que alcança 0,45 s, com a esfera do quadro 4 na tela")
	var mouth: Vector2 = toad.global_position + Vector2(30, -32)
	_check(not shots.is_empty() and (shots[0].origin as Vector2).is_equal_approx(mouth), "projétil nasce na boca, do lado do jogador (espelhado à direita)")
	_check(main.player.health.current == hp_before, "nenhum dano no disparo: só quando o projétil atinge o jogador")
	_check(toad.spit_time == -1.0 and (toad.view as Floor3MonsterView).toad_frame() == 0, "volta ao Sapo parado após a recuperação, sem novo disparo")
	toad.projectile_requested.disconnect(on_shot)
	# Projétil real voando com a lógica existente até o jogador.
	var hits := 0
	for projectile in main.get_children():
		if projectile is EnemyProjectile: hits += 1
	_check(hits == 1, "um único projétil real em voo (%d)" % hits)
	var flight := 0
	for _i in range(60):
		await physics_frame
		flight += 1
		if main.player.health.current < hp_before: break
	_check(main.player.health.current < hp_before and flight > 5, "dano aplicado só quando o projétil atinge o jogador (%d de dano após %d quadros de voo)" % [hp_before - main.player.health.current, flight])
	# Ataque completo com a física do jogo ligada (60 Hz).
	shots.clear()
	toad.projectile_requested.connect(on_shot)
	toad.attack_cooldown = 0.0
	toad.reposition_left = 9.0
	toad.set_physics_process(true)
	for _i in range(70): await physics_frame
	toad.set_physics_process(false)
	_check(shots.size() == 1 and int(shots[0].frame) == 3, "em jogo: um disparo, no quadro 4 (%d)" % shots.size())
	toad.projectile_requested.disconnect(on_shot)
	toad.queue_free()
	for projectile in main.get_children():
		if projectile is EnemyProjectile: projectile.queue_free()
	await physics_frame

# 7: morrer durante a preparação cancela o ataque; nenhum projétil sai depois.
func _death_cancels() -> void:
	var at := _spot()
	_place_player(at + Vector2(170, 0))
	var toad := _toad_at(at)
	toad.set_physics_process(false)
	await physics_frame
	var shots := [0]
	var on_shot := func(_o: Vector2, _d: Vector2, _dmg: int, _n: String) -> void: shots[0] += 1
	toad.projectile_requested.connect(on_shot)
	toad.attack_cooldown = 0.0
	var offset: Vector2 = main.player.global_position - toad.global_position
	toad._custom_behavior(0.016, offset, offset.length())
	toad._custom_behavior(0.3, offset, offset.length())
	_check((toad.view as Floor3MonsterView).toad_frame() == 2, "acúmulo tóxico em andamento antes da morte")
	# A IA volta a rodar e o sapo morre antes do próximo passo de física.
	toad.set_physics_process(true)
	toad.health.damage(toad.health.current)
	for _i in range(60): await physics_frame
	_check(shots[0] == 0, "morte durante o preparo cancela o disparo")

# Prévia: sapo parado, preparação, acúmulo, disparo, projétil voando e recuperação (30 fps).
func _record_preview() -> void:
	var folder := out.path_join("sapo_cuspe")
	DirAccess.make_dir_recursive_absolute(folder)
	var at := _spot()
	_place_player(at + Vector2(170, 0))
	# Câmera no meio do caminho entre o sapo e o jogador.
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.offset = Vector2(-85, -20)
	camera.force_update_scroll()
	var toad := _toad_at(at)
	toad.reposition_left = 9.0
	toad.attack_cooldown = 0.5
	Engine.max_physics_steps_per_frame = 1
	await physics_frame
	var index := 0
	for step in range(100):
		await physics_frame
		if step % 2 == 1: continue
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if index == 0: _check(image.get_size() == Vector2i(360, 800), "prévia gravada no jogo em 360x800")
		var screen := (main.get_viewport().get_canvas_transform() * toad.global_position).round()
		var area := Rect2i(Vector2i(0, int(screen.y) - 110), Vector2i(360, 150)).intersection(Rect2i(0, 0, 360, 800))
		var crop := image.get_region(area)
		crop.resize(area.size.x * 2, area.size.y * 2, Image.INTERPOLATE_NEAREST)
		crop.save_png(folder.path_join("%03d.png" % index))
		index += 1
	toad.set_physics_process(false)
	_check(index >= 40, "prévia: %d quadros" % index)
