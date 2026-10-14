extends RefCounted
## Presentation only. All mechanics/IDs are read from the existing rules.
const ORDER := ["espada","machado","lanca","arco","cajado"]
const CONFIGS := {
	"espada":{"body":true,"atlas":"res://assets/art/skills1_v1/espada.png","prepare":0.26,"duration":0.48,"color":Color("#fff0b9")},
	"machado":{"atlas":"res://assets/art/skills1_v1/machado.png","prepare":0.22,"duration":0.46,"color":Color("#ddba82")},
	"lanca":{"atlas":"res://assets/art/skills1_v1/lanca.png","prepare":0.16,"duration":0.30,"color":Color("#e1e9c5")},
	"arco":{"atlas":"res://assets/art/skills1_v1/arco.png","prepare":0.18,"duration":0.30,"color":Color("#fff0b9")},
	"cajado":{"atlas":"res://assets/art/skills1_v1/cajado.png","prepare":0.22,"duration":0.38,"color":Color("#a9e4c2")}}
static func rule(category: String) -> Dictionary: return AbilityRules.CATEGORIES[category].skill1
static func supported(category: String) -> bool: return CONFIGS.has(category)
