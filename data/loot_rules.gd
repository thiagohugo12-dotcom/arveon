class_name LootRules
extends RefCounted

# Marco 5 · drops com nome, proteção contra azar e receitas de conjunto por andar.
# As tabelas vivem em FloorCatalog.LOOT; aqui ficam só as regras que as usam.

static func new_pity() -> Dictionary:
	return {"raro": 0, "epico": 0}

static func valid_pity(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 2: return false
	for key: String in ["raro", "epico"]:
		if not value.get(key) is float or value[key] < 0 or value[key] > 100000 or value[key] != floorf(value[key]): return false
	return true

static func named_items() -> Array:
	var result: Array = []
	for item: String in FloorCatalog.LOOT.named: result.append(item)
	for floor_id: int in FloorCatalog.LOOT.trophy: result.append(FloorCatalog.LOOT.trophy[floor_id])
	result.append(FloorCatalog.LOOT.fragment)
	return result

static func is_named(item: String) -> bool:
	return named_items().has(item)

# Identificador de uma receita de conjunto: "set:<andar>:<arma>".
static func is_piece(key: String) -> bool:
	return RPGRules.EQUIPMENT.has(key) and not ArsenalRules.CATEGORIES.has(key) and RPGRules.EQUIPMENT[key].has("set_floor")

static func recipe_id(floor_id: int, key: String) -> String:
	return "piece:%d:%s" % [floor_id, key] if is_piece(key) else "set:%d:%s" % [floor_id, key]

static func valid_recipe_id(value: Variant) -> bool:
	if not value is String: return false
	var parts: PackedStringArray = (value as String).split(":")
	if parts.size() != 3 or not parts[1].is_valid_int() or not FloorCatalog.LOOT.sets.has(int(parts[1])): return false
	if parts[0] == "set": return ArsenalRules.CATEGORIES.has(parts[2])
	return parts[0] == "piece" and is_piece(parts[2]) and int(RPGRules.EQUIPMENT[parts[2]].set_floor) == int(parts[1])

static func weapon_title(floor_id: int, category: String) -> String:
	if is_piece(category): return str(RPGRules.EQUIPMENT[category].name)
	var biome := "Mata" if floor_id == 1 else "Vale" if floor_id == 2 else "Andar %d" % floor_id
	return "%s da %s" % [ArsenalRules.category_name(category), biome] if floor_id == 1 else "%s do %s" % [ArsenalRules.category_name(category), biome]

# Custo e raridade de saída da receita de conjunto; vazio se o andar não tem conjunto.
static func set_recipe(floor_id: int, category: String) -> Dictionary:
	if is_piece(category): return piece_recipe(floor_id,category)
	if not FloorCatalog.LOOT.sets.has(floor_id) or not ArsenalRules.CATEGORIES.has(category): return {}
	var data: Dictionary = FloorCatalog.LOOT.sets[floor_id]
	var base := "Couro" if category in ["espada", "machado", "lanca"] else "Seda"
	var materials := {}
	materials[data.named[category]] = 6
	materials[EquipmentEconomy.key(base, data.base_rarity)] = 3
	materials[FloorCatalog.LOOT.trophy[floor_id]] = 1
	return {"gold": int(data.gold), "materials": materials, "rarity": data.rarity}

# Raridade final de um drop de material, aplicando a proteção contra azar.
# "pool_alto" vale para elites e chefes, os únicos que podem render o Épico garantido.
static func apply_pity(rarity: String, pity: Dictionary, pool_alto: bool) -> String:
	var tier := EquipmentEconomy.RARITY_ORDER.find(rarity)
	var limits: Dictionary = FloorCatalog.LOOT.pity
	if pool_alto and int(pity.epico) >= int(limits.epico) and tier < 3: tier = 3
	elif int(pity.raro) >= int(limits.raro) and tier < 2: tier = 2
	pity.raro = 0 if tier >= 2 else int(pity.raro) + 1
	pity.epico = 0 if tier >= 3 else int(pity.epico) + 1
	return EquipmentEconomy.RARITY_ORDER[tier]

static func _material(item: String, rarity: String) -> Dictionary:
	return {"item": item, "rarity": rarity, "key": EquipmentEconomy.key(item, rarity)}

static func _named(item: String) -> Dictionary:
	return {"item": item, "rarity": "comum", "key": item, "named": true}

# Monstros comuns e elites: material base com proteção contra azar mais o drop nomeado do andar.
static func roll(kind: int, rng: RandomNumberGenerator, pity: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in EquipmentEconomy.DROP_TABLE.get(kind, []):
		var occurrence := rng.randf()
		if occurrence >= float(entry.chance): continue
		var rolled := EquipmentEconomy.roll_entry(entry, occurrence, rng.randf())
		if rolled.is_empty(): continue
		result.append(_material(entry.item, apply_pity(rolled.rarity, pity, kind in [3, 4])))
	for entry: Dictionary in FloorCatalog.LOOT.drops.get(kind, []):
		if rng.randf() < float(entry.chance): result.append(_named(entry.item))
	if kind == 3 and rng.randf() < float(FloorCatalog.LOOT.fragment_elite_chance):
		result.append(_named(FloorCatalog.LOOT.fragment))
	return result

# Guardião do andar: troféu garantido e de 3 a 5 materiais base, no mínimo Incomuns.
static func field_boss(floor_id: int, rng: RandomNumberGenerator, pity: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if FloorCatalog.LOOT.trophy.has(floor_id): result.append(_named(FloorCatalog.LOOT.trophy[floor_id]))
	for _i in range(rng.randi_range(3, 5)):
		var item: String = ["Couro", "Seda", "Essência"][rng.randi() % 3]
		var chance := rng.randf()
		var rarity := "incomum" if chance < 0.6 else "raro" if chance < 0.9 else "epico"
		result.append(_material(item, apply_pity(rarity, pity, true)))
	return result

# Guardião da Torre: troféu do andar e um Fragmento de Receita.
static func tower_boss(floor_id: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if FloorCatalog.LOOT.trophy.has(floor_id): result.append(_named(FloorCatalog.LOOT.trophy[floor_id]))
	result.append(_named(FloorCatalog.LOOT.fragment))
	return result

# Peças de conjunto (Capacete, Armadura, Luvas, Botas, Anel, Colar, Amuleto): 4 do material nomeado
# do andar, 2 do material base e ouro; o item é único e depois evolui pelo aprimoramento normal.
static func piece_recipe(floor_id: int, item_id: String) -> Dictionary:
	if not is_piece(item_id) or not FloorCatalog.LOOT.sets.has(floor_id): return {}
	var item: Dictionary = RPGRules.EQUIPMENT[item_id]
	if int(item.set_floor) != floor_id: return {}
	var data: Dictionary = FloorCatalog.LOOT.sets[floor_id]
	var base := "Couro" if str(item.slot) in ["Capacete", "Armadura", "Luvas", "Botas"] else "Seda"
	var materials := {}
	materials[data.pieces[item.slot]] = 4
	materials[EquipmentEconomy.key(base, data.base_rarity)] = 2
	return {"gold": int(data.piece_gold), "materials": materials, "rarity": item.rarity, "piece": item_id}
