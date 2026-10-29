class_name FloorCatalog
extends RefCounted

# Marco 2 · fonte única dos dados de andar. FloorConfig, TowerTrial, Floor2Layout e
# Main apontam para cá; os valores dos Andares 1 e 2 são os mesmos de antes e os
# testes de paridade (tests/floor_catalog_tests.gd) guardam os números originais.
# Este arquivo não referencia outros scripts em constantes, para não criar ciclos.

# Escala por andar. "difficulty" multiplica vida e dano; "rewards", XP e ouro.
const SCALE := {
	"1": {"difficulty": 1.0, "rewards": 1.0},
	"2": {"difficulty": 1.5, "rewards": 1.1},
	"3": {"difficulty": 2.1, "rewards": 2.6},
	"4": {"difficulty": 2.8, "rewards": 3.5},
	"5": {"difficulty": 3.6, "rewards": 4.5},
	"6": {"difficulty": 4.5, "rewards": 5.6},
	"7": {"difficulty": 5.5, "rewards": 6.9},
	"8": {"difficulty": 6.6, "rewards": 8.3},
	"9": {"difficulty": 7.8, "rewards": 9.8},
	"10": {"difficulty": 9.0, "rewards": 11.3}}

# Marco 4 · chefes em fases. Limiares de vida, ritmo e asseclas valem para todos os chefes;
# "minions" (tipos de monstro da fase 3) fica na definição de cada chefe em FLOORS.
const BOSS_PHASES := {
	"thresholds": [0.66, 0.33],
	"windup": [1.0, 0.9, 0.8],
	"speed": [1.0, 1.1, 1.2],
	"transition": 1.0,
	"max_minions": 2}

# Vida efetiva (já com a dificuldade) dos chefes dos andares ainda sem conteúdo; os Andares 1 e 2
# seguem com os valores de FLOORS multiplicados pela dificuldade, como antes.
const BOSS_HP := {
	"field": {3: 840, 4: 1200, 5: 1700, 6: 2300, 7: 3000, 8: 3900, 9: 5000, 10: 6500},
	"tower": {3: 800, 4: 1150, 5: 1600, 6: 2200, 7: 2900, 8: 3700, 9: 4800, 10: 6200}}

# "kind" é o id numérico antigo; continua válido para saves, testes e drops.
const MONSTERS := {
	"javali": {"kind": 0, "name": "Javali", "hp": 48, "speed": 70.0, "contact": 8, "xp": 12},
	"aranha": {"kind": 1, "name": "Aranha", "hp": 36, "speed": 92.0, "contact": 7, "xp": 10},
	"mandacaru": {"kind": 2, "name": "Mandacaru", "hp": 64, "speed": 48.0, "contact": 10, "xp": 16},
	"javali_elite": {"kind": 3, "name": "Javali Elite", "hp": 120, "speed": 60.0, "contact": 12, "xp": 35},
	"criatura_da_mata": {"kind": 4, "name": "Criatura da Mata", "hp": 48, "speed": 70.0, "contact": 8, "xp": 80},
	"goblin_garimpeiro": {"kind": 5, "name": "Goblin Garimpeiro", "hp": 52, "speed": 95.0, "contact": 8, "xp": 10},
	"tatu_rochoso": {"kind": 6, "name": "Tatu Rochoso", "hp": 108, "speed": 54.0, "contact": 11, "xp": 16},
	"escorpiao_da_chapada": {"kind": 7, "name": "Escorpião da Chapada", "hp": 72, "speed": 105.0, "contact": 13, "xp": 20}}
const GOLD_RANGE := Vector2i(2, 5)

