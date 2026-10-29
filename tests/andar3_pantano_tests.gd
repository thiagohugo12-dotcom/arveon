extends SceneTree

# Andar 3 — Pântano das Vozes: validação jogável e capturas reais 360x800.
# Uso (janela, para as capturas): QA_RENDER_DIR=<pasta> godot --path . --resolution 360x800 -s res://tests/andar3_pantano_tests.gd
# Sem QA_RENDER_DIR roda só as verificações.
var failures := 0
var checks := 0
var out := ""
var main: Node2D
var save_path := ""

func _initialize() -> void:
	create_timer(300.0).timeout.connect(func():
		push_error("ANDAR3 FALHA: tempo limite do teste")
		quit(1))
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("ANDAR3 OK: " + label)
	else:
		failures += 1
		push_error("ANDAR3 FALHA: " + label)

func _frames(count: int) -> void:
	for _i in range(count): await process_frame

func _physics(count: int) -> void:
	for _i in range(count): await physics_frame

func _shot(name: String) -> Image:
	await _frames(4)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if not out.is_empty():
		_check(image.get_size() == Vector2i(360, 800), "captura real 360x800: " + name)
		image.save_png(out.path_join("andar3-%s.png" % name))
	return image

func _freeze_world() -> void:
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"):
		if actor is EnemyActor and actor != main.enemy:
			actor.queue_free()
	for hazard in get_nodes_in_group("swamp_hazards"): hazard.queue_free()

func _place_player(at: Vector2) -> void:
	main.player.global_position = at
	main.player.velocity = Vector2.ZERO
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.reset_smoothing()
	camera.force_update_scroll()

func _heal_player() -> void:
	main.player.health.initialize(99999)

func _monster(kind: int, at: Vector2) -> EnemyActor:
	var actor: EnemyActor = main._make_enemy(kind)
	actor.position = at
	actor.target = main.player
	main._register_enemy_defeat(actor)
	actor.projectile_requested.connect(main._on_enemy_projectile)
	main.add_child(actor)
	actor.view.damage_occluders = main.hud.damage_occluders
	return actor

