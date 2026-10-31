extends SceneTree

# Mãe dos Sussurros (Andar 3), FASE 1: as quatro folhas aprovadas (repouso 4, movimento 4,
# ataque 6, dano 3) ligadas ao comportamento real da Guardiã, com o contato do golpe de
# raízes (quadro 4) no instante em que Rajada, Manchas e Onda resolvem. A fase 2 continua
# com a arte estática oficial (transformação e folhas da fase 2 ainda não aprovadas).
# Uso: godot --path . --resolution 360x800 -s res://tests/andar3_mae_tests.gd
# Com QA_RENDER_DIR=<pasta>, grava também a prévia (<pasta>/mae/NNN.png).
const DIR := "res://art_source/andar3/23-26_MAE_DOS_SUSSURROS_FASE_1/"
const SOURCES := {
	"idle": DIR + "23_MAE_F1_IDLE_4_QUADROS.png",
	"movimento": DIR + "24_MAE_F1_MOVIMENTO_4_QUADROS.png",
	"ataque": DIR + "25_MAE_F1_ATAQUE_6_QUADROS.png",
	"dano": DIR + "26_MAE_F1_DANO_3_QUADROS.png"}
const MANIFEST := DIR + "MANIFESTO.json"
var out := ""
var main: Node
var failures := 0
var checks := 0
var save_path := ""

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition: print("MAE OK: " + label)
	else:
		failures += 1
		push_error("MAE FALHA: " + label)

