class_name RPGRules
extends RefCounted

const MAX_LEVEL := 100
const LEGACY_ATTRIBUTES := ["Força", "Vitalidade", "Agilidade", "Espírito"]
const ATTRIBUTES := ["Força", "Vitalidade", "Resistência", "Mobilidade", "Destreza", "Espírito"]
const ATTRIBUTE_HELP := {
	"Força": "+2 de dano físico por ponto.",
	"Vitalidade": "+8 de HP máximo por ponto.",
	"Resistência": "+0,5% de redução física e mágica · limite 25%.",
	"Mobilidade": "+1% de movimento normal · limite 20%. Dash fixo.",
	"Destreza": "−0,75% no intervalo básico · limite 15%. Sem erros aleatórios.",
	"Espírito": "+2 de dano mágico por ponto."}

static func empty_attributes() -> Dictionary:
	var result := {}
	for attribute: String in ATTRIBUTES: result[attribute] = 0
	return result

static func received_damage(amount: int, damage_type: String, armor: int, resistance: float, fury: float = 0.0) -> int:
	if amount <= 0 or damage_type not in ["physical", "magical"]: return 0
	var after_armor := maxi(1, amount - armor) if damage_type == "physical" else amount
	return maxi(1, ceili(after_armor * (1.0-clampf(resistance,0,0.25)) * (1.0-clampf(fury,0,0.4))))
const SKILLS := ["Corte Circular", "Investida", "Fúria Ancestral"]
# Oito espaços. "Acessório" é o Colar (nome interno mantido por compatibilidade com saves antigos).
const LEGACY_SLOTS := ["Arma", "Armadura", "Acessório"]
const SLOTS := ["Arma", "Capacete", "Armadura", "Luvas", "Botas", "Anel", "Acessório", "Amuleto"]
const SLOT_TITLES := {"Acessório": "Colar"}

static func slot_title(slot: String) -> String:
	return str(SLOT_TITLES.get(slot, slot))
const EQUIPMENT := {
	"espada": {"name": "Espada Inicial", "slot": "Arma", "damage": 0, "hp": 0, "speed": 0, "spirit": 0, "armor": 0, "gold": 30, "materials": {"Madeira": 3, "Pedras": 2}},
	"machado": {"name": "Machado Inicial", "slot": "Arma", "damage": 4, "hp": 0, "speed": -4, "spirit": 0, "armor": 0, "gold": 35, "materials": {"Madeira": 3, "Pedras": 4}},
	"lanca": {"name": "Lança Inicial", "slot": "Arma", "damage": 2, "hp": 0, "speed": 6, "spirit": 1, "armor": 0, "gold": 40, "materials": {"Madeira": 4, "Seda": 2}},
	"arco": {"name": "Arco Inicial", "slot": "Arma", "damage": 0, "hp": 0, "speed": 0, "spirit": 0, "armor": 0, "gold": 30, "materials": {"Madeira": 3, "Seda": 2}},
	"cajado": {"name": "Cajado Inicial", "slot": "Arma", "damage": 0, "hp": 0, "speed": 0, "spirit": 2, "armor": 0, "gold": 35, "materials": {"Madeira": 3, "Essência": 2}},
	"couro": {"name": "Colete de couro", "slot": "Armadura", "damage": 0, "hp": 12, "speed": 0, "spirit": 0, "armor": 1, "gold": 25, "materials": {"Couro": 4, "Madeira": 1}},
	"trama": {"name": "Trama de seda", "slot": "Armadura", "damage": 0, "hp": 6, "speed": 4, "spirit": 2, "armor": 0, "gold": 30, "materials": {"Seda": 4, "Ervas": 2}},
	"pedra": {"name": "Amuleto de pedra", "slot": "Acessório", "damage": 1, "hp": 6, "speed": 0, "spirit": 0, "armor": 0, "gold": 20, "materials": {"Pedras": 3, "Essência": 1}},
	"semente": {"name": "Talismã da mata", "slot": "Acessório", "damage": 0, "hp": 0, "speed": 4, "spirit": 3, "armor": 0, "gold": 25, "materials": {"Madeira": 2, "Ervas": 3, "Essência": 2}},
# Conjuntos de andar (Marco 6): rarity fields remain as legacy-save defaults; new pieces start Comuns and store rarity per owned item.
	"elmo_mata": {"name": "Elmo da Mata", "slot": "Capacete", "rarity": "raro", "set_floor": 1, "damage": 0, "hp": 16, "speed": 0, "spirit": 0, "armor": 2, "crit": 0.0, "crit_damage": 0.0, "resist": 0.0, "gold": 0, "materials": {}},
	"colete_mata": {"name": "Armadura da Mata", "slot": "Armadura", "rarity": "raro", "set_floor": 1, "damage": 0, "hp": 19, "speed": 0, "spirit": 0, "armor": 2, "crit": 0.0, "crit_damage": 0.0, "resist": 0.0, "gold": 0, "materials": {}},
	"luvas_mata": {"name": "Luvas da Mata", "slot": "Luvas", "rarity": "raro", "set_floor": 1, "damage": 3, "hp": 0, "speed": 0, "spirit": 0, "armor": 0, "crit": 0.008, "crit_damage": 0.0, "resist": 0.0, "gold": 0, "materials": {}},
	"botas_mata": {"name": "Botas da Mata", "slot": "Botas", "rarity": "raro", "set_floor": 1, "damage": 0, "hp": 0, "speed": 6, "spirit": 0, "armor": 2, "crit": 0.0, "crit_damage": 0.0, "resist": 0.0, "gold": 0, "materials": {}},
	"anel_mata": {"name": "Anel da Mata", "slot": "Anel", "rarity": "raro", "set_floor": 1, "damage": 0, "hp": 0, "speed": 0, "spirit": 0, "armor": 0, "crit": 0.016, "crit_damage": 0.05, "resist": 0.0, "gold": 0, "materials": {}},
	"colar_mata": {"name": "Colar da Mata", "slot": "Acessório", "rarity": "raro", "set_floor": 1, "damage": 0, "hp": 13, "speed": 0, "spirit": 0, "armor": 0, "crit": 0.0, "crit_damage": 0.0, "resist": 0.008, "gold": 0, "materials": {}},
	"amuleto_mata": {"name": "Amuleto da Mata", "slot": "Amuleto", "rarity": "raro", "set_floor": 1, "damage": 0, "hp": 0, "speed": 0, "spirit": 2, "armor": 0, "crit": 0.0, "crit_damage": 0.0, "resist": 0.008, "gold": 0, "materials": {}},
	"elmo_vale": {"name": "Elmo do Vale", "slot": "Capacete", "rarity": "epico", "set_floor": 2, "damage": 0, "hp": 21, "speed": 0, "spirit": 0, "armor": 2, "crit": 0.0, "crit_damage": 0.0, "resist": 0.0, "gold": 0, "materials": {}},
	"colete_vale": {"name": "Armadura do Vale", "slot": "Armadura", "rarity": "epico", "set_floor": 2, "damage": 0, "hp": 25, "speed": 0, "spirit": 0, "armor": 2, "crit": 0.0, "crit_damage": 0.0, "resist": 0.0, "gold": 0, "materials": {}},
	"luvas_vale": {"name": "Luvas do Vale", "slot": "Luvas", "rarity": "epico", "set_floor": 2, "damage": 4, "hp": 0, "speed": 0, "spirit": 0, "armor": 0, "crit": 0.011, "crit_damage": 0.0, "resist": 0.0, "gold": 0, "materials": {}},
	"botas_vale": {"name": "Botas do Vale", "slot": "Botas", "rarity": "epico", "set_floor": 2, "damage": 0, "hp": 0, "speed": 8, "spirit": 0, "armor": 2, "crit": 0.0, "crit_damage": 0.0, "resist": 0.0, "gold": 0, "materials": {}},
	"anel_vale": {"name": "Anel do Vale", "slot": "Anel", "rarity": "epico", "set_floor": 2, "damage": 0, "hp": 0, "speed": 0, "spirit": 0, "armor": 0, "crit": 0.021, "crit_damage": 0.06, "resist": 0.0, "gold": 0, "materials": {}},
	"colar_vale": {"name": "Colar do Vale", "slot": "Acessório", "rarity": "epico", "set_floor": 2, "damage": 0, "hp": 17, "speed": 0, "spirit": 0, "armor": 0, "crit": 0.0, "crit_damage": 0.0, "resist": 0.011, "gold": 0, "materials": {}},
	"amuleto_vale": {"name": "Amuleto do Vale", "slot": "Amuleto", "rarity": "epico", "set_floor": 2, "damage": 0, "hp": 0, "speed": 0, "spirit": 2, "armor": 0, "crit": 0.0, "crit_damage": 0.0, "resist": 0.011, "gold": 0, "materials": {}}
}

