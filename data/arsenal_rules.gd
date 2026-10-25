class_name ArsenalRules
extends RefCounted

# Stable IDs and separate rarity/upgrade; no proficiency system in this stage.
const RARITIES := {
	"comum": {"name": "Comum", "color": "#b0b8b3"},
	"incomum": {"name": "Incomum", "color": "#81c77e"},
	"raro": {"name": "Raro", "color": "#7eb5ed"},
	"epico": {"name": "Épico", "color": "#be8fea"},
	"lendario": {"name": "Lendário", "color": "#e7c36d"},
	"mitico": {"name": "Mítico · reservado", "color": "#e891bd"}}
const CATEGORIES := {
	"espada": {"name": "Espada", "reach": 75.0, "interval": 0.72, "projectile": "", "speed": 0.0},
	"machado": {"name": "Machado", "reach": 80.0, "interval": 0.9, "projectile": "", "speed": 0.0},
	"lanca": {"name": "Lança", "reach": 115.0, "interval": 0.75, "projectile": "", "speed": 0.0},
	"arco": {"name": "Arco", "reach": 250.0, "interval": 0.8, "projectile": "flecha", "speed": 440.0},
	"cajado": {"name": "Cajado", "reach": 220.0, "interval": 0.95, "projectile": "orbe", "speed": 260.0}}
static func metadata(id: String) -> Dictionary:
	var item: Dictionary = RPGRules.EQUIPMENT.get(id, {})
	if item.is_empty():
		return {}
	return {"category": id if CATEGORIES.has(id) else item.slot, "rarity": str(item.get("rarity","incomum" if id in ["lanca","cajado","trama","semente"] else "comum")), "icon": id if CATEGORIES.has(id) else item.slot, "level": 1}
static func profile(id: String) -> Dictionary:
	return CATEGORIES.get(weapon_category(id), CATEGORIES.espada).duplicate()
static func weapon_category(id: String) -> String:
	var category: String = metadata(id).get("category","")
	return category if CATEGORIES.has(category) else ""
static func rarity(id: String) -> Dictionary:
	return RARITIES[metadata(id).rarity]
static func category_name(id: String) -> String:
	var category: String = metadata(id).category
	return CATEGORIES[category].name if CATEGORIES.has(category) else category
static func effective(progress: GameProgress, id: String) -> Dictionary:
	# Comparison computes the candidate build without mutating ownership or HP.
	var current := progress.equipped.duplicate()
	var candidate := GameProgress.new()
	candidate.attributes = progress.attributes.duplicate()
	candidate.equipment = progress.equipment.duplicate()
	candidate.weapon_instances = progress.weapon_instances.duplicate(true)
	candidate.equipped_weapon_uid = progress.equipped_weapon_uid if progress.weapon(progress.equipped_weapon_uid).get("category","") == id else ""
	if candidate.equipped_weapon_uid == "":
		for uid: String in candidate.weapon_instances:
			if candidate.weapon_instances[uid].category == id:
				candidate.equipped_weapon_uid = uid
				break
	candidate.equipment[id] = int(progress.equipment.get(id,0))
	if candidate.equipped_weapon_uid != "": candidate.equipment[id] = int(candidate.weapon_instances[candidate.equipped_weapon_uid].level)
	candidate.talents = progress.talents
	candidate.abilities = progress.abilities
	candidate.etapa2_enabled = progress.etapa2_enabled
	candidate.equipped = current
	candidate.equipped[RPGRules.EQUIPMENT[id].slot] = id
	var values := candidate.combat_stats()
	var weapon_id: String = candidate.equipped.Arma
	var configuration := profile(weapon_id)
	values.reach = configuration.reach
	values.interval = configuration.interval * float(values.basic_interval_factor)
	return values
