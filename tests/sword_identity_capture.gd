extends SceneTree
## Render test: the explorer's opaque head pixels must remain the original
## approved walking/basic artwork through every technique pose and direction.
var failures := 0
var checks := 0

func _initialize() -> void:
	create_timer(30.0).timeout.connect(func(): quit(1))
	call_deferred("run")

func head_match(rendered: Image, people: Image, sword: Image, row: int, pose: int) -> float:
	var matched := 0
	var total := 0
	for y in range(24):
		for x in range(32):
			# Basic poses legitimately move a few original head pixels and can
			# raise the original sword across the face. Compare to that approved
			# pose instead of incorrectly treating the raised blade as a new face.
			var expected := people.get_pixel(x,row*40+y) if pose < 0 else sword.get_pixel(pose*80+24+x,row*80+20+y)
			if expected.a < 0.99: continue
			total += 1
			var actual := rendered.get_pixel(48+x*2,36+y*2)
			if absf(actual.r-expected.r) < 0.015 and absf(actual.g-expected.g) < 0.015 and absf(actual.b-expected.b) < 0.015: matched += 1
	return float(matched)/maxi(1,total)

func run() -> void:
	root.size = Vector2i(160,160)
	root.content_scale_size = root.size
	var actor := Node2D.new()
	actor.position = Vector2(80,100)
	root.add_child(actor)
	var view := Skill1GameView.new()
	actor.add_child(view)
	view.village_scale = true
	view.configure("espada")
	view.z_index = 200
	view.set_process(false)
	view.sword_technique.set_process(false)
	var people := VillageActorArt.PEOPLE.get_image()
	var sword := SwordActorView.SWORD.get_image()
	for row in range(4):
		view.facing = SwordActorView.DIRECTIONS[row]
		for id: String in ["estocada_precisa","guarda_reativa","danca_laminas"]:
			view.play_sword_technique(id,SwordActorView.DIRECTIONS[row],3.0)
			view.sword_technique.z_index = 199
			var times: Array = SwordTechniqueEffect.ESTOCADA_FRAMES if id == "estocada_precisa" else (SwordTechniqueEffect.GUARDA_FRAMES if id == "guarda_reativa" else SwordTechniqueEffect.KAMUSARI_FRAMES)
			var sample_time := 0.0
			for frame in range(6):
				var effect: SwordTechniqueEffect = view.sword_technique
				effect.remaining = 1.0
				effect.elapsed = sample_time + 0.001
				effect.counter_elapsed = -1.0
				if id == "guarda_reativa" and frame >= 3: effect.counter_elapsed = 0.001 if frame == 3 else (0.05 if frame == 4 else 0.13)
				view.queue_redraw()
				effect.queue_redraw()
				for i in range(3): await process_frame
				await RenderingServer.frame_post_draw
				var poses := [0,0,1,1,1,5] if id != "guarda_reativa" else [0,1,-1,1,1,5]
				var match_ratio := head_match(root.get_texture().get_image(),people,sword,row,poses[frame])
				checks += 1
				if match_ratio < 0.99:
					failures += 1
					push_error("SWORD_IDENTITY_FAIL: %s direction %d frame %d head match %.3f" % [id,row,frame,match_ratio])
				sample_time += float(times[frame])
	actor.queue_free()
	await process_frame
	print("SWORD_IDENTITY_RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures > 0 else 0)
