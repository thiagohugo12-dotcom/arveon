extends SceneTree

# Mãe dos Sussurros (Andar 3), conjunto aprovado ligado ao comportamento real da Guardiã:
#  - fase 1 (repouso 4, movimento 4, ataque 6, dano 3), contato do golpe no quadro 4;
#  - transformação (6 quadros) durante a pausa de sempre da troca de fase (50% da vida);
#  - fase 2 (repouso 4, movimento 5, ataque 6, dano 3, morte 6), contato no quadro 3.
# Rajada, Manchas, Onda e Raízes resolvem no quadro de contato, com os avisos de sempre.
# Uso: godot --path . --resolution 360x800 -s res://tests/andar3_mae_tests.gd
# Com QA_RENDER_DIR=<pasta>, grava também a prévia (<pasta>/mae/NNN.png).
const DIR := "res://art_source/andar3/23-26_MAE_DOS_SUSSURROS_FASE_1/"
const SOURCES := {
	"idle": DIR + "23_MAE_F1_IDLE_4_QUADROS.png",
	"movimento": DIR + "24_MAE_F1_MOVIMENTO_4_QUADROS.png",
	"ataque": DIR + "25_MAE_F1_ATAQUE_6_QUADROS.png",
	"dano": DIR + "26_MAE_F1_DANO_3_QUADROS.png"}
const MANIFEST := DIR + "MANIFESTO.json"
const F2_DIR := "res://art_source/andar3/27-32_MAE_DOS_SUSSURROS_TRANSFORMACAO_E_FASE_2/"
const F2_MANIFEST := F2_DIR + "MANIFESTO.json"
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
	await _walk_in_game(false)
	for move in [MotherOfWhispers.Move.BURST, MotherOfWhispers.Move.PUDDLES, MotherOfWhispers.Move.WAVE]:
		await _attack_in_game(move, false)
	await _hurt(false)
	await _hurt_during_attack()
	await _transformation()
	await _walk_in_game(true)
	for move in [MotherOfWhispers.Move.ROOTS, MotherOfWhispers.Move.WAVE]:
		await _attack_in_game(move, true)
	await _hurt(true)
	if not out.is_empty(): await _record_preview()
	await _defeat_phase_one()
	main.progress.floor_states["3"].guardian_defeated = false
	await _death_phase_two()
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
	_check(manifest.get("status", "") == "conjunto_completo" and manifest.get("fase", 0) == 1, "Mãe dos Sussurros fase 1 marcada como conjunto completo no manifesto")
	var hashes := {}
	for entry: Dictionary in manifest.spritesheets: hashes[String(entry.arquivo)] = entry.sha256
	var originals_ok := true
	for name: String in SOURCES:
		var path := ProjectSettings.globalize_path(SOURCES[name])
		var image := Image.load_from_file(path)
		originals_ok = originals_ok and image != null and image.get_size() == Vector2i(2048, 682) and FileAccess.get_sha256(path) == hashes.get(String(SOURCES[name]).get_file(), "")
	_check(originals_ok, "as 4 folhas originais da fase 1 estão em art_source sem alteração (2048x682, sha256 do pacote)")
	var f2_manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(F2_MANIFEST))
	var f2_ok: bool = f2_manifest.get("status", "") == "aprovado" and f2_manifest.spritesheets.size() == 6
	for entry: Dictionary in f2_manifest.spritesheets:
		var path := ProjectSettings.globalize_path(F2_DIR + String(entry.arquivo))
		var image := Image.load_from_file(path)
		f2_ok = f2_ok and image != null and image.get_size() == Vector2i(int(entry.resolucao_px[0]), int(entry.resolucao_px[1])) and FileAccess.get_sha256(path) == String(entry.sha256)
	_check(f2_ok, "transformação e 5 folhas da fase 2 em art_source sem alteração (tamanho e sha256 do manifesto)")
	var f1 := {}
	for name: String in MotherOfWhispersView.PHASE_ONE: f1[name] = _strip_checks("fase 1 " + name, MotherOfWhispersView.PHASE_ONE[name], "mae_f1_" + name)
	var transformation := _strip_checks("transformação", MotherOfWhispersView.TRANSFORMATION, "mae_transformacao")
	var f2 := {}
	for name: String in MotherOfWhispersView.PHASE_TWO: f2[name] = _strip_checks("fase 2 " + name, MotherOfWhispersView.PHASE_TWO[name], "mae_f2_" + name)
	for group: Array in [["fase 1", f1, ["ataque", "dano"]], ["fase 2", f2, ["ataque", "dano", "morte"]]]:
		var areas: Dictionary = group[1]
		var same := true
		var shown := {}
		for name: String in group[2]:
			same = same and absf(float(areas[name][0]) / float(areas.idle[0]) - 1.0) <= 0.04
			shown[name] = areas[name][0]
		_check(same, "%s: pose 1 com a área do repouso (%d px²; %s)" % [group[0], areas.idle[0], str(shown)])
		_check(absf(float(areas.movimento[1]) / float(areas.idle[1]) - 1.0) <= 0.04, "%s: movimento com a área média do repouso (%.0f x %.0f px²)" % [group[0], areas.movimento[1], areas.idle[1]])
	var static_area := _area((load("res://assets/art/andar3/monsters/mae_dos_sussurros_fase1.png") as Texture2D).get_image())
	_check(absf(float(f1.idle[0]) / float(static_area) - 1.0) <= 0.03, "repouso da fase 1 com a área da Guardiã estática anterior (%d x %d px²)" % [f1.idle[0], static_area])
	_check(absf(float(transformation[0]) / float(f1.idle[0]) - 1.0) <= 0.04, "transformação começa no tamanho do repouso da fase 1 (%d x %d px²)" % [transformation[0], f1.idle[0]])
	_check(absf(float(f2.idle[0]) / float(transformation[2]) - 1.0) <= 0.04, "repouso da fase 2 no tamanho do último quadro da transformação (%d x %d px²)" % [f2.idle[0], transformation[2]])

