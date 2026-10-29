extends SceneTree
var checks := 0
var failures := 0
const TRIAL = preload("res://tests/tower_trial_tests.gd")
var output := "C:/Users/Thiago/Documents/Codex/2026-10-16/o-c/outputs/ARVEON/Revisoes/guardiao-integrado"
func _initialize() -> void:
	create_timer(45).timeout.connect(func(): push_error("GUARDIAN_LOCAL_TIMEOUT"); quit(1))
	call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; print("FAIL: ",message)
func frames(count: int=3) -> void:
	for i in range(count): await process_frame
	await RenderingServer.frame_post_draw
func capture(name: String) -> void:
	await frames()
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	OS.set_environment("ARVEON_SAVE_PATH","user://guardian_new_%d.json" % Time.get_ticks_usec())
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	root.size=Vector2i(960,640)
	root.content_scale_size=root.size
	var main=preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	TRIAL._freeze(main)
	main.progress.ascension.defeats["1"]=50
	await TRIAL._enter(self,main)
	preload("res://tests/tower_guardian_tests.gd").reach_guardian(main)
	var boss: TowerGuardian=main.tower_guardian
	var player: PlayerActor=main.player
	var center:=TowerTrial.ORIGIN+Vector2(360,270)
	player.get_node("Camera2D").position_smoothing_enabled=false
	boss.view.set_process(false)
	check(boss.view is TowerGuardianView,"main spawns the integrated guardian view")
	check(boss.health.maximum==360,"guardian HP is unchanged")
	for row in range(4):
		var aim: Vector2=SwordActorView.DIRECTIONS[row]
		for action: int in [TowerGuardian.Action.ROOT_WAVE,TowerGuardian.Action.SEEDS]:
			for delta: float in [1.0/120,1.0/30,0.25]:
				boss.position=center
				player.position=center+aim*80
				player.health.initialize(100)
				boss.action=action
				boss._begin_attack()
				var warning:=boss.action_left
				check(boss.view.sprite_frame()==2,"new skill has a preparation pose")
				boss._physics_process(warning-0.01)
				check(player.health.current==100,"warning never deals damage")
				boss._physics_process(0.01)
				check(boss.state==TowerGuardian.State.ACTIVE,"correct active transition")
				check(boss.view.sprite_frame()==4,"active contact pose is driven by boss state")
				var remaining: float=TowerGuardian.ACTIVES[action]
				while remaining>0.000001:
					var step:=minf(remaining,delta)
					boss._physics_process(step)
					remaining-=step
				check(player.health.current==(84 if action==TowerGuardian.Action.ROOT_WAVE else 86),"swept skill hits exactly once at all physics intervals")
				check(not boss.view.warning and not boss.view.hazards_active,"skill clears effects on recovery")
				check(boss.action==(action+1)%5,"all five attacks are in the rotation")
			# Actual main-scene captures of warning and execution, four directions.
			boss.position=center
			player.position=center+aim*90
			player.health.initialize(100)
			boss.action=action
			boss._begin_attack()
			await capture("acao%d-dir%d-aviso" % [action,row])
			boss._physics_process(float(TowerGuardian.WINDUPS[action]))
			boss._physics_process(0.30)
			await capture("acao%d-dir%d-execucao" % [action,row])
	# Safe center/outside the wave and perpendicular dodge of the fan.
	for distance: float in [8.0,190.0]:
		boss.position=center
		player.position=center+Vector2.RIGHT*distance
		player.health.initialize(100)
		boss.action=TowerGuardian.Action.ROOT_WAVE
		boss._begin_attack()
		boss._physics_process(1.1)
		boss._physics_process(0.65)
		check(player.health.current==100,"wave has a safe center and safe exterior")
	boss.position=center
	player.position=center+Vector2.RIGHT*100
	player.health.initialize(100)
	boss.action=TowerGuardian.Action.SEEDS
	boss._begin_attack()
	player.position=center+Vector2.DOWN*100
	boss._physics_process(0.9)
	boss._physics_process(0.9)
	check(player.health.current==100 and boss.aim==Vector2.RIGHT,"seeds use locked aim and can be dodged")
	# Pause the real boss clock while a menu blocks the player's input.
	boss.action=TowerGuardian.Action.ROOT_WAVE
	boss._begin_attack()
	player.input_driver.blocked=true
	var held:=boss.action_left
	boss._physics_process(1)
	check(boss.action_left==held,"modal input pauses new skill")
	player.input_driver.blocked=false
	# Real World wall blocks the fan, and a fresh cast resets blocked seeds.
	boss.position=center
	player.position=center+Vector2.RIGHT*100
	player.health.initialize(100)
	var wall:=StaticBody2D.new()
	wall.collision_layer=1
	var shape:=CollisionShape2D.new()
	var rectangle:=RectangleShape2D.new()
	rectangle.size=Vector2(10,200)
	shape.shape=rectangle
	wall.add_child(shape)
	wall.position=center+Vector2(50,0)
	main.add_child(wall)
	await physics_frame
	await physics_frame
	boss.action=TowerGuardian.Action.SEEDS
	boss._begin_attack()
	boss._physics_process(0.9)
	boss._physics_process(0.9)
	check(player.health.current==100 and boss.seed_blocked[1],"seeds stop at real walls without damage through them")
	boss.action=TowerGuardian.Action.SEEDS
	boss._begin_attack()
	check(not boss.seed_blocked.has(true),"new cast clears previous blocked seeds")
	for i in range(3): check(boss.arena_bounds.has_point(boss.seed_position(i,20)),"seeds stay bounded by arena")
	boss.view.hazards_active=true
	boss._clear_warning()
	check(not boss.view.warning and not boss.view.hazards_active,"death/cancel cleanup removes all hazards")
	wall.queue_free()
	await physics_frame
	await physics_frame
	# Same warning and damage in phase two; shorter recovery only.
	for action: int in [TowerGuardian.Action.ROOT_WAVE,TowerGuardian.Action.SEEDS]:
		boss.health.initialize(360)
		boss.health.current=180
		boss.position=center
		player.position=center+Vector2.RIGHT*80
		player.health.initialize(100)
		boss.action=action
		boss._begin_attack()
		check(is_equal_approx(boss.action_left,TowerGuardian.WINDUPS[action]),"phase two keeps full warning")
		boss._physics_process(float(TowerGuardian.WINDUPS[action]))
		boss._physics_process(float(TowerGuardian.ACTIVES[action]))
		check(player.health.current==(84 if action==TowerGuardian.Action.ROOT_WAVE else 86),"phase two keeps provisional damage")
		check(is_equal_approx(boss.recovery_left,0.8),"phase two retains original shorter recovery")
	boss.state=TowerGuardian.State.APPROACH
	boss.view.guardian_time=0
	var idle: int=boss.view.sprite_frame()
	boss.view.guardian_time=0.6
	check(boss.view.sprite_frame()!=idle,"new body animates during idle")
	main.queue_free()
	await process_frame
	# The two new skills can be inspected in the local review UI too.
	var review=preload("res://scenes/demos/local_combat_review.tscn").instantiate()
	root.add_child(review)
	review.playing=false
	review.actor_kind=1
	review._populate_attacks()
	check(review.attack_choice.item_count==6,"review offers idle plus all five guardian attacks")
	for ability in ["root_wave","seeds"]:
		for row in range(4):
			review.ability=ability
			review.attack_choice.select(review.GUARDIAN_ATTACKS.find(ability))
			review.direction_index=row
			review.rebuild()
			review.seek(review.contact_time+0.4)
			check(review.real_damage>0,"new skill executes real combat in review")
			check(review.new_enemy.view.telegraph_kind==(3 if ability == "root_wave" else 4) and review.new_enemy.view.warning and review.new_enemy.view.hazards_active,"review shows the actual new active effect")
			await capture("revisao-%s-dir%d" % [ability,row])
	review.queue_free()
	await process_frame
	print("GUARDIAN_LOCAL_RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
