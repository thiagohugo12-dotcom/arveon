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
const SLOTS := ["Arma", "Armadura", "Acessório"]
const EQUIPMENT := {
	"espada": {"name": "Espada Inicial", "slot": "Arma", "damage": 0, "hp": 0, "speed": 0, "spirit": 0, "armor": 0, "gold": 30, "materials": {"Madeira": 3, "Pedras": 2}},
	"machado": {"name": "Machado Inicial", "slot": "Arma", "damage": 4, "hp": 0, "speed": -4, "spirit": 0, "armor": 0, "gold": 35, "materials": {"Madeira": 3, "Pedras": 4}},
	"lanca": {"name": "Lança Inicial", "slot": "Arma", "damage": 2, "hp": 0, "speed": 6, "spirit": 1, "armor": 0, "gold": 40, "materials": {"Madeira": 4, "Seda": 2}},
	"arco": {"name": "Arco Inicial", "slot": "Arma", "damage": 0, "hp": 0, "speed": 0, "spirit": 0, "armor": 0, "gold": 30, "materials": {"Madeira": 3, "Seda": 2}},
	"cajado": {"name": "Cajado Inicial", "slot": "Arma", "damage": 0, "hp": 0, "speed": 0, "spirit": 2, "armor": 0, "gold": 35, "materials": {"Madeira": 3, "Essência": 2}},
	"couro": {"name": "Colete de couro", "slot": "Armadura", "damage": 0, "hp": 12, "speed": 0, "spirit": 0, "armor": 1, "gold": 25, "materials": {"Couro": 4, "Madeira": 1}},
	"trama": {"name": "Trama de seda", "slot": "Armadura", "damage": 0, "hp": 6, "speed": 4, "spirit": 2, "armor": 0, "gold": 30, "materials": {"Seda": 4, "Ervas": 2}},
	"pedra": {"name": "Amuleto de pedra", "slot": "Acessório", "damage": 1, "hp": 6, "speed": 0, "spirit": 0, "armor": 0, "gold": 20, "materials": {"Pedras": 3, "Essência": 1}},
	"semente": {"name": "Talismã da mata", "slot": "Acessório", "damage": 0, "hp": 0, "speed": 4, "spirit": 3, "armor": 0, "gold": 25, "materials": {"Madeira": 2, "Ervas": 3, "Essência": 2}}
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
	var result := {"damage": int(item.damage), "hp": int(item.hp), "speed": int(item.speed), "spirit": int(item.spirit), "armor": int(item.armor)}
	if item.slot == "Arma":
		result.damage += upgrade
	elif item.slot == "Armadura":
		result.hp += upgrade * 4
	else:
		result.spirit += upgrade
	return result

static func bonus_text(id: String, upgrade: int) -> String:
	var b := bonuses(id, upgrade)
	return "Dano %+d · HP %+d\nVel %+d · Espírito %+d · Defesa %d" % [b.damage, b.hp, b.speed, b.spirit, b.armor]

static func recipe(id: String, owned: bool, upgrade: int) -> Dictionary:
	if owned:
		return {"gold": 15 * (upgrade + 1), "materials": {"Pedras": 2 + upgrade, "Essência": 1 + upgrade}}
	return {"gold": EQUIPMENT[id].gold, "materials": EQUIPMENT[id].materials}

static func cost_text(cost: Dictionary) -> String:
	var result := "%d ouro" % cost.gold
	for item: String in cost.materials:
		result += " · %s × %d" % [item, cost.materials[item]]
	return result
