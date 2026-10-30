extends "res://tools/build_andar3_sapo_cuspe.gd"

# Gera as folhas derivadas do Vulto do Brejo a partir das cinco folhas ORIGINAIS aprovadas
# em art_source/andar3 (13 a 17), que nunca são alteradas:
#  - 13_VULTO_IDLE_4_QUADROS.png      → vulto_idle.png (repouso, loop)
#  - 14_VULTO_MOVIMENTO_4_QUADROS.png → vulto_movimento.png (deslocamento, loop)
#  - 15_VULTO_ATAQUE_6_QUADROS.png    → vulto_ataque.png (garras; contato no quadro 4)
#  - 16_VULTO_DANO_3_QUADROS.png      → vulto_dano.png (reação ao dano)
#  - 17_VULTO_MORTE_6_QUADROS.png     → vulto_morte.png (colapso em raízes)
# - As folhas (2048 px) não dividem em grade: poses encostam e cruzam as divisas teóricas
#   (garras do ataque, montes da morte). Cada pose sai pela sua região conectada; só o
#   halo quase invisível (alfa < 0,12) liga uma pose à outra e fica de fora, como nas
#   folhas do Sapo. Nenhum pixel visível é movido, apagado ou recriado.
# - Mesma escala visual nas cinco folhas. As folhas originais não foram desenhadas no mesmo
#   tamanho (a pose neutra mede 535 px de altura no repouso e 407 px no ataque), então cada
#   folha tem a sua escala: o quadro 1 do repouso fica com a largura do Vulto atual (72 px)
#   e a pose neutra (quadro 1) do ataque, do dano e da morte fica com a mesma altura dele.
#   O movimento não tem pose neutra: a altura média das 4 poses fica igual à média do
#   repouso. (A distância entre os olhos confirma: diferença de até 4%.)
# - Chão de cada folha = base das raízes da pose 1; cada pose fica na altura em que foi
#   desenhada sobre esse chão (no ataque as raízes do avanço descem um pouco, como na
#   folha). Na horizontal, o centro das raízes fica na mesma coluna.
# Uso: godot --headless --path . -s res://tools/build_andar3_vulto.gd
const VULTO_WIDTH := 72.0
# [nome, folha original, quadros, referência de escala: "neutra" (quadro 1) ou "media"]
const SHEETS := [
	["idle", "res://art_source/andar3/13_VULTO_IDLE_4_QUADROS.png", 4, "neutra"],
	["movimento", "res://art_source/andar3/14_VULTO_MOVIMENTO_4_QUADROS.png", 4, "media"],
	["ataque", "res://art_source/andar3/15_VULTO_ATAQUE_6_QUADROS.png", 6, "neutra"],
	["dano", "res://art_source/andar3/16_VULTO_DANO_3_QUADROS.png", 3, "neutra"],
	["morte", "res://art_source/andar3/17_VULTO_MORTE_6_QUADROS.png", 6, "neutra"]]

func _run() -> void:
	var base_factor := 0.0
	var idle_neutral := 0.0
	var idle_mean := 0.0
	for entry: Array in SHEETS:
		var name: String = entry[0]
		var poses := _vulto_poses(entry[1], int(entry[2]))
		if poses.is_empty():
			quit(1)
			return
		var neutral := float(poses.boxes[0][3])
		var mean := 0.0
		for box: Array in poses.boxes: mean += float(box[3]) / poses.boxes.size()
		# O repouso (primeira folha) define a escala; as outras seguem a altura dele.
		if base_factor == 0.0:
			base_factor = VULTO_WIDTH / float(poses.boxes[0][2])
			idle_neutral = neutral
			idle_mean = mean
		var factor := base_factor * (idle_mean / mean if entry[3] == "media" else idle_neutral / neutral)
		var strip := _vulto_strip(poses, factor, "res://assets/art/andar3/monsters/vulto_%s.png" % name)
		var meta := {"frames": int(entry[2]), "cell": [strip.cell.x, strip.cell.y], "anchor": strip.anchor, "scale": factor,
			"scale_reference": entry[3], "source_boxes": poses.boxes}
		_save_meta("res://assets/art/andar3/derived/vulto_%s.json" % name, meta)
		print("VULTO_%s %s" % [name.to_upper(), JSON.stringify(meta)])
	quit()

# Poses da folha inteira pelas regiões conectadas visíveis, da esquerda para a direita.
func _vulto_poses(source_path: String, frames: int) -> Dictionary:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(source_path))
	sheet.convert(Image.FORMAT_RGBA8)
	for y in range(sheet.get_height()):
		for x in range(sheet.get_width()):
			if sheet.get_pixel(x, y).a < 0.12: sheet.set_pixel(x, y, Color(0, 0, 0, 0))
	var parts := _split_poses(sheet, frames, source_path)
	if parts.is_empty(): return {}
	var full: Array = []
	var only_body: Array = []
	var boxes: Array = []
	for part: Image in parts:
		var box := part.get_used_rect()
		var frame := part.get_region(box)
		full.append(frame)
		only_body.append(_largest_part(frame))
		boxes.append([box.position.x, box.position.y, box.size.x, box.size.y])
	return {"full": full, "only_body": only_body, "boxes": boxes}

# Reduz com a escala da folha e alinha pelos pés: altura de cada pose como na folha, sobre
# o chão da pose 1; centro das raízes na mesma coluna. 1 px de folga transparente em volta.
func _vulto_strip(poses: Dictionary, factor: float, out_path: String) -> Dictionary:
	var frames: int = poses.full.size()
	var scaled: Array = []
	var anchors: Array = []
	for index in range(frames):
		scaled.append(_downscale(poses.full[index], factor))
		anchors.append(_anchor(_downscale(poses.only_body[index], factor), true))
	var boxes: Array = poses.boxes
	var ground := float(boxes[0][1]) + float((anchors[0] as Vector2i).y) / factor
	for index in range(frames):
		var anchor: Vector2i = anchors[index]
		anchors[index] = Vector2i(anchor.x, roundi((ground - float(boxes[index][1])) * factor))
	var left := 0
	var right := 0
	var up := 0
	var down := 0
	for index in range(frames):
		var image: Image = scaled[index]
		var anchor: Vector2i = anchors[index]
		left = maxi(left, anchor.x)
		right = maxi(right, image.get_width() - anchor.x)
		up = maxi(up, anchor.y)
		down = maxi(down, image.get_height() - anchor.y)
	var cell := Vector2i(left + right + 2, up + down + 2)
	var strip := Image.create(cell.x * frames, cell.y, false, Image.FORMAT_RGBA8)
	for index in range(frames):
		var image: Image = scaled[index]
		var anchor: Vector2i = anchors[index]
		strip.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(index * cell.x + 1 + left - anchor.x, 1 + up - anchor.y))
	strip.save_png(ProjectSettings.globalize_path(out_path))
	return {"cell": cell, "anchor": [1 + left, 1 + up]}
