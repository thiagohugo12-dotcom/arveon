class_name AbilityState
extends RefCounted

# Separate, versionable combat state for Etapa 2. Legacy saves remain v9
# until the runtime and UI migration are exercised end-to-end.
var loadouts: Dictionary = {}
var grades: Dictionary = {}
var talents: Dictionary = {}
var charge: Dictionary = {}
var charge_remainder: Dictionary = {}
var cooldowns: Dictionary = {}
var skill1_cooldowns: Dictionary = {}
var global_ultimate_cooldown := 0.0
var last_ultimate_category := ""

func _init() -> void:
	for category: String in AbilityRules.CATEGORIES:
		loadouts[category] = {"skills":["",""],"passives":["",""],"specialization":""}
		grades[category] = {}
		talents[category] = []
		charge[category] = 0
		charge_remainder[category] = 0
		cooldowns[category] = {}
		skill1_cooldowns[category] = 0.0

func spent() -> int:
	var sum := 0
	for category: String in AbilityRules.CATEGORIES:
		for grade: int in grades[category].values():
			sum += grade - 1
		sum += talents[category].size()
	return sum

func select_skill(category: String, slot: int, id: String, prof: int, at_camp: bool) -> bool:
	if not at_camp or not loadouts.has(category) or slot < 0 or slot > 1:
		return false
	if not id.is_empty() and not AbilityRules.available(category,id,prof):
		return false
	var other: int = 1 - slot
	if not id.is_empty() and loadouts[category].skills[other] == id:
		return false
	loadouts[category].skills[slot] = id
	return true

func select_passive(category: String, slot: int, id: String, prof: int, at_camp: bool) -> bool:
	if not at_camp or not loadouts.has(category) or slot < 0 or slot > 1:
		return false
	if not id.is_empty():
		var rule := AbilityRules.passive(category,id)
		if rule.is_empty() or prof < int(rule.prof) or loadouts[category].passives[1-slot] == id:
			return false
	loadouts[category].passives[slot] = id
	return true

func set_specialization(category: String, id: String, prof: int, at_camp: bool) -> bool:
	if not at_camp or prof < 18 or not loadouts.has(category):
		return false
	if not id.is_empty() and not AbilityRules.CATEGORIES[category].specializations.has(id):
		return false
	loadouts[category].specialization = id
	return true

func improve(category: String, id: String, prof: int, free_points: int, at_camp: bool) -> bool:
	var rule := AbilityRules.active_skill(category,id)
	if not at_camp or free_points < 1 or rule.is_empty() or id == AbilityRules.CATEGORIES[category].ultimate.id or prof < int(rule.prof):
		return false
	var grade := int(grades[category].get(id,1))
	if grade >= AbilityRules.MAX_NORMAL_GRADE:
		return false
	grades[category][id] = grade + 1
	return true

func learn_talent(category: String, id: String, prof: int, free_points: int, at_camp: bool) -> bool:
	if not at_camp or free_points < 1 or not talents.has(category) or talents[category].has(id):
		return false
	var rule := AbilityRules.talent(category,id)
	if rule.is_empty() or prof < int(rule.prof) or (not rule.parent.is_empty() and not talents[category].has(rule.parent)):
		return false
	talents[category].append(id)
	return true

func refund(category: String, at_camp: bool) -> bool:
	if not at_camp or not grades.has(category):
		return false
	grades[category].clear()
	talents[category].clear()
	return true

func tick(delta: float, active_category: String) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	global_ultimate_cooldown = maxf(0.0,global_ultimate_cooldown-delta)
	if not cooldowns.has(active_category):
		return
	skill1_cooldowns[active_category] = maxf(0.0,float(skill1_cooldowns[active_category])-delta)
	for id: String in cooldowns[active_category]:
		cooldowns[active_category][id] = maxf(0.0,float(cooldowns[active_category][id])-delta)