# Marco 5 · materiais com nome, troféus, proteção contra azar e conjuntos de arma por andar.
const LOOT := {
	"named": {"Presa de Javali": 1, "Teia Reforçada": 1, "Espinho Seco": 1, "Pepita Dourada": 2, "Placa de Tatu": 2, "Ferrão da Chapada": 2},
	"drops": {
		0: [{"item": "Presa de Javali", "chance": 0.25}], 3: [{"item": "Presa de Javali", "chance": 0.60}],
		1: [{"item": "Teia Reforçada", "chance": 0.25}], 2: [{"item": "Espinho Seco", "chance": 0.25}],
		5: [{"item": "Pepita Dourada", "chance": 0.25}], 6: [{"item": "Placa de Tatu", "chance": 0.25}],
		7: [{"item": "Ferrão da Chapada", "chance": 0.25}]},
	"trophy": {1: "Coração da Mata", 2: "Núcleo de Arenito"},
	"fragment": "Fragmento de Receita",
	"fragment_elite_chance": 0.02,
	"pity": {"raro": 25, "epico": 60},
	"sets": {
		1: {"rarity": "raro", "gold": 120, "base_rarity": "incomum", "piece_gold": 90, "pieces": {"Capacete": "Presa de Javali", "Armadura": "Teia Reforçada", "Luvas": "Espinho Seco", "Botas": "Presa de Javali", "Anel": "Espinho Seco", "Acessório": "Teia Reforçada", "Amuleto": "Espinho Seco"}, "named": {"espada": "Presa de Javali", "machado": "Presa de Javali", "lanca": "Espinho Seco", "arco": "Teia Reforçada", "cajado": "Espinho Seco"}},
		2: {"rarity": "epico", "gold": 240, "base_rarity": "raro", "piece_gold": 180, "pieces": {"Capacete": "Placa de Tatu", "Armadura": "Placa de Tatu", "Luvas": "Pepita Dourada", "Botas": "Ferrão da Chapada", "Anel": "Pepita Dourada", "Acessório": "Ferrão da Chapada", "Amuleto": "Pepita Dourada"}, "named": {"espada": "Pepita Dourada", "machado": "Placa de Tatu", "lanca": "Ferrão da Chapada", "arco": "Ferrão da Chapada", "cajado": "Pepita Dourada"}}}}

