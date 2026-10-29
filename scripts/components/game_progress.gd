class_name GameProgress
extends RefCounted

const ITEMS := ["Couro", "Seda", "Essência", "Broto Ancestral", "Ervas", "Cogumelos", "Madeira", "Pedras", "Minério de Ferro",
	"Presa de Javali", "Teia Reforçada", "Espinho Seco", "Pepita Dourada", "Placa de Tatu", "Ferrão da Chapada",
	"Coração da Mata", "Núcleo de Arenito", "Fragmento de Receita"]
const TRADE_ITEMS := ["Couro", "Seda", "Essência"]
const SELL_ITEMS := ["Couro", "Seda", "Essência", "Ervas", "Cogumelos", "Madeira", "Pedras"]
const BUY_PRICE := 5
const SELL_PRICE := 2
const SAVE_VERSION := 13
# Legacy-format mode remains only for migration fixtures. Runtime uses v10.
var etapa2_enabled := true
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
	if etapa2_enabled: skills = {}
	for id in range(1,6):
		floor_states[str(id)] = _empty_floor()

static func _empty_floor() -> Dictionary:
	return {"harvested_until": {}, "opened_caches": {}, "discovered_pois": {}, "guardian_defeated": false, "mining": {}}

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
var training_mode := false # Disposable practice session; never written to a journal.
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
var equipment_rarities: Dictionary = {}
var equipped: Dictionary = {"Arma": "espada", "Capacete": "", "Armadura": "", "Luvas": "", "Botas": "", "Anel": "", "Acessório": "", "Amuleto": ""}
var weapon_instances: Dictionary = {}
var equipped_weapon_uid := ""
var next_weapon_uid := 1
# Marco 5: contadores de azar (raro/épico) e receitas de conjunto liberadas por Fragmento.
var pity: Dictionary = LootRules.new_pity()
var gems := 0 # Moeda premium futura: ainda sem fonte no jogo, salva como campo opcional.
var bag_expansions := 0
# Três conjuntos de equipamento salvos: {} (vazio) ou {"slots": {espaço: id}, "weapon_uid": uid}.
var loadouts: Array = [{}, {}, {}]
var overflowed := false # O último add_item mandou o excedente para o Baú.
const BAG_CAPACITY := 40
const BAG_STEP := 10
const EXPANSION_GOLD := [500,1000,2000,4000]
const EXPANSION_GEMS := [5,10,20,40]
var recipes: Array[String] = []
# Existing snapshots are exempt; only the no-save runtime starts the introduction.
var introduction: Dictionary = {"status":"legacy","met_smith":false,"weapon":""}

func begin_new_character() -> void:
	equipment = {}
	equipment_rarities = {}
	equipped = {"Arma":"","Capacete":"","Armadura":"","Luvas":"","Botas":"","Anel":"","Acessório":"","Amuleto":""}
	weapon_instances = {}
	equipped_weapon_uid = ""
	next_weapon_uid = 1
	pity = LootRules.new_pity()
	gems = 0
	bag_expansions = 0
	loadouts = [{}, {}, {}]
	recipes = []
	introduction = {"status":"active","met_smith":false,"weapon":""}

func introduction_active() -> bool:
	return introduction.status == "active"

func introduction_summary() -> String:
	return "O Primeiro Passo\n" + ("✓ Encontre o Ferreiro\nEscolha sua primeira arma" if introduction.met_smith else "Encontre o Ferreiro\nEscolha sua primeira arma")

func meet_smith() -> bool:
	if not introduction_active() or introduction.met_smith: return false
	introduction.met_smith = true
	return true

func claim_first_weapon(id: String, at_smith: bool) -> bool:
	# Reward and completion share a single durable snapshot. No UI state grants items.
	if not at_smith or save_blocked or not introduction_active() or not introduction.met_smith or not ArsenalRules.CATEGORIES.has(id) or not equipment.is_empty(): return false
	var previous := introduction.duplicate()
	equipment[id] = 0
	equipped.Arma = id
	var uid := _create_weapon(id,"comum")
	equipped_weapon_uid = uid
	introduction = {"status":"complete","met_smith":true,"weapon":id}
	if save(true): return true
	equipment.erase(id)
	equipped.Arma = ""
	weapon_instances.erase(uid)
	equipped_weapon_uid = ""
	introduction = previous
	return false

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

func learn_talent(weapon: String, node: String, at_camp: bool = false) -> bool:
	if etapa2_enabled: return abilities.learn_talent(weapon,node,talents.level(weapon),skill_points(),at_camp)
	return talents.learn(weapon,node,skill_points())

func active_class() -> String:
	return TalentRules.CLASSES.get(active_category(),"Aventureiro")

func active_category() -> String:
	return ArsenalRules.weapon_category(equipped.Arma)

func skill_rank(index: int) -> int:
	if etapa2_enabled:
		var category := active_category()
		if index == 0 or category.is_empty(): return 1
		return int(abilities.grades[category].get(abilities.loadouts[category].skills[index-1],1))
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

