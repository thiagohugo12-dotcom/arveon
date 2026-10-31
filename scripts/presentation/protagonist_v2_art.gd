class_name ProtagonistV2Art
extends RefCounted
## Protagonista 2.0 (aprovado): folhas inteiras do corpo, geradas por
## tools/build_protagonist_v2.gd. Só apresentação: colisão, alcance e dano não mudam.
## Linhas das folhas de 4 direções: Frente, Costas, Esquerda, Direita (= _explorer_direction).
## As técnicas da Espada só existem voltadas para a Direita; a Esquerda é a mesma pose
## espelhada (vista lateral, como as técnicas atuais). Cima/Baixo continuam no ataque antigo
## até chegarem artes próprias: basta acrescentar linhas na folha e em ATTACK_ROWS.
const TEXTURES := {
	"idle": preload("res://assets/art/protagonist_v2/idle.png"),
	"corrida": preload("res://assets/art/protagonist_v2/corrida.png"),
	"espada_basico": preload("res://assets/art/protagonist_v2/espada_basico.png"),
	"espada_estocada": preload("res://assets/art/protagonist_v2/espada_estocada.png"),
	"espada_guarda": preload("res://assets/art/protagonist_v2/espada_guarda.png")
}
const FEET := Vector2(0, 12) # Mesmos pés do explorador anterior: sombra, colisão e alvo intactos.
const IDLE_FRAME_TIME := 0.18 # Ritmo do GIF de referência do pacote.
const RUN_PIXELS_PER_FRAME := 19.8 # 0,11 s por quadro do GIF a 180 px/s: os pés não deslizam.
const MIRROR_LEFT := true
# Direção (0 Frente, 1 Costas, 2 Esquerda, 3 Direita) -> linha da folha de golpe; -1 = sem arte.
const ATTACK_ROWS := [-1, -1, 0, 0]

static func has_attack_art(direction_row: int) -> bool:
	if direction_row == 2 and not MIRROR_LEFT: return false
	return ATTACK_ROWS[direction_row] >= 0

static func frame_count(sheet: String) -> int:
	return int(ProtagonistV2Layout.SHEETS[sheet].frames)

static func draw(canvas: CanvasItem, sheet: String, row: int, frame: int, tint := Color.WHITE, mirrored := false) -> void:
	var layout: Dictionary = ProtagonistV2Layout.SHEETS[sheet]
	var cell := Vector2(layout.cell)
	var scale := 1.0 / ProtagonistV2Layout.TEXELS
	var target := Rect2(FEET - Vector2(layout.anchor) * scale, cell * scale)
	var source := Rect2(Vector2(clampi(frame, 0, int(layout.frames) - 1), clampi(row, 0, int(layout.rows) - 1)) * cell, cell)
	if mirrored: canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	canvas.draw_texture_rect_region(TEXTURES[sheet], target, source, tint)
	if mirrored: canvas.draw_set_transform(Vector2.ZERO)

## Golpe voltado para a Direita (linha 3) ou, espelhado, para a Esquerda (linha 2).
static func draw_attack(canvas: CanvasItem, sheet: String, direction_row: int, frame: int, tint := Color.WHITE) -> void:
	draw(canvas, sheet, ATTACK_ROWS[direction_row], frame, tint, direction_row == 2)
