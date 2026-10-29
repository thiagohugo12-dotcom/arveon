extends RefCounted

# Marco 3 · acampamentos de monstros (modo opt-in). O modo contínuo continua sendo o
# padrão e é coberto pelos testes existentes; aqui valem os dados, o ciclo de vida e
# a contabilidade igual entre os dois modos.

static func run(suite) -> void:
	# A opção: padrão contínuo; override de teste liga os acampamentos.
	GameOptions.set_override("")
	suite.check(GameOptions.encounter_mode() == GameOptions.MODE_CONTINUOUS, "encounter mode defaults to continuous spawning")
	GameOptions.set_override(GameOptions.MODE_CAMPS)
	suite.check(GameOptions.encounter_mode() == GameOptions.MODE_CAMPS, "camps mode can be requested")
	GameOptions.set_override("")
	suite.check(GameOptions.MODE_CAMPS == "acampamentos" and GameOptions.MODE_CONTINUOUS == "continuo", "mode names match the URL and options values")
	# Dados dos acampamentos.
	for floor_id in [1, 2]:
		var camps := FloorCatalog.camps(floor_id)
		var def := FloorCatalog.floor_def(floor_id)
		var area := SafeCamp.area_for_floor(floor_id).grow(SafeCamp.CLEARANCE)
		var bounds := Rect2(Vector2(16, 16), (def.world_size as Vector2) - Vector2(32, 32))
		var ids := {}
		var positions := {}
		var centers: Array = []
		suite.check(not camps.is_empty(), "floor %d defines camps" % floor_id)
		for camp: Dictionary in camps:
			suite.check(not ids.has(camp.id) and not camp.members.is_empty() and float(camp.respawn) >= 45.0 and float(camp.respawn) <= 120.0, "camp %s has a unique id, members and a sane respawn" % camp.id)
			ids[camp.id] = true
			var total := Vector2.ZERO
			for member: Dictionary in camp.members:
				suite.check(not FloorCatalog.monster_id_for_kind(int(member.kind)).is_empty() and int(member.kind) != 4, "camp %s member kind %d is a regular monster" % [camp.id, int(member.kind)])
				suite.check(bounds.has_point(member.position) and not area.has_point(member.position), "camp %s member %s is inside the world and outside the safe camp" % [camp.id, str(member.position)])
				suite.check(not positions.has(member.position), "camp %s member %s is not duplicated" % [camp.id, str(member.position)])
				positions[member.position] = true
				total += member.position
			centers.append(total / float(camp.members.size()))
		var nearest := INF
		for i in range(centers.size()):
			for j in range(i + 1, centers.size()):
				nearest = minf(nearest, (centers[i] as Vector2).distance_to(centers[j]))
		suite.check(nearest >= 340.0, "camp centers on floor %d stay at least 340 px apart (closest %.0f)" % [floor_id, nearest])
		# O monstro inicial do andar é o primeiro membro do primeiro acampamento.
		var first: Dictionary = camps[0].members[0]
		suite.check(int(first.kind) == FloorCatalog.first_enemy_kind(floor_id) and first.position == FloorCatalog.first_enemy_position(floor_id), "floor %d initial enemy is the first camp member" % floor_id)
	# Andar 1: todo membro vem de um ponto de spawn já existente.
	var spawns := FloorCatalog.enemy_spawns(1)
	for camp: Dictionary in FloorCatalog.camps(1):
		for member: Dictionary in camp.members:
			suite.check(spawns.has(member.position), "Andar 1 camp member %s reuses an existing spawn point" % str(member.position))
	suite.check(FloorCatalog.camps(3).is_empty() and FloorCatalog.camps(99).is_empty(), "floors without a definition have no camps")

static func _free_at(suite, point: Vector2) -> bool:
	# Mesmo corpo do monstro (círculo de 13 px) contra as paredes do mundo (camada 1).
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 13.0
	query.shape = shape
	query.transform = Transform2D(0.0, point)
	query.collision_mask = 1
	return suite.root.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

