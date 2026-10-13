class_name GameProgress
extends RefCounted

const ITEMS := ["Couro", "Seda", "Essência", "Broto Ancestral", "Ervas", "Cogumelos", "Madeira", "Pedras"]
const TRADE_ITEMS := ["Couro", "Seda", "Essência"]
const SELL_ITEMS := ["Couro", "Seda", "Essência", "Ervas", "Cogumelos", "Madeira", "Pedras"]
const BUY_PRICE := 5
const SELL_PRICE := 2
const SAVE_VERSION := 10
# Switched on by the combat integration after both formats pass regression QA.
var etapa2_enabled := false
var abilities := AbilityState.new()
var migration_refund := 0
const ATTRIBUTES := RPGRules.ATTRIBUTES
const MAX_LEVEL := RPGRules.MAX_LEVEL
const POINTS_PER_LEVEL := 2

const ADVENTURES := {"explorar": 3, "forjar": 1, "elite": 1, "guardiao": 1}
var adventures: Dictionary = {"explorar": 0, "forjar": 0, "elite": 0, "guardiao": 0}
var ascension := AscensionProgress.new()
var talents := TalentProgress.new()
var floor_states: Dictionary = {}

func _init() -> void:
	for id in range(1,6):
		floor_states[str(id)] = _empty_floor()

static func _empty_floor() -> Dictionary:
	return {"harvested_until": {}, "opened_caches": {}, "discovered_pois": {}, "guardian_defeated": false}

func _store_floor() -> void:
	var state: Dictionary = floor_states[str(ascension.current_floor)]
	state.harvested_until = harvested_until
	state.opened_caches = opened_caches
	state.discovered_pois = discovered_pois

func switch_floor(id: int) -> bool:
	if not ascension.can_travel(id):
		return false
	_store_floor()
	ascension.current_floor = id
	_bind_floor()
	return true

func _bind_floor() -> void:
	var state: Dictionary = floor_states[str(ascension.current_floor)]
	harvested_until = state.harvested_until
	opened_caches = state.opened_caches
	discovered_pois = state.discovered_pois

const MAX_SAVE_BYTES := 262144
var save_blocked := false
var save_status := ""
var last_saved_text := ""
var disk_writes := 0
var browser := BrowserSave.new()

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
var attributes: Dictionary = RPGRules.empty_attributes()
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
	if etapa2_enabled: return maxi(0,level()-1-abilities.spent())
	var spent := 0
	for value in skills.values():
		spent += int(value) - 1
	return maxi(0, level() - 1 - spent - talents.spent())

func learn_talent(weapon: String, node: String) -> bool:
	return talents.learn(weapon,node,skill_points())

func active_class() -> String:
	return TalentRules.CLASSES.get(active_category(),"Aventureiro")

func active_category() -> String:
	return ArsenalRules.weapon_category(equipped.Arma)

func skill_rank(index: int) -> int:
	var rank := int(skills[RPGRules.SKILLS[index]])
	var weapon := active_category()
	for node: String in talents.learned.get(weapon,[]):
		if int(TalentRules.NODES[node].skill) == index: rank += 1
	# A tree adds one extra rank beyond the old three-rank progression.
	return mini(4,rank)

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
	if not equipment.has(id) or not RPGRules.EQUIPMENT.has(id) or level() < int(ArsenalRules.metadata(id).level):
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
	var result := {"physical": 12 + int(attributes["Força"]) * 2, "magical": 12 + int(attributes["Espírito"]) * 2,
		"hp": 100 + int(attributes["Vitalidade"]) * 8, "speed": 180.0,
		"spirit": int(attributes["Espírito"]), "armor": 0, "cooldown": 1.0,
		"resistance": minf(0.25, int(attributes["Resistência"]) * 0.005),
		"basic_interval_factor": 1.0-minf(0.15, int(attributes["Destreza"]) * 0.0075),
		"accuracy": 100 + int(attributes["Destreza"])}
	for slot: String in RPGRules.SLOTS:
		var id: String = equipped[slot]
		if id.is_empty():
			continue
		var bonus := RPGRules.bonuses(id, int(equipment[id]))
		result.physical += int(bonus.damage)
		result.magical += int(bonus.damage) + int(bonus.spirit) * 2
		for key: String in ["hp","speed","spirit","armor"]: result[key] += bonus[key]
	var passive := talents.bonuses(active_category())
	result.physical += int(passive.damage)
	result.magical += int(passive.damage)
	result.hp += int(passive.hp)
	result.armor += int(passive.armor)
	result.speed *= 1.0+minf(0.2,int(attributes["Mobilidade"])*0.01)
	result.damage_type = "magical" if active_category() == "cajado" else "physical"
	result.merge(talents.mastery_bonuses(active_category()))
	result.damage = roundi(float(result[result.damage_type]) * (1.0+result.automatic+result.basic))
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