# Uma folha derivada: células iguais às da ferramenta, nada cortado pela borda e poses na
# altura da folha original. Devolve [área da pose 1, área média, área da última pose].
func _strip_checks(label: String, sheet: Array, file: String) -> Array:
	var texture: Texture2D = sheet[0]
	var cell: Vector2i = sheet[1]
	var anchor: Vector2i = sheet[2]
	var frames: int = sheet[3]
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/andar3/derived/%s.json" % file))
	_check(texture.get_size() == Vector2(cell.x * frames, cell.y) and int(meta.frames) == frames and Vector2i(int(meta.cell[0]), int(meta.cell[1])) == cell and Vector2i(int(meta.anchor[0]), int(meta.anchor[1])) == anchor,
		"%s: %d células de %dx%d, iguais às da ferramenta" % [label, frames, cell.x, cell.y])
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
	_check(edges_clear, "%s: nenhuma pose cortada pela borda da célula" % label)
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
	_check(follows and lows[0] - anchor.y >= 0 and lows[0] - anchor.y <= 18, "%s: raízes no chão como na folha (topo %s, folha %s; base %s, folha %s; %d px abaixo da âncora)" % [label, str(tops.map(func(v: int) -> int: return v - tops[0])), str(drawn_tops), str(lows.map(func(v: int) -> int: return v - lows[0])), str(drawn), lows[0] - anchor.y])
	var sum := 0.0
	for area in areas: sum += area
	return [areas[0], sum / areas.size(), areas[frames - 1]]

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
	main.progress.floor_states["3"].guardian_defeated = false
	_place_player(Floor3Layout.GUARDIAN_ALTAR + Vector2(0, 30))
	main._start_guardian()
	var mother := main.guardian as MotherOfWhispers
	mother.move_recover = recover
	return mother

