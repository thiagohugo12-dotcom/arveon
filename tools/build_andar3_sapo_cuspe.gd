extends SceneTree

# Gera a folha derivada da Cuspida Tóxica do Sapo Venenoso a partir da folha ORIGINAL
# aprovada (art_source/andar3/10_SAPO_CUSPE_6_QUADROS.png), que nunca é alterada.
# - Os 6 quadros são separados pelos pixels conectados de cada pose (sem grade fixa); a
#   esfera, os respingos e o brilho vão para o quadro mais próximo, mantendo a ordem
#   original da esquerda para a direita.
# - Escala única para a folha inteira: o corpo do quadro 1 fica com a largura do Sapo
#   atual (84 px), sem mudar proporções nem cores.
# - Todos os quadros são alinhados pela base dos pés e pelo centro da cabeça.
# - O brilho verde translúcido do veneno é mantido; o contorno do corpo fica nítido
#   para o filtro "nearest".
# - Grava também o centro da esfera do quadro 4 (disparo), de onde sai o projétil real.
# Uso: godot --headless --path . -s res://tools/build_andar3_sapo_cuspe.gd
const SOURCE := "res://art_source/andar3/10_SAPO_CUSPE_6_QUADROS.png"
const OUT := "res://assets/art/andar3/monsters/sapo_cuspe.png"
const ORB_OUT := "res://assets/art/andar3/monsters/sapo_cuspe_projetil.png"
const META := "res://assets/art/andar3/derived/sapo_cuspe.json"
const ORB_RADIUS := 8
const FRAMES := 6
const SHOT_FRAME := 3
const BODY_WIDTH := 84.0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	sheet.convert(Image.FORMAT_RGBA8)
	var w := sheet.get_width()
	var h := sheet.get_height()
	# Divisão pelos vãos reais: colunas sem nenhum pixel sólido (alfa > 0,5) entre as poses.
	# O brilho translúcido que atravessa um vão fica com o quadro do lado em que está.
	var gaps: Array = []
	var gap_start := -1
	for x in range(w):
		var solid := false
		for y in range(h):
			if sheet.get_pixel(x, y).a > 0.5:
				solid = true
				break
		if not solid and gap_start < 0: gap_start = x
		elif solid and gap_start >= 0:
			if gap_start > 0: gaps.append((gap_start + x - 1) / 2)
			gap_start = -1
	if gaps.size() != FRAMES - 1:
		push_error("SAPO_CUSPE: esperados %d vãos entre poses, encontrados %d" % [FRAMES - 1, gaps.size()])
		quit(1)
		return
	var edges: Array = [0] + gaps + [w]
	var full: Array = []
	var only_body: Array = []
	var boxes: Array = []
	for index in range(FRAMES):
		var cell_rect := Rect2i(int(edges[index]), 0, int(edges[index + 1]) - int(edges[index]), h)
		var frame := sheet.get_region(cell_rect)
		# Pontos quase invisíveis (alfa < 0,12) espalhados pela folha não fazem parte da pose.
		for y in range(frame.get_height()):
			for x in range(frame.get_width()):
				if frame.get_pixel(x, y).a < 0.12: frame.set_pixel(x, y, Color(0, 0, 0, 0))
		var box := frame.get_used_rect()
		frame = frame.get_region(box)
		full.append(frame)
		only_body.append(_largest_part(frame))
		boxes.append(Rect2i(box.position + cell_rect.position, box.size))
	var factor := BODY_WIDTH / float((only_body[0] as Image).get_used_rect().size.x)
	var scaled: Array = []
	var anchors: Array = []
	for index in range(FRAMES):
		scaled.append(_downscale(full[index], factor))
		anchors.append(_anchor(_downscale(only_body[index], factor)))
	var left := 0
	var right := 0
	var up := 0
	var down := 0
	for index in range(FRAMES):
		var image: Image = scaled[index]
		var anchor: Vector2i = anchors[index]
		left = maxi(left, anchor.x)
		right = maxi(right, image.get_width() - anchor.x)
		up = maxi(up, anchor.y)
		down = maxi(down, image.get_height() - anchor.y)
	var cell := Vector2i(left + right + 2, up + down + 2)
	var strip := Image.create(cell.x * FRAMES, cell.y, false, Image.FORMAT_RGBA8)
	for index in range(FRAMES):
		var image: Image = scaled[index]
		var anchor: Vector2i = anchors[index]
		strip.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(index * cell.x + 1 + left - anchor.x, 1 + up - anchor.y))
	strip.save_png(ProjectSettings.globalize_path(OUT))
	# Centro da esfera do disparo: pixels verdes luminosos no quarto esquerdo do quadro 4
	# (a esfera sai à esquerda da boca), medidos no original e levados para a escala do
	# jogo, relativos aos pés.
	var shot: Image = full[SHOT_FRAME]
	var shot_anchor: Vector2i = anchors[SHOT_FRAME]
	var orb_limit := shot.get_width() * 0.25
	var orb_sum := Vector2.ZERO
	var orb_count := 0
	for y in range(shot.get_height()):
		for x in range(shot.get_width()):
			var c := shot.get_pixel(x, y)
			if x < orb_limit and c.a > 0.5 and c.g > 0.7 and c.r < 0.75 and c.b < 0.45 and c.g > c.r + 0.15:
				orb_sum += Vector2(x, y)
				orb_count += 1
	var orb := (orb_sum / maxf(1.0, orb_count)) * factor
	var mouth := Vector2(roundf(orb.x - shot_anchor.x), roundf(orb.y - shot_anchor.y))
	# Projétil em voo = a própria esfera aprovada do quadro 4, recortada da folha derivada
	# (só a esfera e o brilho; a boca do sapo fica de fora).
	var shot_scaled: Image = scaled[SHOT_FRAME]
	var orb_box := Rect2i(Vector2i(roundi(orb.x) - ORB_RADIUS, roundi(orb.y) - ORB_RADIUS), Vector2i(ORB_RADIUS * 2 + 1, ORB_RADIUS * 2 + 1))
	var orb_image := Image.create(orb_box.size.x, orb_box.size.y, false, Image.FORMAT_RGBA8)
	for y in range(orb_box.size.y):
		for x in range(orb_box.size.x):
			var source := orb_box.position + Vector2i(x, y)
			if source.x < 0 or source.y < 0 or source.x >= shot_scaled.get_width() or source.y >= shot_scaled.get_height(): continue
			if Vector2(x - ORB_RADIUS, y - ORB_RADIUS).length() > ORB_RADIUS + 0.5: continue
			orb_image.set_pixel(x, y, shot_scaled.get_pixel(source.x, source.y))
	orb_image.save_png(ProjectSettings.globalize_path(ORB_OUT))
	var meta := {"frames": FRAMES, "cell": [cell.x, cell.y], "anchor": [1 + left, 1 + up], "shot_frame": SHOT_FRAME,
		"orb_offset": [mouth.x, mouth.y], "orb_pixels": orb_count, "orb_size": ORB_RADIUS * 2 + 1, "scale": factor,
		"source_boxes": boxes.map(func(b: Rect2i) -> Array: return [b.position.x, b.position.y, b.size.x, b.size.y])}
	var file := FileAccess.open(META, FileAccess.WRITE)
	file.store_string(JSON.stringify(meta, "\t", true))
	print("SAPO_CUSPE " + JSON.stringify(meta))
	quit()

