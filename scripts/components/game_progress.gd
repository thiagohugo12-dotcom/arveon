class_name GameProgress
extends RefCounted

const ITEMS := ["Couro", "Seda", "Essência", "Broto Ancestral", "Ervas", "Cogumelos", "Madeira", "Pedras"]
const TRADE_ITEMS := ["Couro", "Seda", "Essência"]
const SELL_ITEMS := ["Couro", "Seda", "Essência", "Ervas", "Cogumelos", "Madeira", "Pedras"]
const BUY_PRICE := 5
const SELL_PRICE := 2
const SAVE_VERSION := 5
const ATTRIBUTES := RPGRules.ATTRIBUTES
const MAX_LEVEL := RPGRules.MAX_LEVEL
const POINTS_PER_LEVEL := 2

const ADVENTURES := {"explorar": 3, "forjar": 1, "elite": 1, "guardiao": 1}
var adventures: Dictionary = {"explorar": 0, "forjar": 0, "elite": 0, "guardiao": 0}

var save_path: String = "user://andar1_progress.json"
var bag: Dictionary = {}
var chest: Dictionary = {}
var gold: int = 0
var xp: int = 0
var kills: int = 0
var mission_index: int = 0
var mission_progress: int = 0
var mission_completed: int = 0
var harvested_until: Dictionary = {}
var opened_caches: Dictionary = {}
var discovered_pois: Dictionary = {}
var attributes: Dictionary = {"Força": 0, "Vitalidade": 0, "Agilidade": 0, "Espírito": 0}
var skills: Dictionary = {"Corte Circular": 1, "Investida": 1, "Fúria Ancestral": 1}
# Recipe IDs are unique inventory identities; equipping never removes ownership.
var equipment: Dictionary = {"espada": 0}
var equipped: Dictionary = {"Arma": "espada", "Armadura": "", "Acessório": ""}

func level() -> int:
	return RPGRules.level_for_xp(xp)

func attribute_points() -> int:
	var spent := 0
	for value in attributes.values():
		spent += int(value)
	return maxi(0, (level() - 1) * 2 - spent)

func skill_points() -> int:
	var spent := 0
	for value in skills.values():
		spent += int(value) - 1
	return maxi(0, level() - 1 - spent)

func allocate_attribute(name: String) -> bool:
	if not RPGRules.ATTRIBUTES.has(name) or attribute_points() < 1 or int(attributes[name]) >= 198:
		return false
	attributes[name] = int(attributes[name]) + 1
	return true

func improve_skill(name: String) -> bool:
	if not RPGRules.SKILLS.has(name) or skill_points() < 1 or int(skills[name]) >= 3:
		return false
	skills[name] = int(skills[name]) + 1
	return true

func can_forge(id: String) -> bool:
	if not RPGRules.EQUIPMENT.has(id) or (equipment.has(id) and int(equipment[id]) >= 3):
		return false
	var cost := RPGRules.recipe(id, equipment.has(id), int(equipment.get(id, 0)))
	if gold < int(cost.gold):
		return false
	for item: String in cost.materials:
		if int(bag.get(item, 0)) < int(cost.materials[item]):
			return false
	return true

func forge(id: String, expected_upgrade: int) -> bool:
	# A stale/double tap cannot repeat a transaction after the recipe changes.
	if int(equipment.get(id, -1)) != expected_upgrade or not can_forge(id):
		return false
	var cost := RPGRules.recipe(id, equipment.has(id), int(equipment.get(id, 0)))
	gold -= int(cost.gold)
	for item: String in cost.materials:
		bag[item] = int(bag[item]) - int(cost.materials[item])
		if bag[item] == 0:
			bag.erase(item)
	equipment[id] = expected_upgrade + 1
	return true

func equip(id: String) -> bool:
	if not equipment.has(id):
		return false
	var slot: String = RPGRules.EQUIPMENT[id].slot
	if equipped[slot] == id:
		return false
	equipped[slot] = id
	return true

