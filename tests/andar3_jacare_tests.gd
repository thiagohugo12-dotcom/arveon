extends SceneTree

# Jacaré Ancião (Andar 3): as cinco folhas aprovadas (repouso 4, movimento 4, mordida 6,
# dano 3, morte 6) ligadas ao comportamento real do mini-chefe, com a mandíbula fechando no
# quadro 4 junto com a janela de acerto da mordida.
# Uso: godot --path . --resolution 360x800 -s res://tests/andar3_jacare_tests.gd
# Com QA_RENDER_DIR=<pasta>, grava também a prévia (<pasta>/jacare/NNN.png).
const DIR := "res://art_source/andar3/18-22_JACARE_ANCIAO/"
const SOURCES := {
	"idle": DIR + "18_JACARE_IDLE_4_QUADROS.png",
	"movimento": DIR + "19_JACARE_MOVIMENTO_4_QUADROS.png",
	"ataque": DIR + "20_JACARE_ATAQUE_6_QUADROS.png",
	"dano": DIR + "21_JACARE_DANO_3_QUADROS.png",
	"morte": DIR + "22_JACARE_MORTE_6_QUADROS.png"}
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
	if condition: print("JACARE OK: " + label)
	else:
		failures += 1
		push_error("JACARE FALHA: " + label)

func _run() -> void:
	out = OS.get_environment("QA_RENDER_DIR")
	save_path = "user://qa_jacare_%d.json" % Time.get_ticks_usec()
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
	_check(main.progress.ascension.current_floor == 3 and main.world is Andar3World, "Jacaré testado dentro do Pântano das Vozes (Andar 3)")
	await _idle()
	await _walk_in_game()
	await _bite_in_game(-1.0, false)
	await _bite_in_game(1.0, false)
	await _bite_in_game(-1.0, true)
	await _charge_in_game()
	await _tail_in_game()
	await _hurt()
	await _hurt_during_attacks()
	await _death()
	await _death_during_windup()
	if not out.is_empty(): await _record_preview()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("ARVEON_SAVE_PATH")
	print("JACARE_RESULT checks=%d failures=%d" % [checks, failures])
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
	_check(manifest.get("status", "") == "conjunto_completo", "Jacaré Ancião marcado como conjunto completo no manifesto")
	var hashes := {}
	for entry: Dictionary in manifest.spritesheets: hashes[String(entry.arquivo)] = entry.sha256
	var originals_ok := true
	for name: String in SOURCES:
		var path := ProjectSettings.globalize_path(SOURCES[name])
		var image := Image.load_from_file(path)
		originals_ok = originals_ok and image != null and image.get_size() == Vector2i(2048, 682) and FileAccess.get_sha256(path) == hashes.get(String(SOURCES[name]).get_file(), "")
	_check(originals_ok, "as 5 folhas originais estão em art_source sem alteração (2048x682, sha256 do pacote)")
	var neutral := {}
	var mean := {}
	for name: String in Floor3MonsterView.CAIMAN:
		var sheet: Array = Floor3MonsterView.CAIMAN[name]
		var texture: Texture2D = sheet[0]
		var cell: Vector2i = sheet[1]
		var anchor: Vector2i = sheet[2]
		var frames: int = sheet[3]
		var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/andar3/derived/jacare_%s.json" % name))
		_check(texture.get_size() == Vector2(cell.x * frames, cell.y) and int(meta.frames) == frames and Vector2i(int(meta.cell[0]), int(meta.cell[1])) == cell and Vector2i(int(meta.anchor[0]), int(meta.anchor[1])) == anchor,
			"%s: %d células de %dx%d, iguais às da ferramenta" % [name, frames, cell.x, cell.y])
		var image := texture.get_image()
		var lows: Array[int] = []
		var edges_clear := true
		var areas: Array[int] = []
		for frame in range(frames):
			var region := image.get_region(Rect2i(frame * cell.x, 0, cell.x, cell.y))
			var used := region.get_used_rect()
			areas.append(_area(region))
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
		_check(follows and lows[0] - anchor.y >= 0 and lows[0] - anchor.y <= 18, "%s: patas no chão como na folha (base %s, folha %s; garras %d px abaixo da âncora)" % [name, str(lows.map(func(v: int) -> int: return v - lows[0])), str(drawn), lows[0] - anchor.y])
		neutral[name] = areas[0]
		var sum := 0.0
		for area in areas: sum += area
		mean[name] = sum / areas.size()
	var same := true
	for name: String in ["ataque", "dano", "morte"]: same = same and absf(float(neutral[name]) / float(neutral.idle) - 1.0) <= 0.04
	_check(same, "pose 1 com a mesma área no repouso, mordida, dano e morte (%s px²)" % str(neutral))
	_check(absf(float(mean.movimento) / float(mean.idle) - 1.0) <= 0.04, "movimento com a área média do repouso (%.0f x %.0f px²)" % [mean.movimento, mean.idle])
	var static_area := _area((load("res://assets/art/andar3/monsters/jacare_anciao.png") as Texture2D).get_image())
	_check(absf(float(neutral.idle) / float(static_area) - 1.0) <= 0.03, "repouso do tamanho do Jacaré estático anterior (%d x %d px²)" % [neutral.idle, static_area])