func improve_skill(name: String, at_camp: bool = false) -> bool:
	if etapa2_enabled:
		var parts := name.split(":")
		return parts.size() == 2 and abilities.improve(parts[0],parts[1],talents.level(parts[0]),skill_points(),at_camp)
	if not RPGRules.SKILLS.has(name) or skill_points() < 1 or int(skills[name]) >= 3:
		return false
	skills[name] = int(skills[name]) + 1
	return true

func _create_weapon(category: String, rarity: String) -> String:
	var uid := "w%d" % next_weapon_uid
	next_weapon_uid += 1
	weapon_instances[uid] = {"model":category,"category":category,"rarity":rarity,"level":0,"choices":{}}
	return uid

func weapon(uid: String) -> Dictionary:
	return weapon_instances.get(uid,{})

func _can_pay(recipe: Dictionary) -> bool:
	if recipe.is_empty() or gold < int(recipe.gold): return false
	for item: String in recipe.materials:
		if int(bag.get(item,0)) < int(recipe.materials[item]): return false
	return true

func _pay(recipe: Dictionary) -> void:
	gold -= int(recipe.gold)
	for item: String in recipe.materials:
		bag[item] = int(bag[item]) - int(recipe.materials[item])
		if bag[item] == 0: bag.erase(item)

func can_craft_weapon(category: String, rarity: String) -> bool:
	return not introduction_active() and not save_blocked and has_room() and _can_pay(EquipmentEconomy.craft_recipe(category,rarity))

func craft_weapon(category: String, rarity: String) -> String:
	if not can_craft_weapon(category,rarity): return ""
	_pay(EquipmentEconomy.craft_recipe(category,rarity))
	var uid := _create_weapon(category,rarity)
	if not equipment.has(category): equipment[category] = 0
	return uid

func can_craft_vale_iron(rarity: String) -> bool:
	return not introduction_active() and not save_blocked and has_room() and _can_pay(EquipmentEconomy.vale_iron_recipe(rarity))

func craft_vale_iron(rarity: String) -> String:
	if not can_craft_vale_iron(rarity): return ""
	_pay(EquipmentEconomy.vale_iron_recipe(rarity))
	var uid := _create_weapon("espada", rarity)
	if not equipment.has("espada"): equipment["espada"] = 0
	return uid

# ── Receitas de conjunto (Marco 5) ────────────────────────────────────────────────────────
func recipe_unlocked(floor_id: int, category: String) -> bool:
	if recipes.has(LootRules.recipe_id(floor_id,category)): return true
	var state: Dictionary = floor_states.get(str(floor_id),{})
	return bool(state.get("guardian_defeated",false)) or bool(ascension.completed_trials.get(str(floor_id),false))

func fragments() -> int:
	return int(bag.get(FloorCatalog.LOOT.fragment,0))

func can_use_fragment(floor_id: int, category: String) -> bool:
	return not save_blocked and not LootRules.set_recipe(floor_id,category).is_empty() and not recipe_unlocked(floor_id,category) and fragments() > 0

func use_fragment(floor_id: int, category: String) -> bool:
	if not can_use_fragment(floor_id,category): return false
	_pay({"gold":0,"materials":{FloorCatalog.LOOT.fragment:1}})
	recipes.append(LootRules.recipe_id(floor_id,category))
	return true

func can_craft_set(floor_id: int, category: String) -> bool:
	if LootRules.is_piece(category) and equipment.has(category): return false
	return not introduction_active() and not save_blocked and has_room() and recipe_unlocked(floor_id,category) and _can_pay(LootRules.set_recipe(floor_id,category))

func craft_set(floor_id: int, category: String) -> String:
	if not can_craft_set(floor_id,category): return ""
	var recipe := LootRules.set_recipe(floor_id,category)
	_pay(recipe)
	if LootRules.is_piece(category):
		equipment[category] = 0
		equipment_rarities[category] = "comum"
		return category
	var uid := _create_weapon(category,recipe.rarity)
	if not equipment.has(category): equipment[category] = 0
	return uid

func mining_snapshot(floor_id: int, id: String, now: int) -> Dictionary:
	var config := MiningRules.definition(floor_id, id)
	if config.is_empty(): return {}
	var state: Dictionary = floor_states[str(floor_id)].mining.get(id, {})
	var until := int(state.get("ready_at", 0))
	if until > 0 and now >= until:
		floor_states[str(floor_id)].mining.erase(id)
		state = {}
	return {"remaining": int(state.get("remaining", config.uses)), "ready_at": int(state.get("ready_at", 0))}