const FLOORS := {
	1: {
		"id": 1, "name": "Mata", "title": "Mata · Andar 1", "map_title": "Mapa · Mata · Andar 1", "biome": "mata",
		"world_scene": "res://scenes/world/andar_1.tscn", "world_size": Vector2(1700, 1350),
		"tower_guardian_name": "Guardião da Mata", "return_name": "Mata",
		"features": {"modern_art": true, "village_camp": true, "expanded_world": true, "mining": false, "vale_iron": false},
		"training_spawn": Vector2(900, 440),
		"tower_position": Vector2(830, 1290),
		"seal_note": " · Selo da Mata",
		# Os 6 primeiros pontos são da Mata original; os 16 seguintes, da expansão.
		# O tipo de cada spawn segue o ciclo de Main._spawn_enemy (1 elite a cada 8).
		"enemy_spawn_groups": [
			[Vector2(850, 400), Vector2(930, 440), Vector2(610, 750),
			Vector2(180, 460), Vector2(630, 135), Vector2(955, 665)],
			[Vector2(1350,250),Vector2(1510,260),Vector2(1600,365),Vector2(1335,400),
			Vector2(1360,560),Vector2(1510,590),Vector2(1630,650),Vector2(1530,770),
			Vector2(1370,760),Vector2(630,1015),Vector2(800,1110),Vector2(980,1045),
			Vector2(1090,1190),Vector2(660,1250),Vector2(1000,1260),Vector2(1640,1310)]],
		"enemy_spawn_kinds": [],
		"guardian_altar": Vector2(1060, 155),
		# Acampamentos (modo opt-in "acampamentos"). Todos os pontos vêm dos spawns acima.
		"camps": [
			{"id": "clareira_leste", "name": "Clareira Leste", "ring": "A", "respawn": 60.0, "members": [{"kind": 0, "position": Vector2(850, 400)}, {"kind": 0, "position": Vector2(930, 440)}, {"kind": 1, "position": Vector2(955, 665)}]},
			{"id": "sentinela_oeste", "name": "Sentinela Oeste", "ring": "A", "respawn": 60.0, "members": [{"kind": 2, "position": Vector2(180, 460)}]},
			{"id": "sentinela_norte", "name": "Sentinela Norte", "ring": "A", "respawn": 60.0, "members": [{"kind": 2, "position": Vector2(630, 135)}]},
			{"id": "vila_sul", "name": "Sul da Vila", "ring": "A", "respawn": 60.0, "members": [{"kind": 0, "position": Vector2(610, 750)}]},
			{"id": "nordeste", "name": "Nordeste", "ring": "B", "respawn": 75.0, "members": [{"kind": 1, "position": Vector2(1350, 250)}, {"kind": 1, "position": Vector2(1335, 400)}, {"kind": 0, "position": Vector2(1510, 260)}, {"kind": 2, "position": Vector2(1600, 365)}]},
			{"id": "leste", "name": "Leste", "ring": "B", "respawn": 75.0, "members": [{"kind": 0, "position": Vector2(1360, 560)}, {"kind": 0, "position": Vector2(1510, 590)}, {"kind": 1, "position": Vector2(1530, 770)}, {"kind": 2, "position": Vector2(1370, 760)}]},
			{"id": "sul_oeste", "name": "Sul-oeste", "ring": "B", "respawn": 75.0, "members": [{"kind": 1, "position": Vector2(630, 1015)}, {"kind": 0, "position": Vector2(800, 1110)}, {"kind": 1, "position": Vector2(660, 1250)}]},
			{"id": "sul_leste", "name": "Sul-leste", "ring": "C", "respawn": 90.0, "members": [{"kind": 1, "position": Vector2(1090, 1190)}, {"kind": 3, "position": Vector2(1000, 1260)}]},
			{"id": "toca", "name": "Toca do Elite", "ring": "C", "respawn": 90.0, "members": [{"kind": 3, "position": Vector2(1640, 1310)}]}],
		"field_guardian": {"variant": "root", "minions": [1, 1], "name": "Guardião da Mata", "hp": 320, "speed": 45.0, "radius": 0.0,
			"challenge_label": "Desafiar Guardião (opcional)",
			"notice": "Guardião: evite as áreas douradas. Desafio opcional!"},
		"tower_guardian": {"variant": "mata", "minions": [1, 1], "hp": 360, "speed": 65.0, "radius": 26.0},
		"guardian_spawn_candidates": [Vector2(360, 245), Vector2(200, 300), Vector2(520, 300), Vector2(360, 350)],
		"waves": [[0, 1, 2, 0], [0, 1, 2, 0, 1, 2], [0, 1, 2, 0, 1, 3]]},
	2: {
		"id": 2, "name": "Vale das Pedras", "title": "Vale das Pedras · Andar 2", "map_title": "Mapa · Vale · Andar 2", "biome": "vale",
		"world_scene": "res://scenes/world/andar_2.tscn", "world_size": Vector2(1700, 1350),
		"tower_guardian_name": "Guardião de Arenito", "return_name": "Vale",
		"features": {"modern_art": true, "village_camp": false, "expanded_world": false, "mining": true, "vale_iron": true},
		"training_spawn": Vector2(560, 350),
		"tower_position": Vector2(216, 782),
		"seal_note": "",
		# Camp próprio do Vale; a Mata e os andares sem definição usam o camp padrão de SafeCamp.
		"camp": {"area": Rect2(190, 715, 350, 300), "respawn": Vector2(340, 885),
			"stations": {"Baú": Vector2(282, 940), "Ferreiro": Vector2(285, 855), "Vendedor": Vector2(450, 928)}},
		"enemy_spawn_groups": [[Vector2(750, 700), Vector2(945, 930), Vector2(1040, 690), Vector2(1260, 790), Vector2(1390, 1080), Vector2(490, 350), Vector2(1200, 410), Vector2(900, 1120)]],
		# Goblin na pedreira, tatus nos campos abertos, escorpiões perto das ruínas.
		"enemy_spawn_kinds": [6, 6, 7, 7, 7, 5, 7, 6],
		"guardian_altar": Vector2(1380, 1070),
		"camps": [
			{"id": "campos", "name": "Campos do Cerrado", "ring": "A", "respawn": 75.0, "members": [{"kind": 6, "position": Vector2(750, 700)}, {"kind": 7, "position": Vector2(1040, 690)}, {"kind": 6, "position": Vector2(945, 930)}]},
			{"id": "cerrado_sul", "name": "Cerrado Sul", "ring": "B", "respawn": 75.0, "members": [{"kind": 6, "position": Vector2(900, 1120)}]},
			{"id": "chapada_leste", "name": "Chapada Leste", "ring": "B", "respawn": 75.0, "members": [{"kind": 7, "position": Vector2(1260, 790)}, {"kind": 7, "position": Vector2(1390, 1080)}]},
			{"id": "ruinas", "name": "Ruínas da Chapada", "ring": "C", "respawn": 90.0, "members": [{"kind": 7, "position": Vector2(1200, 410)}]},
			{"id": "pedreira", "name": "Pedreira Dourada", "ring": "A", "respawn": 75.0, "members": [{"kind": 5, "position": Vector2(490, 350)}, {"kind": 5, "position": Vector2(430, 270)}, {"kind": 5, "position": Vector2(570, 370)}]}],
		"field_guardian": {"variant": "colossus", "minions": [5, 5], "name": "Colosso de Arenito", "hp": 540, "speed": 38.0, "radius": 34.0,
			"challenge_label": "Desafiar Colosso",
			"notice": "Colosso de Arenito · evite as áreas avisadas!"},
		"tower_guardian": {"variant": "arenito", "minions": [5, 5], "hp": 520, "speed": 52.0, "radius": 34.0},
		"guardian_spawn_candidates": [Vector2(360, 190), Vector2(200, 260), Vector2(520, 260), Vector2(360, 350)],
		"waves": [[5, 6, 7, 5], [5, 6, 7, 5, 6, 7], [5, 6, 7, 5, 6, 7]]}}

