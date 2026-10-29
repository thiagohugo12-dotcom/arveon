class_name Floor3Layout
extends RefCounted

# Andar 3 — Pântano das Vozes. A composição segue o mapa oficial aprovado
# (art_source/andar3/00_MAPA_APROVADO_PANTANO_DAS_VOZES.png) na escala 1,5x:
# um ponto (x, y) do mapa fica em (1,5x, 1,5y) no mundo. Terra, trilhas e água vêm
# da máscara derivada desse mapa (tools/build_andar3_terrain.gd); pontes, ruínas,
# acampamento e santuários foram posicionados lendo o mapa. A vegetação é distribuída
# de forma determinística nas áreas de mata, longe das trilhas, como no mapa.
const MASK := preload("res://assets/art/andar3/derived/pantano_mask.png")
const MASK_SOFT := preload("res://assets/art/andar3/derived/pantano_mask_soft.png")
const CELL := 6.0
const WORLD_SIZE := Vector2(2172, 1626)
const RESPAWN := Vector2(375, 1200)
const CAMP_AREA := Rect2(60, 1060, 520, 380)
const TOWER_POSITION := Vector2(228, 1030)
const STATIONS := {"Baú": Vector2(150, 1290), "Ferreiro": Vector2(300, 1150), "Vendedor": Vector2(470, 1210)}

# Ordem de consulta: a primeira região que contém o ponto vence; o resto é Lodaçal.
const REGIONS := [
	{"id": "pantano_entrada", "name": "Entrada Encharcada", "bounds": Rect2(0, 1000, 660, 626), "center": Vector2(330, 1230)},
	{"id": "pantano_lodacal", "name": "Lodaçal Nebuloso", "bounds": Rect2(660, 560, 1512, 1066), "center": Vector2(1180, 930)},
	{"id": "pantano_bosque", "name": "Bosque Afundado", "bounds": Rect2(0, 0, 1000, 1000), "center": Vector2(420, 400)},
	{"id": "pantano_coracao", "name": "Coração do Brejo", "bounds": Rect2(1450, 0, 722, 560), "center": Vector2(1850, 300)}]

# Mini-chefe e Guardião: arenas abertas de combate.
const CAIMAN_HOME := Vector2(420, 360)
const CAIMAN_ARENA := Rect2(250, 230, 360, 260)
const GUARDIAN_ALTAR := Vector2(1858, 262)
const GUARDIAN_ARENA := Rect2(1705, 150, 310, 230)
const SHRINE_FLOOR := Rect2(1732, 184, 252, 156)
const CENTRAL_SHRINE := Vector2(1263, 866)

# Pontes lidas do mapa: centro no mundo e direção de travessia ("v" norte-sul,
# "h" leste-oeste). O vão real é medido na máscara (bridge_spans).
const BRIDGES := [
	{"center": Vector2(638, 285), "axis": "h"}, {"center": Vector2(932, 284), "axis": "h"},
	{"center": Vector2(1082, 444), "axis": "v"}, {"center": Vector2(471, 531), "axis": "h"},
	{"center": Vector2(531, 713), "axis": "v"}, {"center": Vector2(948, 719), "axis": "v"},
	{"center": Vector2(434, 915), "axis": "v"}, {"center": Vector2(804, 1128), "axis": "h"},
	{"center": Vector2(734, 1343), "axis": "v"},
	{"center": Vector2(1466, 542), "axis": "v"}, {"center": Vector2(1263, 644), "axis": "h"},
	{"center": Vector2(1836, 396), "axis": "v"}, {"center": Vector2(1895, 644), "axis": "v"},
	{"center": Vector2(1589, 767), "axis": "h"}, {"center": Vector2(1445, 1140), "axis": "h"},
	{"center": Vector2(1182, 1284), "axis": "v"}, {"center": Vector2(1724, 990), "axis": "v"},
	{"center": Vector2(1905, 1380), "axis": "h"}]

