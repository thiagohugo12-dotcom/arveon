extends SceneTree

# Gera as folhas do Protagonista 2.0 (aprovado) a partir do pacote original em
# art_source/protagonista_2_0, que nunca é alterado.
#  - 04_ANIMACOES_NORMAIS/idle_4_direcoes_4_quadros.png    → idle.png (4 × Frente/Costas/Esquerda/Direita)
#  - 04_ANIMACOES_NORMAIS/corrida_4_direcoes_6_quadros.png → corrida.png (6 × as mesmas direções)
#  - 02_ESPADA_ANIMACOES_ORIGINAIS/ataque_basico_6_quadros.png    → espada_basico.png (Direita)
#  - 02_ESPADA_ANIMACOES_ORIGINAIS/estocada_precisa_6_quadros.png → espada_estocada.png (Direita)
#  - 01_ESPADA_APROVADA/ESPADA_PRIMEIRA_PRANCHA_COMPLETA.png, linha 2, 4 primeiras poses → espada_guarda.png
# As pranchas não são grades regulares: efeitos e cachecóis passam para a vizinha. Cada
# quadro sai pelas regiões com alfa >= 0,25 (os N maiores componentes são as poses); o
# brilho fraco fica com a pose a que está ligado pelo próprio brilho (busca em largura) e o
# que ficar solto vai para a pose de caixa mais próxima. Nenhum pixel é movido, apagado ou
# recriado; só há uma redução de escala (Lanczos) por folha para que o corpo tenha o mesmo
# tamanho em todas as animações, a TEXELS texels por pixel do mundo.
# Uso: godot --headless --path . -s res://tools/build_protagonist_v2.gd [-- --inspect <pasta>]
const SRC := "res://art_source/protagonista_2_0/"
const OUT := "res://assets/art/protagonist_v2/"
const LAYOUT := "res://scripts/presentation/protagonist_v2_layout.gd"
const SEED_ALPHA := 0.25
const RESIDUE_ALPHA := 0.12
const RESIDUE_REACH := 4
const TEXELS := 3 # Texels por pixel do mundo: 1:1 num celular 3x, mip 1 exato numa tela 1,5x.
const BODY_HEIGHT := 64.0 # Mesma altura do explorador antigo (32 px do atlas em 2x).

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "--inspect":
		_inspect(args[1])
	else:
		_build()
	quit()

func _load(path: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SRC + path))
	image.convert(Image.FORMAT_RGBA8)
	return image