static func has_floor(id: int) -> bool:
	return FLOORS.has(id)

# Andares sem definição (3 a 5) seguem usando os dados do Andar 1, como antes.
static func def_or_default(id: int) -> Dictionary:
	return floor_def(id if FLOORS.has(id) else 1)

static func floor_def(id: int) -> Dictionary:
	return (FLOORS[id] as Dictionary).duplicate(true) if FLOORS.has(id) else {}

static func feature(id: int, name: String) -> bool:
	return FLOORS.has(id) and bool(FLOORS[id].features.get(name, false))

static func valid_scale(id: int) -> bool:
	return SCALE.has(str(id))

static func difficulty(id: int) -> float:
	return float(SCALE[str(id)].difficulty) if SCALE.has(str(id)) else 1.0

static func reward(amount: int, id: int) -> int:
	return roundi(amount * float(SCALE[str(id)].rewards)) if SCALE.has(str(id)) else 0

static func world_scene(id: int, fallback: String) -> String:
	return str(FLOORS[id].world_scene) if FLOORS.has(id) else fallback

static func world_size(id: int, fallback: Vector2) -> Vector2:
	return FLOORS[id].world_size if FLOORS.has(id) else fallback

static func tower_guardian_name(id: int) -> String:
	return str(FLOORS[id].tower_guardian_name) if FLOORS.has(id) else "Guardião da Mata"

static func return_name(id: int) -> String:
	return str(FLOORS[id].return_name) if FLOORS.has(id) else "Mata"

static func heading(id: int) -> String:
	return str(FLOORS[id].title) if FLOORS.has(id) else "Mata · Andar %d" % id