# Estruturas fixas: peça, pés no mundo e sólido (raio do círculo ou meia-largura de caixa).
const STRUCTURES := [
	# Bosque Afundado (noroeste): portal antigo iluminado, arcos e pilares.
	{"art": "arco_grande", "feet": Vector2(192, 203), "solid": {"legs": 46}},
	{"art": "lanterna_b", "feet": Vector2(150, 205), "solid": {"radius": 8}},
	{"art": "lanterna_b", "feet": Vector2(300, 228), "solid": {"radius": 8}},
	{"art": "pilar_lua_a", "feet": Vector2(258, 212), "solid": {"radius": 12}},
	{"art": "pilar_b", "feet": Vector2(304, 214), "solid": {"radius": 16}},
	{"art": "arco_quebrado", "feet": Vector2(243, 458), "solid": {"legs": 22}},
	{"art": "lanterna_a", "feet": Vector2(306, 452), "solid": {"radius": 8}},
	{"art": "pedras_a", "feet": Vector2(405, 268), "solid": {"radius": 14}},
	{"art": "pilar_a", "feet": Vector2(621, 118), "solid": {"radius": 12}},
	{"art": "pilar_c", "feet": Vector2(740, 209), "solid": {"radius": 12}},
	{"art": "arco_baixo", "feet": Vector2(896, 578), "solid": {"legs": 28}},
	{"art": "muro_e", "feet": Vector2(1046, 600), "solid": {"box": Vector2(22, 8)}},
	{"art": "pedras_c", "feet": Vector2(606, 526), "solid": {"radius": 12}},
	{"art": "pilar_d", "feet": Vector2(780, 698), "solid": {"radius": 12}},
	{"art": "pilar_f", "feet": Vector2(818, 690), "solid": {"radius": 12}},
	{"art": "pilar_a", "feet": Vector2(150, 771), "solid": {"radius": 12}},
	{"art": "pilar_c", "feet": Vector2(338, 750), "solid": {"radius": 12}},
	{"art": "pilar_e", "feet": Vector2(393, 750), "solid": {"radius": 12}},
	{"art": "placa_madeira", "feet": Vector2(954, 579), "solid": {"radius": 6}},
	{"art": "tronco_caido", "feet": Vector2(788, 840), "solid": {"box": Vector2(30, 8)}},
	# Lodaçal Nebuloso (centro): árvore seca, santuário central, ruínas e poças.
	{"art": "arvore_seca", "feet": Vector2(1103, 1052), "solid": {"radius": 20}},
	{"art": "circulo_lunar", "feet": Vector2(1263, 900), "ground": true},
	{"art": "arco_baixo", "feet": Vector2(1230, 815), "solid": {"legs": 28}},
	{"art": "braseiro_a", "feet": Vector2(1186, 852), "solid": {"radius": 12}},
	{"art": "braseiro_a", "feet": Vector2(1340, 893), "solid": {"radius": 12}},
	{"art": "pilar_c", "feet": Vector2(1372, 860), "solid": {"radius": 12}},
	{"art": "poca_lama", "feet": Vector2(960, 950), "ground": true},
	{"art": "pilar_b", "feet": Vector2(675, 1028), "solid": {"radius": 14}},
	{"art": "pilar_e", "feet": Vector2(750, 1028), "solid": {"radius": 12}},
	{"art": "pedras_b", "feet": Vector2(594, 1052), "solid": {"radius": 14}},
	{"art": "arco_baixo", "feet": Vector2(996, 1390), "solid": {"legs": 28}},
	{"art": "pilar_c", "feet": Vector2(819, 1530), "solid": {"radius": 12}},
	{"art": "arco_quebrado", "feet": Vector2(1568, 1113), "solid": {"legs": 22}},
	{"art": "pilar_d", "feet": Vector2(1857, 1220), "solid": {"radius": 12}},
	{"art": "pedras_c", "feet": Vector2(1766, 1156), "solid": {"radius": 12}},
	{"art": "arco_grande", "feet": Vector2(2034, 1209), "solid": {"legs": 46}},
	{"art": "pilar_e", "feet": Vector2(1520, 1455), "solid": {"radius": 12}},
	{"art": "pilar_f", "feet": Vector2(2018, 1445), "solid": {"radius": 12}},
	{"art": "pedras_c", "feet": Vector2(1118, 1446), "solid": {"radius": 12}},
	{"art": "pedras_d", "feet": Vector2(1307, 1478), "solid": {"radius": 10}},
	{"art": "tronco_oco", "feet": Vector2(1610, 645), "solid": {"box": Vector2(28, 8)}},
	# Coração do Brejo (nordeste): ruínas e santuário lunar do Guardião.
	{"art": "pilar_b", "feet": Vector2(1448, 117), "solid": {"radius": 14}},
	{"art": "arco_grande", "feet": Vector2(1448, 322), "solid": {"legs": 46}},
	{"art": "pilar_c", "feet": Vector2(1295, 344), "solid": {"radius": 12}},
	{"art": "pilar_e", "feet": Vector2(1403, 472), "solid": {"radius": 12}},
	{"art": "pedras_b", "feet": Vector2(1163, 212), "solid": {"radius": 14}},
	{"art": "pilar_d", "feet": Vector2(1623, 418), "solid": {"radius": 12}},
	{"art": "arco_grande", "feet": Vector2(2085, 536), "solid": {"legs": 46}},
	{"art": "arco_quebrado", "feet": Vector2(2066, 700), "solid": {"legs": 22}},
	{"art": "arco_grande", "feet": Vector2(1862, 150), "solid": {"legs": 46}},
	{"art": "braseiro_b", "feet": Vector2(1752, 176), "solid": {"radius": 12}},
	{"art": "braseiro_b", "feet": Vector2(1968, 176), "solid": {"radius": 12}},
	{"art": "braseiro_c", "feet": Vector2(1740, 330), "solid": {"radius": 12}},
	{"art": "braseiro_c", "feet": Vector2(1975, 330), "solid": {"radius": 12}},
	{"art": "pilar_lua_santuario", "feet": Vector2(1700, 238), "solid": {"radius": 12}},
	{"art": "pilar_lua_c", "feet": Vector2(2020, 244), "solid": {"radius": 12}},
	{"art": "pilar_santuario_a", "feet": Vector2(1640, 170), "solid": {"radius": 14}},
	{"art": "pilar_santuario_c", "feet": Vector2(2060, 160), "solid": {"radius": 12}},
	{"art": "ruina_santuario", "feet": Vector2(1620, 300), "solid": {"radius": 16}},
	{"art": "ruina_santuario_b", "feet": Vector2(2080, 330), "solid": {"radius": 20}},
	{"art": "pilar_santuario_b", "feet": Vector2(1700, 70), "solid": {"radius": 10}},
	{"art": "pilar_lua_b", "feet": Vector2(2000, 70), "solid": {"radius": 12}},
	# Entrada Encharcada (sudoeste): acampamento seguro.
	{"art": "barraca", "feet": Vector2(165, 1232), "solid": {"box": Vector2(64, 10)}},
	{"art": "fogueira", "feet": Vector2(273, 1268), "solid": {"radius": 18}},
	{"art": "tronco_oco_b", "feet": Vector2(200, 1316), "solid": {"box": Vector2(20, 6)}},
	{"art": "tronco_oco_b", "feet": Vector2(345, 1316), "solid": {"box": Vector2(20, 6)}},
	{"art": "lanterna_a", "feet": Vector2(402, 1078), "solid": {"radius": 8}},
	{"art": "lanterna_b", "feet": Vector2(494, 1150), "solid": {"radius": 8}},
	{"art": "lanterna_a", "feet": Vector2(369, 1368), "solid": {"radius": 8}},
	{"art": "lanterna_b", "feet": Vector2(108, 1370), "solid": {"radius": 8}},
	{"art": "estandarte", "feet": Vector2(540, 1268), "solid": {"radius": 8}},
	{"art": "barril", "feet": Vector2(82, 1240), "solid": {"radius": 9}},
	{"art": "placa_dupla", "feet": Vector2(560, 1080), "solid": {"radius": 6}}]


