extends RefCounted
static func seed_existing() -> void:
	var existing := GameProgress.new()
	existing.save_path = OS.get_environment("ARVEON_SAVE_PATH")
	# Reset fixed QA paths as well; captures exercise established characters.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(existing.save_path))
	existing.save()

static func unlock(progress: GameProgress, category: String = "espada", level: int = 8) -> void:
	progress.talents.xp[category] = TalentRules.xp_floor(level)
	progress.abilities.select_skill(category,0,AbilityRules.CATEGORIES[category].normal[0].id,level,true)
	progress.abilities.select_skill(category,1,AbilityRules.CATEGORIES[category].normal[1].id,level,true)
static func reset(player: PlayerActor) -> void:
	player._cancel_skill1()
	player.progress.abilities.death_reset()
	player.class_combat.clear_effects()
	player._sync_skill_cooldowns()

static func legacy_skills(progress: GameProgress) -> Dictionary:
	var result := {"Corte Circular":1,"Investida":1,"Fúria Ancestral":1}
	for id: String in progress.skills: result[id] = progress.skills[id]
	return result

static func finish_skill1(player: PlayerActor) -> void:
	# Frozen-physics combat fixtures advance the explicitly approved startup.
	if player.skill1_pending > 0: player._tick_skill1(player.skill1_pending)

static func finish_technique(player: PlayerActor) -> void:
	if not player.class_combat.technique.is_empty():
		var id: String = player.class_combat.technique.id
		var duration: float = BowTechniqueEffect.duration_time(id,float(player.class_combat.technique.reach)) if BowTechniqueEffect.TIMINGS.has(id) else float(StaffTechniqueEffect.TIMINGS[id].duration) if StaffTechniqueEffect.TIMINGS.has(id) else float(AxeTechniqueEffect.TIMINGS[id].duration) if AxeTechniqueEffect.TIMINGS.has(id) else float(SpearTechniqueEffect.TIMINGS[id].duration) if SpearTechniqueEffect.TIMINGS.has(id) else SwordTechniqueTiming.duration(id)
		player.class_combat.tick(duration)