func mine_deposit(floor_id: int, id: String, now: int, rng: RandomNumberGenerator) -> Dictionary:
	var config := MiningRules.definition(floor_id, id)
	if config.is_empty() or floor_id != ascension.current_floor or now <= 0 or save_blocked: return {}
	var state := mining_snapshot(floor_id, id, now)
	if state.remaining <= 0: return {}
	var remaining := int(state.remaining) - 1
	var ready_at := now + int(config.respawn_seconds) if remaining == 0 else 0
	floor_states[str(floor_id)].mining[id] = {"remaining": remaining, "ready_at": ready_at}
	var drop := MiningRules.roll(config, rng)
	if not drop.is_empty(): add_item(drop.key)
	return {"attempted": true, "drop": drop, "remaining": remaining, "ready_at": ready_at}

func reset_mining_for_training(floor_id: int) -> void:
	if training_mode: floor_states[str(floor_id)].mining.clear()

func can_evolve_weapon(uid: String) -> bool:
	if not weapon_instances.has(uid) or save_blocked: return false
	var recipe := EquipmentEconomy.rarity_recipe(weapon(uid).rarity)
	return not recipe.is_empty() and _can_pay(recipe)

func evolve_weapon(uid: String) -> bool:
	if not can_evolve_weapon(uid): return false
	var data: Dictionary = weapon_instances[uid]
	_pay(EquipmentEconomy.rarity_recipe(data.rarity))
	data.rarity = EquipmentEconomy.RARITY_ORDER[EquipmentEconomy.RARITY_ORDER.find(data.rarity)+1]
	data.level = 0
	data.choices = {}
	if uid == equipped_weapon_uid: equipment[data.category] = 0
	return true

func equipment_rarity(id: String) -> String:
	return str(equipment_rarities.get(id, ArsenalRules.metadata(id).get("rarity", "comum")))

func can_evolve_equipment(id: String) -> bool:
	if not equipment.has(id) or not RPGRules.EQUIPMENT.has(id) or not RPGRules.EQUIPMENT[id].has("set_floor") or save_blocked:
		return false
	var recipe := EquipmentEconomy.rarity_recipe(equipment_rarity(id))
	return not recipe.is_empty() and _can_pay(recipe)

func evolve_equipment(id: String) -> bool:
	if not can_evolve_equipment(id): return false
	var current := equipment_rarity(id)
	var recipe := EquipmentEconomy.rarity_recipe(current)
	_pay(recipe)
	equipment_rarities[id] = EquipmentEconomy.RARITY_ORDER[EquipmentEconomy.RARITY_ORDER.find(current) + 1]
	return true

func can_enhance_weapon(uid: String) -> bool:
	return weapon_instances.has(uid) and not save_blocked and int(weapon(uid).level) < 20 and _can_pay(EquipmentEconomy.enhance_recipe(int(weapon(uid).level),weapon(uid).rarity))

func enhance_weapon(uid: String, use_seal: bool = false, roll: float = -1.0, loss_roll: float = -1.0) -> Dictionary:
	if not can_enhance_weapon(uid) or use_seal and int(bag.get(EquipmentEconomy.SEAL,0)) < 1: return {}
	var data: Dictionary = weapon_instances[uid]
	var old := int(data.level)
	_pay(EquipmentEconomy.enhance_recipe(old,data.rarity))
	var success: bool = (randf() if roll < 0 else roll) < float(EquipmentEconomy.SUCCESS[old])
	var lost := 0
	if success:
		data.level = old + 1
	elif old >= int(EquipmentEconomy.FAILURE.safe_through):
		lost = (2 if (randf() if loss_roll < 0 else loss_roll) < float(EquipmentEconomy.FAILURE.highest_loss_chance_two) else 1) if old >= 15 else int(EquipmentEconomy.FAILURE.high_loss)
		if use_seal:
			bag[EquipmentEconomy.SEAL] -= 1
			if bag[EquipmentEconomy.SEAL] == 0: bag.erase(EquipmentEconomy.SEAL)
			lost = 0
		else:
			data.level = maxi(0,old-lost)
	if uid == equipped_weapon_uid: equipment[data.category] = int(data.level)
	return {"success":success,"old":old,"level":int(data.level),"lost":lost,"seal_used":use_seal and not success and old >= 10}

func choose_weapon_bonus(uid: String, milestone: int, choice: String) -> bool:
	if not weapon_instances.has(uid) or int(weapon(uid).level) < milestone: return false
	var data: Dictionary = weapon_instances[uid]
	if data.choices.has(str(milestone)): return false
	for option: Dictionary in EquipmentEconomy.bonus_options(data.category,milestone):
		if option.id == choice:
			data.choices[str(milestone)] = choice
			return true
	return false

func equip_weapon_instance(uid: String) -> bool:
	if not weapon_instances.has(uid): return false
	var data: Dictionary = weapon_instances[uid]
	if not equipment.has(data.category): equipment[data.category] = 0
	equipped_weapon_uid = uid
	equipped.Arma = data.category
	equipment[data.category] = int(data.level)
	return true