func unequip(slot: String) -> bool:
	if not RPGRules.SLOTS.has(slot) or equipped[slot] == "":
		return false
	equipped[slot] = ""
	return true

func combat_stats() -> Dictionary:
	var result := {"damage": 12 + int(attributes["Força"]) * 2 + int(attributes["Espírito"]), "hp": 100 + int(attributes["Vitalidade"]) * 8 + int(attributes["Espírito"]) * 2,
		"speed": 180 + int(attributes["Agilidade"]) * 2, "spirit": int(attributes["Espírito"]), "armor": 0,
		"cooldown": 1.0 - minf(0.2, float(attributes["Agilidade"]) * 0.01)}
	for slot: String in RPGRules.SLOTS:
		var id: String = equipped[slot]
		if id.is_empty():
			continue
		var bonus := RPGRules.bonuses(id, int(equipment[id]))
		for key: String in bonus:
			result[key] += bonus[key]
	return result

func discover_nearby(point: Vector2) -> bool:
	var changed := false
	for spot: Dictionary in Exploration.RESOURCE_SPOTS:
		if not discovered_pois.has(spot.id) and point.distance_squared_to(spot.position) <= 95.0 * 95.0:
			discovered_pois[spot.id] = true
			changed = true
	return changed

func add_item(item: String, amount: int = 1) -> bool:
	if not ITEMS.has(item) or amount < 1:
		return false
	bag[item] = int(bag.get(item, 0)) + amount
	return true

func transfer(item: String, to_chest: bool) -> bool:
	if not ITEMS.has(item):
		return false
	var source: Dictionary = bag if to_chest else chest
	var destination: Dictionary = chest if to_chest else bag
	if int(source.get(item, 0)) < 1:
		return false
	source[item] = int(source[item]) - 1
	if source[item] == 0:
		source.erase(item)
	destination[item] = int(destination.get(item, 0)) + 1
	return true

func buy(item: String) -> bool:
	if not TRADE_ITEMS.has(item) or gold < BUY_PRICE:
		return false
	gold -= BUY_PRICE
	add_item(item)
	return true

func sell(item: String) -> bool:
	if not SELL_ITEMS.has(item) or int(bag.get(item, 0)) < 1:
		return false
	bag[item] = int(bag[item]) - 1
	if bag[item] == 0:
		bag.erase(item)
	gold += SELL_PRICE
	return true

func collect_resource(id: String, now: int) -> String:
	for spot: Dictionary in Exploration.RESOURCE_SPOTS:
		if spot.id == id and now >= int(harvested_until.get(id, 0)) and now > 0:
			var item: String = spot.item
			add_item(item)
			harvested_until[id] = now + Exploration.RESOURCE_COOLDOWN
			return item
	return ""

func open_exploration_chest(id: String) -> Dictionary:
	if opened_caches.has(id):
		return {}
	for chest_data: Dictionary in Exploration.HIDDEN_CHESTS:
		if chest_data.id == id:
			gold += int(chest_data.gold)
			var item: String = chest_data.item
			add_item(item)
			opened_caches[id] = true
			return {"gold": int(chest_data.gold), "item": item}
	return {}

func death_loss() -> String:
	for item: String in ITEMS:
		if int(bag.get(item, 0)) > 0:
			bag[item] = int(bag[item]) - 1
			if bag[item] == 0:
				bag.erase(item)
			return item
	return ""

func save() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "bag": bag, "chest": chest,
		"gold": gold, "xp": xp, "kills": kills, "mission_index": mission_index,
		"mission_progress": mission_progress, "mission_completed": mission_completed,
		"harvested_until": harvested_until, "opened_caches": opened_caches,
		"discovered_pois": discovered_pois, "adventures": adventures, "rpg": {"level": level(), "attributes": attributes,
		"skills": skills, "equipment": equipment, "equipped": equipped}}))
	file.close()
	return true

