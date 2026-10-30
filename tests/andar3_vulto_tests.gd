extends SceneTree

# Vulto do Brejo (Andar 3): as cinco folhas aprovadas (repouso 4, movimento 4, golpe de
# garras 6, dano 3, morte 6) ligadas ao comportamento real, com o golpe no quadro 4.
# Uso: godot --path . --resolution 360x800 -s res://tests/andar3_vulto_tests.gd
# Com QA_RENDER_DIR=<pasta>, grava também a prévia (<pasta>/vulto/NNN.png).
const SOURCES := {
	"idle": "res://art_source/andar3/13_VULTO_IDLE_4_QUADROS.png",
	"movimento": "res://art_source/andar3/14_VULTO_MOVIMENTO_4_QUADROS.png",
	"ataque": "res://art_source/andar3/15_VULTO_ATAQUE_6_QUADROS.png",
	"dano": "res://art_source/andar3/16_VULTO_DANO_3_QUADROS.png",
	"morte": "res://art_source/andar3/17_VULTO_MORTE_6_QUADROS.png"}
const MANIFEST := "res://art_source/andar3/13-17_VULTO_MANIFESTO.json"
var out := ""
var main: Node
var failures := 0
var checks := 0
var save_path := ""

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition: print("VULTO OK: " + label)
	else:
		failures += 1
		push_error("VULTO FALHA: " + label)