func start_skill1(category: String, seconds: float) -> bool:
	if not skill1_cooldowns.has(category) or float(skill1_cooldowns[category]) > 0.0 or not _safe_number(seconds,120.0) or seconds <= 0.0:
		return false
	skill1_cooldowns[category] = seconds
	return true

func start_normal(category: String, id: String, prof: int) -> bool:
	var rule := AbilityRules.active_skill(category,id)
	if rule.is_empty() or id == AbilityRules.CATEGORIES[category].ultimate.id or prof < int(rule.prof):
		return false
	if not loadouts[category].skills.has(id) or float(cooldowns[category].get(id,0.0)) > 0.0:
		return false
	cooldowns[category][id] = float(rule.cooldown)
	return true

func add_ultimate_damage(category: String, effective: int, active_category: String) -> bool:
	if effective <= 0 or category != active_category or not charge.has(category):
		return false
	if not loadouts[category].skills.has(AbilityRules.CATEGORIES[category].ultimate.id) or int(charge[category]) >= AbilityRules.MAX_ULTIMATE_CHARGE:
		return false
	var units := int(charge_remainder[category]) + effective
	@warning_ignore("integer_division")
	charge[category] = mini(AbilityRules.MAX_ULTIMATE_CHARGE,int(charge[category])+units/AbilityRules.CHARGE_HP_PER_POINT)
	charge_remainder[category] = units % AbilityRules.CHARGE_HP_PER_POINT if int(charge[category]) < AbilityRules.MAX_ULTIMATE_CHARGE else 0
	return true

func use_ultimate(category: String, active_category: String) -> bool:
	if category != active_category or not charge.has(category) or (global_ultimate_cooldown > 0.0 and category != last_ultimate_category):
		return false
	if int(charge[category]) != AbilityRules.MAX_ULTIMATE_CHARGE or not loadouts[category].skills.has(AbilityRules.CATEGORIES[category].ultimate.id):
		return false
	charge[category] = 0
	charge_remainder[category] = 0
	global_ultimate_cooldown = AbilityRules.GLOBAL_ULTIMATE_INTERVAL
	last_ultimate_category = category
	return true

func death_reset() -> void:
	global_ultimate_cooldown = 0.0
	last_ultimate_category = ""
	for category: String in AbilityRules.CATEGORIES:
		charge[category] = 0
		charge_remainder[category] = 0
		skill1_cooldowns[category] = 0.0
		cooldowns[category].clear()

func to_save() -> Dictionary:
	return {"loadouts":loadouts.duplicate(true),"grades":grades.duplicate(true),"talents":talents.duplicate(true),
		"charge":charge.duplicate(true),"charge_remainder":charge_remainder.duplicate(true),
		"cooldowns":cooldowns.duplicate(true),"skill1_cooldowns":skill1_cooldowns.duplicate(true),
		"global_ultimate_cooldown":global_ultimate_cooldown,"last_ultimate_category":last_ultimate_category}