static func run_world(suite) -> void:
	var previous_path := OS.get_environment("ARVEON_SAVE_PATH")
	var path := "user://encounter_camps_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", path)
	GameOptions.set_override(GameOptions.MODE_CAMPS)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	suite.root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.progress.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	var camps: EncounterCamps = main.encounter_camps
	for i in range(3): await suite.frames()
	suite.check(not _free_at(suite, Vector2(2, 675)), "the open-ground probe does detect the world wall")
	for camp: Dictionary in FloorCatalog.camps(1):
		for member: Dictionary in camp.members:
			suite.check(_free_at(suite, member.position), "Andar 1 camp %s member %s stands on open ground" % [camp.id, str(member.position)])
	suite.check(main.camps_mode and camps.camps.size() == FloorCatalog.camps(1).size(), "camps mode is active on Andar 1 when requested")
	# Carregamento: acampamentos próximos nascem; o monstro inicial é adotado, não duplicado.
	var start := Vector2(540, 450)
	main.player.global_position = start
	camps.update(0.016, start)
	var expected_total := 0
	var expected_active := 0
	for camp: Dictionary in camps.camps:
		if start.distance_to(camp.center) <= EncounterCamps.SPAWN_RADIUS:
			expected_total += camp.def.members.size()
			expected_active += 1
	var enemies: Array = []
	for node in main.get_children():
		if node is EnemyActor: enemies.append(node)
	suite.check(camps.count_state(EncounterCamps.State.ACTIVE) == expected_active and enemies.size() == expected_total and camps.alive_count() == expected_total, "nearby camps spawn their members once (%d monsters)" % expected_total)
	var seen := {}
	var duplicated := false
	for actor: EnemyActor in enemies:
		if seen.has(actor.position): duplicated = true
		seen[actor.position] = true
	suite.check(not duplicated and main.enemy.has_meta("camp_id") and camps.alive_count() <= EncounterCamps.MAX_ALIVE, "initial enemy is adopted and the alive cap holds")
	suite.check(expected_active < camps.camps.size(), "camps beyond the spawn radius are not created yet")
	# Mesma contabilidade do modo contínuo: XP, ouro e contagem pelo mesmo caminho.
	var victim: EnemyActor = null
	for actor: EnemyActor in enemies:
		if actor.kind == 1: victim = actor
	if victim == null: victim = enemies[0]
	var xp_before: int = main.earned_xp
	var gold_before: int = main.earned_gold
	var defeats_before: int = main.defeated_count
	var ascension_before: int = main.progress.ascension.defeats["1"]
	var kind := victim.kind
	victim.health.damage(victim.health.current)
	suite.check(main.earned_xp - xp_before == FloorConfig.reward(FloorCatalog.xp_for_kind(kind), 1), "camp kill grants the same XP as a continuous kill")
	var gold_gain: int = main.earned_gold - gold_before
	suite.check(gold_gain >= 2 and gold_gain <= 5 and main.defeated_count == defeats_before + 1 and main.progress.ascension.defeats["1"] == ascension_before + 1, "camp kill grants gold and counts for the tower the same way")
	# Ciclo de vida: limpar um acampamento, esperar o respawn e só voltar fora da tela.
	var target: Dictionary = camps.camps[0]
	for actor in target.actors:
		if is_instance_valid(actor) and actor.health.is_alive(): actor.health.damage(actor.health.current)
	camps.update(0.016, start)
	suite.check(target.state == EncounterCamps.State.CLEARED and is_equal_approx(float(target.timer), float(target.def.respawn)), "a cleared camp waits its respawn time")
	camps.update(float(target.def.respawn) - 5.0, start)
	suite.check(target.state == EncounterCamps.State.CLEARED, "a camp does not respawn before its timer ends")
	var near_member: Vector2 = target.def.members[0].position + Vector2(200, 0)
	camps.update(10.0, near_member)
	suite.check(target.state == EncounterCamps.State.CLEARED, "a camp never respawns within sight of the player")
	var far_corner := Vector2(1640, 1310)
	camps.update(0.016, far_corner)
	suite.check(target.state == EncounterCamps.State.UNSPAWNED, "a camp becomes eligible once the player is far from every member")
	camps.update(0.016, far_corner)
	suite.check(target.state == EncounterCamps.State.UNSPAWNED and far_corner.distance_to(target.center) > EncounterCamps.SPAWN_RADIUS, "a camp outside the spawn radius stays uncreated")
	var approach := Vector2(912, 1300)
	suite.check(approach.distance_to(target.center) <= EncounterCamps.SPAWN_RADIUS and approach.distance_to(target.def.members[2].position) >= EncounterCamps.MIN_SPAWN_DISTANCE, "the approach point is inside the radius but out of sight")
	camps.update(0.016, approach)
	suite.check(target.state == EncounterCamps.State.ACTIVE and camps.alive_count() <= EncounterCamps.MAX_ALIVE, "a camp spawns again when the player is near but out of sight")
	# Descarte por distância: acampamento intocado e muito distante é liberado.
	var distant: Dictionary = {}
	for camp: Dictionary in camps.camps:
		if camp.def.id == "sentinela_oeste": distant = camp
	distant.state = EncounterCamps.State.UNSPAWNED
	camps.update(0.016, Vector2(880, 460))
	suite.check(distant.state == EncounterCamps.State.ACTIVE and not distant.persistent, "the west sentinel spawns when approached")
	var doomed: Array = distant.actors.duplicate()
	camps.update(0.016, Vector2(1690, 1340))
	await suite.frames()
	var freed := true
	for actor in doomed: freed = freed and not is_instance_valid(actor)
	suite.check(distant.state == EncounterCamps.State.UNSPAWNED and freed, "an untouched camp is released when the player is very far")
	# Redefinir (Torre, troca de andar) deixa tudo pronto para recomeçar.
	camps.reset()
	suite.check(camps.count_state(EncounterCamps.State.UNSPAWNED) == camps.camps.size() and camps.alive_count() == 0, "reset returns every camp to its initial state")
	# O modo contínuo continua sendo o padrão quando a opção não é pedida.
	GameOptions.set_override("")
	main._setup_encounters()
	suite.check(not main.camps_mode and camps.camps.is_empty(), "continuous mode leaves the camp system idle")
	GameOptions.set_override(GameOptions.MODE_CAMPS)
	# Andar 2: mesmos acampamentos, tipos originais.
	main.progress.ascension.current_floor = 2
	main._setup_encounters()
	suite.check(main.camps_mode and camps.camps.size() == FloorCatalog.camps(2).size(), "camps mode covers Andar 2")
	main.queue_free()
	await suite.frames()
	# Andar 2: cada posição de acampamento precisa estar livre de obstáculos do mundo.
	var vale := (load(FloorConfig.world_scene(2)) as PackedScene).instantiate()
	suite.root.add_child(vale)
	for i in range(4): await suite.frames()
	for camp: Dictionary in FloorCatalog.camps(2):
		for member: Dictionary in camp.members:
			suite.check(_free_at(suite, member.position), "Andar 2 camp %s member %s stands on open ground" % [camp.id, str(member.position)])
	vale.queue_free()
	await suite.frames()
	GameOptions.set_override("")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.set_environment("ARVEON_SAVE_PATH", previous_path)