func can_forge(id: String) -> bool:
	if introduction_active(): return false
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
	if ArsenalRules.CATEGORIES.has(id):
		var target_uid := ""
		for uid: String in weapon_instances:
			if weapon_instances[uid].category == id:
				target_uid = uid
				break
		if target_uid == "": target_uid = _create_weapon(id,"comum")
		weapon_instances[target_uid].level = expected_upgrade + 1
		if equipped.Arma == id: equipped_weapon_uid = target_uid
	return true

# Gold-only starter shop at the Ferreiro. The free first-weapon gift is separate.
static func starter_weapon_price(id: String) -> int:
	if not ArsenalRules.CATEGORIES.has(id): return -1
	return int(RPGRules.EQUIPMENT[id].gold)

func can_buy_starter_weapon(id: String) -> bool:
	var price := starter_weapon_price(id)
	return not introduction_active() and not save_blocked and price > 0 and not equipment.has(id) and gold >= price

func purchase_starter_weapon(id: String, at_smith: bool) -> bool:
	# The caller must verify the player is actually at the Ferreiro.
	if not at_smith or not can_buy_starter_weapon(id): return false
	var price := starter_weapon_price(id)
	var previous_weapon: String = equipped.Arma
	var previous_uid := equipped_weapon_uid
	gold -= price
	equipment[id] = 0
	equipped.Arma = id
	var uid := _create_weapon(id,"comum")
	equipped_weapon_uid = uid
	# One durable transaction: balance, ownership and active class.
	if save(true): return true
	gold += price
	equipment.erase(id)
	equipped.Arma = previous_weapon
	weapon_instances.erase(uid)
	equipped_weapon_uid = previous_uid
	return false

func equip(id: String) -> bool:
	if not equipment.has(id) or not RPGRules.EQUIPMENT.has(id) or level() < int(ArsenalRules.metadata(id).level):
		return false
	var slot: String = RPGRules.EQUIPMENT[id].slot
	if equipped[slot] == id:
		return false
	equipped[slot] = id
	if slot == "Arma":
		for uid: String in weapon_instances:
			if weapon_instances[uid].category == id:
				equipped_weapon_uid = uid
				equipment[id] = int(weapon_instances[uid].level)
				break
	return true

func unequip(slot: String) -> bool:
	if not RPGRules.SLOTS.has(slot) or equipped[slot] == "":
		return false
	equipped[slot] = ""
	if slot == "Arma": equipped_weapon_uid = ""
	return true

func combat_stats() -> Dictionary:
	var physical_bonus := 0
	var magical_bonus := 0
	var critical_bonus := 0.0
	var attack_speed_bonus := 0.0
	var crit_damage_bonus := 0.0
	var resist_bonus := 0.0
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
		var level_value := int(equipment[id])
		if slot == "Arma" and weapon_instances.has(equipped_weapon_uid): level_value = int(weapon(equipped_weapon_uid).level)
		var bonus := RPGRules.bonuses(id, level_value)
		if slot == "Arma" and weapon_instances.has(equipped_weapon_uid):
			var data := weapon(equipped_weapon_uid)
			var tier := EquipmentEconomy.RARITY_ORDER.find(data.rarity)
			bonus.damage += tier * 2
			bonus.spirit += tier
			for milestone: int in EquipmentEconomy.MILESTONES:
				if level_value < milestone or not data.choices.has(str(milestone)): continue
				for option: Dictionary in EquipmentEconomy.bonus_options(data.category,milestone):
					if option.id == data.choices[str(milestone)]:
						match option.stat:
							"physical": physical_bonus += int(option.value)
							"magical": magical_bonus += int(option.value)
							"critical": critical_bonus += float(option.value)
							"attack_speed": attack_speed_bonus += float(option.value)
							"hp": bonus.hp += int(option.value)
							"armor": bonus.armor += int(option.value)
							"spirit": bonus.spirit += int(option.value)
		result.physical += int(bonus.damage)
		result.magical += int(bonus.damage) + int(bonus.spirit) * 2
		for key: String in ["hp","speed","spirit","armor"]: result[key] += bonus[key]
		critical_bonus += float(bonus.crit)
		crit_damage_bonus += float(bonus.crit_damage)
		resist_bonus += float(bonus.resist)
	var passive := {"damage":0,"hp":0,"armor":0} if etapa2_enabled else talents.bonuses(active_category())
	result.physical += int(passive.damage)
	result.magical += int(passive.damage)
	result.hp += int(passive.hp)
	result.armor += int(passive.armor)
	result.speed *= 1.0+minf(0.2,int(attributes["Mobilidade"])*0.01)
	result.damage_type = "magical" if active_category() == "cajado" else "physical"
	result.merge(talents.mastery_bonuses(active_category()))
	result.physical += physical_bonus
	result.magical += magical_bonus
	result.critical_chance = minf(0.15,float(result.critical_chance)+critical_bonus)
	result.critical_multiplier = float(result.critical_multiplier) + crit_damage_bonus
	result.resistance = minf(0.25,float(result.resistance) + resist_bonus)
	result.basic_interval_factor = maxf(0.7,float(result.basic_interval_factor)-attack_speed_bonus)
	result.damage = roundi(float(result[result.damage_type]) * (1.0+result.automatic+result.basic))
	return result