func _done(mother: MotherOfWhispers) -> void:
	if is_instance_valid(mother): mother.queue_free()
	for hazard in get_nodes_in_group("swamp_hazards"): hazard.queue_free()
	await process_frame

# Golpe completo com a física do jogo: [animação na tela (conjunto, folha, quadro), dano no
# jogador, relógio do ataque, golpe resolvido neste passo, aviso, raízes no chão].
func _trace(mother: MotherOfWhispers, steps: int) -> Array:
	var view := mother.view as MotherOfWhispersView
	var health: Variant = main.player.health
	var trace: Array = []
	for _i in range(steps):
		var before: int = health.current
		var attack_before := view.attack_left
		await physics_frame
		var roots := 0
		for hazard in get_nodes_in_group("swamp_hazards"):
			if (hazard as SwampHazard).style == "raiz": roots += 1
		trace.append([view.animation(), before - int(health.current), mother.attack_time, view.attack_left > attack_before, view.telegraph, roots])
	return trace

# Guardiã já na fase 2, depois da transformação (a pausa de sempre).
func _mother_phase_two() -> MotherOfWhispers:
	var mother := _mother(99.0)
	mother.health.damage(roundi(mother.health.maximum * 0.55))
	for _i in range(120):
		await physics_frame
		if mother.phases.phase == 2 and not mother.phases.transitioning(): break
	await process_frame
	return mother

# ── Comportamento ─────────────────────────────────────────────────────────────
# Parada (sem IA): o repouso repete os 4 quadros na ordem.
func _idle() -> void:
	var mother := _mother()
	_check(is_instance_valid(mother) and mother.view is MotherOfWhispersView, "Mãe dos Sussurros surge pelo altar com a vista da Guardiã")
	if not is_instance_valid(mother): return
	mother.set_physics_process(false)
	await process_frame
	var view := mother.view as MotherOfWhispersView
	_check(view.animation() == ["fase1", "idle", 0] and view._shown_phase == 1, "começa na fase 1, no repouso")
	var seen: Array[int] = []
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 1000:
		var current := view.phase_one_animation()
		if current[0] == "idle" and (seen.is_empty() or seen.back() != current[1]): seen.append(int(current[1]))
		await process_frame
	_check(seen.slice(0, 5) == [0, 1, 2, 3, 0], "repouso em loop: 1 → 2 → 3 → 4 → 1 (%s)" % str(seen))
	await _done(mother)

# Na pausa entre golpes, com o jogador a mais de 140 px: anda até ele por todos os quadros do
# movimento (4 na fase 1, 5 na fase 2) e, ao parar, sai do movimento.
func _walk_in_game(phase_two: bool) -> void:
	var mother: MotherOfWhispers = await _mother_phase_two() if phase_two else _mother()
	mother.move_recover = 3.0
	_place_player(mother.global_position + Vector2(0, 260))
	var view := mother.view as MotherOfWhispersView
	var label := "fase 2" if phase_two else "fase 1"
	var frames := int((MotherOfWhispersView.PHASE_TWO if phase_two else MotherOfWhispersView.PHASE_ONE).movimento[3])
	var seen := {}
	var start := mother.global_position
	var stopped := ""
	for _i in range(200):
		await physics_frame
		await process_frame
		var current := view.animation()
		if current[1] == "movimento": seen[current[2]] = true
		if not seen.is_empty() and not view.walking:
			stopped = current[1]
			break
	_check(mother.global_position.distance_to(start) > 30.0, "%s: Guardiã avançou até o jogador (%.0f px)" % [label, mother.global_position.distance_to(start)])
	_check(seen.size() == frames, "%s: andando, os %d quadros de movimento aparecem (%s)" % [label, frames, str(seen.keys())])
	_check(stopped in ["idle", "ataque"], "%s: ao parar, sai do movimento (%s)" % [label, stopped])
	await _done(mother)