# Redução com cor estendida para dentro da transparência (sem halo escuro), Lanczos na
# cor e alfa bilinear. Contorno do corpo nítido (alfa 0 ou 1); o brilho verde do veneno,
# translúcido no original, continua translúcido.
func _downscale(image: Image, factor: float) -> Image:
	var w := image.get_width()
	var h := image.get_height()
	var colors := PackedColorArray()
	colors.resize(w * h)
	var solid := PackedByteArray()
	solid.resize(w * h)
	for i in range(w * h):
		var c := image.get_pixel(i % w, i / w)
		colors[i] = c
		solid[i] = 1 if c.a > 0.0 else 0
	for _pass in range(4):
		var next := colors.duplicate()
		var next_solid := solid.duplicate()
		for y in range(h):
			for x in range(w):
				var i := y * w + x
				if solid[i] == 1: continue
				var sum := Color(0, 0, 0, 0)
				var count := 0
				for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx := x + offset.x
					var ny := y + offset.y
					if nx >= 0 and ny >= 0 and nx < w and ny < h and solid[ny * w + nx] == 1:
						sum += colors[ny * w + nx]
						count += 1
				if count > 0:
					next[i] = sum / float(count)
					next_solid[i] = 1
		colors = next
		solid = next_solid
	var color_image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var alpha_image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for i in range(w * h):
		var c := colors[i]
		color_image.set_pixel(i % w, i / w, Color(c.r, c.g, c.b, 1.0))
		var a := image.get_pixel(i % w, i / w).a
		alpha_image.set_pixel(i % w, i / w, Color(a, a, a, 1.0))
	var tw := maxi(1, roundi(w * factor))
	var th := maxi(1, roundi(h * factor))
	color_image.resize(tw, th, Image.INTERPOLATE_LANCZOS)
	alpha_image.resize(tw, th, Image.INTERPOLATE_BILINEAR)
	var out := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	for y in range(th):
		for x in range(tw):
			var c := color_image.get_pixel(x, y)
			var a := alpha_image.get_pixel(x, y).r
			var glow := c.g > 0.5 and c.g > c.r + 0.15 and c.g > c.b + 0.2
			var alpha := 1.0 if a >= 0.5 else (a if glow and a >= 0.2 else 0.0)
			out.set_pixel(x, y, Color(c.r, c.g, c.b, alpha))
	return out

