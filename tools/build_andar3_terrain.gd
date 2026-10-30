extends SceneTree

# Gera a máscara de terreno do Andar 3 a partir do mapa oficial aprovado
# (art_source/andar3/00_MAPA_APROVADO_PANTANO_DAS_VOZES.png). O mapa NÃO é usado
# como imagem de fundo: só suas regiões são lidas (água, trilha, terra, mata densa)
# para que o cenário seja montado em camadas com as texturas e peças aprovadas.
# Saída: assets/art/andar3/derived/pantano_mask.png, uma célula por CELL pixels do mapa:
#   R = terra firme, G = trilha, A = 255; água = R zero. pantano_mask_soft.png traz
#   as mesmas camadas suavizadas, só para o desenho das bordas.
#   Água = nenhum canal. Uso: godot --headless --path . -s res://tools/build_andar3_terrain.gd
const SOURCE := "res://art_source/andar3/00_MAPA_APROVADO_PANTANO_DAS_VOZES.png"
const OUTPUT := "res://assets/art/andar3/derived/pantano_mask.png"
const SOFT_OUTPUT := "res://assets/art/andar3/derived/pantano_mask_soft.png"
const CELL := 4
enum Kind { WATER, LAND, PATH, FOREST, BRIDGE }

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var map := Image.load_from_file(SOURCE)
	map.convert(Image.FORMAT_RGBA8)
	var w := map.get_width() / CELL
	var h := map.get_height() / CELL
	var grid := PackedByteArray()
	grid.resize(w * h)
	for gy in range(h):
		for gx in range(w):
			var votes := [0, 0, 0, 0, 0]
			for y in range(gy * CELL, gy * CELL + CELL):
				for x in range(gx * CELL, gx * CELL + CELL):
					votes[_classify(map.get_pixel(x, y))] += 1
			grid[gy * w + gx] = _argmax(votes)
	# Terra x água: maioria binária (remove folhas, lírios e reflexos), depois ilhas
	# minúsculas (lírios, pilares na água) voltam a ser água e poças minúsculas, terra.
	# A madeira das pontes do mapa conta como água: a ponte é uma peça própria por cima.
	var near_water := PackedByteArray()
	near_water.resize(w * h)
	for i in range(w * h): near_water[i] = 1 if grid[i] == Kind.WATER else 0
	for _step in range(9): near_water = _dilate(near_water, w, h)
	var land := PackedByteArray()
	land.resize(w * h)
	for i in range(w * h): land[i] = 0 if grid[i] == Kind.WATER or (grid[i] == Kind.BRIDGE and near_water[i] == 1) else 1
	for _pass in range(2): land = _majority(land, w, h)
	land = _drop_small_bin(land, w, h, 1, 60, 0)
	land = _drop_small_bin(land, w, h, 0, 90, 1)
	# Trilhas: fechamento (dilata e erode) para não quebrar nas flores e tufos.
	var path := PackedByteArray()
	path.resize(w * h)
	for i in range(w * h): path[i] = 1 if grid[i] == Kind.PATH else 0
	path = _erode(_dilate(_dilate(path, w, h), w, h), w, h)
	path = _erode(path, w, h)
	path = _dilate(path, w, h)
	for i in range(w * h): path[i] = path[i] * land[i]
	path = _drop_small_bin(path, w, h, 1, 30, 0)
	for i in range(w * h): grid[i] = Kind.WATER if land[i] == 0 else (Kind.PATH if path[i] == 1 else Kind.LAND)
	var mask := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var k := grid[y * w + x]
			mask.set_pixel(x, y, Color(1.0 if k != Kind.WATER else 0.0, 1.0 if k == Kind.PATH else 0.0, 1.0 if k == Kind.FOREST else 0.0, 1.0))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/art/andar3/derived"))
	mask.save_png(OUTPUT)
	# Versão suavizada (só visual): contornos orgânicos em vez de degraus de célula.
	var soft_land := _blur(_blur(_to_float(land), w, h), w, h)
	var soft_path := _blur(_blur(_to_float(path), w, h), w, h)
	var soft := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w): soft.set_pixel(x, y, Color(soft_land[y * w + x], soft_path[y * w + x], 0.0, 1.0))
	soft.save_png(SOFT_OUTPUT)
	var preview := OS.get_environment("PREVIEW")
	if not preview.is_empty():
		var colors := [Color("#1b5a5a"), Color("#6f9b3a"), Color("#d2aa62"), Color("#1d3b22")]
		var view := Image.create(w, h, false, Image.FORMAT_RGBA8)
		for y in range(h):
			for x in range(w): view.set_pixel(x, y, colors[grid[y * w + x]])
		view.resize(w * 2, h * 2, Image.INTERPOLATE_NEAREST)
		view.save_png(preview)
	print("MASK %dx%d" % [w, h])
	quit(0)

func _to_float(grid: PackedByteArray) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(grid.size())
	for i in range(grid.size()): out[i] = float(grid[i])
	return out