func to_json() -> String:
	_store_floor()
	var payload := {"version": SAVE_VERSION if etapa2_enabled else 9, "bag": bag, "chest": chest,
		"gold": gold, "xp": xp, "talents": talents.to_save(), "kills": kills, "mission_index": mission_index,
		"mission_progress": mission_progress, "mission_completed": mission_completed,
		"harvested_until": harvested_until, "opened_caches": opened_caches,
		"discovered_pois": discovered_pois, "adventures": adventures, "ascension": ascension.to_save(), "floor_states": floor_states, "rpg": {"level": level(), "attributes": attributes,
		"skills": {} if etapa2_enabled else skills, "equipment": equipment, "equipped": equipped, "equipment_meta": equipment_metadata()}}
	if etapa2_enabled: payload["abilities"] = abilities.to_save()
	return JSON.stringify(payload)

func _web_save() -> bool:
	return OS.has_feature("web") and save_path == "user://andar1_progress.json"

func _read_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_SAVE_BYTES:
		return ""
	return file.get_as_text()

func _write_file(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	var success := file.get_error() == OK
	file.close()
	return success and _read_file(path) == text

func _replace_file(path: String, text: String) -> bool:
	if not _write_file(path + ".tmp", text):
		return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path)) == OK

func _valid_text(text: String) -> bool:
	var candidate = get_script().new()
	return candidate.load_text(text)

func save() -> bool:
	if save_blocked:
		return false
	var text := to_json()
	if text == last_saved_text:
		return true
	if not _valid_text(text):
		save_status = "Progresso inválido; save anterior preservado."
		return false
	var old := _read_file(save_path)
	if FileAccess.file_exists(save_path) and not _valid_text(old):
		save_blocked = true
		save_status = "Save existente inválido ou de versão futura; não foi substituído."
		return false
	if not old.is_empty():
		var old_version := int(_parse_json(old).version)
		if old_version < SAVE_VERSION and not FileAccess.file_exists(save_path + ".v%d.original" % old_version):
			if not _replace_file(save_path + ".v%d.original" % old_version, old):
				return false
		if not _replace_file(save_path + ".bak", old):
			return false
	# Synchronous journal first: it is authoritative if the tab closes before
	# the asynchronous IndexedDB sync. Compare-and-swap rejects another tab.
	if _web_save():
		var result := browser.write(export_backup())
		if result != "ok":
			save_blocked = result == "conflict"
			save_status = "Outra aba alterou o save. Reabra o jogo nesta aba." if save_blocked else "Backup do navegador indisponível; exporte um arquivo."
			if save_blocked:
				return false
	if not _replace_file(save_path, text):
		save_status = "Falha ao gravar; cópia anterior preservada."
		return false
	last_saved_text = text
	disk_writes += 1
	if _web_save():
		JavaScriptBridge.force_fs_sync()
		if not OS.is_userfs_persistent() or not browser.available():
			save_status = "Armazenamento limitado neste navegador. Exporte um backup."
		else:
			save_status = "Salvo neste navegador."
	else:
		save_status = "Salvo localmente."
	return true

func load_save() -> bool:
	save_blocked = false
	if _web_save():
		var journal := browser.read()
		if not journal.is_empty():
			var candidate = preview_backup(journal)
			if candidate != null:
				load_text(candidate.to_json())
				save_status = "Progresso recuperado do navegador."
				return true
			save_blocked = true
			save_status = "Registro do navegador inválido; preservado sem sobrescrita."
	var existing := FileAccess.file_exists(save_path)
	var text := _read_file(save_path)
	if existing and load_text(text):
		last_saved_text = text if int(_parse_json(text).version) == SAVE_VERSION and not _web_save() else ""
		return true
	if not existing and _web_save():
		var legacy := _legacy_web_path()
		if not legacy.is_empty():
			text = _read_file(legacy)
			if load_text(text):
				save_status = "Save anterior recuperado; arquivo original preservado."
				return true
			existing = true
	if existing:
		save_blocked = true
		save_status = "Save inválido ou incompatível; original preservado. Importe um backup para recuperar."
		# Recovery is read-only until explicit import confirmation.
		if _parse_json(text) == null and load_text(_read_file(save_path + ".bak")):
			save_status = "Cópia anterior recuperada. Exporte e importe para confirmar a recuperação."
			return true
	return false