# Âncora = (centro da cabeça, linha da base dos pés). A cabeça é o terço de cima do corpo;
# a base é a última linha larga (ignora pontas soltas embaixo).
func _anchor(image: Image) -> Vector2i:
	var w := image.get_width()
	var h := image.get_height()
	var widths := PackedInt32Array()
	widths.resize(h)
	var widest := 0
	for y in range(h):
		var count := 0
		for x in range(w):
			if image.get_pixel(x, y).a > 0.0: count += 1
		widths[y] = count
		widest = maxi(widest, count)
	var top := 0
	while top < h and widths[top] == 0: top += 1
	var base := h - 1
	while base > top and widths[base] < widest * 0.3: base -= 1
	var sum := 0.0
	var count := 0
	for y in range(top, top + maxi(1, (base - top) / 3)):
		for x in range(w):
			if image.get_pixel(x, y).a > 0.0:
				sum += x
				count += 1
	return Vector2i(roundi(sum / maxf(1.0, count)), base)

# Corpo da pose = maior região de pixels sólidos conectados (sem esfera nem respingos).
func _largest_part(image: Image) -> Image:
	var w := image.get_width()
	var h := image.get_height()
	var label := PackedInt32Array()
	label.resize(w * h)
	label.fill(-1)
	var best_id := -1
	var best_count := 0
	var next_id := 0
	for start in range(w * h):
		if label[start] >= 0 or image.get_pixel(start % w, start / w).a <= 0.5: continue
		var stack := [start]
		label[start] = next_id
		var count := 0
		while not stack.is_empty():
			var current: int = stack.pop_back()
			count += 1
			var cx := current % w
			var cy := current / w
			for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := cx + offset.x
				var ny := cy + offset.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h: continue
				var next := ny * w + nx
				if label[next] < 0 and image.get_pixel(nx, ny).a > 0.5:
					label[next] = next_id
					stack.append(next)
		if count > best_count:
			best_count = count
			best_id = next_id
		next_id += 1
	var body := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for i in range(w * h):
		if label[i] == best_id: body.set_pixel(i % w, i / w, image.get_pixel(i % w, i / w))
	return body
