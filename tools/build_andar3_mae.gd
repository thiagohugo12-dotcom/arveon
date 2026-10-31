extends "res://tools/build_andar3_jacare.gd"

# Gera as folhas derivadas da Mãe dos Sussurros (FASE 1) a partir das quatro folhas ORIGINAIS
# aprovadas em art_source/andar3/23-26_MAE_DOS_SUSSURROS_FASE_1 (conjunto parcial), que
# nunca são alteradas:
#  - 23_MAE_F1_IDLE_4_QUADROS.png      → mae_f1_idle.png (repouso, loop)
#  - 24_MAE_F1_MOVIMENTO_4_QUADROS.png → mae_f1_movimento.png (deslocamento pelas raízes, loop)
#  - 25_MAE_F1_ATAQUE_6_QUADROS.png    → mae_f1_ataque.png (golpe de raízes; contato no quadro 4)
#  - 26_MAE_F1_DANO_3_QUADROS.png      → mae_f1_dano.png (reação ao dano)
# Mesmo recorte e mesma régua do Jacaré: poses pelas regiões conectadas visíveis, base das
# raízes da pose 1 como chão, escala pela ÁREA visível (o quadro 1 do repouso fica com a
# área da Guardiã estática da fase 1, para o tamanho em jogo não mudar). A fase 2 continua
# com a arte estática oficial até chegarem a transformação e as folhas da fase 2.
# Uso: godot --headless --path . -s res://tools/build_andar3_mae.gd
const MAE_STATIC := "res://assets/art/andar3/monsters/mae_dos_sussurros_fase1.png"
const MAE_DIR := "res://art_source/andar3/23-26_MAE_DOS_SUSSURROS_FASE_1/"
const MAE_SHEETS := [
	["idle", MAE_DIR + "23_MAE_F1_IDLE_4_QUADROS.png", 4, "neutra"],
	["movimento", MAE_DIR + "24_MAE_F1_MOVIMENTO_4_QUADROS.png", 4, "media"],
	["ataque", MAE_DIR + "25_MAE_F1_ATAQUE_6_QUADROS.png", 6, "neutra"],
	["dano", MAE_DIR + "26_MAE_F1_DANO_3_QUADROS.png", 3, "neutra"]]

func _run() -> void:
	var target_area := _area(Image.load_from_file(ProjectSettings.globalize_path(MAE_STATIC)))
	var base_factor := 0.0
	var idle_neutral := 0.0
	var idle_mean := 0.0
	for entry: Array in MAE_SHEETS:
		var name: String = entry[0]
		var poses := _vulto_poses(entry[1], int(entry[2]))
		if poses.is_empty():
			quit(1)
			return
		var neutral := _area(poses.full[0])
		var mean := 0.0
		for image: Image in poses.full: mean += _area(image) / poses.full.size()
		if base_factor == 0.0:
			base_factor = sqrt(target_area / neutral)
			idle_neutral = neutral
			idle_mean = mean
		var factor := base_factor * sqrt(idle_mean / mean if entry[3] == "media" else idle_neutral / neutral)
		var strip := _vulto_strip(poses, factor, "res://assets/art/andar3/monsters/mae_f1_%s.png" % name)
		var meta := {"frames": int(entry[2]), "cell": [strip.cell.x, strip.cell.y], "anchor": strip.anchor, "scale": factor,
			"scale_reference": entry[3], "width_frame1": roundi(float(poses.boxes[0][2]) * factor), "source_boxes": poses.boxes}
		_save_meta("res://assets/art/andar3/derived/mae_f1_%s.json" % name, meta)
		print("MAE_F1_%s %s" % [name.to_upper(), JSON.stringify(meta)])
	quit()