# Descobertas de região (exploração).
const REGION_MARKERS := [
	{"id": "pantano_poi_entrada", "name": "Entrada Encharcada", "position": Vector2(330, 1230)},
	{"id": "pantano_poi_lodacal", "name": "Lodaçal Nebuloso", "position": Vector2(1180, 930)},
	{"id": "pantano_poi_bosque", "name": "Bosque Afundado", "position": Vector2(420, 400)},
	{"id": "pantano_poi_coracao", "name": "Coração do Brejo", "position": Vector2(1850, 300)}]

static var _grid := PackedByteArray()
static var _walk := PackedByteArray()
static var _size := Vector2i.ZERO
static var _spans: Array = []
static var _decor: Dictionary = {}

# _grid: 0 água, 1 terra, 2 trilha. _walk: igual, com 3 = tabuleiro de ponte.
static func _load() -> void:
	if not _grid.is_empty(): return
	var image := MASK.get_image()
	if image.is_compressed(): image.decompress()
	_size = image.get_size()
	_grid.resize(_size.x * _size.y)
	for y in range(_size.y):
		for x in range(_size.x):
			var c := image.get_pixel(x, y)
			_grid[y * _size.x + x] = 0 if c.r < 0.5 else (2 if c.g >= 0.5 else 1)
	_spans = []
	for bridge: Dictionary in BRIDGES:
		var span := _measure_bridge(bridge)
		if not span.is_empty(): _spans.append(span)
	_walk = _grid.duplicate()
	for span: Dictionary in _spans:
		var rect: Rect2 = span.rect
		for y in range(floori(rect.position.y / CELL), ceili(rect.end.y / CELL)):
			for x in range(floori(rect.position.x / CELL), ceili(rect.end.x / CELL)):
				if x >= 0 and y >= 0 and x < _size.x and y < _size.y and _walk[y * _size.x + x] == 0: _walk[y * _size.x + x] = 3