# ── Ajudantes ─────────────────────────────────────────────────────────────────
func _caiman(recover := 0.0) -> AncientCaiman:
	var caiman := main._make_enemy(11) as AncientCaiman
	caiman.position = Floor3Layout.CAIMAN_HOME
	caiman.target = main.player
	caiman.arena = Floor3Layout.CAIMAN_ARENA
	main._register_enemy_defeat(caiman)
	main.add_child(caiman)
	caiman.recover = recover
	return caiman

func _place_player(at: Vector2) -> void:
	main.player.global_position = at
	main.player.velocity = Vector2.ZERO
	main.player.health.initialize(99999)
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled = false
	camera.reset_smoothing()
	camera.force_update_scroll()

func _done(caiman: AncientCaiman) -> void:
	if is_instance_valid(caiman): caiman.queue_free()
	await process_frame

# Golpe completo com a física do jogo: [animação, dano, relógio da mordida, lado, recuperação].
func _trace(caiman: AncientCaiman, steps: int) -> Array:
	var view := caiman.view as Floor3MonsterView
	var health: Variant = main.player.health
	var trace: Array = []
	for _i in range(steps):
		var before: int = health.current
		await physics_frame
		trace.append([view.caiman_animation(), before - int(health.current), caiman.bite_time, view.caiman_flipped, caiman.recover, view.telegraph])
	return trace

func _hits(trace: Array) -> Array[int]:
	var hits: Array[int] = []
	for index in range(trace.size()):
		if int(trace[index][1]) > 0: hits.append(index)
	return hits

# ── Comportamento ─────────────────────────────────────────────────────────────
# Parado (sem IA): o repouso repete os 4 quadros na ordem.
func _idle() -> void:
	var caiman := _caiman()
	caiman.set_physics_process(false)
	await process_frame
	var view := caiman.view as Floor3MonsterView
	_check(view is Floor3MonsterView and view.caiman_animation() == ["idle", 0], "Jacaré criado pelo _make_enemy do mini-chefe começa no repouso")
	var seen: Array[int] = []
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 1000:
		var current := view.caiman_animation()
		if current[0] == "idle" and (seen.is_empty() or seen.back() != current[1]): seen.append(int(current[1]))
		await process_frame
	_check(seen.slice(0, 5) == [0, 1, 2, 3, 0], "repouso em loop: 1 → 2 → 3 → 4 → 1 (%s)" % str(seen))
	await _done(caiman)

# Na recuperação, com o jogador longe dentro da arena: anda até ele pelos 4 quadros e para
# a 110 px, voltando ao repouso.
func _walk_in_game() -> void:
	_place_player(Floor3Layout.CAIMAN_HOME + Vector2(-160, 0))
	var caiman := _caiman(3.0)
	var view := caiman.view as Floor3MonsterView
	var seen := {}
	var start := caiman.global_position
	var stopped := false
	for _i in range(120):
		await physics_frame
		await process_frame
		var current := view.caiman_animation()
		if current[0] == "movimento": seen[current[1]] = true
		if not seen.is_empty() and not view.walking:
			stopped = current[0] == "idle"
			break
	_check(caiman.global_position.distance_to(start) > 30.0, "Jacaré avançou até o jogador (%.0f px)" % caiman.global_position.distance_to(start))
	_check(seen.has(0) and seen.has(1) and seen.has(2) and seen.has(3), "andando, os 4 quadros de movimento aparecem (%s)" % str(seen.keys()))
	_check(stopped, "ao parar perto do jogador, volta ao repouso")
	await _done(caiman)

