extends RefCounted
static func unlock(progress: GameProgress, category: String = "espada", level: int = 8) -> void:
	progress.talents.xp[category] = TalentRules.xp_floor(level)
	progress.abilities.select_skill(category,0,AbilityRules.CATEGORIES[category].normal[0].id,level,true)
	progress.abilities.select_skill(category,1,AbilityRules.CATEGORIES[category].normal[1].id,level,true)
static func reset(player: PlayerActor) -> void:
	player.progress.abilities.death_reset()
	player.class_combat.clear_effects()
	player._sync_skill_cooldowns()

static func legacy_skills(progress: GameProgress) -> Dictionary:
	var result := {"Corte Circular":1,"Investida":1,"Fúria Ancestral":1}
	for id: String in progress.skills: result[id] = progress.skills[id]
	return result