func _legacy_web_path() -> String:
	var directory := DirAccess.open("/userfs/godot/app_userdata")
	if directory == null:
		return ""
	var candidates: Array[String] = []
	for name: String in directory.get_directories():
		if name.begins_with("Grande Árvore RPG") and FileAccess.file_exists("/userfs/godot/app_userdata/" + name + "/andar1_progress.json"):
			candidates.append(name)
	# Natural version order avoids choosing v0.3 over v0.5; never fall back
	# past a corrupt most-recent save and silently replace newer progress.
	candidates.sort_custom(func(a: String, b: String): return a.naturalnocasecmp_to(b) > 0)
	return "/userfs/godot/app_userdata/" + candidates[0] + "/andar1_progress.json" if not candidates.is_empty() else ""

func export_backup() -> String:
	var payload := to_json()
	return JSON.stringify({"format": "grande-arvore-rpg-save", "archive_version": 1, "sha256": payload.sha256_text(), "payload": payload})

func preview_backup(text: String) -> Variant:
	if text.to_utf8_buffer().size() > MAX_SAVE_BYTES:
		return null
	var parsed: Variant = _parse_json(text)
	if not parsed is Dictionary:
		return null
	var payload := text
	if parsed.has("format"):
		if parsed.get("format") != "grande-arvore-rpg-save" or parsed.get("archive_version") != 1.0 or not parsed.get("payload") is String or not parsed.get("sha256") is String:
			return null
		payload = parsed.payload
		if payload.sha256_text() != parsed.sha256:
			return null
	var candidate = get_script().new()
	if not candidate.load_text(payload):
		return null
	if not parsed.has("format"):
		candidate.save_status = "Formato antigo: estrutura validada, sem checksum de origem."
	return candidate

func import_backup(text: String, confirmed: bool) -> bool:
	var candidate = preview_backup(text)
	if not confirmed or candidate == null:
		return false
	var had_original := FileAccess.file_exists(save_path)
	var preserved := save_path + ".before-import-%d" % Time.get_ticks_usec()
	if had_original:
		# Preserve even corrupt/future originals before an explicit replacement.
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(save_path), ProjectSettings.globalize_path(preserved)) != OK:
			return false
	var replacement: String = candidate.to_json()
	if not _replace_file(save_path, replacement):
		return false
	if _web_save() and browser.write(candidate.export_backup(), true) != "ok":
		# No asynchronous frame has run; roll back the staged filesystem write.
		if had_original:
			DirAccess.copy_absolute(ProjectSettings.globalize_path(preserved), ProjectSettings.globalize_path(save_path))
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
		return false
	load_text(replacement)
	save_blocked = false
	last_saved_text = replacement
	if _web_save():
		JavaScriptBridge.force_fs_sync()
	return true

func _parse_json(text: String) -> Variant:
	var parser := JSON.new()
	return parser.data if parser.parse(text) == OK else null