func discover_nearby(point: Vector2, floor_id: int = 1) -> bool:
	var changed := false
	for spot: Dictionary in Exploration.resources_for_floor(floor_id):
		if not discovered_pois.has(spot.id) and point.distance_squared_to(spot.position) <= 95.0 * 95.0:
			discovered_pois[spot.id] = true
			changed = true
	return changed

func add_item(item: String, amount: int = 1) -> bool:
	if not ITEMS.has(item) and not EquipmentEconomy.valid_item(item) or amount < 1:
		return false
	overflowed = false
	# Mochila cheia: o item novo vai direto para o Baú, nada se perde.
	if not bag.has(item) and not has_room():
		chest[item] = int(chest.get(item, 0)) + amount
		overflowed = true
		return true
	bag[item] = int(bag.get(item, 0)) + amount
	return true

# ── Capacidade da mochila (Marco 6) ──────────────────────────────────────────────────────
func bag_capacity() -> int:
	return BAG_CAPACITY + BAG_STEP * bag_expansions

func used_slots() -> int:
	var count := bag.size() + weapon_instances.size()
	for id: String in equipment:
		if not ArsenalRules.CATEGORIES.has(id): count += 1
	return count

func has_room() -> bool:
	return used_slots() < bag_capacity()

func expansion_cost(with_gems: bool) -> int:
	if bag_expansions >= EXPANSION_GOLD.size(): return -1
	return int((EXPANSION_GEMS if with_gems else EXPANSION_GOLD)[bag_expansions])

func can_expand_bag(with_gems: bool) -> bool:
	var cost := expansion_cost(with_gems)
	return cost > 0 and not save_blocked and (gems if with_gems else gold) >= cost

func expand_bag(with_gems: bool) -> bool:
	if not can_expand_bag(with_gems): return false
	if with_gems: gems -= expansion_cost(true)
	else: gold -= expansion_cost(false)
	bag_expansions += 1
	return true

# ── Conjuntos de equipamento (Marco 6) ──────────────────────────────────────────────────
func has_loadout(index: int) -> bool:
	return index >= 0 and index < loadouts.size() and not (loadouts[index] as Dictionary).is_empty()

func save_loadout(index: int) -> bool:
	if index < 0 or index >= loadouts.size() or save_blocked or introduction_active(): return false
	loadouts[index] = {"slots": equipped.duplicate(), "weapon_uid": equipped_weapon_uid}
	return true

# Veste o conjunto salvo: o que não existe mais no equipamento é ignorado e o espaço fica como está.
func apply_loadout(index: int) -> bool:
	if not has_loadout(index) or save_blocked or introduction_active(): return false
	var data: Dictionary = loadouts[index]
	var uid := str(data.weapon_uid)
	if uid != "" and weapon_instances.has(uid): equip_weapon_instance(uid)
	for slot: String in RPGRules.SLOTS:
		if slot == "Arma": continue
		var id := str(data.slots.get(slot,""))
		if id.is_empty(): unequip(slot)
		elif equipment.has(id) and RPGRules.EQUIPMENT.has(id) and RPGRules.EQUIPMENT[id].slot == slot: equip(id)
	return true

func _valid_loadouts(value: Variant) -> Variant:
	if not value is Array or value.size() != 3: return null
	var result: Array = []
	for entry: Variant in value:
		if not entry is Dictionary: return null
		if (entry as Dictionary).is_empty():
			result.append({})
			continue
		if entry.size() != 2 or not entry.get("slots") is Dictionary or not entry.get("weapon_uid") is String: return null
		var uid: String = entry.weapon_uid
		if uid != "" and (not uid.begins_with("w") or not uid.substr(1).is_valid_int()): return null
		var slots := {}
		for slot: String in entry.slots:
			var id: Variant = entry.slots[slot]
			if not RPGRules.SLOTS.has(slot) or not id is String: return null
			if id != "" and (not RPGRules.EQUIPMENT.has(id) or RPGRules.EQUIPMENT[id].slot != slot): return null
			slots[slot] = id
		result.append({"slots": slots, "weapon_uid": uid})
	return result

func grant_gems(amount: int) -> void:
	gems = clampi(gems + amount,0,100000000)

func transfer(item: String, to_chest: bool) -> bool:
	if not ITEMS.has(item) and not EquipmentEconomy.valid_item(item):
		return false
	var source: Dictionary = bag if to_chest else chest
	var destination: Dictionary = chest if to_chest else bag
	if int(source.get(item, 0)) < 1:
		return false
	if not to_chest and not bag.has(item) and not has_room():
		return false
	source[item] = int(source[item]) - 1
	if source[item] == 0:
		source.erase(item)
	destination[item] = int(destination.get(item, 0)) + 1
	return true