# Separa `frames` poses dentro de `region`. Retorna as imagens (tamanho da folha) e caixas.
# `forced`: [[Rect2i, Vector2i], ...] — a loose piece centred inside the rectangle belongs
# to the pose whose seed box is nearest the point (tips that touch the next pose only by glow).
func segment(sheet: Image, region: Rect2i, frames: int, forced: Array = [], cuts: Array = []) -> Dictionary:
	var w := sheet.get_width()
	var h := sheet.get_height()
	var data := sheet.get_data()
	var seed_threshold := int(SEED_ALPHA * 255.0)
	var label := PackedInt32Array()
	label.resize(w * h)
	label.fill(0)
	var components: Array = [] # [size, id, box]
	var next := 1
	var offsets: Array[Vector2i] = [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(1,1),Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1)]
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var i := y * w + x
			if label[i] != 0 or data[i * 4 + 3] < seed_threshold: continue
			var stack := PackedInt32Array([i])
			label[i] = next
			var count := 0
			var box := Rect2i(x, y, 1, 1)
			while not stack.is_empty():
				var j := stack[stack.size() - 1]
				stack.resize(stack.size() - 1)
				count += 1
				var p := Vector2i(j % w, j / w)
				box = box.expand(p).merge(Rect2i(p, Vector2i.ONE))
				for offset in offsets:
					var n := p + offset
					if not region.has_point(n): continue
					var k := n.y * w + n.x
					if label[k] == 0 and data[k * 4 + 3] >= seed_threshold:
						label[k] = next
						stack.append(k)
			components.append([count, next, box])
			next += 1
	components.sort_custom(func(a, b): return a[0] > b[0])
	if components.size() < frames:
		push_error("only %d components for %d frames" % [components.size(), frames])
		return {}
	# The largest components are the poses; the others join the pose that owns them.
	var poses: Array = components.slice(0, frames)
	var pose_of_label := {}
	for index in range(frames): pose_of_label[poses[index][1]] = index
	var owner := _flood(data, w, h, region, label, pose_of_label)
	# A detached piece (an arc tip, a spark) stays whole: it goes to the pose that
	# reached most of its pixels, never split between two neighbouring poses. The
	# glow is then flooded again from the poses and these whole pieces.
	var votes := {}
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var i := y * w + x
			if label[i] == 0 or pose_of_label.has(label[i]) or owner[i] < 0: continue
			var tally: Dictionary = votes.get_or_add(label[i], {})
			tally[owner[i]] = int(tally.get(owner[i], 0)) + 1
	var piece_box := {}
	for component: Array in components: piece_box[component[1]] = component[2]
	var seeds := pose_of_label.duplicate()
	for piece in votes:
		var tally: Dictionary = votes[piece]
		var best_pose := -1
		for pose in tally:
			if best_pose < 0 or tally[pose] > tally[best_pose]: best_pose = pose
		for rule: Array in forced:
			if (rule[0] as Rect2i).has_point(piece_box[piece].get_center()):
				best_pose = _nearest_pose(poses, rule[1])
		seeds[piece] = best_pose
	owner = _flood(data, w, h, region, label, seeds)
	# A pose can touch a neighbouring effect at full alpha (the outer arc of basic frame 4
	# grazes the scarf of frame 5). Inside a narrow strip, effect-coloured pixels (pale blue
	# or white light, never the dark teal scarf) go to the pose that drew the effect.
	for rule: Array in cuts:
		var strip: Rect2i = rule[0]
		var target := _nearest_pose(poses, rule[1])
		for y in range(strip.position.y, strip.end.y):
			for x in range(strip.position.x, strip.end.x):
				var c := sheet.get_pixel(x, y)
				if c.a > 0.0 and ((c.b > c.r + 0.1 and c.r > 0.4) or (c.v > 0.8 and c.s < 0.3)): owner[y * w + x] = target
	var residue_threshold := int(RESIDUE_ALPHA * 255.0)
	var images: Array = []
	var boxes: Array = []
	for index in range(frames):
		images.append(Image.create(w, h, false, Image.FORMAT_RGBA8))
		boxes.append(poses[index][2])
	var loose := 0
	var residue := 0
	var residue_max := 0
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var i := y * w + x
			if data[i * 4 + 3] == 0: continue
			var index := owner[i]
			if index < 0 and data[i * 4 + 3] < residue_threshold:
				residue += 1
				residue_max = maxi(residue_max, data[i * 4 + 3])
				continue
			if index < 0:
				loose += 1
				var best := INF
				for candidate in range(frames):
					var box: Rect2i = boxes[candidate]
					var d := Vector2(x, y).distance_to(Vector2(clampi(x, box.position.x, box.end.x - 1), clampi(y, box.position.y, box.end.y - 1)))
					if d < best:
						best = d
						index = candidate
			(images[index] as Image).set_pixel(x, y, sheet.get_pixel(x, y))
	var used: Array = []
	for image: Image in images: used.append(image.get_used_rect())
	return {"images": images, "used": used, "seed_boxes": boxes, "loose": loose, "residue": residue, "residue_max": residue_max}

# Ordena as poses em linhas (por y) e colunas (por x).
func grid_order(result: Dictionary, rows: int, columns: int) -> Array:
	var order: Array = range(rows * columns)
	var used: Array = result.used
	order.sort_custom(func(a, b): return used[a].get_center().y < used[b].get_center().y)
	var ordered: Array = []
	for row in range(rows):
		var chunk: Array = order.slice(row * columns, (row + 1) * columns)
		chunk.sort_custom(func(a, b): return used[a].get_center().x < used[b].get_center().x)
		ordered.append_array(chunk)
	return ordered

# [nome, folha, região (vazia = toda), linhas, colunas, escala relativa ao Idle, âncora, peças forçadas]
# Escala relativa: altura da cabeça (topo do cabelo → início do lenço) nas posturas neutras.
# Idle 72 px, Corrida igual (mesmo pacote), Básico 90 (0,79), Estocada 84 (0,85). A prancha
# completa está a 0,48 da folha do Básico (mesma pose no quadro 1: 152/316 px), logo 1,62.
# Âncora "tronco": centro do tronco/cabeça sem o lenço, na linha de chão da linha da folha
# (Idle e Corrida). "pe_tras": o pé de trás fica plantado e o tronco do quadro 1 fica sobre a
# origem (golpes voltados para a Direita), preservando o avanço do corpo no golpe.
# Cada entrada pode trazer, por último, cortes por pixel [[Rect2i, ponto da pose dona]].
const JOBS := [
	["idle", "04_ANIMACOES_NORMAIS/idle_4_direcoes_4_quadros.png", Rect2i(), 4, 4, 1.0, "tronco", []],
	["corrida", "04_ANIMACOES_NORMAIS/corrida_4_direcoes_6_quadros.png", Rect2i(), 4, 6, 1.0, "tronco", []],
	# A ponta externa do arco do quadro 4 encosta no lenço do quadro 5 só pelo brilho.
	["espada_basico", "02_ESPADA_ANIMACOES_ORIGINAIS/ataque_basico_6_quadros.png", Rect2i(), 1, 6, 0.79, "pe_tras", [[Rect2i(1300, 330, 250, 190), Vector2i(1280, 390)]], [[Rect2i(1490, 340, 50, 170), Vector2i(1280, 390)]]],
	["espada_estocada", "02_ESPADA_ANIMACOES_ORIGINAIS/estocada_precisa_6_quadros.png", Rect2i(), 1, 6, 0.85, "pe_tras", []],
	["espada_guarda", "01_ESPADA_APROVADA/ESPADA_PRIMEIRA_PRANCHA_COMPLETA.png", Rect2i(30, 250, 710, 215), 1, 4, 1.62, "pe_tras", []]]