func load_text(text: String) -> bool:
	if text.to_utf8_buffer().size() > MAX_SAVE_BYTES:
		return false
	var parsed: Variant = _parse_json(text)
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
	var new_rpg: Dictionary = {"attributes": RPGRules.empty_attributes(),
		"skills": {"Corte Circular": 1, "Investida": 1, "Fúria Ancestral": 1},
		"equipment": {"espada": 0}, "equipped": {"Arma": "espada", "Armadura": "", "Acessório": ""}}
	if loaded_version == 4:
		var legacy_attributes: Variant = parsed.get("attributes")
		if not legacy_attributes is Dictionary or legacy_attributes.size() != 4:
			return false
		var spent := 0
		for name: String in RPGRules.LEGACY_ATTRIBUTES:
			var amount: Variant = legacy_attributes.get(name)
			if not _bounded_integer(amount, 0, 198):
				return false
			spent += int(amount)
			if name != "Agilidade": new_rpg.attributes[name] = int(amount)
		if spent > (RPGRules.level_for_xp(int(parsed.xp)) - 1) * 2:
			return false
	if loaded_version >= 5:
		var rpg_value: Variant = _valid_rpg(parsed.get("rpg"), int(parsed.xp), loaded_version)
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
	var new_ascension := AscensionProgress.new()
	if loaded_version >= 6:
		new_ascension = AscensionProgress.from_save(parsed.get("ascension"))
		if new_ascension == null:
			return false
	else:
		# Every historical kill in v1–5 came from the only existing floor, Mata.
		new_ascension.defeats["1"] = mini(int(parsed.kills), new_ascension.required_defeats())
	var new_floors: Dictionary = {}
	for id in range(1,6):
		new_floors[str(id)] = _empty_floor()
	if loaded_version >= 6 and parsed.has("floor_states"):
		if not parsed.floor_states is Dictionary or parsed.floor_states.size() != 5:
			return false
		for key: String in new_floors:
			var state: Variant = parsed.floor_states.get(key)
			if not state is Dictionary or state.size() != 4 or not state.get("guardian_defeated") is bool:
				return false
			var harvested: Variant = _valid_exploration(state.get("harvested_until"), false)
			var opened: Variant = _valid_exploration(state.get("opened_caches"), true)
			var discovered: Variant = _valid_discoveries(state.get("discovered_pois"))
			if harvested == null or opened == null or discovered == null:
				return false
			if not new_ascension.can_travel(int(key)) and (not harvested.is_empty() or not opened.is_empty() or not discovered.is_empty() or state.guardian_defeated):
				return false
			new_floors[key] = {"harvested_until": harvested, "opened_caches": opened, "discovered_pois": discovered, "guardian_defeated": state.guardian_defeated}
		var active: Dictionary = new_floors[str(new_ascension.current_floor)]
		if active.harvested_until != new_harvested or active.opened_caches != new_opened or active.discovered_pois != new_discovered:
			return false
	else:
		if new_ascension.current_floor != 1:
			return false
		new_floors["1"] = {"harvested_until": new_harvested, "opened_caches": new_opened, "discovered_pois": new_discovered, "guardian_defeated": new_adventures.guardiao > 0}
	var new_talents := TalentProgress.new()
	if loaded_version >= 7:
		var remaining := RPGRules.level_for_xp(int(parsed.xp))-1
		for rank: int in new_rpg.skills.values(): remaining -= rank-1
		new_talents = TalentProgress.from_save(parsed.get("talents"),remaining,loaded_version < 9)
		if new_talents == null: return false
	var new_abilities := AbilityState.new()
	if loaded_version >= 10:
		for category: String in new_talents.learned:
			if not new_talents.learned[category].is_empty(): return false
		var levels := {}
		for category: String in AbilityRules.CATEGORIES: levels[category] = new_talents.level(category)
		new_abilities = AbilityState.from_save(parsed.get("abilities"),levels,RPGRules.level_for_xp(int(parsed.xp))-1)
		if new_abilities == null: return false
	# Commit all validated fields together; malformed trees cannot partially load.
	talents = new_talents
	abilities = new_abilities
	floor_states = new_floors
	adventures = new_adventures
	ascension = new_ascension
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
	if loaded_version >= 10: etapa2_enabled = true
	elif etapa2_enabled: migrate_etapa2()
	return true

func equipment_metadata() -> Dictionary:
	var result := {}
	for id: String in equipment:
		result[id] = ArsenalRules.metadata(id)
	return result

func _valid_rpg(value: Variant, total_xp: int, version: int) -> Variant:
	if not value is Dictionary or value.get("level") != RPGRules.level_for_xp(total_xp):
		return null
	for field: String in ["attributes", "skills", "equipment", "equipped"]:
		if not value.get(field) is Dictionary:
			return null
	var attribute_names: Array = RPGRules.LEGACY_ATTRIBUTES if version < 8 else RPGRules.ATTRIBUTES
	if value.attributes.size() != attribute_names.size() or value.skills.size() != (0 if version >= 10 else 3) or value.equipped.size() != 3:
		return null
	var attribute_spent := 0
	var skill_spent := 0
	var result := {"attributes": RPGRules.empty_attributes(), "skills": {}, "equipment": {}, "equipped": value.equipped.duplicate()}
	for name: String in attribute_names:
		var amount: Variant = value.attributes.get(name)
		if not _bounded_integer(amount, 0, 198):
			return null
		attribute_spent += int(amount)
		if name != "Agilidade": result.attributes[name] = int(amount)
	for name: String in (RPGRules.SKILLS if version < 10 else []):
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
	if value.has("equipment_meta"):
		if not value.equipment_meta is Dictionary or value.equipment_meta.size() != value.equipment.size():
			return null
		for id: String in value.equipment:
			var meta: Variant = value.equipment_meta.get(id)
			var canonical := ArsenalRules.metadata(id)
			if not meta is Dictionary or meta.size() != canonical.size():
				return null
			for field: String in canonical:
				if meta.get(field) != canonical[field]:
					return null
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

func migrate_etapa2() -> int:
	# Called only on a completely validated legacy snapshot. No currency grants,
	# fivefold refunds or additive point wallets: available = earned - investments.
	var refund := talents.spent()
	for rank: int in skills.values(): refund += rank-1
	for category: String in talents.learned: talents.learned[category].clear()
	skills = {}
	etapa2_enabled = true
	migration_refund = refund
	return refund