static var _minimap: ImageTexture

# Miniatura do pântano para o minimapa e o Mapa: água, terra, trilhas e pontes.
static func minimap_texture() -> ImageTexture:
	_load()
	if _minimap == null:
		var image := Image.create(_size.x, _size.y, false, Image.FORMAT_RGBA8)
		var colors := [Color("#1f5c5a"), Color("#4f7f3c"), Color("#c4a46a"), Color("#8a5a32")]
		for y in range(_size.y):
			for x in range(_size.x): image.set_pixel(x, y, colors[_walk[y * _size.x + x]])
		_minimap = ImageTexture.create_from_image(image)
	return _minimap

static func grid_size() -> Vector2i:
	_load()
	return _size

static func cell_of(point: Vector2) -> Vector2i:
	return Vector2i(clampi(floori(point.x / CELL), 0, _size.x - 1), clampi(floori(point.y / CELL), 0, _size.y - 1))

static func kind_at(point: Vector2) -> int:
	_load()
	var cell := cell_of(point)
	return _grid[cell.y * _size.x + cell.x]

static func is_land(point: Vector2) -> bool:
	return kind_at(point) != 0

static func is_path(point: Vector2) -> bool:
	return kind_at(point) == 2

# Transitável: terra, trilha ou tabuleiro de ponte.
static func walkable(point: Vector2) -> bool:
	_load()
	if point.x < 0 or point.y < 0 or point.x >= WORLD_SIZE.x or point.y >= WORLD_SIZE.y: return false
	var cell := cell_of(point)
	return _walk[cell.y * _size.x + cell.x] != 0