func _run() -> void:
	out = OS.get_environment("QA_RENDER_DIR")
	save_path = "user://qa_mae_%d.json" % Time.get_ticks_usec()
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
	if is_instance_valid(main.mini_boss): main.mini_boss.queue_free()
	await physics_frame
	_check(main.progress.ascension.current_floor == 3 and main.world is Andar3World, "Guardiã testada dentro do Pântano das Vozes (Andar 3)")
	await _idle()
	await _walk_in_game()
	for move in [MotherOfWhispers.Move.BURST, MotherOfWhispers.Move.PUDDLES, MotherOfWhispers.Move.WAVE]:
		await _attack_in_game(move)
	await _hurt()
	await _hurt_during_attack()
	await _phase_two()
	if not out.is_empty(): await _record_preview()
	await _defeat()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("ARVEON_SAVE_PATH")
	print("MAE_RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)

# ── Folhas ────────────────────────────────────────────────────────────────────
func _area(image: Image) -> int:
	var count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.5: count += 1
	return count

func _sheet_checks() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	_check(manifest.get("status", "") == "parcial" and manifest.get("fase", 0) == 1, "Mãe dos Sussurros fase 1 marcada como conjunto parcial no manifesto")
	var hashes := {}
	for entry: Dictionary in manifest.spritesheets: hashes[String(entry.arquivo)] = entry.sha256
	var originals_ok := true
	for name: String in SOURCES:
		var path := ProjectSettings.globalize_path(SOURCES[name])
		var image := Image.load_from_file(path)
		originals_ok = originals_ok and image != null and image.get_size() == Vector2i(2048, 682) and FileAccess.get_sha256(path) == hashes.get(String(SOURCES[name]).get_file(), "")
	_check(originals_ok, "as 4 folhas originais estão em art_source sem alteração (2048x682, sha256 do pacote)")
	var neutral := {}
	var mean := {}
	for name: String in MotherOfWhispersView.PHASE_ONE:
		var sheet: Array = MotherOfWhispersView.PHASE_ONE[name]
		var texture: Texture2D = sheet[0]
		var cell: Vector2i = sheet[1]
		var anchor: Vector2i = sheet[2]
		var frames: int = sheet[3]
		var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/andar3/derived/mae_f1_%s.json" % name))
		_check(texture.get_size() == Vector2(cell.x * frames, cell.y) and int(meta.frames) == frames and Vector2i(int(meta.cell[0]), int(meta.cell[1])) == cell and Vector2i(int(meta.anchor[0]), int(meta.anchor[1])) == anchor,
			"%s: %d células de %dx%d, iguais às da ferramenta" % [name, frames, cell.x, cell.y])
		var image := texture.get_image()
		var lows: Array[int] = []
		var tops: Array[int] = []
		var edges_clear := true
		var areas: Array[int] = []
		for frame in range(frames):
			var region := image.get_region(Rect2i(frame * cell.x, 0, cell.x, cell.y))
			var used := region.get_used_rect()
			areas.append(_area(region))
			lows.append(used.end.y - 1)
			tops.append(used.position.y)
			edges_clear = edges_clear and used.position.x >= 1 and used.position.y >= 1 and used.end.x <= cell.x - 1 and used.end.y <= cell.y - 1
		_check(edges_clear, "%s: nenhuma pose cortada pela borda da célula" % name)
		# Altura: o topo de cada pose sobe ou desce em relação à pose 1 o mesmo que na folha
		# (até 1 px); na base, até 2 px, porque pontas finas de raiz somem na redução.
		var drawn_tops: Array[int] = []
		var drawn: Array[int] = []
		var follows := true
		for frame in range(frames):
			var box: Array = meta.source_boxes[frame]
			var first: Array = meta.source_boxes[0]
			drawn_tops.append(roundi((float(box[1]) - float(first[1])) * float(meta.scale)))
			drawn.append(roundi((float(box[1]) + float(box[3]) - float(first[1]) - float(first[3])) * float(meta.scale)))
			follows = follows and absi((tops[frame] - tops[0]) - drawn_tops[frame]) <= 1 and absi((lows[frame] - lows[0]) - drawn[frame]) <= 2
		_check(follows and lows[0] - anchor.y >= 0 and lows[0] - anchor.y <= 18, "%s: raízes no chão como na folha (topo %s, folha %s; base %s, folha %s; %d px abaixo da âncora)" % [name, str(tops.map(func(v: int) -> int: return v - tops[0])), str(drawn_tops), str(lows.map(func(v: int) -> int: return v - lows[0])), str(drawn), lows[0] - anchor.y])
		neutral[name] = areas[0]
		var sum := 0.0
		for area in areas: sum += area
		mean[name] = sum / areas.size()
	var same := true
	for name: String in ["ataque", "dano"]: same = same and absf(float(neutral[name]) / float(neutral.idle) - 1.0) <= 0.04
	_check(same, "pose 1 com a mesma área no repouso, ataque e dano (%s px²)" % str(neutral))
	_check(absf(float(mean.movimento) / float(mean.idle) - 1.0) <= 0.04, "movimento com a área média do repouso (%.0f x %.0f px²)" % [mean.movimento, mean.idle])
	var static_area := _area((load("res://assets/art/andar3/monsters/mae_dos_sussurros_fase1.png") as Texture2D).get_image())
	_check(absf(float(neutral.idle) / float(static_area) - 1.0) <= 0.03, "repouso com a área da Guardiã estática anterior da fase 1 (%d x %d px²)" % [neutral.idle, static_area])

# ── Ajudantes ─────────────────────────────────────────────────────────────────
func _place_player(at: Vector2) -> void:
	main.player.global_position = at
	main.player.velocity = Vector2.ZERO
	main.player.health.initialize(99999)
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled = false
	camera.reset_smoothing()
	camera.force_update_scroll()

func _mother(recover := 0.0) -> MotherOfWhispers:
	_place_player(Floor3Layout.GUARDIAN_ALTAR + Vector2(0, 30))
	main._start_guardian()
	var mother := main.guardian as MotherOfWhispers
	mother.move_recover = recover
	return mother

func _done(mother: MotherOfWhispers) -> void:
	if is_instance_valid(mother): mother.queue_free()
	for hazard in get_nodes_in_group("swamp_hazards"): hazard.queue_free()
	await process_frame

# Golpe completo com a física do jogo: [animação, dano no jogador, relógio do ataque,
# golpe resolvido neste passo, aviso].
func _trace(mother: MotherOfWhispers, steps: int) -> Array:
	var view := mother.view as MotherOfWhispersView
	var health: Variant = main.player.health
	var trace: Array = []
	for _i in range(steps):
		var before: int = health.current
		var attack_before := view.attack_left
		await physics_frame
		trace.append([view.phase_one_animation(), before - int(health.current), mother.attack_time, view.attack_left > attack_before, view.telegraph])
	return trace

# ── Comportamento ─────────────────────────────────────────────────────────────
# Parada (sem IA): o repouso repete os 4 quadros na ordem.
func _idle() -> void:
	var mother := _mother()
	_check(is_instance_valid(mother) and mother.view is MotherOfWhispersView, "Mãe dos Sussurros surge pelo altar com a vista da Guardiã")
	if not is_instance_valid(mother): return
	mother.set_physics_process(false)
	await process_frame
	var view := mother.view as MotherOfWhispersView
	_check(view.phase_one_animation() == ["idle", 0] and view._shown_phase == 1, "começa na fase 1, no repouso")
	var seen: Array[int] = []
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 1000:
		var current := view.phase_one_animation()
		if current[0] == "idle" and (seen.is_empty() or seen.back() != current[1]): seen.append(int(current[1]))
		await process_frame
	_check(seen.slice(0, 5) == [0, 1, 2, 3, 0], "repouso em loop: 1 → 2 → 3 → 4 → 1 (%s)" % str(seen))
	await _done(mother)

# Na pausa entre golpes, com o jogador a mais de 140 px: anda até ele pelos 4 quadros e,
# ao parar, sai do movimento.
func _walk_in_game() -> void:
	var mother := _mother(3.0)
	_place_player(mother.global_position + Vector2(0, 260))
	var view := mother.view as MotherOfWhispersView
	var seen := {}
	var start := mother.global_position
	var stopped := ""
	for _i in range(200):
		await physics_frame
		await process_frame
		var current := view.phase_one_animation()
		if current[0] == "movimento": seen[current[1]] = true
		if not seen.is_empty() and not view.walking:
			stopped = current[0]
			break
	_check(mother.global_position.distance_to(start) > 30.0, "Guardiã avançou até o jogador (%.0f px)" % mother.global_position.distance_to(start))
	_check(seen.has(0) and seen.has(1) and seen.has(2) and seen.has(3), "andando, os 4 quadros de movimento aparecem (%s)" % str(seen.keys()))
	_check(stopped in ["idle", "ataque"], "ao parar, sai do movimento (%s)" % stopped)
	await _done(mother)

# Golpe real: aviso com os quadros 1–3, o golpe resolve com o quadro 4 no fim do aviso (tempo
# de sempre), quadros 5–6 depois. Na Onda, o único dano no jogador cai nesse mesmo passo.
func _attack_in_game(move: int) -> void:
	var mother := _mother()
	_place_player(mother.global_position + Vector2(0, 90))
	mother.move_index = MotherOfWhispers.PHASE_ONE.find(move)
	var trace := await _trace(mother, 110)
	var name: String = ["rajada", "manchas", "onda", "raizes"][move]
	var start := -1
	var resolved: Array[int] = []
	for index in range(trace.size()):
		if start < 0 and float(trace[index][2]) >= 0.0: start = index
		if trace[index][3]: resolved.append(index)
	_check(resolved.size() == 1 and start >= 0, "%s: um golpe resolvido (%d)" % [name, resolved.size()])
	if resolved.is_empty() or start < 0:
		await _done(mother)
		return
	var hit := resolved[0]
	_check(trace[hit][0] == ["ataque", MotherOfWhispers.ATTACK_CONTACT_FRAME] and trace[hit - 1][4] == name, "%s: golpe resolve com o quadro 4 (contato) (%s)" % [name, str(trace[hit][0])])
	var windup := float(MotherOfWhispers.MOVE_WINDUP[move])
	_check(absi((hit - start) - ceili(windup * 60.0 - 0.001)) <= 1, "%s: aviso de %.2f s como antes (%d quadros de física)" % [name, windup, hit - start])
	var order: Array[int] = []
	for index in range(start, trace.size()):
		var current: Array = trace[index][0]
		if current[0] != "ataque": break
		if order.is_empty() or order.back() != current[1]: order.append(int(current[1]))
	_check(order == [0, 1, 2, 3, 4, 5], "%s: 6 quadros na ordem (%s)" % [name, str(order)])
	var after := ""
	for index in range(hit, trace.size()):
		if trace[index][0][0] != "ataque":
			after = trace[index][0][0]
			break
	_check(after in ["movimento", "idle"], "%s: termina no repouso/movimento (%s)" % [name, after])
	if move == MotherOfWhispers.Move.WAVE:
		var damaged: Array[int] = []
		for index in range(trace.size()):
			if int(trace[index][1]) > 0: damaged.append(index)
		_check(damaged == [hit], "onda: um único dano no jogador, no passo do quadro 4 (%s, contato %d)" % [str(damaged), hit])
	await _done(mother)

# Dano com a Guardiã viva: neutra → impacto → recuperação e volta ao repouso.
func _hurt() -> void:
	var mother := _mother()
	mother.set_physics_process(false)
	await process_frame
	var view := mother.view as MotherOfWhispersView
	mother.receive_damage(10)
	_check(mother.health.is_alive() and view.phase_one_animation() == ["dano", 0], "dano inicia a reação pela pose 1")
	var seen: Array[int] = []
	var started := Time.get_ticks_msec()
	while view.hurt_frame() >= 0 and Time.get_ticks_msec() - started < 2000:
		if seen.is_empty() or seen.back() != view.hurt_frame(): seen.append(view.hurt_frame())
		await process_frame
	_check(seen == [0, 1, 2], "reação toca os 3 quadros na ordem (%s)" % str(seen))
	_check(view.phase_one_animation()[0] == "idle", "termina e volta ao repouso")
	view.hurt_time = 0.25
	mother.receive_damage(10)
	_check(view.hurt_frame() == 1, "golpe durante a reação volta ao quadro de impacto")
	await _done(mother)

# Aviso e contato do ataque não são cortados pelo dano; com as raízes voltando, o dano aparece.
func _hurt_during_attack() -> void:
	var mother := _mother()
	mother.set_physics_process(false)
	await process_frame
	var view := mother.view as MotherOfWhispersView
	mother.attack_time = 0.15
	mother.receive_damage(10)
	_check(view.phase_one_animation() == ["ataque", 1] and view.hurt_frame() == -1, "dano no aviso não interrompe o ataque")
	mother.attack_time = 0.45
	mother.receive_damage(10)
	_check(view.phase_one_animation() == ["dano", 0], "dano com as raízes voltando mostra a reação")
	await _done(mother)

# Abaixo de 50%: fase 2 com a arte estática oficial, como antes; o dano não liga a reação da
# fase 1 e o golpe de raízes da fase 2 continua.
func _phase_two() -> void:
	var mother := _mother()
	_place_player(mother.global_position + Vector2(0, 150))
	mother.health.damage(roundi(mother.health.maximum * 0.55))
	for _i in range(80): await physics_frame
	var view := mother.view as MotherOfWhispersView
	_check(mother.phases.phase == 2 and view._shown_phase == 2, "abaixo de 50%: fase 2 com a arte estática oficial")
	view.hurt_time = -1.0
	mother.receive_damage(10)
	_check(view.hurt_time < 0.0, "na fase 2 o dano não usa a reação da fase 1")
	var roots := false
	for _i in range(300):
		await physics_frame
		for hazard in get_nodes_in_group("swamp_hazards"):
			if (hazard as SwampHazard).style == "raiz": roots = true
		if roots: break
	_check(roots, "fase 2: Raízes emergentes continuam com aviso no chão")
	await _done(mother)

# Derrota: o quadro atual fica parado enquanto ela some (sem folha de morte aprovada) e a
# vitória fica registrada no andar.
func _defeat() -> void:
	var mother := _mother()
	mother.set_physics_process(false)
	await process_frame
	var view := mother.view as MotherOfWhispersView
	mother.health.damage(mother.health.current)
	var frame := view.phase_one_animation()
	for _i in range(4): await process_frame
	_check(is_instance_valid(view) and view.phase_one_animation() == frame and view.modulate.a < 1.0, "derrota congela o quadro atual e some como antes (%s)" % str(frame))
	await create_timer(0.5).timeout
	_check(not is_instance_valid(mother), "Guardiã sai de cena no tempo de sempre")
	_check(bool(main.progress.floor_states["3"].guardian_defeated), "derrota da Guardiã fica registrada no andar (save)")

# ── Prévia ────────────────────────────────────────────────────────────────────
# No jogo, 360x800, 30 quadros por segundo de jogo: repouso, aproximação, Rajada, Manchas,
# Onda, dano recebido e a troca para a fase 2 (arte estática). A vista avança 1/60 s por
# passo de física para a animação seguir o tempo do jogo mesmo com a gravação lenta.
func _record_preview() -> void:
	var folder := out.path_join("mae")
	DirAccess.make_dir_recursive_absolute(folder)
	Engine.max_physics_steps_per_frame = 1
	var mother := _mother(99.0)
	var home := mother.global_position
	_place_player(home + Vector2(0, 330))
	var view := mother.view as MotherOfWhispersView
	view.set_process(false)
	var view_center := home + Vector2(0, -60)
	var camera := main.player.get_node("Camera2D") as Camera2D
	var aim := func() -> void:
		camera.offset = view_center - main.player.global_position
		camera.force_update_scroll()
	aim.call()
	var index := 0
	var states := {}
	var last_hurt := -99
	for step in range(640):
		if step == 50:
			_place_player(home + Vector2(0, 260))
			mother.move_recover = 1.2
			aim.call()
		if step == 150:
			_place_player(mother.global_position + Vector2(0, 100))
			aim.call()
		# Golpes do jogador fora dos ataques da Guardiã e, no fim, a troca para a fase 2.
		var busy := mother.attack_time >= 0.0 or mother.move_windup > 0.0
		if step >= 330 and step < 520 and not busy and view.hurt_time < 0.0 and step - last_hurt >= 30:
			mother.receive_damage(25)
			last_hurt = step
		if step == 540: mother.health.damage(roundi(mother.health.maximum * 0.55))
		await physics_frame
		view._process(1.0 / 60.0)
		states[view.phase_one_animation()[0] if view._shown_phase == 1 else "fase2"] = true
		if step % 2 == 1: continue
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if index == 0: _check(image.get_size() == Vector2i(360, 800), "prévia gravada no jogo em 360x800")
		var screen: Vector2 = (main.get_viewport().get_canvas_transform() * view_center).round()
		var area := Rect2i(Vector2i(0, int(screen.y) - 230), Vector2i(360, 400)).intersection(Rect2i(0, 0, 360, 800))
		image.get_region(area).save_png(folder.path_join("%03d.png" % index))
		index += 1
	_check(states.has("idle") and states.has("movimento") and states.has("ataque") and states.has("dano") and states.has("fase2"), "prévia passa pelas 4 animações e pela fase 2 (%s)" % str(states.keys()))
	print("MAE prévia: %d quadros" % index)
	await _done(mother)