# Golpe real: aviso com os quadros de preparo, o golpe resolve no quadro de contato no fim do
# aviso (tempo de sempre), o resto depois. Na Onda, o único dano no jogador cai nesse passo.
func _attack_in_game(move: int, phase_two: bool) -> void:
	var mother: MotherOfWhispers = await _mother_phase_two() if phase_two else _mother()
	_place_player(mother.global_position + Vector2(0, 90))
	mother.move_index = (MotherOfWhispers.PHASE_TWO if phase_two else MotherOfWhispers.PHASE_ONE).find(move)
	mother.move_recover = 0.0
	var trace := await _trace(mother, 110)
	var name: String = ["rajada", "manchas", "onda", "raizes"][move]
	var group := "fase2" if phase_two else "fase1"
	var label := "%s %s" % ["fase 2" if phase_two else "fase 1", name]
	var contact := MotherOfWhispers.ATTACK_CONTACT_FRAME_F2 if phase_two else MotherOfWhispers.ATTACK_CONTACT_FRAME
	var start := -1
	var resolved: Array[int] = []
	for index in range(trace.size()):
		if start < 0 and float(trace[index][2]) >= 0.0: start = index
		if trace[index][3]: resolved.append(index)
	_check(resolved.size() == 1 and start >= 0, "%s: um golpe resolvido (%d)" % [label, resolved.size()])
	if resolved.is_empty() or start < 0:
		await _done(mother)
		return
	var hit := resolved[0]
	_check(trace[hit][0] == [group, "ataque", contact] and trace[hit - 1][4] == name, "%s: golpe resolve com o quadro %d (contato) (%s)" % [label, contact + 1, str(trace[hit][0])])
	var windup := float(MotherOfWhispers.MOVE_WINDUP[move]) * (0.85 if phase_two else 1.0)
	_check(absi((hit - start) - ceili(windup * 60.0 - 0.001)) <= 1, "%s: aviso de %.2f s como antes (%d quadros de física)" % [label, windup, hit - start])
	var order: Array[int] = []
	for index in range(start, trace.size()):
		var current: Array = trace[index][0]
		if current[1] != "ataque": break
		if order.is_empty() or order.back() != current[2]: order.append(int(current[2]))
	_check(order == [0, 1, 2, 3, 4, 5], "%s: 6 quadros na ordem (%s)" % [label, str(order)])
	var after := ""
	for index in range(hit, trace.size()):
		if trace[index][0][1] != "ataque":
			after = trace[index][0][1]
			break
	_check(after in ["movimento", "idle"], "%s: termina no repouso/movimento (%s)" % [label, after])
	if move == MotherOfWhispers.Move.WAVE:
		var damaged: Array[int] = []
		for index in range(trace.size()):
			if int(trace[index][1]) > 0: damaged.append(index)
		_check(damaged == [hit], "%s: um único dano no jogador, no passo do contato (%s, contato %d)" % [label, str(damaged), hit])
	if move == MotherOfWhispers.Move.ROOTS:
		var roots := int(trace[hit][5])
		_check(roots == 6 and int(trace[hit - 1][5]) == 0, "%s: a fileira de 6 raízes continua com aviso no chão (%d)" % [label, roots])
	await _done(mother)