func buy(item: String) -> bool:
	var meta := EquipmentEconomy.split_key(item)
	if not TRADE_ITEMS.has(meta.item) and item != EquipmentEconomy.SEAL or not ITEMS.has(item) and not EquipmentEconomy.valid_item(item) or gold < buy_price(item):
		return false
	gold -= buy_price(item)
	add_item(item)
	return true

static func buy_price(item: String) -> int:
	if item == EquipmentEconomy.SEAL: return 50
	return BUY_PRICE * (1 + maxi(0,EquipmentEconomy.RARITY_ORDER.find(EquipmentEconomy.split_key(item).rarity)))

func sell(item: String) -> bool:
	if not SELL_ITEMS.has(item) and not EquipmentEconomy.valid_item(item) or item == EquipmentEconomy.SEAL or int(bag.get(item, 0)) < 1:
		return false
	bag[item] = int(bag[item]) - 1
	if bag[item] == 0:
		bag.erase(item)
	gold += sell_price(item)
	return true

static func sell_price(item: String) -> int:
	return SELL_PRICE * (1 + maxi(0,EquipmentEconomy.RARITY_ORDER.find(EquipmentEconomy.split_key(item).rarity)))

func collect_resource(id: String, now: int, floor_id: int = 1) -> String:
	for spot: Dictionary in Exploration.resources_for_floor(floor_id):
		if spot.id == id and now >= int(harvested_until.get(id, 0)) and now > 0:
			var item: String = spot.item
			add_item(item)
			harvested_until[id] = now + Exploration.RESOURCE_COOLDOWN
			return item
	return ""

func open_exploration_chest(id: String, floor_id: int = 1) -> Dictionary:
	if opened_caches.has(id):
		return {}
	for chest_data: Dictionary in Exploration.chests_for_floor(floor_id):
		if chest_data.id == id:
			gold += int(chest_data.gold)
			var item: String = chest_data.item
			add_item(item)
			opened_caches[id] = true
			return {"gold": int(chest_data.gold), "item": item}
	return {}

func death_loss() -> String:
	var loss_order := ITEMS.duplicate()
	for extra: String in bag:
		if not loss_order.has(extra): loss_order.append(extra)
	for item: String in loss_order:
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
	if etapa2_enabled: payload["introduction"] = introduction
	if etapa2_enabled:
		payload["weapon_instances"] = weapon_instances
		payload["equipped_weapon_uid"] = equipped_weapon_uid
		payload["next_weapon_uid"] = next_weapon_uid
		payload["pity"] = pity
		payload["gems"] = gems
		payload["bag_expansions"] = bag_expansions
		payload["loadouts"] = loadouts
		payload["recipes"] = recipes
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

func save(require_journal: bool = false) -> bool:
	if training_mode: return true
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
			if save_blocked or require_journal:
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
	return JSON.stringify({"format": "arveon-save", "archive_version": 1, "sha256": payload.sha256_text(), "payload": payload})