static func level_for_xp(total: int) -> int:
	var result := 1
	while result < MAX_LEVEL and total >= xp_floor(result + 1):
		result += 1
	return result

static func cost_to_level(level: int) -> int:
	return level * 50

static func xp_floor(level: int) -> int:
	return (level - 1) * level * 25

static func bonuses(id: String, upgrade: int) -> Dictionary:
	var item: Dictionary = EQUIPMENT[id]
	var result := {"damage": int(item.damage), "hp": int(item.hp), "speed": int(item.speed), "spirit": int(item.spirit), "armor": int(item.armor),
		"crit": float(item.get("crit",0.0)), "crit_damage": float(item.get("crit_damage",0.0)), "resist": float(item.get("resist",0.0))}
	match str(item.slot):
		"Arma": result.damage += upgrade
		"Armadura": result.hp += upgrade * 4
		"Capacete": result.hp += upgrade * 3
		"Luvas": result.damage += upgrade
		"Botas": result.speed += upgrade
		"Anel": result.crit += upgrade * 0.002
		_: result.spirit += upgrade
	return result

static func bonus_text(id: String, upgrade: int) -> String:
	var b := bonuses(id, upgrade)
	var text := "Dano %+d · HP %+d\nVel %+d · Espírito %+d · Defesa %d" % [b.damage, b.hp, b.speed, b.spirit, b.armor]
	if b.crit > 0.0 or b.crit_damage > 0.0 or b.resist > 0.0:
		text += "\nCrítico %+.1f%% · Dano crít. %+.0f%% · Resist. %+.1f%%" % [b.crit * 100.0, b.crit_damage * 100.0, b.resist * 100.0]
	return text

static func recipe(id: String, owned: bool, upgrade: int) -> Dictionary:
	if owned:
		return {"gold": 15 * (upgrade + 1), "materials": {"Pedras": 2 + upgrade, "Essência": 1 + upgrade}}
	return {"gold": EQUIPMENT[id].gold, "materials": EQUIPMENT[id].materials}

static func cost_text(cost: Dictionary) -> String:
	var result := "%d ouro" % cost.gold
	for item: String in cost.materials:
		result += " · %s × %d" % [item, cost.materials[item]]
	return result