static func _safe_number(value: Variant, max_value: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= 0.0 and float(value) <= max_value

static func from_save(raw: Variant, proficiencies: Dictionary, point_budget: int) -> AbilityState:
	if not raw is Dictionary or raw.size() != 9:
		return null
	var fields := ["loadouts","grades","talents","charge","charge_remainder","cooldowns","skill1_cooldowns"]
	for field: String in fields:
		if not raw.get(field) is Dictionary or raw[field].size() != AbilityRules.CATEGORIES.size():
			return null
	if not _safe_number(raw.get("global_ultimate_cooldown"),AbilityRules.GLOBAL_ULTIMATE_INTERVAL):
		return null
	if not raw.get("last_ultimate_category") is String or (not raw.last_ultimate_category.is_empty() and not AbilityRules.CATEGORIES.has(raw.last_ultimate_category)):
		return null
	if float(raw.global_ultimate_cooldown) > 0.0 and raw.last_ultimate_category.is_empty():
		return null
	var result := AbilityState.new()
	result.last_ultimate_category = raw.last_ultimate_category
	result.global_ultimate_cooldown = float(raw.global_ultimate_cooldown)
	for category: String in AbilityRules.CATEGORIES:
		var level := int(proficiencies.get(category,0))
		if level < 1 or level > TalentRules.MAX_PROFICIENCY:
			return null
		var entry: Variant = raw.loadouts.get(category)
		if not entry is Dictionary or entry.size() != 3 or not entry.get("skills") is Array or not entry.get("passives") is Array or not entry.get("specialization") is String:
			return null
		if entry.skills.size() != 2 or entry.passives.size() != 2:
			return null
		for i in range(2):
			if not entry.skills[i] is String or not entry.passives[i] is String:
				return null
			if not entry.skills[i].is_empty() and not AbilityRules.available(category,entry.skills[i],level):
				return null
			if not entry.passives[i].is_empty():
				var rule := AbilityRules.passive(category,entry.passives[i])
				if rule.is_empty() or level < int(rule.prof):
					return null
		if (not entry.skills[0].is_empty() and entry.skills[0] == entry.skills[1]) or (not entry.passives[0].is_empty() and entry.passives[0] == entry.passives[1]):
			return null
		if not entry.specialization.is_empty() and (level < 18 or not AbilityRules.CATEGORIES[category].specializations.has(entry.specialization)):
			return null
		result.loadouts[category] = {"skills":entry.skills.duplicate(),"passives":entry.passives.duplicate(),"specialization":entry.specialization}
		var category_grades: Variant = raw.grades.get(category)
		var category_talents: Variant = raw.talents.get(category)
		var category_cooldowns: Variant = raw.cooldowns.get(category)
		if not category_grades is Dictionary or not category_talents is Array or not category_cooldowns is Dictionary:
			return null
		for id: Variant in category_grades:
			if not id is String: return null
			var rule := AbilityRules.active_skill(category,id)
			var grade: Variant = category_grades[id]
			if rule.is_empty() or id == AbilityRules.CATEGORIES[category].ultimate.id or level < int(rule.prof):
				return null
			if not _safe_number(grade,AbilityRules.MAX_NORMAL_GRADE) or float(grade) != floorf(float(grade)) or int(grade) < 2:
				return null
			result.grades[category][id] = int(grade)
		for id: Variant in category_talents:
			if not id is String or result.talents[category].has(id):
				return null
			var rule := AbilityRules.talent(category,id)
			if rule.is_empty() or level < int(rule.prof):
				return null
			result.talents[category].append(id)
		for id: String in result.talents[category]:
			var rule := AbilityRules.talent(category,id)
			if not rule.parent.is_empty() and not result.talents[category].has(rule.parent):
				return null
		for id: Variant in category_cooldowns:
			if not id is String: return null
			var rule := AbilityRules.active_skill(category,id)
			if rule.is_empty() or id == AbilityRules.CATEGORIES[category].ultimate.id or not _safe_number(category_cooldowns[id],float(rule.cooldown)):
				return null
			result.cooldowns[category][id] = float(category_cooldowns[id])
		var amount: Variant = raw.charge.get(category)
		var remainder: Variant = raw.charge_remainder.get(category)
		var skill1_left: Variant = raw.skill1_cooldowns.get(category)
		if not _safe_number(amount,AbilityRules.MAX_ULTIMATE_CHARGE) or floorf(float(amount)) != float(amount):
			return null
		if not _safe_number(remainder,AbilityRules.CHARGE_HP_PER_POINT-1) or floorf(float(remainder)) != float(remainder):
			return null
		if int(amount) == AbilityRules.MAX_ULTIMATE_CHARGE and int(remainder) != 0:
			return null
		if not _safe_number(skill1_left,120.0):
			return null
		result.charge[category] = int(amount)
		result.charge_remainder[category] = int(remainder)
		result.skill1_cooldowns[category] = float(skill1_left)
	if result.spent() > point_budget:
		return null
	return result