func load_save() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var version_value: Variant = parsed.get("version")
	if not version_value is float or version_value != floorf(version_value):
		return false
	var loaded_version := int(version_value)
	if loaded_version < 1 or loaded_version > SAVE_VERSION:
		return false
	for key: String in ["gold", "xp", "kills", "mission_index", "mission_progress", "mission_completed"]:
		if not parsed.has(key) or not parsed[key] is float or parsed[key] < 0 or parsed[key] > 100000000 or parsed[key] != floorf(parsed[key]):
			return false
	if parsed.mission_index >= 2 or parsed.mission_progress >= [8, 5][int(parsed.mission_index)]:
		return false
	var new_bag: Variant = _valid_items(parsed.get("bag"))
	var new_chest: Variant = _valid_items(parsed.get("chest"))
	if new_bag == null or new_chest == null:
		return false
	var new_harvested: Dictionary = {}
	var new_opened: Dictionary = {}
	var new_discovered: Dictionary = {}
	if loaded_version >= 2:
		var harvested_value: Variant = _valid_exploration(parsed.get("harvested_until"), false)
		var opened_value: Variant = _valid_exploration(parsed.get("opened_caches"), true)
		if harvested_value == null or opened_value == null:
			return false
		new_harvested = harvested_value
		new_opened = opened_value
	if loaded_version >= 3:
		var discovered_value: Variant = _valid_discoveries(parsed.get("discovered_pois"))
		if discovered_value == null:
			return false
		new_discovered = discovered_value
	var new_rpg: Dictionary = {"attributes": {"Força": 0, "Vitalidade": 0, "Agilidade": 0, "Espírito": 0},
		"skills": {"Corte Circular": 1, "Investida": 1, "Fúria Ancestral": 1},
		"equipment": {"espada": 0}, "equipped": {"Arma": "espada", "Armadura": "", "Acessório": ""}}
	if loaded_version == 4:
		var legacy_attributes: Variant = parsed.get("attributes")
		if not legacy_attributes is Dictionary or legacy_attributes.size() != 4:
			return false
		var spent := 0
		for name: String in ATTRIBUTES:
			var amount: Variant = legacy_attributes.get(name)
			if not _bounded_integer(amount, 0, 198):
				return false
			spent += int(amount)
			new_rpg.attributes[name] = int(amount)
		if spent > (RPGRules.level_for_xp(int(parsed.xp)) - 1) * 2:
			return false
	if loaded_version >= 5:
		var rpg_value: Variant = _valid_rpg(parsed.get("rpg"), int(parsed.xp))
		if rpg_value == null:
			return false
		new_rpg = rpg_value
	var new_adventures: Dictionary = {"explorar": 0, "forjar": 0, "elite": 0, "guardiao": 0}
	if parsed.has("adventures"):
		if not parsed.adventures is Dictionary or parsed.adventures.size() != 4:
			return false
		for key: String in ADVENTURES:
			var amount: Variant = parsed.adventures.get(key)
			if not _bounded_integer(amount, 0, ADVENTURES[key]):
				return false
			new_adventures[key] = int(amount)
	adventures = new_adventures
	bag = new_bag
	chest = new_chest
	gold = int(parsed.gold)
	xp = int(parsed.xp)
	kills = int(parsed.kills)
	mission_index = int(parsed.mission_index)
	mission_progress = int(parsed.mission_progress)
	mission_completed = int(parsed.mission_completed)
	harvested_until = new_harvested
	opened_caches = new_opened
	discovered_pois = new_discovered
	attributes = new_rpg.attributes
	skills = new_rpg.skills
	equipment = new_rpg.equipment
	equipped = new_rpg.equipped
	return true

