class_name TalentProgress
extends RefCounted

var xp: Dictionary = {}
var learned: Dictionary = {}

func _init() -> void:
	for weapon: String in ArsenalRules.CATEGORIES:
		xp[weapon] = 0
		learned[weapon] = []

func level(weapon: String) -> int:
	return TalentRules.level_for_xp(int(xp.get(weapon,0)))

func record_hit(weapon: String) -> bool:
	if not xp.has(weapon) or int(xp[weapon]) >= TalentRules.xp_floor(30): return false
	xp[weapon] = int(xp[weapon])+1
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
	return {"xp":xp.duplicate(true),"learned":learned.duplicate(true)}

static func from_save(value: Variant, points: int) -> TalentProgress:
	if not value is Dictionary or value.size() != 2 or not value.get("xp") is Dictionary or not value.get("learned") is Dictionary: return null
	if value.xp.size() != 5 or value.learned.size() != 5: return null
	var result := TalentProgress.new()
	for weapon: String in ArsenalRules.CATEGORIES:
		var amount: Variant = value.xp.get(weapon)
		var nodes: Variant = value.learned.get(weapon)
		if not amount is float or amount != floorf(amount) or amount < 0 or amount > TalentRules.xp_floor(30) or not nodes is Array or nodes.size() > TalentRules.NODES.size(): return null
		result.xp[weapon] = int(amount)
		for node: Variant in nodes:
			if not node is String or not TalentRules.NODES.has(node) or result.owns(weapon,node) or result.level(weapon) < TalentRules.NODES[node].prof: return null
			result.learned[weapon].append(node)
		# Check the entire set, independent of JSON ordering.
		for node: String in result.learned[weapon]:
			var parent: String = TalentRules.NODES[node].parent
			if not parent.is_empty() and not result.owns(weapon,parent): return null
	if result.spent() > points: return null
	return result