const IDLE_FRONT_HEIGHT := 248.0 # Altura do quadro Frente 1 do Idle na folha original.

func _extract(job: Array) -> Dictionary:
	var sheet := _load(job[1])
	var region: Rect2i = job[2]
	if region.size == Vector2i.ZERO: region = Rect2i(Vector2i.ZERO, sheet.get_size())
	var result := segment(sheet, region, int(job[3]) * int(job[4]), job[7], job[8] if job.size() > 8 else [])
	result.order = grid_order(result, job[3], job[4])
	return result

func _inspect(out_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	for job: Array in JOBS:
		var result := _extract(job)
		print("== ", job[0], " loose=", result.loose, " residue=", result.residue, " residue_max_alpha=", result.residue_max)
		for slot in range(result.order.size()):
			var index: int = result.order[slot]
			var used: Rect2i = result.used[index]
			print("  r%d c%d used=%s" % [slot / job[4], slot % job[4], used])
			var frame: Image = (result.images[index] as Image).get_region(used)
			frame.save_png(out_dir.path_join("%s_r%d_c%d.png" % [job[0], slot / job[4], slot % job[4]]))

static func _is_scarf_or_effect(c: Color) -> bool:
	return c.b > c.r + 0.05 or (c.s < 0.12 and c.v > 0.45)

# Centro x do tronco/cabeça (60% de cima), sem lenço, brilhos e lâmina.
static func _torso_x(image: Image, used: Rect2i) -> float:
	var total := 0.0
	var count := 0
	for y in range(used.position.y, used.position.y + int(used.size.y * 0.6)):
		for x in range(used.position.x, used.end.x):
			var c := image.get_pixel(x, y)
			if c.a < 0.5 or _is_scarf_or_effect(c): continue
			total += x
			count += 1
	return total / maxf(1.0, count)

# Ponta de trás (esquerda) da bota mais atrás, nos 8% de baixo do corpo.
static func _rear_foot_x(image: Image, used: Rect2i) -> int:
	for x in range(used.position.x, used.end.x):
		for y in range(used.end.y - maxi(4, int(used.size.y * 0.08)), used.end.y):
			var c := image.get_pixel(x, y)
			if c.a >= 0.5 and c.r > c.b + 0.08: return x
	return used.position.x

static func _resize_premultiplied(image: Image, size: Vector2i) -> Image:
	# Premultiply so transparent texels never bleed their (garbage) colour into edges.
	var out := image.duplicate() as Image
	out.premultiply_alpha()
	out.resize(maxi(1, size.x), maxi(1, size.y), Image.INTERPOLATE_LANCZOS)
	for y in range(out.get_height()):
		for x in range(out.get_width()):
			var c := out.get_pixel(x, y)
			c.a = clampf(c.a, 0.0, 1.0)
			if c.a <= 0.002:
				out.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			out.set_pixel(x, y, Color(clampf(c.r / c.a, 0, 1), clampf(c.g / c.a, 0, 1), clampf(c.b / c.a, 0, 1), c.a))
	return out

func _build() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var base := TEXELS * BODY_HEIGHT / IDLE_FRONT_HEIGHT
	var layout := "class_name ProtagonistV2Layout\nextends RefCounted\n## Gerado por tools/build_protagonist_v2.gd — não editar à mão.\n"
	layout += "## Folhas em %d texels por pixel do mundo; âncora = pés na origem do ator.\nconst TEXELS := %d\nconst SHEETS := {\n" % [TEXELS, TEXELS]
	for job: Array in JOBS:
		var result := _extract(job)
		var rows: int = job[3]
		var columns: int = job[4]
		var factor: float = base * float(job[5])
		var anchors: Array = []
		for row in range(rows):
			var baseline := 0
			for column in range(columns):
				baseline = maxi(baseline, (result.used[result.order[row * columns + column]] as Rect2i).end.y)
			var first: int = result.order[row * columns]
			var first_used: Rect2i = result.used[first]
			var first_offset := _torso_x(result.images[first], first_used) - _rear_foot_x(result.images[first], first_used)
			for column in range(columns):
				var index: int = result.order[row * columns + column]
				var used: Rect2i = result.used[index]
				var x := _torso_x(result.images[index], used) if job[6] == "tronco" else _rear_foot_x(result.images[index], used) + first_offset
				anchors.append(Vector2(x, baseline))
		# Uniform cells: the largest extent around the feet, after scaling.
		var left := 0.0
		var right := 0.0
		var top := 0.0
		var bottom := 0.0
		for slot in range(rows * columns):
			var used: Rect2i = result.used[result.order[slot]]
			var anchor: Vector2 = anchors[slot]
			left = maxf(left, (anchor.x - used.position.x) * factor)
			right = maxf(right, (used.end.x - anchor.x) * factor)
			top = maxf(top, (anchor.y - used.position.y) * factor)
			bottom = maxf(bottom, (used.end.y - anchor.y) * factor)
		var cell_anchor := Vector2i(ceili(left) + 2, ceili(top) + 2)
		var cell := Vector2i(cell_anchor.x + ceili(right) + 2, cell_anchor.y + ceili(bottom) + 2)
		var atlas := Image.create(cell.x * columns, cell.y * rows, false, Image.FORMAT_RGBA8)
		for slot in range(rows * columns):
			var index: int = result.order[slot]
			var used: Rect2i = result.used[index]
			var anchor: Vector2 = anchors[slot]
			var scaled := _resize_premultiplied((result.images[index] as Image).get_region(used), Vector2i(roundi(used.size.x * factor), roundi(used.size.y * factor)))
			var at := Vector2i((slot % columns) * cell.x, (slot / columns) * cell.y) + cell_anchor + Vector2i(roundi((used.position.x - anchor.x) * factor), roundi((used.position.y - anchor.y) * factor))
			atlas.blend_rect(scaled, Rect2i(Vector2i.ZERO, scaled.get_size()), at)
		atlas.save_png(ProjectSettings.globalize_path(OUT + String(job[0]) + ".png"))
		print("%s cell=%s anchor=%s factor=%.4f atlas=%s" % [job[0], cell, cell_anchor, factor, atlas.get_size()])
		layout += "\t\"%s\": {\"texture\": \"%s%s.png\", \"cell\": Vector2i(%d, %d), \"anchor\": Vector2i(%d, %d), \"rows\": %d, \"frames\": %d},\n" % [job[0], OUT, job[0], cell.x, cell.y, cell_anchor.x, cell_anchor.y, rows, columns]
	layout += "}\n"
	var file := FileAccess.open(ProjectSettings.globalize_path(LAYOUT), FileAccess.WRITE)
	file.store_string(layout)
# Multi-source flood from labelled seed pixels. Glow (alpha >= RESIDUE_ALPHA) follows its
# pose at any distance; fainter pixels only within RESIDUE_REACH steps of it (anti-aliased
# edges). What is never reached and fainter than RESIDUE_ALPHA is sheet residue.
func _flood(data: PackedByteArray, w: int, h: int, region: Rect2i, label: PackedInt32Array, seeds: Dictionary) -> PackedInt32Array:
	var offsets: Array[Vector2i] = [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(1,1),Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1)]
	var owner := PackedInt32Array()
	owner.resize(w * h)
	owner.fill(-1)
	var queue := PackedInt32Array()
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var i := y * w + x
			if seeds.has(label[i]):
				owner[i] = seeds[label[i]]
				queue.append(i)
	var faint := PackedInt32Array()
	faint.resize(w * h)
	faint.fill(0)
	var residue_threshold := int(RESIDUE_ALPHA * 255.0)
	var head := 0
	while head < queue.size():
		var current := queue[head]
		head += 1
		var p := Vector2i(current % w, current / w)
		for offset in offsets:
			var n := p + offset
			if not region.has_point(n): continue
			var k := n.y * w + n.x
			var alpha := data[k * 4 + 3]
			if owner[k] >= 0 or alpha == 0: continue
			var steps := 0 if alpha >= residue_threshold else faint[current] + 1
			if steps > RESIDUE_REACH: continue
			faint[k] = steps
			owner[k] = owner[current]
			queue.append(k)
	return owner

static func _nearest_pose(poses: Array, point: Vector2i) -> int:
	var best := 0
	for index in range(poses.size()):
		if Vector2((poses[index][2] as Rect2i).get_center()).distance_to(point) < Vector2((poses[best][2] as Rect2i).get_center()).distance_to(point): best = index
	return best
