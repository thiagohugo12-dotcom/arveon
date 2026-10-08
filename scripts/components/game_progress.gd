class_name GameProgress
extends RefCounted

const ITEMS := ["Couro", "Seda", "Essência", "Broto Ancestral"]
const TRADE_ITEMS := ["Couro", "Seda", "Essência"]
const BUY_PRICE := 5
const SELL_PRICE := 2
const SAVE_VERSION := 1

var save_path: String = "user://andar1_progress.json"
var bag: Dictionary = {}
var chest: Dictionary = {}
var gold: int = 0
var xp: int = 0
var kills: int = 0
var mission_index: int = 0
var mission_progress: int = 0
var mission_completed: int = 0

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
	if not TRADE_ITEMS.has(item) or int(bag.get(item, 0)) < 1:
		return false
	bag[item] = int(bag[item]) - 1
	if bag[item] == 0:
		bag.erase(item)
	gold += SELL_PRICE
	return true

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
		"mission_progress": mission_progress, "mission_completed": mission_completed}))
	file.close()
	return true

func load_save() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or parsed.get("version") != SAVE_VERSION:
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
	bag = new_bag
	chest = new_chest
	gold = int(parsed.gold)
	xp = int(parsed.xp)
	kills = int(parsed.kills)
	mission_index = int(parsed.mission_index)
	mission_progress = int(parsed.mission_progress)
	mission_completed = int(parsed.mission_completed)
	return true

func _valid_items(value: Variant) -> Variant:
	if not value is Dictionary:
		return null
	var result := {}
	for item: String in value:
		if not ITEMS.has(item) or not value[item] is float or value[item] < 1 or value[item] > 100000000 or value[item] != floorf(value[item]):
			return null
		result[item] = int(value[item])
	return result