func preview_backup(text: String) -> Variant:
	if text.to_utf8_buffer().size() > MAX_SAVE_BYTES:
		return null
	var parsed: Variant = _parse_json(text)
	if not parsed is Dictionary:
		return null
	var payload := text
	if parsed.has("format"):
		if not ["arveon-save", "grande-arvore-rpg-save"].has(parsed.get("format")) or parsed.get("archive_version") != 1.0 or not parsed.get("payload") is String or not parsed.get("sha256") is String:
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
		"equipment": {"espada": 0}, "equipment_rarities": {}, "equipped": {"Arma": "espada", "Capacete": "", "Armadura": "", "Luvas": "", "Botas": "", "Anel": "", "Acessório": "", "Amuleto": ""}}
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
			if not state is Dictionary or state.size() < 4 or state.size() > 5 or not state.get("guardian_defeated") is bool:
				return false
			var mining: Variant = _valid_mining(state.get("mining", {}), int(key))
			if mining == null: return false
			var harvested: Variant = _valid_exploration(state.get("harvested_until"), false)
			var opened: Variant = _valid_exploration(state.get("opened_caches"), true)
			var discovered: Variant = _valid_discoveries(state.get("discovered_pois"))
			if harvested == null or opened == null or discovered == null:
				return false
			if not new_ascension.can_travel(int(key)) and (not harvested.is_empty() or not opened.is_empty() or not discovered.is_empty() or state.guardian_defeated or not mining.is_empty()):
				return false
			new_floors[key] = {"harvested_until": harvested, "opened_caches": opened, "discovered_pois": discovered, "guardian_defeated": state.guardian_defeated, "mining": mining}
		var active: Dictionary = new_floors[str(new_ascension.current_floor)]
		if active.harvested_until != new_harvested or active.opened_caches != new_opened or active.discovered_pois != new_discovered:
			return false
	else:
		if new_ascension.current_floor != 1:
			return false
		new_floors["1"] = {"harvested_until": new_harvested, "opened_caches": new_opened, "discovered_pois": new_discovered, "guardian_defeated": new_adventures.guardiao > 0, "mining": {}}
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
	var new_introduction := {"status":"legacy","met_smith":false,"weapon":""}
	if loaded_version >= 11:
		var intro: Variant = parsed.get("introduction")
		if not intro is Dictionary or intro.size() != 3 or not intro.get("met_smith") is bool or not intro.get("status") is String or not intro.get("weapon") is String: return false
		if intro.status not in ["active","complete","legacy"]: return false
		if intro.status == "active":
			if intro.weapon != "" or not new_rpg.equipment.is_empty() or new_rpg.equipped.Arma != "" or parsed.xp != 0 or parsed.kills != 0 or parsed.mission_index != 0 or parsed.mission_progress != 0 or parsed.mission_completed != 0: return false
		elif intro.status == "complete":
			if not intro.met_smith or not ArsenalRules.CATEGORIES.has(intro.weapon) or not new_rpg.equipment.has(intro.weapon): return false
		elif intro.weapon != "" or intro.met_smith: return false
		new_introduction = intro.duplicate()
	# Campos opcionais do Marco 5: saves anteriores simplesmente começam com os contadores zerados.
	var new_pity := LootRules.new_pity()
	var new_recipes: Array[String] = []
	if parsed.has("pity"):
		if not LootRules.valid_pity(parsed.pity): return false
		new_pity = {"raro": int(parsed.pity.raro), "epico": int(parsed.pity.epico)}
	var new_loadouts: Array = [{}, {}, {}]
	if parsed.has("loadouts"):
		var checked: Variant = _valid_loadouts(parsed.loadouts)
		if checked == null: return false
		new_loadouts = checked
	var new_expansions := 0
	if parsed.has("bag_expansions"):
		if not _bounded_integer(parsed.bag_expansions,0,EXPANSION_GOLD.size()): return false
		new_expansions = int(parsed.bag_expansions)
	var new_gems := 0
	if parsed.has("gems"):
		if not _bounded_integer(parsed.gems,0,100000000): return false
		new_gems = int(parsed.gems)
	if parsed.has("recipes"):
		if not parsed.recipes is Array or parsed.recipes.size() > 20: return false
		for id: Variant in parsed.recipes:
			if not LootRules.valid_recipe_id(id) or new_recipes.has(id): return false
			new_recipes.append(id)
	var new_instances := {}
	var new_equipped_uid := ""
	var new_next_uid := 1
	if loaded_version >= 12:
		if not parsed.get("weapon_instances") is Dictionary or not parsed.get("equipped_weapon_uid") is String or not _bounded_integer(parsed.get("next_weapon_uid"),1,10000000): return false
		new_instances = parsed.weapon_instances.duplicate(true)
		new_equipped_uid = parsed.equipped_weapon_uid
		new_next_uid = int(parsed.next_weapon_uid)
		if new_instances.size() > 300: return false
		for uid: String in new_instances:
			var entry: Variant = new_instances[uid]
			if not uid.begins_with("w") or not uid.substr(1).is_valid_int() or int(uid.substr(1)) >= new_next_uid: return false
			if not entry is Dictionary or entry.size() != 5 or not ArsenalRules.CATEGORIES.has(entry.get("category")) or entry.get("model") != entry.get("category") or not EquipmentEconomy.RARITY_ORDER.has(entry.get("rarity")) or not _bounded_integer(entry.get("level"),0,20) or not entry.get("choices") is Dictionary: return false
			entry.level = int(entry.level)
			if not new_rpg.equipment.has(entry.category): return false
			for milestone: String in entry.choices:
				if not milestone.is_valid_int() or not EquipmentEconomy.MILESTONES.has(int(milestone)) or not entry.choices[milestone] is String: return false
				var matched := false
				for option: Dictionary in EquipmentEconomy.bonus_options(entry.category,int(milestone)):
					if option.id == entry.choices[milestone]: matched = true
				if not matched: return false
		if new_equipped_uid != "" and (not new_instances.has(new_equipped_uid) or new_instances[new_equipped_uid].category != new_rpg.equipped.Arma or int(new_instances[new_equipped_uid].level) != int(new_rpg.equipment[new_rpg.equipped.Arma])): return false
	elif new_rpg.equipped.Arma != "":
		for category: String in new_rpg.equipment:
			if ArsenalRules.CATEGORIES.has(category):
				var uid := "w%d" % new_next_uid
				new_next_uid += 1
				new_instances[uid] = {"model":category,"category":category,"rarity":ArsenalRules.metadata(category).rarity,"level":int(new_rpg.equipment[category]),"choices":{}}
				if category == new_rpg.equipped.Arma: new_equipped_uid = uid
	# Commit all validated fields together; malformed trees cannot partially load.
	introduction = new_introduction
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
	pity = new_pity
	gems = new_gems
	bag_expansions = new_expansions
	loadouts = new_loadouts
	recipes = new_recipes
	attributes = new_rpg.attributes
	skills = new_rpg.skills
	equipment = new_rpg.equipment
	equipment_rarities = new_rpg.equipment_rarities
	equipped = new_rpg.equipped
	weapon_instances = new_instances
	equipped_weapon_uid = new_equipped_uid
	next_weapon_uid = new_next_uid
	if loaded_version >= 10: etapa2_enabled = true
	elif etapa2_enabled: migrate_etapa2()
	return true