# Dano com a Guardiã viva: neutra → impacto → recuperação e volta ao repouso, nas duas fases.
func _hurt(phase_two: bool) -> void:
	var mother: MotherOfWhispers = await _mother_phase_two() if phase_two else _mother()
	mother.set_physics_process(false)
	await process_frame
	var view := mother.view as MotherOfWhispersView
	var group := "fase2" if phase_two else "fase1"
	var label := "fase 2" if phase_two else "fase 1"
	view.hurt_time = -1.0
	mother.receive_damage(10)
	_check(mother.health.is_alive() and view.animation() == [group, "dano", 0], "%s: dano inicia a reação pela pose 1" % label)
	var seen: Array[int] = []
	var started := Time.get_ticks_msec()
	while view.hurt_frame() >= 0 and Time.get_ticks_msec() - started < 2000:
		if seen.is_empty() or seen.back() != view.hurt_frame(): seen.append(view.hurt_frame())
		await process_frame
	_check(seen == [0, 1, 2], "%s: reação toca os 3 quadros na ordem (%s)" % [label, str(seen)])
	_check(view.animation()[1] == "idle", "%s: termina e volta ao repouso" % label)
	view.hurt_time = 0.25
	mother.receive_damage(10)
	_check(view.hurt_frame() == 1, "%s: golpe durante a reação volta ao quadro de impacto" % label)
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

# Abaixo de 50%: a transformação toca os 6 quadros na ordem durante a pausa de sempre (a
# Guardiã fica parada e invulnerável, sem o tom genérico da troca), e a fase 2 começa no
# repouso logo depois.
func _transformation() -> void:
	var mother := _mother(99.0)
	_place_player(mother.global_position + Vector2(0, 150))
	var view := mother.view as MotherOfWhispersView
	await physics_frame
	mother.health.damage(roundi(mother.health.maximum * 0.55))
	var frames: Array[int] = []
	var steps := 0
	var after: Array = []
	var still := true
	var white := true
	var start := mother.global_position
	for _i in range(120):
		await physics_frame
		await process_frame
		var current := view.animation()
		if current[0] == "transformacao":
			steps += 1
			if frames.is_empty() or frames.back() != current[2]: frames.append(int(current[2]))
			white = white and mother.modulate == Color.WHITE
			still = still and mother.invulnerable and mother.attack_time < 0.0
		elif not frames.is_empty():
			after = current
			break
	_check(mother.phases.phase == 2 and view._shown_phase == 2, "abaixo de 50%: fase 2 (Vozes do Fundo)")
	_check(frames == [0, 1, 2, 3, 4, 5], "transformação toca os 6 quadros na ordem (%s)" % str(frames))
	var pause := float(FloorCatalog.BOSS_PHASES.transition)
	_check(absi(steps - roundi(pause * 60.0)) <= 2, "transformação dura a pausa de sempre (%.1f s; %d quadros de física)" % [pause, steps])
	_check(still and mother.global_position.distance_to(start) < 1.0, "durante a transformação ela fica parada, invulnerável e sem atacar")
	_check(white, "transformação com as cores da arte, sem o tom genérico da troca de fase")
	_check(after.size() == 3 and after[0] == "fase2" and after[1] in ["idle", "ataque", "movimento"], "depois da transformação começa a fase 2 (%s)" % str(after))
	await _done(mother)

# Derrota na fase 1 (sem folha de morte): o quadro atual fica parado enquanto ela some.
func _defeat_phase_one() -> void:
	var mother := _mother()
	mother.set_physics_process(false)
	await process_frame
	var view := mother.view as MotherOfWhispersView
	mother.health.damage(mother.health.current)
	var frame := view.phase_one_animation()
	for _i in range(4): await process_frame
	_check(is_instance_valid(view) and view.phase_one_animation() == frame and view.modulate.a < 1.0, "fase 1: derrota congela o quadro atual e some (%s)" % str(frame))
	await create_timer(1.2).timeout
	_check(not is_instance_valid(mother), "fase 1: Guardiã sai de cena depois de sumir")
	_check(bool(main.progress.floor_states["3"].guardian_defeated), "derrota da Guardiã fica registrada no andar (save)")