static func walk_grid() -> PackedByteArray:
	_load()
	return _walk

static func region_at(point: Vector2) -> Dictionary:
	for index in [3, 2, 0]:
		if (REGIONS[index].bounds as Rect2).has_point(point): return REGIONS[index]
	return REGIONS[1]

static func bridge_spans() -> Array:
	_load()
	return _spans

# Mede o vão de água sob a ponte: da última terra antes até a primeira terra depois,
# com 14 px de apoio em cada margem. A largura do tabuleiro é fixa e confortável.
static func _measure_bridge(bridge: Dictionary) -> Dictionary:
	var axis := Vector2(0, 1) if bridge.axis == "v" else Vector2(1, 0)
	var center: Vector2 = bridge.center
	# Se o centro anotado caiu em terra, procura a água mais próxima no eixo.
	if _grid_at(center) != 0:
		var found := false
		for step in range(1, 30):
			for sign in [-1.0, 1.0]:
				var probe: Vector2 = center + axis * sign * step * 3.0
				if _grid_at(probe) == 0:
					center = probe
					found = true
					break
			if found: break
	var back := 0.0
	while back < 260.0 and _grid_at(center - axis * back) == 0: back += 3.0
	var ahead := 0.0
	while ahead < 260.0 and _grid_at(center + axis * ahead) == 0: ahead += 3.0
	# Sem água de verdade no eixo: a travessia já é terra firme e a ponte sobra.
	if back + ahead < 12.0: return {}
	# Vão maior que uma ponte do mapa: a anotação caiu em água aberta, sem margem oposta.
	if back + ahead > 170.0: return {}
	var start := center - axis * (back + 14.0)
	var end := center + axis * (ahead + 14.0)
	var width := 66.0
	var cross := Vector2(axis.y, axis.x) * width * 0.5
	var rect := Rect2(start - cross, Vector2.ZERO).expand(end + cross)
	return {"axis": bridge.axis, "rect": rect, "length": back + ahead + 28.0, "center": (start + end) * 0.5}

static func _grid_at(point: Vector2) -> int:
	if point.x < 0 or point.y < 0 or point.x >= WORLD_SIZE.x or point.y >= WORLD_SIZE.y: return 1
	var cell := cell_of(point)
	return _grid[cell.y * _size.x + cell.x]

# Retângulos de água (não transitável) agrupados por linhas iguais, para a colisão.
static func water_rects() -> Array:
	_load()
	var rects: Array = []
	var open := {}
	for y in range(_size.y + 1):
		var runs := {}
		if y < _size.y:
			var x := 0
			while x < _size.x:
				if _walk[y * _size.x + x] != 0:
					x += 1
					continue
				var start := x
				while x < _size.x and _walk[y * _size.x + x] == 0: x += 1
				runs[Vector2i(start, x)] = true
		var next := {}
		for run: Vector2i in runs:
			next[run] = open[run] if open.has(run) else y
		for run: Vector2i in open:
			if not runs.has(run):
				var top: int = open[run]
				rects.append(Rect2(run.x * CELL, top * CELL, (run.y - run.x) * CELL, (y - top) * CELL))
		open = next
	return rects

# Distância (em células) até as células de origem, por varredura em largura.
static func _distance(sources: Callable) -> PackedInt32Array:
	var distance := PackedInt32Array()
	distance.resize(_size.x * _size.y)
	distance.fill(9999)
	var queue := PackedInt32Array()
	for i in range(_size.x * _size.y):
		if sources.call(i):
			distance[i] = 0
			queue.append(i)
	var head := 0
	while head < queue.size():
		var current: int = queue[head]
		head += 1
		var cx := current % _size.x
		var cy := current / _size.x
		for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx := cx + offset.x
			var ny := cy + offset.y
			if nx < 0 or ny < 0 or nx >= _size.x or ny >= _size.y: continue
			var next := ny * _size.x + nx
			if distance[next] > distance[current] + 1:
				distance[next] = distance[current] + 1
				queue.append(next)
	return distance

