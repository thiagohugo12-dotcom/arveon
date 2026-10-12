class_name TalentRules
extends RefCounted

# Provisional values approved as an adjustable first playable tree (ADR).
const MAX_PROFICIENCY := 30
const DAMAGE_PER_XP := 10 # Provisional: carry every fractional unit between hits/saves.
const CLASSES := {"espada":"Espadachim","machado":"Guerreiro de Machado","lanca":"Lanceiro","arco":"Arqueiro","cajado":"Místico"}
const MASTERY := {"Dano":{"cap":12,"step":0.01},"Dano Especial":{"cap":12,"step":0.0125},"Crítico":{"cap":10,"step":0.01},"Dano Crítico":{"cap":10,"step":0.03}}
const NODES := {
	"corte": {"name":"Corte Circular", "kind":"Técnica", "prof":3, "parent":"", "skill":0, "bonus":{}, "description":"+1 grau de Corte Circular com esta arma (máximo 4).", "icon":"espada", "position":Vector2(0.25,90)},
	"vigor": {"name":"Vigor", "kind":"Passiva", "prof":5, "parent":"", "skill":-1, "bonus":{"hp":8}, "description":"+8 de HP máximo com esta arma. Não recupera vida.", "icon":"Ervas", "position":Vector2(0.75,90)},
	"investida": {"name":"Investida", "kind":"Técnica", "prof":8, "parent":"corte", "skill":1, "bonus":{}, "description":"+1 grau de Investida com esta arma (máximo 4).", "icon":"lanca", "position":Vector2(0.25,200)},
	"guarda": {"name":"Guarda", "kind":"Passiva", "prof":12, "parent":"vigor", "skill":-1, "bonus":{"armor":1}, "description":"+1 de defesa com esta arma.", "icon":"Armadura", "position":Vector2(0.75,200)},
	"furia": {"name":"Fúria Ancestral", "kind":"Técnica", "prof":15, "parent":"investida", "skill":2, "bonus":{}, "description":"+1 grau de Fúria Ancestral com esta arma (máximo 4).", "icon":"cajado", "position":Vector2(0.25,310)},
	"especializacao": {"name":"Especialização", "kind":"Passiva", "prof":18, "parent":"guarda", "skill":-1, "bonus":{"damage":2}, "description":"+2 de dano com esta arma.", "icon":"machado", "position":Vector2(0.75,310)},
	"maestria": {"name":"Maestria", "kind":"Maestria", "prof":30, "parent":"especializacao", "skill":-1, "bonus":{"hp":8,"damage":2}, "description":"+8 de HP máximo e +2 de dano com esta arma. Não recupera vida.", "icon":"maestria", "position":Vector2(0.5,420)}
}

static func xp_floor(level: int) -> int:
	return (level-1)*level*4

static func level_for_xp(xp: int) -> int:
	var level := 1
	while level < MAX_PROFICIENCY and xp >= xp_floor(level+1): level += 1
	return level
