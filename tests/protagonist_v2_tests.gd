extends SceneTree
## Protagonista 2.0 on the real main scene, isolated from the player's save.
## With QA_RENDER_DIR it also captures every integrated frame on the real map at the
## phone scale (3 physical px per world px) and writes contact sheets plus an animated
## HTML viewer for review. Run with a window for captures.
var checks := 0
var failures := 0
var output := ""
var strips := {} # name -> Array[Image]

func _initialize() -> void:
	CombatRules.random_roll_source = func(): return 0.99
	create_timer(90).timeout.connect(func(): quit(1))
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("PROTAGONIST_V2_FAIL: "+message)

func frames() -> void:
	for i in range(3):
		await physics_frame
		await process_frame

func capture(view: ActorView, strip: String) -> void:
	if output.is_empty(): return
	view.queue_redraw()
	await frames()
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var scale := root.get_final_transform().x.x * (view.get_parent().get_node("Camera2D") as Camera2D).zoom.x
	var centre := root.get_final_transform() * (view.get_parent() as Node2D).get_global_transform_with_canvas().origin
	var crop := Rect2i(Vector2i(centre + Vector2(-110, -78) * scale), Vector2i(Vector2(220, 104) * scale))
	strips.get_or_add(strip, []).append(image.get_region(crop))