func equipment_metadata() -> Dictionary:
	var result := {}
	for id: String in equipment:
		var meta := ArsenalRules.metadata(id)
		meta.rarity = equipment_rarity(id)
		result[id] = meta
	return result

func _valid_rpg(value: Variant, total_xp: int, version: int) -> Variant:
	if not value is Dictionary or value.get("level") != RPGRules.level_for_xp(total_xp):
		return null
	for field: String in ["attributes", "skills", "equipment", "equipped"]:
		if not value.get(field) is Dictionary:
			return null
	var attribute_names: Array = RPGRules.LEGACY_ATTRIBUTES if version < 8 else RPGRules.ATTRIBUTES
	if value.attributes.size() != attribute_names.size() or value.skills.size() != (0 if version >= 10 else 3) or not value.equipped.size() in [3,8]:
		return null
	var attribute_spent := 0
	var skill_spent := 0
	var result := {"attributes": RPGRules.empty_attributes(), "skills": {}, "equipment": {}, "equipment_rarities": {}, "equipped": value.equipped.duplicate()}
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
		if not RPGRules.EQUIPMENT.has(id) or not _bounded_integer(value.equipment[id], 0, 20 if version >= 12 and ArsenalRules.CATEGORIES.has(id) else 3):
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
				if field == "rarity":
					var rarity := str(meta.get(field, ""))
					if not EquipmentEconomy.RARITY_ORDER.has(rarity): return null
					if not RPGRules.EQUIPMENT[id].has("set_floor") and rarity != canonical.rarity: return null
					result.equipment_rarities[id] = rarity
				elif meta.get(field) != canonical[field]:
					return null
	if not value.has("equipment_meta"):
		for id: String in value.equipment:
			result.equipment_rarities[id] = ArsenalRules.metadata(id).rarity
	for slot: String in RPGRules.SLOTS:
		var id: Variant = value.equipped.get(slot,"" if value.equipped.size() == 3 and not RPGRules.LEGACY_SLOTS.has(slot) else null)
		if not id is String:
			return null
		result.equipped[slot] = id
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
		for spot: Dictionary in Exploration.known_resources():
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
	var sources: Array = Exploration.known_chests() if is_cache else Exploration.known_resources()
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
		if not ITEMS.has(item) and not EquipmentEconomy.valid_item(item) or not value[item] is float or value[item] < 1 or value[item] > 100000000 or value[item] != floorf(value[item]):
			return null
		result[item] = int(value[item])
	return result

func _valid_mining(value: Variant, floor_id: int) -> Variant:
	if not value is Dictionary: return null
	var result := {}
	for id: String in value:
		var config := MiningRules.definition(floor_id, id)
		var state: Variant = value[id]
		if config.is_empty() or not state is Dictionary or state.size() != 2: return null
		var remaining: Variant = state.get("remaining")
		var ready_at: Variant = state.get("ready_at")
		if not _bounded_integer(remaining, 0, int(config.uses)) or not _bounded_integer(ready_at, 0, 1000000000000): return null
		if (int(remaining) == 0) != (int(ready_at) > 0): return null
		result[id] = {"remaining": int(remaining), "ready_at": int(ready_at)}
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

func configure_ability(action: String, category: String, id: String, slot: int, at_camp: bool) -> bool:
	if not at_camp or not AbilityRules.CATEGORIES.has(category): return false
	var prof := talents.level(category)
	match action:
		"equip_skill":
			if slot not in [0,1]: return false
			if not id.is_empty() and not AbilityRules.available(category,id,prof): return false
			if id == AbilityRules.CATEGORIES[category].ultimate.id:
				return abilities.select_ultimate(category,id,prof,true)
			var slots: Array = abilities.loadouts[category].skills
			if not id.is_empty() and slots[1-slot] == id:
				slots[1-slot] = slots[slot]
				slots[slot] = id
				return true
			return abilities.select_skill(category,slot,id,prof,true)
		"equip_ultimate":
			return abilities.select_ultimate(category,id,prof,true)
		"equip_passive":
			if slot not in [0,1]: return false
			var rule := AbilityRules.passive(category,id)
			if not id.is_empty() and (rule.is_empty() or prof < int(rule.prof)): return false
			var slots: Array = abilities.loadouts[category].passives
			if not id.is_empty() and slots[1-slot] == id:
				slots[1-slot] = slots[slot]
				slots[slot] = id
				return true
			return abilities.select_passive(category,slot,id,prof,true)
		"specialization": return abilities.set_specialization(category,id,prof,true)
		"reset_tree": return abilities.refund(category,true)
		"reset_mastery": return talents.reset_mastery(category)
	return false
