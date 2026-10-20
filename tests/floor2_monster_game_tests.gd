extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("MONSTER GAME OK: " + message)
	else:
		failures += 1
		push_error("MONSTER GAME FAIL: " + message)

func _run() -> void:
	var save_path := "user://qa_floor2_monsters_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	_check(main.enemy.kind == 0 and not main.enemy.view is Floor2MonsterView, "Andar 1 mantém inimigo e visual originais")
	main.progress.ascension.defeats["1"] = 50
	main.progress.ascension.complete_forest_trial()
	await main._travel_floor(2)
	main.set_process(false)
	main.player.set_physics_process(false)
	_check(main.enemy.kind == 6 and main.enemy.view is Floor2MonsterView, "viagem cria Tatu Rochoso real")
	_check(Floor2Layout.ENEMY_SPAWNS.size() == Floor2Layout.ENEMY_SPAWN_KINDS.size(), "cada ponto de surgimento possui espécie")
	main.player.position = Vector2(510, 350)
	main._spawn_enemy()
	var quarry_spawned := false
	for existing in get_nodes_in_group("damageable_enemies"):
		if existing is EnemyActor and existing.kind == 5 and existing.position == Floor2Layout.ENEMY_SPAWNS[5]:
			quarry_spawned = true
			existing.set_physics_process(false)
	_check(quarry_spawned, "surgimento real da Pedreira cria Goblin Garimpeiro")
	for kind in [5, 6, 7]:
		var actor: EnemyActor = main._make_enemy(kind)
		actor.position = Floor2Layout.ENEMY_SPAWNS[[5, 0, 6][kind - 5]]
		actor.target = main.player
		main._register_enemy_defeat(actor)
		main.add_child(actor)
		actor.set_physics_process(false)
		var view := actor.view as Floor2MonsterView
		_check(view != null and view.monster_index == kind - 5 and actor.health.current == actor.stats.max_hp, "espécie %d usa sheet e HP próprios" % kind)
		view.set_moving(true)
		view._process(0.1)
		_check(view.animation_state == "walk", "espécie %d caminha animada (estado: %s)" % [kind, view.animation_state])
		view.set_moving(false)
		if kind == 6:
			actor.charge_left = 0.25
			view._process(0.1)
			_check(view.animation_state == "charge", "investida do Tatu usa animação própria")
			actor.charge_left = 0.0
		else:
			view.play_attack()
			view._process(0.1)
			_check(view.animation_state == "attack", "espécie %d ataca animada" % kind)
		actor.receive_damage(1)
		await process_frame
		_check(view.animation_state == "hit", "espécie %d reage ao dano" % kind)
		var xp_before: int = main.earned_xp
		actor.receive_damage(actor.health.current)
		await process_frame
		_check(view.animation_state == "death" and main.earned_xp > xp_before, "espécie %d morre e concede XP uma vez" % kind)
		actor.queue_free()
		await process_frame
	await main._travel_floor(1)
	_check(main.enemy.kind == 0 and not main.enemy.view is Floor2MonsterView, "retorno preserva o Andar 1")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("GRANDE_ARVORE_SAVE_PATH")
	print("MONSTER GAME RESULT: %d failures" % failures)
	quit(1 if failures > 0 else 0)