func run() -> void:
	var save_path := "user://qa_protagonist_v2_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH",save_path)
	output = OS.get_environment("QA_RENDER_DIR")
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	# Assets: the five sheets match the generated layout and carry mipmaps.
	for sheet: String in ProtagonistV2Layout.SHEETS:
		var layout: Dictionary = ProtagonistV2Layout.SHEETS[sheet]
		var texture: Texture2D = ProtagonistV2Art.TEXTURES[sheet]
		check(texture.get_size() == Vector2(layout.cell.x * layout.frames, layout.cell.y * layout.rows),"sheet %s matches its layout" % sheet)
		check(texture.get_image().has_mipmaps(),"sheet %s imported with mipmaps" % sheet)
	check(ProtagonistV2Layout.SHEETS.idle.frames == 4 and ProtagonistV2Layout.SHEETS.idle.rows == 4,"idle: 4 frames x 4 directions")
	check(ProtagonistV2Layout.SHEETS.corrida.frames == 6 and ProtagonistV2Layout.SHEETS.corrida.rows == 4,"run: 6 frames x 4 directions")
	check(ProtagonistV2Layout.SHEETS.espada_basico.frames == 6 and ProtagonistV2Layout.SHEETS.espada_estocada.frames == 6 and ProtagonistV2Layout.SHEETS.espada_guarda.frames == 4,"sword sheets: 6 basic, 6 thrust, 4 guard")
	check(ProtagonistV2Layout.SHEETS.espada_contra.frames == 6 and ProtagonistV2Layout.SHEETS.espada_crescente.frames == 5 and ProtagonistV2Layout.SHEETS.espada_ruptura.frames == 5,"board sheets: 6 counter, 5 Crescente, 5 Ruptura")
	var main := preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.set_process(false)
	var player: PlayerActor = main.player
	player.set_physics_process(false)
	player.view.set_process(false)
	for actor in get_nodes_in_group("damageable_enemies"):
		actor.set_physics_process(false)
		if actor != main.enemy: actor.queue_free()
	main.enemy.target = null
	await frames()
	var view := player.view as Skill1GameView
	check(view != null and view.village_scale,"main scene uses the village presentation")
	check(view.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS,"protagonist samples without bilinear filter, with mipmaps")
	check((player.get_node("Collision") as CollisionShape2D).shape.radius == 13.0,"collision unchanged")
	var scenery: FloorView = main.get_node("Andar1/FloorView")
	var centre := Vector2.ZERO
	for y in range(300,760,20):
		for x in range(860,1120,20):
			var point := Vector2(x,y)
			var clear := true
			for direction: Vector2 in SwordActorView.DIRECTIONS:
				var ray := PhysicsRayQueryParameters2D.create(point,point+direction*75.0,1)
				clear = clear and player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()
			for feet: Vector2 in scenery.v2_view.visible_tree_positions():
				var canopy := Rect2(feet-Vector2(56,122),Vector2(112,128)).grow(20.0)
				clear = clear and not canopy.has_point(point-Vector2(0,30))
			if clear and centre.is_zero_approx(): centre = point
	check(not centre.is_zero_approx(),"real map has an open patch")
	player.position = centre
	main.enemy.position = centre + Vector2(400, 400)
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output)
		main.hud.visible = false
		var camera := player.get_node("Camera2D") as Camera2D
		camera.position_smoothing_enabled = false
		camera.limit_left = -10000
		camera.limit_top = -10000
		camera.limit_right = 10000
		camera.limit_bottom = 10000
		camera.zoom = Vector2.ONE * (3.0 / root.get_final_transform().x.x)
		camera.force_update_scroll()
	var directions := [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
	# Idle: 4 continuous frames per direction, last direction kept.
	for row in range(4):
		view.set_moving(true)
		view.set_facing(directions[row])
		view.set_moving(false)
		check(view._explorer_direction() == row and view.v2_idle_frame() == 0,"idle starts at frame 1 facing %d" % row)
		for frame in range(8):
			check(view.v2_idle_frame() == frame % 4,"idle loops frame %d dir %d" % [frame, row])
			if frame < 4: await capture(view, "idle_%d" % row)
			view._process(ProtagonistV2Art.IDLE_FRAME_TIME)
		check(view._explorer_direction() == row,"idle keeps the last direction %d" % row)
	# Run: 6 frames per direction, advanced by distance (no foot sliding), any speed.
	for row in range(4):
		view.set_facing(directions[row])
		view.set_moving(true)
		var start := player.position
		for frame in range(12):
			check(view.v2_run_frame() == frame % 6,"run frame %d dir %d follows distance" % [frame, row])
			if frame < 6: await capture(view, "corrida_%d" % row)
			player.position += directions[row] * (ProtagonistV2Art.RUN_PIXELS_PER_FRAME + 0.01)
			view._process(0.016)
		var held := view.v2_run_frame()
		view._process(0.5)
		check(view.v2_run_frame() == held,"standing still in time never advances the stride")
		view.set_moving(false)
		check(view.v2_idle_frame() == 0 and not view.walking,"run -> idle returns to idle frame 1")
		player.position = start
		view._process(0.0)
	player.position = centre
	view._process(0.0)
	# Basic attack on the real AutoAttack: lead-in 0-2 in the preparation, impact 3 on
	# the damage tick, 4-5 in recovery; up/down keep the current atlas.
	var impact_frames := []
	player.attack.attacked.connect(func(_target): impact_frames.append(view.v2_sword_frame()))
	for index in range(4):
		view.clear_sword()
		main.enemy.position = centre + directions[index] * 60.0
		main.enemy.health.initialize(48)
		var lead_in := []
		player.attack.cooldown_left = SwordActorView.PREPARE_TIME
		player.attack.search_left = 0.0
		for step in range(12):
			player._physics_process(0.03)
			if impact_frames.size() > index: break
			check(main.enemy.health.current == 48,"preparation deals no damage %d" % index)
			lead_in.append(view.v2_sword_frame())
			if index >= 2 and lead_in.size() % 2 == 1: await capture(view, "basico_%d" % index)
		check(lead_in.has(0) and lead_in.has(1) and lead_in.has(2),"lead-in shows preparation, recoil and cut start %d" % index)
		check(impact_frames.size() == index + 1 and impact_frames[index] == 3,"damage tick shows the impact frame %d" % index)
		check(main.enemy.health.current == 48 - roundi(12.0 * ArsenalRules.basic_power("espada")),"unchanged single hit %d" % index)
		check(view.sword_row == index and view.phase() >= 0,"attack works facing %d" % index)
		check(ProtagonistV2Art.has_attack_art(index) == (index >= 2),"new art right/left only, %d keeps the current attack" % index)
		var recovery := [view.v2_sword_frame()]
		if index >= 2: await capture(view, "basico_%d" % index)
		for step in range(2):
			view._process(view.sword_duration / 3.0 + 0.001)
			recovery.append(view.v2_sword_frame())
			if index >= 2: await capture(view, "basico_%d" % index)
		check(recovery == [3, 4, 5],"impact, completion and recovery %d: %s" % [index, recovery])
		view._process(1.0)
		check(view.phase() == -1,"returns to the normal body %d" % index)
	# Attack while moving: the attack frame wins over the run cycle.
	view.set_moving(true)
	view.play_sword_attack(Vector2.RIGHT, player.attack.weapon.interval)
	check(view.phase() >= 0 and view.v2_sword_frame() == 3,"running does not overwrite the attack")
	view._process(1.0)
	view.set_moving(false)
	main.enemy.position = centre + Vector2(400, 400)
	# Estocada Precisa: six frames on the shared clock, contact at frame 3, linear trail.
	for row in [3, 2, 0]:
		view.play_sword_technique("estocada_precisa", directions[row])
		var effect := view.sword_technique
		check(effect.body_trail == (row >= 2),"body trail replaces the crescent only with the new art %d" % row)
		var seen := []
		var t := 0.0
		while effect.remaining > 0.0:
			view.seek_sword_technique(t)
			var frame := effect._frame()
			if seen.is_empty() or seen[-1] != frame:
				seen.append(frame)
				if row >= 2: await capture(view, "estocada_%d" % row)
			t += 0.005
			if t > effect.duration: break
		check(seen == [0, 1, 2, 3, 4, 5],"thrust plays 6 frames in order %d: %s" % [row, seen])
		check(SwordTechniqueTiming.frame("estocada_precisa", SwordTechniqueTiming.contact("estocada_precisa")) == 3,"contact lands on frame 4 (index 3)")
		check(view.v2_technique_pose(3) == ([] if row < 2 else ["espada_estocada", 3]),"thrust body art used only where it exists %d" % row)
		view.clear_sword_technique()
		check(not effect.body_trail and effect.remaining == 0.0,"thrust clears without leftovers")
	# Kamusari: eight frames on the technique's own clock; the arc lands on the damage contact.
	var before_contact := 0.0
	for i in range(ProtagonistV2Art.KAMUSARI_CONTACT_FRAME): before_contact += ProtagonistV2Art.KAMUSARI_FRAMES[i]
	var total := 0.0
	for value: float in ProtagonistV2Art.KAMUSARI_FRAMES: total += value
	check(is_equal_approx(before_contact, SwordTechniqueTiming.contact("danca_laminas")),"Kamusari arc frame starts exactly at the damage contact")
	check(is_equal_approx(total, SwordTechniqueTiming.duration("danca_laminas")),"Kamusari keeps its 0.485 s duration")
	check(ProtagonistV2Art.kamusari_frame(SwordTechniqueTiming.contact("danca_laminas")) == ProtagonistV2Art.KAMUSARI_CONTACT_FRAME,"contact tick shows the arc")
	for row in [3, 2, 0]:
		view.play_sword_technique("danca_laminas", directions[row])
		var effect := view.sword_technique
		check(effect.body_trail == (row >= 2),"Kamusari near-body swirl replaced only with the new art %d" % row)
		var seen := []
		var t := 0.0
		while t <= effect.duration:
			view.seek_sword_technique(t)
			var pose := view.v2_technique_pose(effect._frame())
			check(pose.is_empty() == (row < 2),"Kamusari body art only where it exists %d" % row)
			if not pose.is_empty() and (seen.is_empty() or seen[-1] != pose[1]):
				seen.append(pose[1])
				await capture(view, "kamusari_%d" % row)
			t += 0.005
		if row >= 2: check(seen == [0, 1, 2, 3, 4, 5, 6, 7],"Kamusari plays 8 frames in order %d: %s" % [row, seen])
		view.clear_sword_technique()
		check(not effect.body_trail and effect.remaining == 0.0,"Kamusari clears without leftovers")
	# Guarda Reativa: four guard frames; the counter is its own six-frame event.
	var counter_time: float = SwordTechniqueEffect.GUARDA_FRAMES[3] + SwordTechniqueEffect.GUARDA_FRAMES[4] + SwordTechniqueEffect.GUARDA_FRAMES[5]
	var counter_frames_time := 0.0
	for value: float in ProtagonistV2Art.COUNTER_FRAMES: counter_frames_time += value
	check(is_equal_approx(counter_frames_time, counter_time),"counter frames fill the 0.22 s reaction")
	for row in [3, 2]:
		view.play_sword_technique("guarda_reativa", directions[row], 3.0)
		var effect := view.sword_technique
		var poses := []
		for t: float in [0.02, 0.08, 0.15, 0.5, 2.0]:
			effect.externally_clocked = true
			effect.elapsed = t
			effect.remaining = effect.duration - t
			poses.append(effect._frame())
			check(view.v2_technique_pose(effect._frame())[0] == "espada_guarda","guard frame drawn with the new art at %.2f" % t)
			await capture(view, "guarda_%d" % row)
		check(poses == [0, 1, 2, 2, 2],"guard activation then held guard %s" % [poses])
		# Counter: six frames over the 0.22 s reaction, then the held guard again.
		view.play_sword_counter(directions[row])
		effect.set_process(false) # Hold counter_elapsed still while capturing.
		var counter := []
		var ct := 0.0
		while ct < counter_time:
			effect.counter_elapsed = ct
			var pose := view.v2_technique_pose(effect._frame())
			if pose[0] == "espada_contra" and (counter.is_empty() or counter[-1] != pose[1]):
				counter.append(pose[1])
				effect.queue_redraw()
				await capture(view, "contra_%d" % row)
			ct += 0.005
		check(counter == [0, 1, 2, 3, 4, 5],"counter plays 6 frames in order %d: %s" % [row, counter])
		view.set_moving(true)
		check(view.v2_technique_pose(effect._frame())[0] == "corrida","counter on the move keeps the run body")
		view.set_moving(false)
		effect.set_process(true)
		effect._process(counter_time - effect.counter_elapsed + 0.001)
		check(effect.counter_elapsed < 0.0 and view.v2_technique_pose(effect._frame()) == ["espada_guarda", 3],"after the counter the guard is held again")
		view.clear_sword_technique()
	# Corte Crescente and Ruptura Ancestral damage on use (no timed contact): the body art
	# starts on the cut / the impact and fills the existing visual duration.
	for id: String in ["corte_crescente", "ruptura_ancestral"]:
		check(not SwordTechniqueTiming.FRAMES.has(id),"%s damage stays immediate" % id)
		var durations: Array = ProtagonistV2Art.CRESCENTE_FRAMES if id == "corte_crescente" else ProtagonistV2Art.RUPTURA_FRAMES
		var total_time := 0.0
		for value: float in durations: total_time += value
		check(is_equal_approx(total_time, SwordTechniqueEffect.EXTRA_DURATIONS[id]),"%s keeps its %.2f s" % [id, SwordTechniqueEffect.EXTRA_DURATIONS[id]])
		var sheet := "espada_crescente" if id == "corte_crescente" else "espada_ruptura"
		var strip := "crescente" if id == "corte_crescente" else "ruptura"
		for row in [3, 2, 0]:
			view.play_sword_technique(id, directions[row])
			var effect := view.sword_technique
			effect.externally_clocked = true
			var seen := []
			var t := 0.0
			while t < effect.duration:
				effect.elapsed = t
				effect.remaining = effect.duration - t
				var pose := view.v2_technique_pose(effect._frame())
				check(pose.is_empty() == (row < 2) and (pose.is_empty() or pose[0] == sheet),"%s body art only where it exists %d" % [id, row])
				if not pose.is_empty() and (seen.is_empty() or seen[-1] != pose[1]):
					seen.append(pose[1])
					effect.queue_redraw()
					await capture(view, "%s_%d" % [strip, row])
				t += 0.005
			if row >= 2: check(seen == ([0, 1, 2, 3, 4] if id == "corte_crescente" else [2, 3, 4]),"%s frames in order %d: %s" % [id, row, seen])
			view.clear_sword_technique()
			check(effect.remaining == 0.0,"%s clears without leftovers" % id)
	# Damage flash and death keep the existing feedback, without stuck poses.
	view.play_sword_attack(Vector2.RIGHT, 0.72)
	view.show_damage(5)
	check(view.flash_left > 0.0,"damage flash still applies to the new body")
	player.health.damage(player.health.maximum)
	check(view.phase() == -1 and view.sword_technique.remaining == 0.0,"death clears attack and technique")
	if not output.is_empty(): _write_preview()
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	CombatRules.random_roll_source = Callable()
	print("PROTAGONIST_V2_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _write_preview() -> void:
	var html := "<!doctype html><meta charset=utf-8><title>Protagonista 2.0</title><style>body{background:#16201b;color:#e7f4d7;font:14px sans-serif;margin:16px}img{image-rendering:pixelated;background:#000;margin:2px}h2{font-size:15px;margin:18px 0 4px}</style>"
	html += "<h1>Protagonista 2.0 no jogo (captura real, escala de celular 3x)</h1>"
	var timing := {"idle": 180, "corrida": 110, "basico": 90, "estocada": 70, "guarda": 400, "contra": 37, "crescente": 60, "ruptura": 113, "kamusari": 60}
	var names := {"idle_0":"Idle Frente","idle_1":"Idle Costas","idle_2":"Idle Esquerda","idle_3":"Idle Direita","corrida_0":"Corrida Frente","corrida_1":"Corrida Costas","corrida_2":"Corrida Esquerda","corrida_3":"Corrida Direita","basico_3":"Ataque Básico Direita","basico_2":"Ataque Básico Esquerda (espelhado)","estocada_3":"Estocada Direita","estocada_2":"Estocada Esquerda (espelhada)","guarda_3":"Guarda Reativa Direita","guarda_2":"Guarda Reativa Esquerda (espelhada)","contra_3":"Contra-ataque da Guarda Direita","contra_2":"Contra-ataque da Guarda Esquerda (espelhado)","crescente_3":"Corte Crescente Direita","crescente_2":"Corte Crescente Esquerda (espelhado)","ruptura_3":"Ruptura Ancestral Direita","ruptura_2":"Ruptura Ancestral Esquerda (espelhada)","kamusari_3":"Kamusari Direita","kamusari_2":"Kamusari Esquerda (espelhado)"}
	for strip: String in names:
		if not strips.has(strip): continue
		var images: Array = strips[strip]
		var w: int = (images[0] as Image).get_width()
		var h: int = (images[0] as Image).get_height()
		var sheet := Image.create(w * images.size(), h, false, Image.FORMAT_RGBA8)
		for i in range(images.size()):
			var image: Image = images[i]
			image.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(i * w, 0))
			image.save_png(output.path_join("%s_%d.png" % [strip, i]))
		sheet.save_png(output.path_join("%s_prancha.png" % strip))
		var delay: int = timing[strip.get_slice("_", 0)]
		html += "<h2>%s</h2><img id=%s width=%d src='%s_0.png'> <img src='%s_prancha.png' width=%d>" % [names[strip], strip, w / 2, strip, strip, w * images.size() / 4]
		html += "<script>(()=>{let i=0;setInterval(()=>{i=(i+1)%%%d;document.getElementById('%s').src='%s_'+i+'.png'},%d)})()</script>" % [images.size(), strip, strip, delay]
	var file := FileAccess.open(output.path_join("previa_protagonista_2_0.html"), FileAccess.WRITE)
	file.store_string(html)
	# One overview image: a row per animation, frames in order, at half size.
	var rows: Array = names.keys().filter(func(strip): return strips.has(strip))
	var first: Image = strips[rows[0]][0]
	var cell := first.get_size() / 2
	var overview := Image.create(cell.x * 8, cell.y * rows.size(), false, Image.FORMAT_RGBA8)
	overview.fill(Color("#16201b"))
	for r in range(rows.size()):
		var images: Array = strips[rows[r]]
		for i in range(mini(8, images.size())):
			var small := (images[i] as Image).duplicate() as Image
			small.resize(cell.x, cell.y, Image.INTERPOLATE_LANCZOS)
			overview.blit_rect(small, Rect2i(Vector2i.ZERO, cell), Vector2i(i * cell.x, r * cell.y))
	overview.save_png(output.path_join("previa_protagonista_2_0_resumo.png"))
