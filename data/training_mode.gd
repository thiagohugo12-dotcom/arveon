class_name TrainingMode
extends RefCounted

## A disposable build. Never load or serialize this build over the player's journal.
static func create() -> GameProgress:
	var practice := GameProgress.new()
	practice.training_mode = true
	practice.xp = RPGRules.xp_floor(RPGRules.MAX_LEVEL)
	practice.gold = 99999
	practice.introduction = {"status":"legacy","met_smith":true,"weapon":""}
	practice.equipment.clear()
	for id: String in RPGRules.EQUIPMENT:
		practice.equipment[id] = 0
	practice.equipped.Arma = "espada"
	for item: String in GameProgress.ITEMS:
		practice.bag[item] = 99
	for category: String in AbilityRules.CATEGORIES:
		practice.talents.xp[category] = TalentRules.xp_floor(TalentRules.MAX_PROFICIENCY)
		var catalog: Dictionary = AbilityRules.CATEGORIES[category]
		practice.abilities.loadouts[category].skills = [catalog.normal[0].id,catalog.ultimate.id]
		practice.abilities.loadouts[category].passives = [catalog.passives[0].id,catalog.passives[1].id]
		practice.abilities.charge[category] = 100
	practice.ascension.unlocked_floors = [1,2,3,4,5]
	practice.ascension.forest_seal = true
	for floor_id in range(1,6):
		practice.ascension.defeats[str(floor_id)] = practice.ascension.required_defeats(floor_id)
	return practice

static func refill(practice: GameProgress) -> void:
	if not practice.training_mode: return
	for category: String in AbilityRules.CATEGORIES:
		practice.abilities.cooldowns[category].clear()
		practice.abilities.skill1_cooldowns[category] = 0.0
		practice.abilities.charge[category] = 100
		practice.abilities.charge_remainder[category] = 0
	practice.abilities.global_ultimate_cooldown = 0.0
	practice.abilities.last_ultimate_category = ""
