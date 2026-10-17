extends SceneTree
var checks:=0
var failures:=0
var hit_events:=0
func _initialize() -> void:
	create_timer(40).timeout.connect(func(): push_error("KAMUSARI_RENDER_TIMEOUT"); quit(1))
	call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; print("FAIL: ",message)
func run() -> void:
	var output:="C:/Users/Thiago/Documents/Codex/2026-10-16/o-c/outputs/kamusari-local"
	DirAccess.make_dir_recursive_absolute(output)
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(512,512)
	viewport.transparent_bg=true
	viewport.world_2d=World2D.new()
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var actor: PlayerActor=preload("res://scenes/actors/player.tscn").instantiate()
	actor.get_node("Camera2D").enabled=false
	actor.position=Vector2(256,256)
	viewport.add_child(actor)
	actor.set_physics_process(false)
	actor.view.set_process(false)
	actor.view.village_scale=true
	check(actor.view.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,"explorer is crisp source pixel art, including while moving")
	actor.apply_progression(TrainingMode.create(),true)
	actor.view.z_as_relative=false
	actor.view.z_index=356
	for row in range(4):
		var aim: Vector2=SwordActorView.DIRECTIONS[row]
		actor.view.play_sword_technique("danca_laminas",aim)
		var fx: SwordTechniqueEffect=actor.view.sword_technique
		fx.set_process(false)
		for reach: float in [150.0,170.0]:
			fx.real_reach=reach
			actor.view.seek_sword_technique(SwordTechniqueTiming.contact("danca_laminas"))
			for i in range(3): await process_frame
			await RenderingServer.frame_post_draw
			var image:=viewport.get_texture().get_image()
			for sample in range(24):
				var point:=Vector2(256,256)+Vector2.RIGHT.rotated(sample*TAU/24)*(reach-2)
				var covered:=false
				for x in range(-2,3):
					for y in range(-2,3):
						var pixel:=image.get_pixel(roundi(point.x)+x,roundi(point.y)+y)
						covered=covered or (pixel.a>0.20 and pixel.r>pixel.g*1.5 and pixel.r>pixel.b*1.4)
				check(covered,"complete perimeter, including rear, row %d reach %d sample %d" % [row,reach,sample])
			if reach == 170: image.save_png(output.path_join("efeito-dir%d.png" % row))
		# Every tapered stroke remains triangulable throughout the dissipating tail.
		for i in range(20):
			var p:=float(i)/20
			var points:=SwordTechniqueEffect.ribbon(Vector2.ZERO,148,aim.angle()+p*TAU,2.1,10*(1-p)+2)
			check(Geometry2D.triangulate_polygon(points).size()>0,"continuous ribbon has valid geometry")
	viewport.queue_free()
	await process_frame
	# Actual full game: movement and Dash while the original explorer casts.
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH","user://kam_motion_%d.json" % Time.get_ticks_usec())
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	root.size=Vector2i(960,540)
	root.content_scale_size=root.size
	var main:=preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in range(4): await process_frame
	main._start_training()
	main.set_process(false)
	main.player.set_physics_process(false)
	main.player.view.set_process(false)
	main.player.get_node("Camera2D").position_smoothing_enabled=false
	main.enemy.set_physics_process(false)
	main.enemy.health.changed.connect(func(_hp: int,_max: int): hit_events+=1)
	var moved_directions:=0
	for row in range(4):
		var aim: Vector2=SwordActorView.DIRECTIONS[row]
		main.player.class_combat.clear_effects()
		TrainingMode.refill(main.progress)
		main.player.position=Vector2(900,440)
		main.player.last_direction=aim
		main.player.view.set_facing(aim)
		main.player.input_driver.touch_direction=aim.orthogonal()
		main.player.dash.time_left=0
		main.player.dash.cooldown_left=0
		main.player.input_driver.request_dash()
		main.enemy.position=main.player.position+aim*65
		main.enemy.health.initialize(1000000)
		hit_events=0
		main.player.attack.cooldown_left=100
		var started: bool=main.player.use_skill(2)
		check(started,"full local game casts Kamusari")
		var fx: SwordTechniqueEffect=main.player.view.sword_technique
		fx.set_process(false)
		var initial: Vector2=main.player.position
		var dash_executed:=false
		for step in range(24):
			main.player._physics_process(1.0/60.0)
			dash_executed=dash_executed or main.player.dash.active()
			main.player.view._process(1.0/60.0)
			fx._process(0)
			if fx.remaining>0:
				check(fx.global_position.is_equal_approx(main.player.global_position),"no detached/cut tail during movement and Dash")
			if step == 13:
				for i in range(3): await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output.path_join("jogo-dash-dir%d.png" % row))
		var distance: float=main.player.position.distance_to(initial)
		if distance>25: moved_directions+=1
		check(dash_executed,"actual Dash requested in all four directions, retaining scenery collisions")
		print("KAM_DASH_DIRECTION: ",row," displacement=",distance)
		check(hit_events == 4,"one activation retains exactly four configured Kamusari hits")
	check(moved_directions>=2,"effect follows real displacement along both open directions of training lane")
	main.queue_free()
	await process_frame
	print("KAMUSARI_LOCAL_RENDER_RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
