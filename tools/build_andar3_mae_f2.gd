extends "res://tools/build_andar3_mae.gd"

# Gera as folhas derivadas da TRANSFORMAÇÃO e da FASE 2 da Mãe dos Sussurros a partir das
# folhas aprovadas em art_source/andar3/27-32_MAE_DOS_SUSSURROS_TRANSFORMACAO_E_FASE_2, que
# nunca são alteradas:
#  - 27_MAE_TRANSFORMACAO_6_QUADROS.png  → mae_transformacao.png (fase 1 → fase 2, sem laço)
#  - 28_MAE_F2_IDLE_4_QUADROS.webp       → mae_f2_idle.png (repouso, loop)
#  - 29_MAE_F2_MOVIMENTO_5_QUADROS.webp  → mae_f2_movimento.png (5 quadros, loop)
#  - 30_MAE_F2_ATAQUE_6_QUADROS.webp     → mae_f2_ataque.png (golpe de raízes)
#  - 31_MAE_F2_DANO_3_QUADROS.webp       → mae_f2_dano.png (reação ao dano)
#  - 32_MAE_F2_MORTE_6_QUADROS.webp      → mae_f2_morte.png (desmorona em raízes)
# Mesmo recorte e régua da fase 1. Tamanho em cadeia: o quadro 1 da transformação tem a área
# do repouso da fase 1 (a troca começa sem salto); o quadro 1 do repouso da fase 2 tem a
# área do quadro 6 da transformação (a troca termina sem salto); as outras folhas da fase 2
# seguem o repouso dela como no Jacaré.
# Na transformação (quadros 4 e 5, pela aura) e no ataque (a raiz esticada do quadro 3 no
# quadro 4), as poses vizinhas só se encostam por um brilho quase
# transparente: as poses saem pelas regiões com alfa >= 0,25 e o brilho fraco (0,12 a 0,25)
# fica com a pose de que faz parte (a mais próxima pelo próprio brilho). Nenhum pixel é
# movido, apagado ou recriado.
# Uso: godot --headless --path . -s res://tools/build_andar3_mae_f2.gd
const F2_DIR := "res://art_source/andar3/27-32_MAE_DOS_SUSSURROS_TRANSFORMACAO_E_FASE_2/"
const TRANSFORMATION := F2_DIR + "27_MAE_TRANSFORMACAO_6_QUADROS.png"
# [nome, folha original, quadros, referência de escala, alfa das poses]
const F2_SHEETS := [
	["idle", F2_DIR + "28_MAE_F2_IDLE_4_QUADROS.webp", 4, "neutra", 0.0],
	["movimento", F2_DIR + "29_MAE_F2_MOVIMENTO_5_QUADROS.webp", 5, "media", 0.0],
	["ataque", F2_DIR + "30_MAE_F2_ATAQUE_6_QUADROS.webp", 6, "neutra", 0.25],
	["dano", F2_DIR + "31_MAE_F2_DANO_3_QUADROS.webp", 3, "neutra", 0.0],
	["morte", F2_DIR + "32_MAE_F2_MORTE_6_QUADROS.webp", 6, "neutra", 0.0]]

func _run() -> void:
	# Área do repouso da fase 1 no jogo (a mesma da Guardiã estática anterior).
	var target_area := _area(Image.load_from_file(ProjectSettings.globalize_path(MAE_STATIC)))
	var transformation := _poses_seeded(TRANSFORMATION, 6, 0.25)
	if transformation.is_empty():
		quit(1)
		return
	var t_factor := sqrt(target_area / _area(transformation.full[0]))
	_write("transformacao", transformation, t_factor, "quadro 1 = repouso da fase 1")
	var f2_target := _area(transformation.full[5]) * t_factor * t_factor
	var base_factor := 0.0
	var idle_neutral := 0.0
	var idle_mean := 0.0
	for entry: Array in F2_SHEETS:
		var poses := _vulto_poses(entry[1], int(entry[2])) if float(entry[4]) == 0.0 else _poses_seeded(entry[1], int(entry[2]), float(entry[4]))
		if poses.is_empty():
			quit(1)
			return
		var neutral := _area(poses.full[0])
		var mean := 0.0
		for image: Image in poses.full: mean += _area(image) / poses.full.size()
		if base_factor == 0.0:
			base_factor = sqrt(f2_target / neutral)
			idle_neutral = neutral
			idle_mean = mean
		var factor := base_factor * sqrt(idle_mean / mean if entry[3] == "media" else idle_neutral / neutral)
		_write("f2_" + String(entry[0]), poses, factor, entry[3])
	quit()

