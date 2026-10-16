class_name TrainingLoadout
extends RefCounted

# Entirely ephemeral: never call save(), load_save(), import_backup(), or BrowserSave.
# Every unlock is local to the training scene. Campaign state is never referenced.

static func build() -> GameProgress:
	var value := GameProgress.new()
	value.xp = RPGRules.xp_floor(RPGRules.MAX_LEVEL)
	value.gold = 999999
	value.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	value.equipment.clear()
	for attribute: String in RPGRules.ATTRIBUTES:
		value.attributes[attribute] = 33 # All 198 attribute points distributed.
	for category: String in AbilityRules.CATEGORIES:
		value.equipment[category] = 3
		value.talents.xp[category] = TalentRules.xp_floor(TalentRules.MAX_PROFICIENCY)
		for stat: String in TalentRules.MASTERY:
			value.talents.mastery[category][stat] = int(TalentRules.MASTERY[stat].cap)
		var catalogue: Dictionary = AbilityRules.CATEGORIES[category]
		for rule: Dictionary in catalogue.normal:
			value.abilities.grades[category][rule.id] = AbilityRules.MAX_NORMAL_GRADE
		for talent: Dictionary in AbilityRules.TALENTS[category]:
			value.abilities.talents[category].append(talent.id)
		var slots: Array = value.abilities.loadouts[category].skills
		slots[0] = catalogue.normal[0].id
		slots[1] = catalogue.ultimate.id
		var passives: Array = value.abilities.loadouts[category].passives
		passives[0] = catalogue.passives[0].id
		passives[1] = catalogue.passives[1].id
		value.abilities.loadouts[category].specialization = catalogue.specializations[0]
	value.equipped.Arma = "espada"
	value.save_blocked = true # Secondary defense even if a save() call slips in.
	value.save_status = "Modo Treino: nenhum progresso será salvo."
	return value

static func equip(value: GameProgress, category: String, skill2: String, skill3: String, passive1: String, passive2: String, specialization: String) -> bool:
	if not AbilityRules.CATEGORIES.has(category):
		return false
	var catalog: Dictionary = AbilityRules.CATEGORIES[category]
	var available_skills: Array[String] = []
	for rule: Dictionary in catalog.normal:
		available_skills.append(rule.id)
	available_skills.append(catalog.ultimate.id)
	var available_passives: Array[String] = []
	for rule: Dictionary in catalog.passives:
		available_passives.append(rule.id)
	if skill2 == skill3 or passive1 == passive2:
		return false
	if not available_skills.has(skill2) or not available_skills.has(skill3):
		return false
	if not available_passives.has(passive1) or not available_passives.has(passive2):
		return false
	if not catalog.specializations.has(specialization):
		return false
	value.equipped.Arma = category
	value.abilities.loadouts[category].skills = [skill2,skill3]
	value.abilities.loadouts[category].passives = [passive1,passive2]
	value.abilities.loadouts[category].specialization = specialization
	reset_combat(value)
	return true

static func reset_combat(value: GameProgress) -> void:
	value.abilities.death_reset()
	refill(value)

static func refill(value: GameProgress) -> void:
	var category := value.active_category()
	if category.is_empty():
		return
	value.abilities.charge[category] = AbilityRules.MAX_ULTIMATE_CHARGE
	value.abilities.charge_remainder[category] = 0
	value.abilities.skill1_cooldowns[category] = 0.0
	value.abilities.cooldowns[category].clear()
	value.abilities.global_ultimate_cooldown = 0.0
	value.abilities.last_ultimate_category = ""
