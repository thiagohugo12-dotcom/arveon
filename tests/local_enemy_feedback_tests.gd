extends RefCounted
static func run(suite: SceneTree) -> void:
	var vp:=SubViewport.new()
	vp.size=Vector2i(640,360)
	vp.world_2d=World2D.new()
	suite.root.add_child(vp)
	var world:=Node2D.new()
	vp.add_child(world)
	var player: PlayerActor=preload("res://scenes/actors/player.tscn").instantiate()
	player.position=Vector2(1100,440)
	world.add_child(player)
	player.set_physics_process(false)
	var driver:=InputDriver.new()
	player.add_child(driver)
	player.input_driver=driver
	player.apply_progression(TrainingMode.create(),true)
	player.class_combat.clear_effects()
	player.health.initialize(1000)
	for direction in [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]:
		var shot:=EnemyProjectile.new()
		world.add_child(shot)
		shot.setup(player.position-direction*60,direction,100,player)
		shot.set_physics_process(false)
		var before:=player.health.current
		shot._physics_process(0.5)
		suite.check(shot.spent and player.health.current < before,"swept spine hits between low-FPS endpoints "+str(direction))
		var after:=player.health.current
		shot._physics_process(0.5)
		suite.check(player.health.current == after,"spent spine cannot damage twice")
		await suite.process_frame
	var wall:=StaticBody2D.new()
	wall.collision_layer=1
	wall.position=player.position-Vector2(35,0)
	var shape:=CollisionShape2D.new()
	var rectangle:=RectangleShape2D.new()
	rectangle.size=Vector2(8,70)
	shape.shape=rectangle
	wall.add_child(shape)
	world.add_child(wall)
	await suite.physics_frame
	await suite.process_frame
	var blocked:=EnemyProjectile.new()
	world.add_child(blocked)
	blocked.setup(player.position-Vector2(65,0),Vector2.RIGHT,100,player)
	blocked.set_physics_process(false)
	var before:=player.health.current
	blocked._physics_process(0.6)
	suite.check(blocked.spent and player.health.current == before,"World wall blocks swept spine")
	wall.queue_free()
	await suite.process_frame
	var cactus: EnemyActor=preload("res://scenes/actors/enemy.tscn").instantiate()
	cactus.kind=2
	cactus.position=player.position-Vector2(140,0)
	world.add_child(cactus)
	cactus.set_physics_process(false)
	cactus.target=player
	cactus.chasing=true
	var launches: Array=[0]
	cactus.projectile_requested.connect(func(_o: Vector2,_d: Vector2,_damage: int): launches[0]+=1)
	cactus._cactus_behavior(Vector2(140,0),140,0)
	cactus._cactus_behavior(Vector2(140,0),140,0.339)
	suite.check(launches[0] == 0,"cactus holds shot throughout preparation")
	player.input_driver.blocked=true
	var held:=cactus.spine_windup
	cactus._physics_process(0.5)
	suite.check(cactus.spine_windup == held and launches[0] == 0,"menu pauses enemy windup")
	player.input_driver.blocked=false
	cactus._cactus_behavior(Vector2(140,0),140,0.001)
	suite.check(launches[0] == 1,"cactus emits once at 340ms physics boundary")
	cactus._cactus_behavior(Vector2(140,0),140,0.2)
	suite.check(launches[0] == 1,"no independent timer emits a duplicate spine")
	cactus._return_home()
	suite.check(cactus.spine_windup == 0,"leaving combat cancels pending spine")
	var boar: EnemyActor=preload("res://scenes/actors/enemy.tscn").instantiate()
	boar.position=player.position+Vector2(25,0)
	world.add_child(boar)
	boar.set_physics_process(false)
	boar.target=player
	boar.charge_windup=0.42
	before=player.health.current
	boar._try_contact(25)
	suite.check(player.health.current == before,"boar windup cannot deal early contact damage")
	boar.charge_windup=0
	boar._try_contact(25)
	var after:=player.health.current
	boar._try_contact(25)
	suite.check(after < before and player.health.current == after,"boar contact respects damage and cooldown")
	var probe:=ActorView.new()
	probe.position=Vector2(180,140)
	world.add_child(probe)
	probe.set_process(false)
	probe.damage_occluders=[Rect2(140,80,80,100)]
	var at:=Vector2(-10,-42)
	var readable:=probe._readable_damage_position(at,20)
	suite.check(readable.distance_to(at) <= 80,"damage number stays near actor instead of cascading to HUD bottom")
	var bounds:=probe.get_global_transform_with_canvas()*Rect2(readable-Vector2(4,21),Vector2(28,26))
	suite.check(not bounds.intersects(probe.damage_occluders[0]),"nearby damage number avoids actual HUD rectangle")
	# Stress the real group-based area damage without changing the game's spawn cap.
	player.view.village_scale=true
	player.progress.abilities.loadouts.espada.skills=["estocada_precisa","guarda_reativa"]
	player.progress.abilities.loadouts.espada.ultimate="danca_laminas"
	player.apply_progression(player.progress)
	var targets: Array[EnemyActor]=[]
	for i in range(24):
		var actor: EnemyActor=preload("res://scenes/actors/enemy.tscn").instantiate()
		actor.position=player.position+Vector2.RIGHT.rotated(i*TAU/24)*80
		world.add_child(actor)
		actor.set_physics_process(false)
		actor.health.initialize(10000)
		targets.append(actor)
	await suite.physics_frame
	player.class_combat.clear_effects()
	player.progress.abilities.charge.espada=100
	var start:=Time.get_ticks_usec()
	player.use_skill(3)
	player.class_combat.tick(SwordTechniqueTiming.contact("danca_laminas"))
	var spent:=Time.get_ticks_usec()-start
	for actor in targets: suite.check(actor.health.current < 10000,"multi-enemy Kamusari legal circular target")
	print("LOCAL_STRESS: 24 additional enemies, contact CPU usec=",spent," (desktop/headless; not a phone FPS benchmark)")
	# Every source cell has transparent borders, so no pose is cut by its atlas.
	for id in ["estocada_precisa","guarda_reativa","danca_laminas","guardiao"]:
		var texture:=load("res://assets/art/local_combat_review/"+id+".png") as Texture2D
		var image:=texture.get_image()
		var count:=8 if id == "guardiao" else 6
		for row in range(4):
			for frame in range(count):
				var clean:=true
				for x in range(80):
					clean=clean and image.get_pixel(frame*80+x,row*80).a == 0 and image.get_pixel(frame*80+x,row*80+79).a == 0
				for y in range(80):
					clean=clean and image.get_pixel(frame*80,row*80+y).a == 0 and image.get_pixel(frame*80+79,row*80+y).a == 0
				suite.check(clean,"uncropped source cell "+id+str(row)+str(frame))
	vp.queue_free()
	await suite.process_frame
