extends RefCounted
## Presentation only. All mechanics/IDs are read from the existing rules.
const ORDER := ["espada","machado","lanca","arco","cajado"]
const CONFIGS := {
	"espada":{"atlas":"res://assets/art/skills1_v1/espada.png","prepare":0.12,"duration":0.24,"color":Color("#fff0b9")},
	"machado":{"atlas":"res://assets/art/skills1_v1/machado.png","prepare":0.22,"duration":0.46,"color":Color("#ddba82")},
	"lanca":{"atlas":"res://assets/art/skills1_v1/lanca.png","prepare":0.16,"duration":0.30,"color":Color("#e1e9c5")}}
static func rule(category: String) -> Dictionary: return AbilityRules.CATEGORIES[category].skill1
static func supported(category: String) -> bool: return CONFIGS.has(category)