static func _hash(x: int, y: int, salt: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)) % 10000

static func _reserved(point: Vector2, margin: float) -> bool:
	if CAMP_AREA.grow(margin).has_point(point) or SHRINE_FLOOR.grow(margin).has_point(point): return true
	if CAIMAN_ARENA.grow(margin * 0.5).has_point(point) or point.distance_to(CENTRAL_SHRINE) < 120.0 + margin: return true
	if point.distance_to(TOWER_POSITION) < 110.0 + margin or point.distance_to(RESPAWN) < 90.0: return true
	for structure: Dictionary in STRUCTURES:
		if point.distance_to(structure.feet) < 46.0 + margin * 0.3: return true
	for spawn_at: Vector2 in FloorCatalog.enemy_spawns(3):
		if point.distance_to(spawn_at) < 64.0 + margin * 0.3: return true
	for span: Dictionary in _spans:
		if (span.rect as Rect2).grow(28.0 + margin * 0.3).has_point(point): return true
	return false

# Vegetação determinística: árvores na mata (longe das trilhas), arbustos nas bordas,
# juncos nas margens e lírios na água aberta. Mesma máscara = mesmo pântano.
static func decor() -> Dictionary:
	_load()
	if not _decor.is_empty(): return _decor
	var path_distance := _distance(func(i: int) -> bool: return _grid[i] == 2)
	var water_distance := _distance(func(i: int) -> bool: return _walk[i] == 0)
	var land_distance := _distance(func(i: int) -> bool: return _grid[i] != 0)
	var trees: Array = []
	var bushes: Array = []
	var reeds: Array = []
	var lilies: Array = []
	# Varredura em blocos de 4x4 células com um candidato sorteado por bloco.
	for by in range(0, _size.y, 4):
		for bx in range(0, _size.x, 4):
			var x := mini(_size.x - 1, bx + _hash(bx, by, 1) % 4)
			var y := mini(_size.y - 1, by + _hash(bx, by, 2) % 4)
			var i := y * _size.x + x
			var at := Vector2((x + 0.5) * CELL, (y + 0.5) * CELL)
			if _grid[i] != 0 and _walk[i] != 3:
				# Mata densa nas bordas do mundo e nos miolos longe das trilhas, como no mapa;
				# as ilhas centrais ficam abertas para explorar e combater.
				var border := mini(mini(x, y), mini(_size.x - 1 - x, _size.y - 1 - y))
				if path_distance[i] >= 12 and water_distance[i] >= 2 and (border <= 22 or path_distance[i] >= 22) and not _reserved(at, 40.0):
					if _far(trees, at, 80.0): trees.append(at)
				elif path_distance[i] >= 3 and path_distance[i] <= 8 and water_distance[i] >= 2 and _hash(x, y, 3) < 4200 and not _reserved(at, 10.0):
					if _far(bushes, at, 96.0) and _far(trees, at, 46.0): bushes.append(at)
			elif _walk[i] == 0:
				if land_distance[i] <= 2 and _hash(x, y, 5) < 3000 and not _reserved(at, 0.0):
					if _far(reeds, at, 84.0): reeds.append(at)
				elif land_distance[i] >= 4 and _hash(x, y, 9) < 1800:
					if _far(lilies, at, 120.0) and _far(reeds, at, 50.0): lilies.append(at)
	_decor = {"trees": trees, "bushes": bushes, "reeds": reeds, "lilies": lilies}
	return _decor

static func _far(list: Array, at: Vector2, spacing: float) -> bool:
	for other: Vector2 in list:
		if absf(other.x - at.x) < spacing and absf(other.y - at.y) < spacing and other.distance_squared_to(at) < spacing * spacing: return false
	return true