# Mordida real: aviso (quadros 1–3), um único dano com o quadro 4 no fim do aviso (0,65 s;
# 0,455 s na fúria), quadros 5–6 na recuperação, e a arte virada para o jogador.
func _bite_in_game(side: float, enraged: bool) -> void:
	_place_player(Floor3Layout.CAIMAN_HOME + Vector2(70 * side, 0))
	var caiman := _caiman()
	if enraged: caiman.health.damage(roundi(caiman.health.maximum * 0.65))
	var trace := await _trace(caiman, 100)
	var hits := _hits(trace)
	var start := -1
	for index in range(trace.size()):
		if start < 0 and float(trace[index][2]) >= 0.0: start = index
	var label := ("à direita" if side > 0 else "à esquerda") + (" na fúria" if enraged else "")
	_check(hits.size() == 1, "mordida %s: exatamente um dano (%d)" % [label, hits.size()])
	if hits.is_empty() or start < 0:
		await _done(caiman)
		return
	var hit := hits[0]
	_check(trace[hit][0] == ["ataque", AncientCaiman.BITE_CONTACT_FRAME] and trace[hit][5] == "mordida", "mordida %s: dano com o quadro 4 (mandíbula fechando) (%s)" % [label, str(trace[hit][0])])
	var windup := float(AncientCaiman.WINDUPS[0]) * (0.7 if enraged else 1.0)
	_check(absi((hit - start) - (ceili(windup * 60.0 - 0.001) + 1)) <= 1, "mordida %s: aviso de %.3f s como antes (%d quadros de física)" % [label, windup, hit - start])
	var order: Array[int] = []
	for index in range(start, trace.size()):
		var current: Array = trace[index][0]
		if current[0] != "ataque": break
		if order.is_empty() or order.back() != current[1]: order.append(int(current[1]))
	_check(order == [0, 1, 2, 3, 4, 5], "mordida %s: 6 quadros na ordem (%s)" % [label, str(order)])
	var after := ""
	for index in range(hit, trace.size()):
		if trace[index][0][0] != "ataque":
			after = trace[index][0][0]
			break
	_check(after in ["movimento", "idle"], "mordida %s: termina no repouso/passos (%s)" % [label, after])
	_check(bool(trace[hit][3]) == (side > 0), "mordida %s com a arte virada para o jogador" % label)
	await _done(caiman)

# Investida: aviso no repouso, corrida com os passos acelerados, um dano; sem quadros da
# mordida.
func _charge_in_game() -> void:
	_place_player(Floor3Layout.CAIMAN_HOME + Vector2(160, 0))
	var caiman := _caiman()
	var trace := await _trace(caiman, 110)
	var hits := _hits(trace)
	var sheets := {}
	var running := {}
	for step: Array in trace:
		if step[5] == "investida": sheets[step[0][0]] = true
		if step[0][0] == "movimento": running[step[0][1]] = true
	_check(hits.size() == 1, "investida: exatamente um dano (%d)" % hits.size())
	_check(not sheets.has("ataque") and sheets.has("idle") and sheets.has("movimento"), "investida: aviso no repouso e corrida no movimento, sem quadros da mordida (%s)" % str(sheets.keys()))
	_check(running.size() == 4, "corrida passa pelos 4 quadros de movimento (%s)" % str(running.keys()))
	await _done(caiman)

