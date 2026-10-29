class_name WhispersTowerGuardianView
extends TowerGuardianView

# Torre do Andar 3: a Guardiã da Torre é a Mãe dos Sussurros com a arte oficial
# (fase 1 até a primeira troca de fase, depois a arte da fase 2). Os golpes, avisos
# e o painel de chefe continuam os da Torre existente.
const PHASE_ONE := preload("res://assets/art/andar3/monsters/mae_dos_sussurros_fase1.png")
const PHASE_TWO := preload("res://assets/art/andar3/monsters/mae_dos_sussurros_fase2.png")

func _draw_body() -> void:
	var boss := get_parent() as TowerGuardian
	var texture: Texture2D = PHASE_TWO if boss != null and boss.phases.phase >= 2 else PHASE_ONE
	var tint := Color(1.5, 1.5, 1.25) if flash_left > 0.0 else Color.WHITE
	# Na arena da Torre a arte fica um pouco menor para os avisos continuarem legíveis.
	var size := Vector2(texture.get_size()) * 0.72
	draw_texture_rect(texture, Rect2(Vector2(-size.x * 0.5, -size.y + 14.0), size), false, tint)