func _run() -> void:
	out = OS.get_environment("QA_RENDER_DIR")
	if not out.is_empty(): DirAccess.make_dir_recursive_absolute(out)
	save_path = "user://qa_andar3_pantano_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	root.size = Vector2i(360, 800)
	root.content_scale_size = Vector2i(360, 800)
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	main.player.set_physics_process(false)
	main.progress.ascension.defeats["1"] = 50
	main.progress.ascension.complete_forest_trial()
	await main._travel_floor(2)
	main.progress.ascension.defeats["2"] = 50
	_check(main.progress.ascension.complete_forest_trial(), "a Torre existente libera o Andar 3")
	await main._travel_floor(3)
	_freeze_world()
	await _physics(2)
	# QA_PART=limo,jacare,... roda só as partes pedidas (padrão: todas).
	var parts := OS.get_environment("QA_PART").split(",", false)
	var steps := {"cena": _scene_and_assets, "navegacao": _navigation, "movimento": _movement_and_dash, "spawns": _spawns,
		"cenario": _scenery_shots, "limo": _slime, "sapo_vulto": _toad_and_wraith, "jacare": _caiman, "mae": _mother, "morte": _death_and_save}
	for name: String in steps:
		if not parts.is_empty() and not parts.has(name): continue
		var started := Time.get_ticks_msec()
		await (steps[name] as Callable).call()
		print("ANDAR3 parte %s: %.1f s" % [name, (Time.get_ticks_msec() - started) / 1000.0])
	_cleanup()
	print("ANDAR3_RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)

func _scene_and_assets() -> void:
	_check(main.progress.ascension.current_floor == 3 and main.world is Andar3World, "a viagem real carrega a cena do Pântano")
	var view := main.world.get_node("FloorView") as Floor3View
	_check(view != null and view.get_child_count() > 300, "cenário montado em camadas com peças separadas (%d nós)" % view.get_child_count())
	var missing := 0
	for path in ["res://assets/art/andar3/monsters/limo_idle.png", "res://assets/art/andar3/monsters/limo_ataque.png", "res://assets/art/andar3/monsters/sapo_venenoso.png", "res://assets/art/andar3/monsters/vulto_do_brejo.png", "res://assets/art/andar3/monsters/jacare_anciao.png", "res://assets/art/andar3/monsters/mae_dos_sussurros_fase1.png", "res://assets/art/andar3/monsters/mae_dos_sussurros_fase2.png", "res://assets/art/andar3/terrain/agua.png", "res://assets/art/andar3/props/ponte_longa.png", "res://assets/art/andar3/props/circulo_lunar.png"]:
		if not (load(path) is Texture2D): missing += 1
	_check(missing == 0, "artes derivadas do pacote importadas na Godot")
	var camera := main.player.get_node("Camera2D") as Camera2D
	_check(camera.limit_right == 2172 and camera.limit_bottom == 1626, "câmera limitada ao mundo do Pântano (2172x1626)")
	_check(main.hud.minimap._world_size() == Floor3Layout.WORLD_SIZE, "minimapa usa a extensão do Pântano")
	_check(Floor3Layout.bridge_spans().size() >= 12, "pontes do mapa aprovado medidas sobre a água (%d)" % Floor3Layout.bridge_spans().size())

func _navigation() -> void:
	const STEP := 16
	var query := PhysicsShapeQueryParameters2D.new()
	var body := CircleShape2D.new()
	body.radius = 13.0
	query.shape = body
	query.collision_mask = 1
	var space: PhysicsDirectSpaceState2D = main.player.get_world_2d().direct_space_state
	var free := func(point: Vector2) -> bool:
		query.transform = Transform2D(0.0, point)
		return space.intersect_shape(query, 1).is_empty()
	var start := Vector2i(roundi(Floor3Layout.RESPAWN.x / STEP), roundi(Floor3Layout.RESPAWN.y / STEP))
	var visited := {start: true}
	var open: Array[Vector2i] = [start]
	var cursor := 0
	while cursor < open.size():
		var cell: Vector2i = open[cursor]
		cursor += 1
		for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := cell + direction
			if next.x < 1 or next.y < 1 or next.x * STEP >= 2160 or next.y * STEP >= 1614 or visited.has(next): continue
			if not free.call(Vector2(next * STEP)): continue
			visited[next] = true
			open.append(next)
	var reachable := func(point: Vector2) -> bool:
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				if visited.has(Vector2i(roundi(point.x / STEP) + dx, roundi(point.y / STEP) + dy)): return true
		return false
	var area := visited.size() * STEP * STEP
	_check(area > 1200000, "área transitável ampla para explorar e combater (%d px²)" % area)
	for region: Dictionary in Floor3Layout.REGIONS:
		_check(reachable.call(region.center), "região acessível a partir do acampamento: " + str(region.name))
	var blocked := 0
	var blocked_points: Array = []
	for spawn: Vector2 in FloorCatalog.enemy_spawns(3):
		if not reachable.call(spawn):
			blocked += 1
			blocked_points.append(spawn)
	_check(blocked == 0, "todos os %d pontos de inimigos são alcançáveis (%d bloqueados %s)" % [FloorCatalog.enemy_spawns(3).size(), blocked, str(blocked_points)])
	_check(reachable.call(Floor3Layout.CAIMAN_HOME), "arena do Jacaré Ancião alcançável")
	_check(reachable.call(Floor3Layout.GUARDIAN_ALTAR + Vector2(0, 80)), "santuário lunar da Mãe dos Sussurros alcançável")
	_check(reachable.call(Floor3Layout.TOWER_POSITION + Vector2(0, 40)), "entrada da Torre alcançável")
	for station: String in Floor3Layout.STATIONS:
		_check(reachable.call(Floor3Layout.STATIONS[station] + Vector2(0, 30)), "serviço do acampamento alcançável: " + station)
	var bridges_ok := 0
	for span: Dictionary in Floor3Layout.bridge_spans():
		if free.call(span.center) and reachable.call(span.center): bridges_ok += 1
	_check(bridges_ok == Floor3Layout.bridge_spans().size(), "pontes transitáveis e ligadas à rede (%d/%d)" % [bridges_ok, Floor3Layout.bridge_spans().size()])
	var water_blocked := 0
	var water_points := 0
	for y in range(60, 1600, 97):
		for x in range(60, 2150, 113):
			var at := Vector2(x, y)
			if Floor3Layout.walkable(at) or Floor3Layout.walkable(at + Vector2(12, 0)) or Floor3Layout.walkable(at - Vector2(12, 0)) or Floor3Layout.walkable(at + Vector2(0, 12)) or Floor3Layout.walkable(at - Vector2(0, 12)): continue
			water_points += 1
			if not free.call(at): water_blocked += 1
	_check(water_points > 20 and water_blocked == water_points, "água funda bloqueia a passagem (%d/%d pontos)" % [water_blocked, water_points])

func _movement_and_dash() -> void:
	_place_player(Floor3Layout.RESPAWN)
	main.player.set_physics_process(true)
	var start: Vector2 = main.player.global_position
	main.input_driver.set_touch_direction(Vector2.RIGHT)
	await _physics(30)
	var walked: float = main.player.global_position.distance_to(start)
	_check(walked > 60.0, "joystick move o explorador no Pântano (%.0f px em 0,5 s)" % walked)
	var before_dash: Vector2 = main.player.global_position
	main.input_driver.request_dash()
	await _physics(12)
	var dashed: float = main.player.global_position.distance_to(before_dash)
	_check(dashed > walked * 0.45, "dash funciona sem travar (%.0f px em 0,2 s)" % dashed)
	main.input_driver.set_touch_direction(Vector2.ZERO)
	await _physics(4)
	main.player.set_physics_process(false)

func _spawns() -> void:
	var kinds := {}
	var off_grid := 0
	for spawn: Vector2 in [Vector2(1150, 960), Vector2(700, 400), Vector2(1850, 700)]:
		_place_player(spawn)
		for _i in range(4):
			main._spawn_enemy()
			main.spawn_count += 1
	for actor in get_nodes_in_group("damageable_enemies"):
		if actor is EnemyActor and actor != main.enemy:
			kinds[actor.kind] = true
			if not Floor3Layout.walkable(actor.global_position): off_grid += 1
	_check(kinds.has(8) and kinds.has(9) and kinds.has(10), "spawns reais do Pântano criam Limo, Sapo e Vulto")
	_check(off_grid == 0, "todos os inimigos nascem em terra firme")
	_freeze_world()
	await _physics(2)

func _scenery_shots() -> void:
	main.hud.show_notice("")
	for entry: Array in [["acampamento-entrada-encharcada", Floor3Layout.RESPAWN + Vector2(-60, 40)], ["lodacal-nebuloso", Vector2(1210, 1130)], ["bosque-afundado", Vector2(430, 540)], ["santuario-lunar", Vector2(1858, 380)]]:
		_place_player(entry[1])
		await _physics(2)
		await _shot(entry[0])

func _slime() -> void:
	_heal_player()
	_place_player(Vector2(1150, 980))
	var slime := _monster(8, Vector2(1240, 990))
	slime.set_physics_process(false)
	await _physics(2)
	var view := slime.view as Floor3MonsterView
	_check(view.slime != null and view.slime.animation == "idle" and view.slime.sprite_frames.get_frame_count("idle") == 4, "Limo usa a respiração aprovada (4 quadros, em loop)")
	_check(view.slime.sprite_frames.get_frame_count("ataque") == 6 and not view.slime.sprite_frames.get_animation_loop("ataque"), "ataque do Limo tem 6 quadros e não repete em loop")
	# Sequência real da respiração dentro do jogo.
	var idle_frames: Array[Image] = []
	for frame in range(4):
		view.slime.pause()
		view.slime.frame = frame
		var image := await _shot("limo-idle-quadro-%d" % (frame + 1)) if frame == 0 else await _grab()
		idle_frames.append(image)
	view.slime.play("idle")
	await _shot("limo-do-brejo-idle")
	# Ataque real: o ator decide, a animação toca e o dano sai no quadro de impacto.
	var hits: Array[int] = []
	var impact_frames: Array[int] = []
	var hp_state := {"before": main.player.health.current}
	var on_damage := func(current: int, _maximum: int):
		if current < int(hp_state.before): hits.append(view.slime.frame if view.slime.animation == "ataque" else -1)
		hp_state.before = current
	main.player.health.changed.connect(on_damage)
	view.impact.connect(func(): impact_frames.append(view.slime.frame))
	_place_player(Vector2(1196, 990))
	slime.set_physics_process(true)
	var order: Array[int] = []
	var restarted := false
	for _step in range(150):
		await physics_frame
		if view.slime.animation == "ataque":
			if order.is_empty() or order[-1] != view.slime.frame:
				if not order.is_empty() and view.slime.frame < order[-1]: restarted = true
				order.append(view.slime.frame)
		if (slime as SwampEnemy).attack_cooldown > 0.0 and not (slime as SwampEnemy).slime_attacking and order.size() >= 6: break
	main.player.health.changed.disconnect(on_damage)
	_check(order == [0, 1, 2, 3, 4, 5], "os 6 quadros do ataque tocam em ordem dentro do jogo (%s)" % str(order))
	_check(impact_frames == [3], "impacto avisado no 4º quadro, uma única vez (%s)" % str(impact_frames))
	_check(hits.size() == 1 and hits[0] == 3, "dano sincronizado com o quadro de impacto, sem dano duplicado (%s)" % str(hits))
	_check(not restarted and view.slime.animation == "idle", "ataque não reinicia no meio e volta para a respiração")
	_check(get_nodes_in_group("swamp_hazards").size() >= 1, "golpe deixa mancha de lodo temporária")
	# Quadros do ataque capturados no jogo, um a um, para a prancha de conferência.
	slime.set_physics_process(false)
	var attack_images: Array[Image] = []
	view.slime.play("ataque")
	for frame in range(6):
		view.slime.pause()
		view.slime.frame = frame
		view._place_slime()
		attack_images.append(await _shot("limo-do-brejo-atacando") if frame == 3 else await _grab())
	view.slime.play("idle")
	view._place_slime()
	if not out.is_empty():
		_strip(idle_frames, slime, "limo-sequencia-idle")
		_strip(attack_images, slime, "limo-sequencia-ataque")
	slime.queue_free()
	_freeze_world()
	await _physics(2)

func _grab() -> Image:
	await _frames(2)
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

# Recorte da área do Limo em cada captura, lado a lado, para ver a animação em sequência.
func _strip(images: Array[Image], actor: EnemyActor, name: String) -> void:
	var camera := main.player.get_node("Camera2D") as Camera2D
	var screen := actor.get_global_transform_with_canvas().origin
	var area := Rect2i(Vector2i(screen) + Vector2i(-80, -110), Vector2i(170, 130)).intersection(Rect2i(0, 0, 360, 800))
	var strip := Image.create(area.size.x * images.size(), area.size.y, false, Image.FORMAT_RGBA8)
	for index in range(images.size()):
		strip.blit_rect(images[index], area, Vector2i(index * area.size.x, 0))
	strip.save_png(out.path_join("andar3-%s.png" % name))
	if camera == null: return

func _toad_and_wraith() -> void:
	_heal_player()
	_place_player(Vector2(1250, 1170))
	var toad := _monster(9, Vector2(1340, 1110))
	var wraith := _monster(10, Vector2(1190, 1080))
	var slime := _monster(8, Vector2(1230, 1280))
	for actor in [toad, wraith, slime]: actor.set_physics_process(false)
	toad.view.set_facing(Vector2.LEFT)
	wraith.view.set_facing(Vector2.RIGHT)
	await _physics(2)
	await _shot("tres-monstros-comuns")
	slime.queue_free()
	_place_player(Vector2(1150, 1000))
	toad.global_position = Vector2(1290, 1000)
	# Sapo: guarda distância e dispara.
	wraith.queue_free()
	toad.set_physics_process(true)
	var shots := 0
	for _i in range(200):
		await physics_frame
		for node in main.get_children():
			if node is EnemyProjectile and not node.has_meta("counted"):
				node.set_meta("counted", true)
				shots += 1
		if shots >= 1: break
	_check(shots >= 1, "Sapo Venenoso dispara projéteis de veneno")
	toad.global_position = main.player.global_position + Vector2(60, 0)
	await _physics(30)
	_check(toad.global_position.distance_to(main.player.global_position) > 80.0, "Sapo salta para longe quando o jogador se aproxima")
	toad.queue_free()
	_freeze_world()
	await _physics(2)
	# Vulto: aproxima, golpeia e recua.
	_heal_player()
	wraith = _monster(10, main.player.global_position + Vector2(150, 0))
	var hp: int = main.player.health.current
	var struck := false
	var retreated := false
	for _i in range(200):
		await physics_frame
		if main.player.health.current < hp: struck = true
		if struck and (wraith as SwampEnemy).retreat_left > 0.0: retreated = true
		if retreated: break
	_check(struck, "Vulto do Brejo alcança e golpeia o jogador")
	_check(retreated, "Vulto recua depois do golpe para se reposicionar")
	wraith.queue_free()
	_freeze_world()
	await _physics(2)

func _caiman() -> void:
	_heal_player()
	_place_player(Vector2(1150, 980))
	main.mini_boss_respawn_left = 0.0
	main._update_mini_boss(0.1)
	var caiman := main.mini_boss as AncientCaiman
	_check(is_instance_valid(caiman) and caiman.kind == 11, "Jacaré Ancião aparece no Bosque Afundado")
	if not is_instance_valid(caiman): return
	await _physics(2)
	_check(caiman.global_position.distance_to(Floor3Layout.CAIMAN_HOME) < 4.0, "Jacaré nasce na própria arena")
	_check((caiman.get_node("Collision") as CollisionShape2D).shape.get("radius") >= 30.0, "hitbox do Jacaré compatível com o tamanho")
	# Perto (mordida e cauda) e depois longe dentro da arena (investida).
	var spots := [Floor3Layout.CAIMAN_HOME + Vector2(0, 80), Floor3Layout.CAIMAN_HOME + Vector2(160, 60)]
	var telegraphs := {}
	var hp: int = main.player.health.current
	var shot_taken := false
	_place_player(spots[0])
	for _i in range(600):
		await physics_frame
		var view := caiman.view as Floor3MonsterView
		if not view.telegraph.is_empty():
			if not telegraphs.has(view.telegraph): print("ANDAR3 aviso do Jacaré: ", view.telegraph)
			telegraphs[view.telegraph] = true
			if not shot_taken and view.telegraph == "mordida":
				shot_taken = true
				await _shot("jacare-anciao")
		if telegraphs.size() >= 3: break
		if _i == 300: _place_player(spots[1])
	_check(telegraphs.has("mordida") and (telegraphs.has("investida") or telegraphs.has("cauda")), "golpes do Jacaré têm aviso visual antes (%s)" % str(telegraphs.keys()))
	_check(main.player.health.current < hp, "Jacaré causa dano de mini-chefe")
	var calm_windup := float(AncientCaiman.WINDUPS[0])
	caiman.health.damage(roundi(caiman.health.maximum * 0.65))
	_check(caiman.enraged(), "Jacaré fica mais agressivo com pouca vida")
	caiman.windup = 0.0
	caiman.active = 0.0
	caiman.recover = 0.0
	_place_player(caiman.global_position + Vector2(0, 80))
	await _physics(2)
	_check(caiman.windup > 0.0 and caiman.windup < calm_windup, "aviso mais curto na fúria (%.2f s)" % caiman.windup)
	caiman.health.damage(caiman.health.current)
	await _physics(4)
	_check(main.mini_boss_respawn_left > 0.0, "Jacaré derrotado reaparece depois do intervalo (combate repetível)")
	_freeze_world()
	await _physics(2)

func _mother() -> void:
	_heal_player()
	_place_player(Floor3Layout.GUARDIAN_ALTAR + Vector2(0, 30))
	var target: Dictionary = main._interaction_target()
	_check(str(target.get("kind", "")) == "guardian", "altar do santuário oferece o desafio da Guardiã")
	main._start_guardian()
	var mother := main.guardian as MotherOfWhispers
	_check(is_instance_valid(mother), "Mãe dos Sussurros surge no santuário lunar")
	if not is_instance_valid(mother): return
	_check(mother.health.maximum == 840, "vida efetiva da Guardiã: 840 (400 x 2,1)")
	_place_player(mother.global_position + Vector2(0, 150))
	var telegraphs := {}
	var phase_one_shot := false
	for _i in range(420):
		await physics_frame
		var view := mother.view as MotherOfWhispersView
		if not view.telegraph.is_empty():
			telegraphs[view.telegraph] = true
			if not phase_one_shot and view.telegraph == "onda":
				phase_one_shot = true
				await _boss_shot("mae-dos-sussurros-fase-1")
		if telegraphs.size() >= 3 and phase_one_shot: break
	_check(telegraphs.has("rajada") and telegraphs.has("manchas") and telegraphs.has("onda"), "fase 1: Rajada de Lodo, Manchas do Brejo e onda avisadas (%s)" % str(telegraphs.keys()))
	mother.health.damage(roundi(mother.health.maximum * 0.55))
	await _physics(80)
	_check(mother.phases.phase == 2 and (mother.view as MotherOfWhispersView)._shown_phase == 2, "abaixo de 50%: fase 2 com a arte oficial da fase 2")
	var roots := false
	var phase_two_shot := false
	for _i in range(420):
		await physics_frame
		for hazard in get_nodes_in_group("swamp_hazards"):
			if (hazard as SwampHazard).style == "raiz": roots = true
		if roots and not phase_two_shot:
			phase_two_shot = true
			await _boss_shot("mae-dos-sussurros-fase-2")
		if roots: break
	_check(roots, "fase 2: Raízes emergentes com aviso no chão")
	mother.health.damage(mother.health.current)
	await _physics(6)
	_check(bool(main.progress.floor_states["3"].guardian_defeated), "derrota da Guardiã fica registrada no andar (save)")
	_freeze_world()
	await _physics(2)

func _death_and_save() -> void:
	_place_player(Vector2(1150, 980))
	main.player.health.initialize(100)
	main.player.health.damage(1000)
	await _physics(4)
	_check(main.hud.death_panel.visible, "morte mostra a tela de derrota existente")
	main.progress.save()
	var loaded := GameProgress.new()
	loaded.save_path = save_path
	_check(loaded.load_save() and loaded.ascension.current_floor == 3, "save/load mantém o jogador no Andar 3")
	_check(SafeCamp.respawn_for_floor(3) == Floor3Layout.RESPAWN and SafeCamp.area_for_floor(3).has_point(Floor3Layout.RESPAWN), "retorno da morte cai no acampamento seguro do Pântano")

func _cleanup() -> void:
	var absolute := ProjectSettings.globalize_path(save_path)
	if FileAccess.file_exists(save_path): DirAccess.remove_absolute(absolute)

# A Guardiã é grande: a câmera do jogo sobe um pouco só na foto para ela não ficar sob o HUD.
func _boss_shot(name: String) -> void:
	var camera := main.player.get_node("Camera2D") as Camera2D
	var previous := camera.offset
	camera.offset = previous + Vector2(0, -130)
	camera.force_update_scroll()
	await _shot(name)
	camera.offset = previous
	camera.force_update_scroll()