func _run() -> void:
	out = OS.get_environment("QA_RENDER_DIR")
	save_path = "user://qa_vulto_%d.json" % Time.get_ticks_usec()
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
	_check(main.progress.ascension.current_floor == 3 and main.world is Andar3World, "Vulto testado dentro do Pântano das Vozes (Andar 3)")
	await _idle()
	await _walk_in_game()
	await _strike_in_game(1.0)
	await _strike_in_game(-1.0)
	await _hurt()
	await _hurt_during_strike()
	await _death()
	await _death_during_windup()
	if not out.is_empty(): await _record_preview()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("ARVEON_SAVE_PATH")
	print("VULTO_RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)

# ── Folhas ────────────────────────────────────────────────────────────────────
func _sheet_checks() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var hashes := {}
	for entry: Dictionary in manifest.spritesheets: hashes[String(entry.file).get_basename().trim_prefix("vulto_")] = entry.sha256
	var originals_ok := true
	for name: String in SOURCES:
		var path := ProjectSettings.globalize_path(SOURCES[name])
		var image := Image.load_from_file(path)
		originals_ok = originals_ok and image != null and image.get_size() == Vector2i(2048, 682) and FileAccess.get_sha256(path) == hashes.get(name, "")
	_check(originals_ok, "as 5 folhas originais estão em art_source sem alteração (2048x682, sha256 do pacote)")
	var neutral := {}
	var mean := {}
	for name: String in Floor3MonsterView.WRAITH:
		var sheet: Array = Floor3MonsterView.WRAITH[name]
		var texture: Texture2D = sheet[0]
		var cell: Vector2i = sheet[1]
		var anchor: Vector2i = sheet[2]
		var frames: int = sheet[3]
		var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/andar3/derived/vulto_%s.json" % name))
		_check(texture.get_size() == Vector2(cell.x * frames, cell.y) and int(meta.frames) == frames and Vector2i(int(meta.cell[0]), int(meta.cell[1])) == cell and Vector2i(int(meta.anchor[0]), int(meta.anchor[1])) == anchor,
			"%s: %d células de %dx%d, iguais às da ferramenta" % [name, frames, cell.x, cell.y])
		var image := texture.get_image()
		var lows: Array[int] = []
		var edges_clear := true
		var heights: Array[int] = []
		for frame in range(frames):
			var region := image.get_region(Rect2i(frame * cell.x, 0, cell.x, cell.y))
			var used := region.get_used_rect()
			heights.append(used.size.y)
			lows.append(used.end.y - 1)
			edges_clear = edges_clear and used.position.x >= 1 and used.position.y >= 1 and used.end.x <= cell.x - 1 and used.end.y <= cell.y - 1
		_check(edges_clear, "%s: nenhuma pose cortada pela borda da célula" % name)
		# Chão: a base de cada pose desce ou sobe em relação à pose 1 o mesmo que na folha.
		var drawn: Array[int] = []
		var follows := true
		for frame in range(frames):
			var box: Array = meta.source_boxes[frame]
			var first: Array = meta.source_boxes[0]
			drawn.append(roundi((float(box[1]) + float(box[3]) - float(first[1]) - float(first[3])) * float(meta.scale)))
			follows = follows and absi((lows[frame] - lows[0]) - drawn[frame]) <= 1
		_check(follows and absi(lows[0] - anchor.y) <= 4, "%s: raízes no chão como na folha (base %s, folha %s, âncora %d)" % [name, str(lows.map(func(v: int) -> int: return v - lows[0])), str(drawn), anchor.y])
		neutral[name] = heights[0]
		var sum := 0.0
		for height in heights: sum += height
		mean[name] = sum / heights.size()
	var same := true
	for name: String in ["ataque", "dano", "morte"]: same = same and absi(int(neutral[name]) - int(neutral.idle)) <= 2
	_check(same, "pose neutra com a mesma altura no repouso, golpe, dano e morte (%s)" % str(neutral))
	_check(absf(float(mean.movimento) - float(mean.idle)) <= 3.0, "movimento com a altura média do repouso (%.1f x %.1f px)" % [mean.movimento, mean.idle])
	var idle_rect := (Floor3MonsterView.WRAITH.idle[0] as Texture2D).get_image().get_region(Rect2i(Vector2i.ZERO, Floor3MonsterView.WRAITH.idle[1])).get_used_rect()
	_check(absi(idle_rect.size.x - 72) <= 1, "repouso com a largura do Vulto atual (%d px)" % idle_rect.size.x)

# ── Ajudantes ─────────────────────────────────────────────────────────────────
func _wraith_at(at: Vector2) -> SwampEnemy:
	var wraith := main._make_enemy(10) as SwampEnemy
	wraith.position = at
	wraith.target = main.player
	main._register_enemy_defeat(wraith)
	main.add_child(wraith)
	return wraith

func _place_player(at: Vector2) -> void:
	main.player.global_position = at
	main.player.velocity = Vector2.ZERO
	main.player.health.initialize(99999)
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled = false
	camera.reset_smoothing()
	camera.force_update_scroll()

# Trecho de trilha livre (sem árvore, moita, junco ou estrutura) para o Vulto aparecer inteiro.
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
			var finish := start + Vector2(170, 0)
			if not (Floor3Layout.is_path(start) and Floor3Layout.is_path(finish)): continue
			if SafeCamp.in_clearance(start - Vector2(60, 0)) or SafeCamp.in_clearance(finish): continue
			var gap := INF
			for blocker: Array in blockers:
				var at: Vector2 = blocker[0]
				gap = minf(gap, Geometry2D.get_closest_point_to_segment(at, start - Vector2(60, 0), finish).distance_to(at) - float(blocker[1]))
			if gap > best_gap:
				best_gap = gap
				best = start
	_spot_cache = best
	return best

func _done(wraith: SwampEnemy) -> void:
	if is_instance_valid(wraith): wraith.queue_free()
	await process_frame

# ── Comportamento ─────────────────────────────────────────────────────────────
# Parado (sem perseguir): o repouso repete os 4 quadros na ordem.
func _idle() -> void:
	var wraith := _wraith_at(_spot())
	wraith.set_physics_process(false)
	await process_frame
	var view := wraith.view as Floor3MonsterView
	_check(view is Floor3MonsterView and view.wraith_animation() == ["idle", 0], "Vulto criado pelo _make_enemy das hordas começa no repouso")
	var seen: Array[int] = []
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 1000:
		var current := view.wraith_animation()
		if current[0] == "idle" and (seen.is_empty() or seen.back() != current[1]): seen.append(int(current[1]))
		await process_frame
	_check(seen.slice(0, 5) == [0, 1, 2, 3, 0], "repouso em loop: 1 → 2 → 3 → 4 → 1 (%s)" % str(seen))
	await _done(wraith)

# Perseguindo com a física do jogo: anda até o jogador passando pelos 4 quadros.
func _walk_in_game() -> void:
	var at := _spot()
	_place_player(at + Vector2(200, 0))
	var wraith := _wraith_at(at)
	wraith.attack_cooldown = 9.0
	var view := wraith.view as Floor3MonsterView
	var seen := {}
	var start := wraith.global_position
	for _i in range(40):
		await physics_frame
		await process_frame
		var current := view.wraith_animation()
		if current[0] == "movimento": seen[current[1]] = true
	_check(wraith.global_position.distance_to(start) > 40.0, "Vulto avançou até o jogador (%.0f px)" % wraith.global_position.distance_to(start))
	_check(seen.has(0) and seen.has(1) and seen.has(2) and seen.has(3), "andando, os 4 quadros de movimento aparecem (%s)" % str(seen.keys()))
	# Jogador colado (sem golpe: recarga longa): o Vulto para e volta ao repouso.
	_place_player(wraith.global_position + Vector2(30, 0))
	for _i in range(3):
		await physics_frame
		await process_frame
	_check(not view.walking and view.wraith_animation()[0] == "idle", "ao parar, volta ao repouso")
	await _done(wraith)

# Golpe real: um único dano, no quadro 4, 0,3 s depois do início (mesmo preparo de antes);
# quadros 1–3 antes, 5–6 depois, e o lado do golpe segue o jogador.
func _strike_in_game(side: float) -> void:
	var at := _spot() + Vector2(60, 0)
	_place_player(at + Vector2(44 * side, 0))
	var wraith := _wraith_at(at)
	var view := wraith.view as Floor3MonsterView
	var health: Variant = main.player.health
	var trace: Array = []
	for _i in range(110):
		var before: int = health.current
		await physics_frame
		trace.append([view.wraith_animation(), before - int(health.current), wraith.strike_time, wraith.strike_flipped, wraith.attack_cooldown])
	var hits: Array[int] = []
	var start := -1
	for index in range(trace.size()):
		if int(trace[index][1]) > 0: hits.append(index)
		if start < 0 and float(trace[index][2]) >= 0.0: start = index
	var label := "à direita" if side > 0 else "à esquerda"
	_check(hits.size() == 1, "golpe %s: exatamente um dano no ataque (%d)" % [label, hits.size()])
	if hits.is_empty() or start < 0:
		await _done(wraith)
		return
	var hit := hits[0]
	_check(trace[hit][0] == ["ataque", SwampEnemy.WRAITH_CONTACT_FRAME], "dano sai com o quadro 4 do golpe (%s)" % str(trace[hit][0]))
	_check(absi((hit - start) - 18) <= 1, "preparo de 0,3 s como antes (%d quadros de física)" % (hit - start))
	var order: Array[int] = []
	for index in range(start, trace.size()):
		var current: Array = trace[index][0]
		if current[0] != "ataque": break
		if order.is_empty() or order.back() != current[1]: order.append(int(current[1]))
	_check(order == [0, 1, 2, 3, 4, 5], "golpe toca os 6 quadros na ordem (%s)" % str(order))
	var after := ""
	for index in range(start, trace.size()):
		if trace[index][0][0] != "ataque":
			after = trace[index][0][0]
			break
	_check(after in ["movimento", "idle"], "depois do golpe segue para o recuo/repouso (%s)" % after)
	_check(bool(trace[hit][3]) == (side < 0), "golpe %s com a arte virada para o jogador" % label)
	_check(is_equal_approx(float(trace[hit][4]), 1.3), "recarga do golpe continua 1,3 s (%.2f)" % float(trace[hit][4]))
	await _done(wraith)

# Dano real com o Vulto vivo: neutra → impacto → recuperação e volta ao repouso.
func _hurt() -> void:
	var wraith := _wraith_at(_spot())
	wraith.set_physics_process(false)
	await process_frame
	var view := wraith.view as Floor3MonsterView
	wraith.receive_damage(10)
	_check(wraith.health.is_alive() and view.wraith_animation() == ["dano", 0], "dano inicia a reação pela pose neutra")
	var seen: Array[int] = []
	var started := Time.get_ticks_msec()
	while view.wraith_hurt_frame() >= 0 and Time.get_ticks_msec() - started < 2000:
		if seen.is_empty() or seen.back() != view.wraith_hurt_frame(): seen.append(view.wraith_hurt_frame())
		await process_frame
	_check(seen == [0, 1, 2], "reação toca neutra → impacto → recuperação (%s)" % str(seen))
	_check(view.wraith_animation()[0] == "idle", "termina e volta ao repouso")
	view.wraith_hurt_time = 0.25
	wraith.receive_damage(10)
	_check(view.wraith_hurt_frame() == 1, "golpe durante a reação volta ao quadro de impacto")
	await _done(wraith)

# Golpe em andamento: o preparo e o contato não são cortados pelo dano; ao recolher as
# garras, o dano aparece.
func _hurt_during_strike() -> void:
	var wraith := _wraith_at(_spot())
	wraith.set_physics_process(false)
	await process_frame
	var view := wraith.view as Floor3MonsterView
	wraith.strike_time = 0.15
	wraith.receive_damage(10)
	_check(view.wraith_animation() == ["ataque", 1] and view.wraith_hurt_frame() == -1, "dano no preparo não interrompe o golpe")
	wraith.strike_time = 0.45
	wraith.receive_damage(10)
	_check(view.wraith_animation() == ["dano", 0], "dano ao recolher as garras mostra a reação")
	await _done(wraith)

# Golpe fatal: morte nos 6 quadros, termina nos restos de raízes, some e sai de cena.
func _death() -> void:
	var wraith := _wraith_at(_spot())
	wraith.set_physics_process(false)
	await process_frame
	var view := wraith.view as Floor3MonsterView
	wraith.receive_damage(10)
	wraith.receive_damage(wraith.health.current + 100)
	_check(not wraith.health.is_alive() and view.wraith_animation() == ["morte", 0] and view.wraith_hurt_frame() == -1, "golpe fatal vai direto para a morte, sem reação de dano")
	var seen: Array[int] = []
	var alpha_at_last := -1.0
	var started := Time.get_ticks_msec()
	while is_instance_valid(wraith) and Time.get_ticks_msec() - started < 3000:
		var frame: int = view.wraith_animation()[1]
		if seen.is_empty() or seen.back() != frame:
			seen.append(frame)
			if frame == 5: alpha_at_last = view.modulate.a
		await process_frame
	_check(seen == [0, 1, 2, 3, 4, 5], "morte toca os 6 quadros na ordem (%s)" % str(seen))
	_check(alpha_at_last == 1.0, "restos de raízes aparecem inteiros antes de sumir")
	_check(not is_instance_valid(wraith), "Vulto sai de cena no tempo de sempre (%d ms)" % (Time.get_ticks_msec() - started))

# Morrer no meio do preparo: vai para a morte e o golpe não acontece.
func _death_during_windup() -> void:
	var at := _spot() + Vector2(60, 0)
	_place_player(at + Vector2(44, 0))
	var wraith := _wraith_at(at)
	var view := wraith.view as Floor3MonsterView
	var started := Time.get_ticks_msec()
	while wraith.strike_time < 0.1 and Time.get_ticks_msec() - started < 3000: await physics_frame
	wraith.receive_damage(wraith.health.current + 100)
	_check(view.wraith_animation()[0] == "morte", "morte no meio do preparo troca para a morte")
	# A recompensa da derrota recalcula a vida do jogador; o dano conta só depois disso.
	await physics_frame
	var hp: int = main.player.health.current
	for _i in range(30): await physics_frame
	_check(int(main.player.health.current) == hp and wraith.strike_time < float(SwampEnemy.WRAITH_FRAME_STARTS[SwampEnemy.WRAITH_CONTACT_FRAME]), "golpe interrompido pela morte não acontece nem causa dano")
	await create_timer(1.2).timeout

# ── Prévia ────────────────────────────────────────────────────────────────────
# No jogo, 360x800, 30 quadros por segundo de jogo: repouso, aproximação, golpes, dano
# recebido e morte. A vista avança 1/60 s por passo de física para a animação seguir o
# tempo do jogo mesmo com a gravação lenta.
func _record_preview() -> void:
	var folder := out.path_join("vulto")
	DirAccess.make_dir_recursive_absolute(folder)
	await create_timer(1.3).timeout
	var at := _spot()
	Engine.max_physics_steps_per_frame = 1
	_place_player(at + Vector2(300, 0))
	var wraith := _wraith_at(at)
	wraith.health.initialize(99999)
	var view := wraith.view as Floor3MonsterView
	view.set_process(false)
	var view_center := at + Vector2(110, -30)
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.offset = view_center - main.player.global_position
	camera.force_update_scroll()
	var index := 0
	var states := {}
	var last_hurt := -99
	for step in range(366):
		if step == 60:
			_place_player(at + Vector2(170, 0))
			camera.offset = view_center - main.player.global_position
			camera.force_update_scroll()
		# Dois golpes do jogador fora do ataque do Vulto e, no fim, o golpe fatal. Na morte o
		# tempo do jogo desacelera só para a gravação acompanhar até ele sair de cena.
		if step >= 230 and step < 290 and wraith.strike_time < 0.0 and view.wraith_hurt_time < 0.0 and step - last_hurt >= 24:
			wraith.receive_damage(25)
			last_hurt = step
		if step == 300: wraith.receive_damage(wraith.health.current + 100)
		if step >= 300: Engine.time_scale = 0.05
		if step < 300: await physics_frame
		else: await process_frame
		view._process(1.0 / 60.0)
		states[view.wraith_animation()[0]] = true
		if step % 2 == 1: continue
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if index == 0: _check(image.get_size() == Vector2i(360, 800), "prévia gravada no jogo em 360x800")
		var screen: Vector2 = (main.get_viewport().get_canvas_transform() * view_center).round()
		var area := Rect2i(Vector2i(0, int(screen.y) - 110), Vector2i(360, 190)).intersection(Rect2i(0, 0, 360, 800))
		var crop := image.get_region(area)
		crop.resize(area.size.x * 2, area.size.y * 2, Image.INTERPOLATE_NEAREST)
		crop.save_png(folder.path_join("%03d.png" % index))
		index += 1
	Engine.time_scale = 1.0
	_check(states.has("idle") and states.has("movimento") and states.has("ataque") and states.has("dano") and states.has("morte"), "prévia passa pelas 5 animações (%s)" % str(states.keys()))
	_check(index == 183, "prévia: %d quadros" % index)
