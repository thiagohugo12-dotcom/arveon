extends "res://tools/build_andar3_vulto.gd"

# Gera as folhas derivadas do Jacaré Ancião a partir das cinco folhas ORIGINAIS aprovadas
# em art_source/andar3/18-22_JACARE_ANCIAO (conjunto completo), que nunca são alteradas:
#  - 18_JACARE_IDLE_4_QUADROS.png      → jacare_idle.png (repouso, loop)
#  - 19_JACARE_MOVIMENTO_4_QUADROS.png → jacare_movimento.png (passos pesados, loop)
#  - 20_JACARE_ATAQUE_6_QUADROS.png    → jacare_ataque.png (mordida; mandíbula fecha no quadro 4)
#  - 21_JACARE_DANO_3_QUADROS.png      → jacare_dano.png (reação ao dano)
#  - 22_JACARE_MORTE_6_QUADROS.png     → jacare_morte.png (colapso)
# - Recorte igual ao do Vulto: poses pelas regiões conectadas visíveis (o halo de alfa
#   < 0,12 fica de fora), pés no chão da pose 1, centro das patas na mesma coluna.
#   Nenhum pixel visível é movido, apagado ou recriado.
# - Escala pela ÁREA do corpo: as folhas foram desenhadas com proporções diferentes (no
#   dano o corpo é mais comprido, no ataque mais curto), então nem a largura nem a altura
#   servem de régua comum. O quadro 1 do repouso fica com a mesma área visível do Jacaré
#   estático atual (o tamanho em jogo não muda); a pose 1 do ataque, do dano e da morte
#   tem a mesma área dele; no movimento, a área média das 4 poses é a média do repouso.
# Uso: godot --headless --path . -s res://tools/build_andar3_jacare.gd
const STATIC_ART := "res://assets/art/andar3/monsters/jacare_anciao.png"
const DIR := "res://art_source/andar3/18-22_JACARE_ANCIAO/"
# [nome, folha original, quadros, referência de escala: "neutra" (quadro 1) ou "media"]
const JACARE_SHEETS := [
	["idle", DIR + "18_JACARE_IDLE_4_QUADROS.png", 4, "neutra"],
	["movimento", DIR + "19_JACARE_MOVIMENTO_4_QUADROS.png", 4, "media"],
	["ataque", DIR + "20_JACARE_ATAQUE_6_QUADROS.png", 6, "neutra"],
	["dano", DIR + "21_JACARE_DANO_3_QUADROS.png", 3, "neutra"],
	["morte", DIR + "22_JACARE_MORTE_6_QUADROS.png", 6, "neutra"]]

func _run() -> void:
	var target_area := _area(Image.load_from_file(ProjectSettings.globalize_path(STATIC_ART)))
	var base_factor := 0.0
	var idle_neutral := 0.0
	var idle_mean := 0.0
	for entry: Array in JACARE_SHEETS:
		var name: String = entry[0]
		var poses := _vulto_poses(entry[1], int(entry[2]))
		if poses.is_empty():
			quit(1)
			return
		var neutral := _area(poses.full[0])
		var mean := 0.0
		for image: Image in poses.full: mean += _area(image) / poses.full.size()
		# O repouso (primeira folha) define a escala; as outras seguem a área dele.
		if base_factor == 0.0:
			base_factor = sqrt(target_area / neutral)
			idle_neutral = neutral
			idle_mean = mean
		var factor := base_factor * sqrt(idle_mean / mean if entry[3] == "media" else idle_neutral / neutral)
		var strip := _vulto_strip(poses, factor, "res://assets/art/andar3/monsters/jacare_%s.png" % name)
		var meta := {"frames": int(entry[2]), "cell": [strip.cell.x, strip.cell.y], "anchor": strip.anchor, "scale": factor,
			"scale_reference": entry[3], "width_frame1": roundi(float(poses.boxes[0][2]) * factor), "source_boxes": poses.boxes}
		_save_meta("res://assets/art/andar3/derived/jacare_%s.json" % name, meta)
		print("JACARE_%s %s" % [name.to_upper(), JSON.stringify(meta)])
	quit()

# Pixels visíveis (alfa > 0,5) de uma imagem.
func _area(image: Image) -> float:
	image.convert(Image.FORMAT_RGBA8)
	var count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.5: count += 1
	return float(count)