# Derrota na fase 2: morte nos 6 quadros, inteira até o último, some e sai de cena em 1 s.
func _death_phase_two() -> void:
	var mother: MotherOfWhispers = await _mother_phase_two()
	mother.set_physics_process(false)
	await process_frame
	var view := mother.view as MotherOfWhispersView
	mother.receive_damage(10)
	mother.receive_damage(mother.health.current + 100)
	_check(not mother.health.is_alive() and view.animation() == ["fase2", "morte", 0] and view.hurt_frame() == -1, "fase 2: golpe fatal vai direto para a morte, sem reação de dano")
	var seen: Array[int] = []
	var alpha_at_last := -1.0
	var started := Time.get_ticks_msec()
	while is_instance_valid(mother) and Time.get_ticks_msec() - started < 3000:
		var frame: int = view.animation()[2]
		if seen.is_empty() or seen.back() != frame:
			seen.append(frame)
			if frame == 5: alpha_at_last = view.modulate.a
		await process_frame
	_check(seen == [0, 1, 2, 3, 4, 5], "fase 2: morte toca os 6 quadros na ordem (%s)" % str(seen))
	_check(alpha_at_last == 1.0, "fase 2: Guardiã caída aparece inteira antes de sumir")
	_check(not is_instance_valid(mother), "fase 2: Guardiã sai de cena em cerca de 1 s (%d ms)" % (Time.get_ticks_msec() - started))
	_check(bool(main.progress.floor_states["3"].guardian_defeated), "derrota na fase 2 fica registrada no andar (save)")

# ── Prévia ────────────────────────────────────────────────────────────────────
# No jogo, 360x800, 30 quadros por segundo de jogo: fase 1 (repouso, aproximação, golpes,
# dano), transformação, fase 2 (repouso, golpes, dano) e morte. A vista avança 1/60 s por
# passo de física para a animação seguir o tempo do jogo mesmo com a gravação lenta; na morte
# o tempo do jogo desacelera só para a gravação acompanhar até ela sair de cena.
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
	for step in range(900):
		if step == 40:
			_place_player(home + Vector2(0, 260))
			mother.move_recover = 1.2
			aim.call()
		if step == 140 or step == 520:
			_place_player(mother.global_position + Vector2(0, 100))
			aim.call()
		# Golpes do jogador fora dos ataques da Guardiã; a troca de fase em 400 e o golpe
		# fatal em 820.
		var busy := mother.attack_time >= 0.0 or mother.move_windup > 0.0 or mother.phases.transitioning()
		if ((step >= 300 and step < 390) or (step >= 700 and step < 800)) and not busy and view.hurt_time < 0.0 and step - last_hurt >= 30:
			mother.receive_damage(25)
			last_hurt = step
		if step == 400: mother.health.damage(mother.health.current - roundi(mother.health.maximum * 0.45))
		if step == 820: mother.receive_damage(mother.health.current + 100)
		if step >= 820: Engine.time_scale = 0.05
		if step < 820: await physics_frame
		else: await process_frame
		if not is_instance_valid(mother): break
		view._process(1.0 / 60.0)
		var current := view.animation()
		states["%s %s" % [current[0], current[1]]] = true
		if step % 2 == 1: continue
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if index == 0: _check(image.get_size() == Vector2i(360, 800), "prévia gravada no jogo em 360x800")
		var screen: Vector2 = (main.get_viewport().get_canvas_transform() * view_center).round()
		var area := Rect2i(Vector2i(0, int(screen.y) - 230), Vector2i(360, 400)).intersection(Rect2i(0, 0, 360, 800))
		image.get_region(area).save_png(folder.path_join("%03d.png" % index))
		index += 1
	Engine.time_scale = 1.0
	_check(states.has("fase1 idle") and states.has("fase1 movimento") and states.has("fase1 ataque") and states.has("fase1 dano") and states.has("transformacao transformacao") and states.has("fase2 idle") and states.has("fase2 ataque") and states.has("fase2 dano") and states.has("fase2 morte"),
		"prévia passa pela fase 1, transformação, fase 2 e morte (%s)" % str(states.keys()))
	print("MAE prévia: %d quadros" % index)
	main.progress.floor_states["3"].guardian_defeated = false
	await _done(mother)