static func map_title(id: int) -> String:
	return str(FLOORS[id].map_title) if FLOORS.has(id) else "Mapa · Mata · Andar %d" % id

static func tower_position(id: int, fallback: Vector2) -> Vector2:
	return FLOORS[id].tower_position if FLOORS.has(id) else fallback

static func seal_note(id: int) -> String:
	return str(FLOORS[id].seal_note) if FLOORS.has(id) else ""

static func camp_area(id: int, fallback: Rect2) -> Rect2:
	return FLOORS[id].camp.area if FLOORS.has(id) and FLOORS[id].has("camp") else fallback

static func camp_respawn(id: int, fallback: Vector2) -> Vector2:
	return FLOORS[id].camp.respawn if FLOORS.has(id) and FLOORS[id].has("camp") else fallback

static func camp_stations(id: int) -> Dictionary:
	return FLOORS[id].camp.stations if FLOORS.has(id) and FLOORS[id].has("camp") else {}

static func camps(id: int) -> Array:
	return FLOORS[id].camps if FLOORS.has(id) and FLOORS[id].has("camps") else []

static func waves(id: int) -> Array:
	return FLOORS[id].waves if FLOORS.has(id) else FLOORS[1].waves

static func enemy_spawns(id: int) -> Array:
	var result: Array = []
	if FLOORS.has(id):
		for group: Array in FLOORS[id].enemy_spawn_groups: result.append_array(group)
	return result

static func enemy_spawn_kinds(id: int) -> Array:
	return FLOORS[id].enemy_spawn_kinds if FLOORS.has(id) else []

# Primeiro monstro com que o andar começa: o tipo do primeiro spawn fixo, ou o 0.
static func first_enemy_kind(id: int) -> int:
	var kinds := enemy_spawn_kinds(id)
	return int(kinds[0]) if not kinds.is_empty() else 0

static func first_enemy_position(id: int) -> Vector2:
	var spawns := enemy_spawns(id)
	return spawns[0] if not spawns.is_empty() else (FLOORS[1].enemy_spawn_groups[0][0] as Vector2)

static func guardian_altar(id: int) -> Vector2:
	return FLOORS[id].guardian_altar if FLOORS.has(id) else FLOORS[1].guardian_altar

static func monster_id_for_kind(kind: int) -> String:
	for id: String in MONSTERS:
		if int(MONSTERS[id].kind) == kind: return id
	return ""

static func monster(id: String) -> Dictionary:
	return (MONSTERS[id] as Dictionary).duplicate(true) if MONSTERS.has(id) else {}

static func xp_for_kind(kind: int) -> int:
	var id := monster_id_for_kind(kind)
	return int(MONSTERS[id].xp) if not id.is_empty() else 0

# Mesma fórmula de Main._apply_floor_stats, aplicada aos valores base do monstro.
static func scaled(id: String, floor_id: int) -> Dictionary:
	var base: Dictionary = MONSTERS[id]
	var multiplier := difficulty(floor_id)
	return {
		"hp": roundi(int(base.hp) * multiplier),
		"contact": roundi(int(base.contact) * multiplier),
		"speed": float(base.speed),
		"damage_scale": multiplier,
		"projectile": roundi(maxi(4, int(base.contact) - 2) * multiplier)}

# Os drops continuam em EquipmentEconomy.DROP_TABLE; aqui só o acesso por tipo.
static func drops(kind: int) -> Array:
	return EquipmentEconomy.DROP_TABLE.get(kind, [])

# Vida efetiva planejada de um chefe nos andares 3–10 (role: "field" ou "tower").
static func planned_boss_hp(id: int, role: String) -> int:
	return int(BOSS_HP[role].get(id, 0))

# Asseclas da fase 3 do chefe (tipos de monstro); vazio se o andar ou o chefe não tem.
static func boss_minions(id: int, role: String) -> Array:
	var def := def_or_default(id)
	var boss: Dictionary = def.field_guardian if role == "field" else def.tower_guardian
	return boss.get("minions", [])