# Golpe de cauda: sem folha própria. O aviso circular aparece sobre o repouso e o dano
# continua igual (um acerto).
func _tail_in_game() -> void:
	_place_player(Floor3Layout.CAIMAN_HOME + Vector2(-70, 0))
	var caiman := _caiman()
	caiman.cycle = 2
	var trace := await _trace(caiman, 70)
	var sheets := {}
	var tail := false
	for step: Array in trace:
		if step[5] == "cauda":
			tail = true
			sheets[step[0][0]] = true
	_check(tail and _hits(trace).size() == 1, "golpe de cauda continua com aviso e um dano (%d)" % _hits(trace).size())
	_check(sheets.keys() == ["idle"], "golpe de cauda mostra o repouso, sem animação inventada (%s)" % str(sheets.keys()))
	await _done(caiman)

# Dano real com o Jacaré vivo: neutra → impacto → recuperação e volta ao repouso.
func _hurt() -> void:
	var caiman := _caiman()
	caiman.set_physics_process(false)
	await process_frame
	var view := caiman.view as Floor3MonsterView
	caiman.receive_damage(10)
	_check(caiman.health.is_alive() and view.caiman_animation() == ["dano", 0], "dano inicia a reação pela pose 1")
	var seen: Array[int] = []
	var started := Time.get_ticks_msec()
	while view.caiman_hurt_frame() >= 0 and Time.get_ticks_msec() - started < 2000:
		if seen.is_empty() or seen.back() != view.caiman_hurt_frame(): seen.append(view.caiman_hurt_frame())
		await process_frame
	_check(seen == [0, 1, 2], "reação toca os 3 quadros na ordem (%s)" % str(seen))
	_check(view.caiman_animation()[0] == "idle", "termina e volta ao repouso")
	view.caiman_hurt_time = 0.25
	caiman.receive_damage(10)
	_check(view.caiman_hurt_frame() == 1, "golpe durante a reação volta ao quadro de impacto")
	await _done(caiman)

# Aviso e fechamento da mordida e a investida não são cortados pelo dano; com a mandíbula
# voltando, o dano aparece.
func _hurt_during_attacks() -> void:
	var caiman := _caiman()
	caiman.set_physics_process(false)
	await process_frame
	var view := caiman.view as Floor3MonsterView
	caiman.bite_time = 0.15
	caiman.receive_damage(10)
	_check(view.caiman_animation() == ["ataque", 1] and view.caiman_hurt_frame() == -1, "dano no aviso não interrompe a mordida")
	caiman.bite_time = 0.45
	caiman.receive_damage(10)
	_check(view.caiman_animation() == ["dano", 0], "dano com a mandíbula voltando mostra a reação")
	caiman.bite_time = -1.0
	view.caiman_hurt_time = -1.0
	caiman.act = AncientCaiman.Act.CHARGE
	caiman.active = 0.3
	caiman.receive_damage(10)
	_check(view.caiman_animation()[0] == "movimento" and view.caiman_hurt_frame() == -1, "dano na investida não interrompe a corrida")
	await _done(caiman)

# Golpe fatal: morte nos 6 quadros, termina caído, some e sai de cena.
func _death() -> void:
	var caiman := _caiman()
	caiman.set_physics_process(false)
	await process_frame
	var view := caiman.view as Floor3MonsterView
	caiman.receive_damage(10)
	caiman.receive_damage(caiman.health.current + 100)
	_check(not caiman.health.is_alive() and view.caiman_animation() == ["morte", 0] and view.caiman_hurt_frame() == -1, "golpe fatal vai direto para a morte, sem reação de dano")
	var seen: Array[int] = []
	var alpha_at_last := -1.0
	var started := Time.get_ticks_msec()
	while is_instance_valid(caiman) and Time.get_ticks_msec() - started < 3000:
		var frame: int = view.caiman_animation()[1]
		if seen.is_empty() or seen.back() != frame:
			seen.append(frame)
			if frame == 5: alpha_at_last = view.modulate.a
		await process_frame
	_check(seen == [0, 1, 2, 3, 4, 5], "morte toca os 6 quadros na ordem (%s)" % str(seen))
	_check(alpha_at_last == 1.0, "Jacaré caído aparece inteiro antes de sumir")
	_check(not is_instance_valid(caiman), "Jacaré sai de cena no tempo de sempre (%d ms)" % (Time.get_ticks_msec() - started))