func _valid_rpg(value: Variant, total_xp: int) -> Variant:
	if not value is Dictionary or value.get("level") != RPGRules.level_for_xp(total_xp):
		return null
	for field: String in ["attributes", "skills", "equipment", "equipped"]:
		if not value.get(field) is Dictionary:
			return null
	if value.attributes.size() != 4 or value.skills.size() != 3 or value.equipped.size() != 3:
		return null
	var attribute_spent := 0
	var skill_spent := 0
	var result := {"attributes": {}, "skills": {}, "equipment": {}, "equipped": value.equipped.duplicate()}
	for name: String in RPGRules.ATTRIBUTES:
		var amount: Variant = value.attributes.get(name)
		if not _bounded_integer(amount, 0, 198):
			return null
		attribute_spent += int(amount)
		result.attributes[name] = int(amount)
	for name: String in RPGRules.SKILLS:
		var amount: Variant = value.skills.get(name)
		if not _bounded_integer(amount, 1, 3):
			return null
		skill_spent += int(amount) - 1
		result.skills[name] = int(amount)
	var loaded_level := RPGRules.level_for_xp(total_xp)
	if attribute_spent > (loaded_level - 1) * 2 or skill_spent > loaded_level - 1 or value.equipment.size() > RPGRules.EQUIPMENT.size():
		return null
	for id: String in value.equipment:
		if not RPGRules.EQUIPMENT.has(id) or not _bounded_integer(value.equipment[id], 0, 3):
			return null
		result.equipment[id] = int(value.equipment[id])
	for slot: String in RPGRules.SLOTS:
		var id: Variant = value.equipped.get(slot)
		if not id is String:
			return null
		if id != "" and (not value.equipment.has(id) or RPGRules.EQUIPMENT[id].slot != slot):
			return null
	return result

func _bounded_integer(value: Variant, low: int, high: int) -> bool:
	return value is float and value >= low and value <= high and value == floorf(value)

func _valid_discoveries(value: Variant) -> Variant:
	if not value is Dictionary:
		return null
	var result := {}
	for id: String in value:
		var valid := false
		for spot: Dictionary in Exploration.RESOURCE_SPOTS:
			if spot.id == id:
				valid = true
				break
		if not valid or value[id] != true:
			return null
		result[id] = true
	return result

func _valid_exploration(value: Variant, is_cache: bool) -> Variant:
	if not value is Dictionary:
		return null
	var result := {}
	var sources: Array = Exploration.HIDDEN_CHESTS if is_cache else Exploration.RESOURCE_SPOTS
	for id: String in value:
		var found := false
		for entry: Dictionary in sources:
			if entry.id == id:
				found = true
				break
		if not found:
			return null
		if is_cache:
			if value[id] != true:
				return null
			result[id] = true
		else:
			if not value[id] is float or value[id] < 0 or value[id] > 1000000000000 or value[id] != floorf(value[id]):
				return null
			result[id] = int(value[id])
	return result

func _valid_items(value: Variant) -> Variant:
	if not value is Dictionary:
		return null
	var result := {}
	for item: String in value:
		if not ITEMS.has(item) or not value[item] is float or value[item] < 1 or value[item] > 100000000 or value[item] != floorf(value[item]):
			return null
		result[item] = int(value[item])
	return result

func xp_for_level(target: int) -> int:
	return RPGRules.xp_floor(clampi(target, 1, MAX_LEVEL))

func attribute_points_available() -> int:
	return attribute_points()

func spend_attribute_point(attribute: String) -> bool:
	return allocate_attribute(attribute)

func add_xp(amount: int) -> bool:
	if amount <= 0 or xp > 100000000 - amount:
		return false
	xp += amount
	return true

func record_adventure(id: String) -> Dictionary:
	if not ADVENTURES.has(id) or adventures[id] >= ADVENTURES[id]:
		return {}
	adventures[id] += 1
	if adventures[id] < ADVENTURES[id]:
		return {}
	var rewards := {"explorar": [30, 10], "forjar": [40, 15], "elite": [60, 20], "guardiao": [120, 40]}
	xp += rewards[id][0]
	gold += rewards[id][1]
	return {"xp": rewards[id][0], "gold": rewards[id][1]}

func adventure_summary() -> String:
	var names := {"explorar": "Coletar na mata", "forjar": "Fabricar no Ferreiro", "elite": "Vencer um elite", "guardiao": "Guardião (opcional)"}
	for key: String in ADVENTURES:
		if adventures[key] < ADVENTURES[key]:
			return "%s %d/%d" % [names[key], adventures[key], ADVENTURES[key]]
	return "Desafios do Andar 1 concluídos"
