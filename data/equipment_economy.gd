class_name EquipmentEconomy
extends RefCounted

# Balanceamento provisório: dados de economia separados da apresentação.
const RARITY_ORDER := ["comum", "incomum", "raro", "epico", "lendario"]
const MATERIALS := ["Couro", "Seda", "Essência", "Minério de Ferro"]
const SEAL := "Selo de Proteção"
const DROP_TABLE := {
	0: [{"item":"Couro", "chance":0.35, "rarities":{"comum":0.88,"incomum":0.10,"raro":0.02}}],
	1: [{"item":"Seda", "chance":0.35, "rarities":{"comum":0.88,"incomum":0.10,"raro":0.02}}],
	2: [{"item":"Essência", "chance":0.35, "rarities":{"comum":0.88,"incomum":0.10,"raro":0.02}}],
	3: [{"item":"Couro", "chance":0.55, "rarities":{"comum":0.65,"incomum":0.28,"raro":0.07}}],
	4: [{"item":"Essência", "chance":0.75, "rarities":{"comum":0.45,"incomum":0.40,"raro":0.15}}]}
const SUCCESS := [1.0,1.0,1.0,1.0,1.0,0.90,0.86,0.82,0.78,0.75,0.70,0.65,0.60,0.55,0.50,0.45,0.40,0.35,0.30,0.25]
const MILESTONES := [5,10,15,20]
const FAILURE := {"safe_through":10,"high_loss":1,"highest_loss_chance_two":0.5}
const BONUS_TEMPLATES := {
	"espada":[{"id":"corte","name":"Dano físico","stat":"physical","base":2},{"id":"ritmo","name":"Ataque rápido","stat":"attack_speed","base":0.0125},{"id":"critico","name":"Crítico","stat":"critical","base":0.005}],
	"machado":[{"id":"impacto","name":"Dano físico","stat":"physical","base":3},{"id":"guarda","name":"Defesa","stat":"armor","base":1},{"id":"vigor","name":"Vida","stat":"hp","base":7}],
	"lanca":[{"id":"ponta","name":"Dano físico","stat":"physical","base":2},{"id":"ritmo","name":"Ataque rápido","stat":"attack_speed","base":0.0125},{"id":"vigor","name":"Vida","stat":"hp","base":6}],
	"arco":[{"id":"tiro","name":"Dano físico","stat":"physical","base":2},{"id":"sequencia","name":"Ataque rápido","stat":"attack_speed","base":0.015},{"id":"critico","name":"Crítico","stat":"critical","base":0.005}],
	"cajado":[{"id":"arcano","name":"Dano mágico","stat":"magical","base":2},{"id":"espirito","name":"Espírito","stat":"spirit","base":1},{"id":"vigor","name":"Vida","stat":"hp","base":5}]}

static func key(item: String, rarity: String = "comum") -> String:
	return item if not MATERIALS.has(item) or rarity == "comum" else item + "|" + rarity

static func split_key(value: String) -> Dictionary:
	var parts := value.split("|")
	return {"item":parts[0], "rarity":parts[1] if parts.size() == 2 else "comum"}

static func valid_item(value: String) -> bool:
	var parts := value.split("|")
	return parts.size() == 2 and MATERIALS.has(parts[0]) and RARITY_ORDER.has(parts[1]) and parts[1] != "comum" or value == SEAL

static func roll_drops(kind: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in DROP_TABLE.get(kind, []):
		var occurrence := rng.randf()
		if occurrence >= float(entry.chance): continue
		var rolled := roll_entry(entry,occurrence,rng.randf())
		if not rolled.is_empty(): result.append(rolled)
	return result

static func roll_entry(entry: Dictionary, occurrence: float, quality: float) -> Dictionary:
	if occurrence < 0.0 or occurrence >= float(entry.chance) or quality < 0.0 or quality >= 1.0: return {}
	var cumulative := 0.0
	for rarity: String in entry.rarities:
		cumulative += float(entry.rarities[rarity])
		if quality < cumulative: return {"item":entry.item,"rarity":rarity,"key":key(entry.item,rarity)}
	return {}

static func valid_drop_table() -> bool:
	for kind: int in DROP_TABLE:
		for entry: Dictionary in DROP_TABLE[kind]:
			if not MATERIALS.has(entry.item) or entry.chance < 0.0 or entry.chance > 1.0: return false
			var sum := 0.0
			for rarity: String in entry.rarities:
				if not RARITY_ORDER.has(rarity) or entry.rarities[rarity] < 0.0: return false
				sum += entry.rarities[rarity]
			if absf(sum - 1.0) > 0.0001: return false
	return true

static func craft_recipe(category: String, rarity: String) -> Dictionary:
	if not ArsenalRules.CATEGORIES.has(category) or not RARITY_ORDER.has(rarity): return {}
	var tier := RARITY_ORDER.find(rarity)
	return {"gold":20 + 25*tier, "materials":{"Madeira":3, key("Couro" if category in ["espada","machado","lanca"] else "Seda",rarity):2+tier, key("Essência",rarity):1+tier}}

# Receita adicional do Vale; as receitas existentes continuam disponíveis.
static func vale_iron_recipe(rarity: String) -> Dictionary:
	if rarity not in ["comum", "raro"]: return {}
	return {"gold": 15 if rarity == "comum" else 45, "materials": {key("Minério de Ferro", rarity): 2, "Madeira": 1}}

static func rarity_recipe(current: String) -> Dictionary:
	var tier := RARITY_ORDER.find(current)
	if tier < 0 or tier >= 4: return {}
	var next: String = RARITY_ORDER[tier+1]
	return {"gold":50+50*tier,"materials":{key("Essência",next):2+tier,key("Couro",next):1+tier}}

static func enhance_recipe(level: int, rarity: String) -> Dictionary:
	if level < 0 or level >= 20 or not RARITY_ORDER.has(rarity): return {}
	var tier := RARITY_ORDER.find(rarity)
	return {"gold":10+level*8+tier*10,"materials":{key("Essência",rarity):1+level/5}}

static func bonus_options(category: String, milestone: int) -> Array[Dictionary]:
	if not ArsenalRules.CATEGORIES.has(category) or not MILESTONES.has(milestone): return []
	var scale := milestone/5
	var result: Array[Dictionary] = []
	for option: Dictionary in BONUS_TEMPLATES[category]:
		result.append({"id":option.id,"name":option.name,"stat":option.stat,"value":option.base*scale})
	return result
