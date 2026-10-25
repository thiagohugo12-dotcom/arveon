class_name FloorCatalog
extends RefCounted

# Marco 1 · andares em dados. Este catálogo REGISTRA os valores que hoje estão
# espalhados pelo código dos Andares 1 e 2; nada no jogo lê daqui ainda. Os
# testes em tests/floor_catalog_tests.gd comparam cada valor com a fonte atual,
# de modo que o Marco 2 possa trocar as consultas sem alterar o comportamento.
# Valores vindos de outras classes são referenciados, não duplicados.

# Fonte atual: FloorConfig.FLOORS (dificuldade = vida e dano; rewards = XP/ouro).
const SCALE := {
	1: {"difficulty": 1.0, "rewards": 1.0},
	2: {"difficulty": 1.5, "rewards": 1.1},
	3: {"difficulty": 1.4, "rewards": 1.2},
	4: {"difficulty": 1.6, "rewards": 1.3},
	5: {"difficulty": 1.8, "rewards": 1.4}}

# Fonte atual: EnemyActor.display_name, Main._make_enemy e Main._on_enemy_defeated.
# "kind" é o id numérico antigo; continua válido para saves e testes.
const MONSTERS := {
	"javali": {"kind": 0, "name": "Javali", "hp": 48, "speed": 70.0, "contact": 8, "xp": 12},
	"aranha": {"kind": 1, "name": "Aranha", "hp": 36, "speed": 92.0, "contact": 7, "xp": 10},
	"mandacaru": {"kind": 2, "name": "Mandacaru", "hp": 64, "speed": 48.0, "contact": 10, "xp": 16},
	"javali_elite": {"kind": 3, "name": "Javali Elite", "hp": 120, "speed": 60.0, "contact": 12, "xp": 35},
	"criatura_da_mata": {"kind": 4, "name": "Criatura da Mata", "hp": 48, "speed": 70.0, "contact": 8, "xp": 80},
	"goblin_garimpeiro": {"kind": 5, "name": "Goblin Garimpeiro", "hp": 52, "speed": 95.0, "contact": 8, "xp": 10},
	"tatu_rochoso": {"kind": 6, "name": "Tatu Rochoso", "hp": 108, "speed": 54.0, "contact": 11, "xp": 16},
	"escorpiao_da_chapada": {"kind": 7, "name": "Escorpião da Chapada", "hp": 72, "speed": 105.0, "contact": 13, "xp": 20}}
# Fonte atual: loot_rng.randi_range(2, 5) em Main._on_enemy_defeated.
const GOLD_RANGE := Vector2i(2, 5)

const FLOORS := {
	1: {
		"id": 1, "name": "Mata", "title": "Mata · Andar 1", "biome": "mata",
		"world_scene": "res://scenes/world/andar_1.tscn", "world_size": Vector2(1700, 1350),
		"tower_guardian_name": "Guardião da Mata", "return_name": "Mata",
		# Fonte atual: Main.ENEMY_POSITIONS + Main.ANDAR1_ENEMY_POSITIONS. O tipo de cada
		# spawn segue a regra "cycle" de Main._spawn_enemy (1 elite a cada 8 spawns).
		"spawn_rule": "cycle",
		"enemy_spawns": [
			Vector2(850, 400), Vector2(930, 440), Vector2(610, 750),
			Vector2(180, 460), Vector2(630, 135), Vector2(955, 665),
			Vector2(1350,250), Vector2(1510,260), Vector2(1600,365), Vector2(1335,400),
			Vector2(1360,560), Vector2(1510,590), Vector2(1630,650), Vector2(1530,770),
			Vector2(1370,760), Vector2(630,1015), Vector2(800,1110), Vector2(980,1045),
			Vector2(1090,1190), Vector2(660,1250), Vector2(1000,1260), Vector2(1640,1310)],
		"enemy_spawn_kinds": [],
		"guardian_altar": Vector2(1060, 155),
		# Fonte atual: Main._start_guardian (chefe opcional de campo).
		"field_guardian": {"name": "Guardião da Mata", "hp": 320, "speed": 45.0, "radius": 0.0},
		# Fonte atual: Main._spawn_tower_guardian e TowerGuardian.MAX_HP.
		"tower_guardian": {"hp": 360, "speed": 65.0, "radius": 26.0},
		# Fonte atual: TowerTrial.WAVES.
		"waves": [[0, 1, 2, 0], [0, 1, 2, 0, 1, 2], [0, 1, 2, 0, 1, 3]]},
	2: {
		"id": 2, "name": "Vale das Pedras", "title": "Vale das Pedras · Andar 2", "biome": "vale",
		"world_scene": "res://scenes/world/andar_2.tscn", "world_size": Vector2(1700, 1350),
		"tower_guardian_name": "Guardião de Arenito", "return_name": "Vale",
		# Fonte atual: Floor2Layout.ENEMY_SPAWNS e ENEMY_SPAWN_KINDS.
		"spawn_rule": "fixed",
		"enemy_spawns": [Vector2(750, 700), Vector2(945, 930), Vector2(1040, 690), Vector2(1260, 790), Vector2(1390, 1080), Vector2(490, 350), Vector2(1200, 410), Vector2(900, 1120)],
		"enemy_spawn_kinds": [6, 6, 7, 7, 7, 5, 7, 6],
		"guardian_altar": Vector2(1380, 1070),
		"field_guardian": {"name": "Colosso de Arenito", "hp": 540, "speed": 38.0, "radius": 34.0},
		"tower_guardian": {"hp": 520, "speed": 52.0, "radius": 34.0},
		# Fonte atual: TowerTrial.VALE_WAVES.
		"waves": [[5, 6, 7, 5], [5, 6, 7, 5, 6, 7], [5, 6, 7, 5, 6, 7]]}}

static func has_floor(id: int) -> bool:
	return FLOORS.has(id)

static func floor_def(id: int) -> Dictionary:
	return (FLOORS[id] as Dictionary).duplicate(true) if FLOORS.has(id) else {}

static func difficulty(id: int) -> float:
	return float(SCALE[id].difficulty) if SCALE.has(id) else 1.0

static func reward(amount: int, id: int) -> int:
	return roundi(amount * float(SCALE[id].rewards)) if SCALE.has(id) else 0

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
