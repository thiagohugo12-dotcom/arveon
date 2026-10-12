extends RefCounted

static func shots(main) -> Array[PlayerProjectile]:
	var result: Array[PlayerProjectile] = []
	for child in main.get_children():
		if child is PlayerProjectile and not child.spent:
			child.set_physics_process(false)
			result.append(child)
	return result

static func run_world(suite) -> void:
	var previous := OS.get_environment("GRANDE_ARVORE_SAVE_PATH")
	var path := "user://qa_arsenal_combat_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",path)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	suite.root.add_child(main)
	main.set_process(false)
	var player: PlayerActor = main.player
	var enemy: EnemyActor = main.enemy
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	player.position = Vector2(810,475)
	enemy.health.initialize(600)
	var p: GameProgress = main.progress
	for id: String in ArsenalRules.CATEGORIES:
		p.equipment[id] = 0
		p.equip(id)
		player.apply_progression(p)
		var profile := ArsenalRules.profile(id)
		suite.check(player.attack.weapon.reach == profile.reach and player.attack.weapon.interval == profile.interval and player.attack.weapon.damage == p.combat_stats().damage, "actual configured range interval damage for " + id)
		enemy.position = player.position + Vector2(profile.reach + 1,0)
		await suite.frames()
		suite.check(player.attack.select_target(player) == null, "outside actual reach excluded for " + id)
		enemy.position = player.position + Vector2(60,0)
		await suite.frames()
		player.attack.cooldown_left = 0
		player.attack.search_left = 0
		var before := enemy.health.current
		var proficiency_before := int(p.talents.xp[id])
		player.attack.tick(0,player)
		var active := shots(main)
		if profile.projectile.is_empty():
			suite.check(active.is_empty() and enemy.health.current == before - player.attack.weapon.damage, "melee hits once without projectile " + id)
			suite.check(p.talents.xp[id] == proficiency_before+1,"melee awards proficiency only on confirmed damage "+id)
		else:
			suite.check(active.size() == 1 and enemy.health.current == before and active[0].kind == profile.projectile, "ranged launch never deals instantaneous damage " + id)
			suite.check(p.talents.xp[id] == proficiency_before,"ranged launch alone grants no proficiency "+id)
			var shot := active[0]
			main.input_driver.blocked = true
			var position_before := shot.position
			shot._physics_process(1)
			suite.check(shot.position == position_before and enemy.health.current == before, "modal freezes pending projectile " + id)
			main.input_driver.blocked = false
			shot._physics_process(0.3)
			shot._physics_process(0.3)
			suite.check(shot.spent and enemy.health.current == before - player.attack.weapon.damage, "swept ranged impact damages exactly once " + id)
			suite.check(p.talents.xp[id] == proficiency_before+1,"ranged proficiency awarded exactly once at impact "+id)
		player.attack.tick(0,player)
		suite.check(enemy.health.current == before - player.attack.weapon.damage, "cooldown rejects duplicate same attack " + id)
		await suite.frames()
	# Arrow snapshots aim; the orb uses limited steering without replacing targets.
	p.equip("arco")
	player.apply_progression(p)
	player.attack.cooldown_left = 0
	player.attack.search_left = 0
	enemy.position = Vector2(930,475)
	player.attack.tick(0,player)
	var arrow := shots(main)[0]
	enemy.position.y += 60
	var before := enemy.health.current
	var miss_xp := int(p.talents.xp.arco)
	arrow._physics_process(0.4)
	suite.check(arrow.direction == Vector2.RIGHT and enemy.health.current == before, "arrow can miss a moving target and never homes")
	suite.check(p.talents.xp.arco == miss_xp,"missed arrow awards no proficiency")
	arrow.finish()
	await suite.frames()
	p.equip("cajado")
	player.apply_progression(p)
	player.attack.cooldown_left = 0
	player.attack.search_left = 0
	enemy.position = Vector2(930,475)
	player.attack.tick(0,player)
	var orb := shots(main)[0]
	enemy.position.y += 60
	orb._physics_process(0.1)
	suite.check(orb.direction.y > 0 and orb.direction.x > 0 and enemy.health.current == before, "staff orb steers moderately with travel time")
	orb.finish()
	await suite.frames()
	# A wall introduced after firing must stop the projectile at any frame size.
	p.equip("arco")
	player.apply_progression(p)
	player.attack.cooldown_left = 0
	player.attack.search_left = 0
	enemy.position = Vector2(930,475)
	player.attack.tick(0,player)
	arrow = shots(main)[0]
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(10,80)
	shape.shape = rectangle
	wall.add_child(shape)
	wall.position = Vector2(870,475)
	main.add_child(wall)
	await suite.frames()
	arrow._physics_process(1)
	suite.check(arrow.spent and enemy.health.current == before, "swept projectile cannot tunnel through a newly blocking obstacle")
	player.attack.cooldown_left = 0
	player.attack.search_left = 0
	player.attack.tick(0,player)
	suite.check(shots(main).is_empty(), "ranged target selection also rejects obstructed line of sight")
	wall.queue_free()
	await suite.frames()
	# Switching equipment during flight must not transfer practice to a new tree.
	enemy.position = player.position+Vector2(60,0)
	await suite.frames()
	player.attack.cooldown_left = 0
	player.attack.search_left = 0
	var bow_xp := int(p.talents.xp.arco)
	var sword_xp := int(p.talents.xp.espada)
	player.attack.tick(0,player)
	var switched_shot := shots(main)[0]
	p.equip("espada")
	player.apply_progression(p)
	switched_shot._physics_process(0.3)
	suite.check(switched_shot.spent and p.talents.xp.arco == bow_xp+1 and p.talents.xp.espada == sword_xp,"in-flight weapon switch preserves original projectile proficiency category")
	p.equip("arco")
	player.apply_progression(p)
	player.attack.cooldown_left = 0
	player.attack.search_left = 0
	for i in range(PlayerProjectile.MAX_ACTIVE):
		var shot := PlayerProjectile.new()
		main.add_child(shot)
		shot.setup(player,enemy,{"speed":440.0,"damage":12,"reach":300.0,"kind":"flecha"},Rect2())
		shot.set_physics_process(false)
	player.attack.tick(0,player)
	suite.check(shots(main).size() == PlayerProjectile.MAX_ACTIVE, "projectile budget caps active nodes without extra shot")
	main._clear_combat_actors()
	await suite.frames()
	suite.check(shots(main).is_empty() and suite.get_nodes_in_group("player_projectiles").is_empty(), "travel/trial cleanup clears player projectiles")
	main.queue_free()
	await suite.frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",previous)
