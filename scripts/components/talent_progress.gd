class_name TalentProgress
extends RefCounted

var xp: Dictionary = {}
var learned: Dictionary = {}
var mastery: Dictionary = {}
var damage_remainder: Dictionary = {}

func _init() -> void:
	for weapon: String in ArsenalRules.CATEGORIES:
		xp[weapon] = 0
		damage_remainder[weapon] = 0
		learned[weapon] = []
		mastery[weapon] = {"Dano":0,"Dano Especial":0,"Crítico":0,"Dano Crítico":0}

func level(weapon: String) -> int:
	return TalentRules.level_for_xp(int(xp.get(weapon,0)))

func record_damage(weapon: String, effective: int) -> bool:
	if not xp.has(weapon) or effective <= 0 or int(xp[weapon]) >= TalentRules.xp_floor(30): return false
	var damage_units := int(damage_remainder[weapon])+effective
	@warning_ignore("integer_division")
	xp[weapon] = mini(TalentRules.xp_floor(30), int(xp[weapon])+damage_units/TalentRules.DAMAGE_PER_XP)
	damage_remainder[weapon] = damage_units%TalentRules.DAMAGE_PER_XP if int(xp[weapon]) < TalentRules.xp_floor(30) else 0
	return true

func mastery_points(weapon: String) -> int:
	if not mastery.has(weapon): return 0
	var used := 0
	for amount: int in mastery[weapon].values(): used += amount
	return maxi(0,level(weapon)-1-used)

func allocate_mastery(weapon: String, stat: String, expected: int) -> bool:
	if not mastery.has(weapon) or not TalentRules.MASTERY.has(stat) or mastery_points(weapon) < 1: return false
	if int(mastery[weapon][stat]) != expected or expected >= int(TalentRules.MASTERY[stat].cap): return false
	mastery[weapon][stat] = expected+1
	return true

func mastery_bonuses(weapon: String) -> Dictionary:
	var values: Dictionary = mastery.get(weapon,{})
	return {"automatic":(level(weapon)-1)*0.005 if xp.has(weapon) else 0.0,
		"basic":int(values.get("Dano",0))*0.01,"special":int(values.get("Dano Especial",0))*0.0125,
		"critical_chance":0.05+int(values.get("Crítico",0))*0.01,
		"critical_multiplier":1.5+int(values.get("Dano Crítico",0))*0.03}

func reset_mastery(weapon: String) -> bool:
	if not mastery.has(weapon):
		return false
	var invested := 0
	for amount: int in mastery[weapon].values():
		invested += amount
	if invested == 0:
		return false
	for stat: String in TalentRules.MASTERY:
		mastery[weapon][stat] = 0
	return true

func reset_tree(weapon: String) -> bool:
	if not learned.has(weapon) or learned[weapon].is_empty(): return false
	learned[weapon].clear()
	return true

func owns(weapon: String, node: String) -> bool:
	return learned.has(weapon) and learned[weapon].has(node)

func spent() -> int:
	var total := 0
	for nodes: Array in learned.values(): total += nodes.size()
	return total

func available(weapon: String, node: String, points: int) -> bool:
	if not learned.has(weapon) or not TalentRules.NODES.has(node) or owns(weapon,node) or points < 1: return false
	var rule: Dictionary = TalentRules.NODES[node]
	return level(weapon) >= rule.prof and (rule.parent.is_empty() or owns(weapon,rule.parent))

func learn(weapon: String, node: String, points: int) -> bool:
	if not available(weapon,node,points): return false
	learned[weapon].append(node)
	return true

func bonuses(weapon: String) -> Dictionary:
	var result := {"hp":0,"damage":0,"armor":0}
	for node: String in learned.get(weapon,[]):
		for stat: String in TalentRules.NODES[node].bonus: result[stat] += int(TalentRules.NODES[node].bonus[stat])
	return result

func to_save() -> Dictionary:
	return {"xp":xp.duplicate(true),"learned":learned.duplicate(true),"mastery":mastery.duplicate(true),"damage_remainder":damage_remainder.duplicate(true)}

static func from_save(value: Variant, points: int, legacy: bool = false) -> TalentProgress:
	if not value is Dictionary or value.size() != (2 if legacy else 4) or not value.get("xp") is Dictionary or not value.get("learned") is Dictionary: return null
	if value.xp.size() != 5 or value.learned.size() != 5: return null
	if not legacy and (not value.get("mastery") is Dictionary or value.mastery.size() != 5): return null
	if not legacy and (not value.get("damage_remainder") is Dictionary or value.damage_remainder.size() != 5): return null
	var result := TalentProgress.new()
	for weapon: String in ArsenalRules.CATEGORIES:
		var amount: Variant = value.xp.get(weapon)
		var nodes: Variant = value.learned.get(weapon)
		var cap := 8700 if legacy else TalentRules.xp_floor(30)
		if not amount is float or amount != floorf(amount) or amount < 0 or amount > cap or not nodes is Array or nodes.size() > TalentRules.NODES.size(): return null
		result.xp[weapon] = floori(float(amount)*0.4) if legacy else int(amount)
		if not legacy:
			var remainder: Variant = value.damage_remainder.get(weapon)
			if not remainder is float or remainder != floorf(remainder) or remainder < 0 or remainder >= TalentRules.DAMAGE_PER_XP or (int(amount) == TalentRules.xp_floor(30) and remainder != 0): return null
			result.damage_remainder[weapon] = int(remainder)
			var distribution: Variant = value.mastery.get(weapon)
			if not distribution is Dictionary or distribution.size() != 4: return null
			var used := 0
			for stat: String in TalentRules.MASTERY:
				var invested: Variant = distribution.get(stat)
				if not invested is float or invested != floorf(invested) or invested < 0 or invested > TalentRules.MASTERY[stat].cap: return null
				result.mastery[weapon][stat] = int(invested)
				used += int(invested)
			if used > result.level(weapon)-1: return null
		for node: Variant in nodes:
			if not node is String or not TalentRules.NODES.has(node) or result.owns(weapon,node) or result.level(weapon) < TalentRules.NODES[node].prof: return null
			result.learned[weapon].append(node)
		# Check the entire set, independent of JSON ordering.
		for node: String in result.learned[weapon]:
			var parent: String = TalentRules.NODES[node].parent
			if not parent.is_empty() and not result.owns(weapon,parent): return null
	if result.spent() > points: return null
	return result
