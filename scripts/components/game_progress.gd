class_name GameProgress
extends RefCounted

const ITEMS := ["Couro", "Seda", "Essência", "Broto Ancestral", "Ervas", "Cogumelos", "Madeira", "Pedras"]
const TRADE_ITEMS := ["Couro", "Seda", "Essência"]
const SELL_ITEMS := ["Couro", "Seda", "Essência", "Ervas", "Cogumelos", "Madeira", "Pedras"]
const BUY_PRICE := 5
const SELL_PRICE := 2
const SAVE_VERSION := 3

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
		"discovered_pois": discovered_pois}))
	file.close()
	return true

func load_save() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not [1, 2, SAVE_VERSION].has(parsed.get("version")):
		return false
	for key: String in ["gold", "xp", "kills", "mission_index", "mission_progress", "mission_completed"]:
		if not parsed.has(key) or not parsed[key] is float or parsed[key] < 0 or parsed[key] > 100000000:
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
	if parsed.version >= 2:
		var harvested_value: Variant = _valid_exploration(parsed.get("harvested_until"), false)
		var opened_value: Variant = _valid_exploration(parsed.get("opened_caches"), true)
		if harvested_value == null or opened_value == null:
			return false
		new_harvested = harvested_value
		new_opened = opened_value
	if parsed.version == SAVE_VERSION:
		var discovered_value: Variant = _valid_discoveries(parsed.get("discovered_pois"))
		if discovered_value == null:
			return false
		new_discovered = discovered_value
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
	return true

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