func _write(name: String, poses: Dictionary, factor: float, reference: String) -> void:
	var strip := _vulto_strip(poses, factor, "res://assets/art/andar3/monsters/mae_%s.png" % name)
	var meta := {"frames": poses.full.size(), "cell": [strip.cell.x, strip.cell.y], "anchor": strip.anchor, "scale": factor,
		"scale_reference": reference, "width_frame1": roundi(float(poses.boxes[0][2]) * factor), "source_boxes": poses.boxes}
	_save_meta("res://assets/art/andar3/derived/mae_%s.json" % name, meta)
	print("MAE_%s %s" % [name.to_upper(), JSON.stringify(meta)])

# Como _vulto_poses, mas as poses saem das regiões com alfa >= seed_alpha; o resto do que é
# visível (alfa >= 0,12) vai para a pose a que está ligado pelo próprio brilho, e o que
# ficar solto vai para a pose mais próxima.
func _poses_seeded(source_path: String, frames: int, seed_alpha: float) -> Dictionary:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(source_path))
	sheet.convert(Image.FORMAT_RGBA8)
	var w := sheet.get_width()
	var h := sheet.get_height()
	var seeds := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var c := sheet.get_pixel(x, y)
			if c.a < 0.12: sheet.set_pixel(x, y, Color(0, 0, 0, 0))
			elif c.a >= seed_alpha: seeds.set_pixel(x, y, c)
	var seeded := _split_poses(seeds, frames, source_path)
	if seeded.is_empty(): return {}
	var owner := PackedInt32Array()
	owner.resize(w * h)
	owner.fill(-1)
	var queue := PackedInt32Array()
	for index in range(frames):
		var part: Image = seeded[index]
		for i in range(w * h):
			if part.get_pixel(i % w, i / w).a > 0.0:
				owner[i] = index
				queue.append(i)
	var head := 0
	while head < queue.size():
		var current := queue[head]
		head += 1
		var cx := current % w
		var cy := current / w
		for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
			var nx := cx + offset.x
			var ny := cy + offset.y
			if nx < 0 or ny < 0 or nx >= w or ny >= h: continue
			var next := ny * w + nx
			if owner[next] < 0 and sheet.get_pixel(nx, ny).a > 0.0:
				owner[next] = owner[current]
				queue.append(next)
	var boxes: Array = []
	for index in range(frames): boxes.append((seeded[index] as Image).get_used_rect())
	var parts: Array = []
	for index in range(frames): parts.append(Image.create(w, h, false, Image.FORMAT_RGBA8))
	for i in range(w * h):
		var color := sheet.get_pixel(i % w, i / w)
		if color.a <= 0.0: continue
		var index := owner[i]
		if index < 0:
			var best_distance := INF
			for candidate in range(frames):
				var box: Rect2i = boxes[candidate]
				var point := Vector2(i % w, i / w)
				var distance := point.distance_to(point.clamp(Vector2(box.position), Vector2(box.end)))
				if distance < best_distance:
					best_distance = distance
					index = candidate
		(parts[index] as Image).set_pixel(i % w, i / w, color)
	var full: Array = []
	var only_body: Array = []
	var out_boxes: Array = []
	for part: Image in parts:
		var box := part.get_used_rect()
		var frame := part.get_region(box)
		full.append(frame)
		only_body.append(_largest_part(frame))
		out_boxes.append([box.position.x, box.position.y, box.size.x, box.size.y])
	return {"full": full, "only_body": only_body, "boxes": out_boxes}
