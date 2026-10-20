extends RefCounted

static func run(suite, main) -> void:
	var original: int = main.progress.ascension.current_floor
	for id in range(1, 6):
		main.progress.ascension.current_floor = id
		for kind in range(4):
			var actor: EnemyActor = main._make_enemy(kind)
			var multiplier := FloorConfig.difficulty(id)
			var base_hp: int = [48, 36, 64, 120][kind]
			var base_damage: int = [8, 7, 10, 12][kind]
			suite.check(actor.stats.max_hp == roundi(base_hp * multiplier) and actor.stats.contact_damage == roundi(base_damage * multiplier), "floor %d kind %d has configured HP and damage" % [id, kind])
			suite.check(actor.projectile_damage_override == roundi(maxi(4, base_damage - 2) * multiplier) and actor.damage_scale == multiplier, "floor %d kind %d scales ranged damage from base once" % [id, kind])
			main._apply_floor_stats(actor)
			suite.check(actor.stats.max_hp == roundi(base_hp * multiplier), "floor scaling is idempotent %d/%d" % [id, kind])
			actor.free()
	main.progress.ascension.current_floor = original
	suite.check((load("res://data/actors/enemy.tres") as ActorData).max_hp == 48, "all five floors preserve original enemy resource")