func _blur(values: PackedFloat32Array, w: int, h: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(values.size())
	for y in range(h):
		for x in range(w):
			var sum := 0.0
			for dy in range(-1, 2):
				for dx in range(-1, 2): sum += values[clampi(y + dy, 0, h - 1) * w + clampi(x + dx, 0, w - 1)]
			out[y * w + x] = sum / 9.0
	return out

func _classify(c: Color) -> int:
	var hue := c.h
	if c.s > 0.55 and hue > 0.40 and hue < 0.58 and c.v < 0.62: return Kind.WATER
	if hue > 0.02 and hue < 0.09 and c.s > 0.5 and c.v > 0.3 and c.v < 0.68: return Kind.BRIDGE
	if hue > 0.07 and hue < 0.15 and c.s > 0.38 and c.v > 0.58: return Kind.PATH
	if c.v < 0.34 and (hue > 0.17 and hue < 0.48) and c.s > 0.3: return Kind.FOREST
	return Kind.LAND

func _argmax(votes: Array) -> int:
	var best := 0
	for i in range(1, votes.size()):
		if votes[i] > votes[best]: best = i
	return best

func _majority(grid: PackedByteArray, w: int, h: int) -> PackedByteArray:
	var out := grid.duplicate()
	for y in range(h):
		for x in range(w):
			var count := 0
			for dy in range(-1, 2):
				for dx in range(-1, 2): count += grid[clampi(y + dy, 0, h - 1) * w + clampi(x + dx, 0, w - 1)]
			out[y * w + x] = 1 if count >= 5 else 0
	return out

func _dilate(grid: PackedByteArray, w: int, h: int) -> PackedByteArray:
	var out := grid.duplicate()
	for y in range(h):
		for x in range(w):
			if grid[y * w + x] == 1: continue
			for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if grid[clampi(y + offset.y, 0, h - 1) * w + clampi(x + offset.x, 0, w - 1)] == 1:
					out[y * w + x] = 1
					break
	return out

func _erode(grid: PackedByteArray, w: int, h: int) -> PackedByteArray:
	var out := grid.duplicate()
	for y in range(h):
		for x in range(w):
			if grid[y * w + x] == 0: continue
			for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if grid[clampi(y + offset.y, 0, h - 1) * w + clampi(x + offset.x, 0, w - 1)] == 0:
					out[y * w + x] = 0
					break
	return out

func _drop_small_bin(grid: PackedByteArray, w: int, h: int, value: int, limit: int, fill: int) -> PackedByteArray:
	var seen := PackedByteArray()
	seen.resize(w * h)
	for start in range(w * h):
		if grid[start] != value or seen[start] == 1: continue
		var cells: Array = [start]
		seen[start] = 1
		var head := 0
		while head < cells.size():
			var current: int = cells[head]
			head += 1
			for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := current % w + offset.x
				var ny := current / w + offset.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h: continue
				var next := ny * w + nx
				if grid[next] == value and seen[next] == 0:
					seen[next] = 1
					cells.append(next)
		if cells.size() < limit:
			for cell: int in cells: grid[cell] = fill
	return grid

func _mode_filter(grid: PackedByteArray, w: int, h: int, radius: int) -> PackedByteArray:
	var out := grid.duplicate()
	for y in range(h):
		for x in range(w):
			var votes := [0, 0, 0, 0, 0]
			for dy in range(-radius, radius + 1):
				for dx in range(-radius, radius + 1):
					var nx := clampi(x + dx, 0, w - 1)
					var ny := clampi(y + dy, 0, h - 1)
					votes[grid[ny * w + nx]] += 1
			out[y * w + x] = _argmax(votes)
	return out

# Componentes do tipo `kind` menores que `limit` células viram `fill`.
func _drop_small(grid: PackedByteArray, w: int, h: int, kind: int, limit: int, fill: int) -> PackedByteArray:
	var seen := PackedByteArray()
	seen.resize(w * h)
	for start in range(w * h):
		if grid[start] != kind or seen[start] == 1: continue
		var cells: Array = [start]
		seen[start] = 1
		var head := 0
		while head < cells.size():
			var current: int = cells[head]
			head += 1
			for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := current % w + offset.x
				var ny := current / w + offset.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h: continue
				var next := ny * w + nx
				if grid[next] == kind and seen[next] == 0:
					seen[next] = 1
					cells.append(next)
		if cells.size() < limit:
			for cell: int in cells: grid[cell] = fill
	return grid

# Terra (qualquer tipo que não seja água) em grupos pequenos vira água.
func _drop_small_land(grid: PackedByteArray, w: int, h: int, limit: int) -> PackedByteArray:
	var seen := PackedByteArray()
	seen.resize(w * h)
	for start in range(w * h):
		if grid[start] == Kind.WATER or seen[start] == 1: continue
		var cells: Array = [start]
		seen[start] = 1
		var head := 0
		while head < cells.size():
			var current: int = cells[head]
			head += 1
			for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := current % w + offset.x
				var ny := current / w + offset.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h: continue
				var next := ny * w + nx
				if grid[next] != Kind.WATER and seen[next] == 0:
					seen[next] = 1
					cells.append(next)
		if cells.size() < limit:
			for cell: int in cells: grid[cell] = Kind.WATER
	return grid