# Morrer no meio do aviso: vai para a morte e a mordida não acontece.
func _death_during_windup() -> void:
	_place_player(Floor3Layout.CAIMAN_HOME + Vector2(-70, 0))
	var caiman := _caiman()
	var view := caiman.view as Floor3MonsterView
	var started := Time.get_ticks_msec()
	while caiman.bite_time < 0.1 and Time.get_ticks_msec() - started < 3000: await physics_frame
	caiman.receive_damage(caiman.health.current + 100)
	_check(view.caiman_animation()[0] == "morte", "morte no meio do aviso troca para a morte")
	# A recompensa da derrota recalcula a vida do jogador; o dano conta só depois disso.
	await physics_frame
	var hp: int = main.player.health.current
	for _i in range(50): await physics_frame
	_check(int(main.player.health.current) == hp and caiman.bite_time < float(AncientCaiman.BITE_FRAME_STARTS[AncientCaiman.BITE_CONTACT_FRAME]), "mordida interrompida pela morte não acontece nem causa dano")
	await create_timer(1.2).timeout

# ── Prévia ────────────────────────────────────────────────────────────────────
# No jogo, 360x800, 30 quadros por segundo de jogo: repouso, aproximação, mordidas, dano
# recebido, investida e morte. A vista avança 1/60 s por passo de física para a animação
# seguir o tempo do jogo mesmo com a gravação lenta.
func _record_preview() -> void:
	var folder := out.path_join("jacare")
	DirAccess.make_dir_recursive_absolute(folder)
	var home := Floor3Layout.CAIMAN_HOME
	Engine.max_physics_steps_per_frame = 1
	_place_player(home + Vector2(0, 400))
	var caiman := _caiman()
	caiman.health.initialize(99999)
	var view := caiman.view as Floor3MonsterView
	view.set_process(false)
	var view_center := home + Vector2(0, -40)
	var camera := main.player.get_node("Camera2D") as Camera2D
	var aim := func() -> void:
		camera.offset = view_center - main.player.global_position
		camera.force_update_scroll()
	aim.call()
	var index := 0
	var states := {}
	var last_hurt := -99
	for step in range(500):
		if step == 60:
			_place_player(home + Vector2(-165, 20))
			caiman.recover = 1.6
			aim.call()
		# Depois da aproximação, o jogador fica ao alcance da mordida.
		if step == 140:
			_place_player(caiman.global_position + Vector2(-80, 10))
			aim.call()
		if step == 300:
			_place_player(home + Vector2(165, 20))
			caiman.cycle = 3
			aim.call()
		# Golpes do jogador fora dos ataques do Jacaré e, no fim, o golpe fatal. Na morte o
		# tempo do jogo desacelera só para a gravação acompanhar até ele sair de cena.
		var busy := caiman.bite_time >= 0.0 or caiman.windup > 0.0 or caiman.active > 0.0
		if ((step >= 250 and step < 290) or (step >= 395 and step < 420)) and not busy and view.caiman_hurt_time < 0.0 and step - last_hurt >= 24:
			caiman.receive_damage(25)
			last_hurt = step
		if step == 420: caiman.receive_damage(caiman.health.current + 100)
		if step >= 420: Engine.time_scale = 0.05
		if step < 420: await physics_frame
		else: await process_frame
		if not is_instance_valid(caiman): break
		view._process(1.0 / 60.0)
		states[view.caiman_animation()[0]] = true
		if step % 2 == 1: continue
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if index == 0: _check(image.get_size() == Vector2i(360, 800), "prévia gravada no jogo em 360x800")
		var screen: Vector2 = (main.get_viewport().get_canvas_transform() * view_center).round()
		var area := Rect2i(Vector2i(0, int(screen.y) - 170), Vector2i(360, 280)).intersection(Rect2i(0, 0, 360, 800))
		image.get_region(area).save_png(folder.path_join("%03d.png" % index))
		index += 1
	Engine.time_scale = 1.0
	_check(states.has("idle") and states.has("movimento") and states.has("ataque") and states.has("dano") and states.has("morte"), "prévia passa pelas 5 animações (%s)" % str(states.keys()))
	print("JACARE prévia: %d quadros" % index)
