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
	"espada_guarda": preload("res://assets/art/protagonist_v2/espada_guarda.png"),
	"espada_kamusari": preload("res://assets/art/protagonist_v2/espada_kamusari.png"),
	"espada_contra": preload("res://assets/art/protagonist_v2/espada_contra.png"),
	"espada_crescente": preload("res://assets/art/protagonist_v2/espada_crescente.png"),
	"espada_ruptura": preload("res://assets/art/protagonist_v2/espada_ruptura.png")
}
const FEET := Vector2(0, 12) # Mesmos pés do explorador anterior: sombra, colisão e alvo intactos.
const IDLE_FRAME_TIME := 0.18 # Ritmo do GIF de referência do pacote.
const RUN_PIXELS_PER_FRAME := 19.8 # 0,11 s por quadro do GIF a 180 px/s: os pés não deslizam.
const MIRROR_LEFT := true
# Direção (0 Frente, 1 Costas, 2 Esquerda, 3 Direita) -> linha da folha de golpe; -1 = sem arte.
const ATTACK_ROWS := [-1, -1, 0, 0]
## Kamusari em 8 quadros no mesmo relógio da técnica (0,485 s): o quadro 5, o arco, cai
## exatamente no contato do dano (SwordTechniqueTiming.contact("danca_laminas") = 0,215 s).
const KAMUSARI_FRAMES := [0.05, 0.06, 0.05, 0.055, 0.08, 0.07, 0.06, 0.06]
const KAMUSARI_CONTACT_FRAME := 4
## Corte Crescente causa o dano no instante do uso (as regras não têm preparação) e já corta
## no quadro 1, dentro da duração visual de SwordTechniqueEffect.EXTRA_DURATIONS.
const CRESCENTE_FRAMES := [0.05, 0.06, 0.07, 0.06, 0.06]
## Ruptura Ancestral no relógio da técnica (SwordTechniqueTiming, 0,44 s): carga e salto em
## 0,10 s, e o impacto com a erupção (quadro 3) entra exatamente no contato do dano.
const RUPTURA_FRAMES := [0.05, 0.05, 0.12, 0.11, 0.11]
const RUPTURA_CONTACT_FRAME := 2
## Contra-ataque da Guarda (reação visual ao bloqueio, sem dano próprio): 6 quadros nos
## 0,22 s em que o efeito mostra o contra-ataque.
const COUNTER_FRAMES := [0.02, 0.04, 0.05, 0.045, 0.035, 0.03]

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

static func kamusari_frame(elapsed: float) -> int:
	return timed_frame(KAMUSARI_FRAMES, elapsed)

## Quadro de uma sequência de durações; o último fica até o fim.
static func timed_frame(durations: Array, elapsed: float) -> int:
	var boundary := 0.0
	for i in range(durations.size() - 1):
		boundary += durations[i]
		if elapsed < boundary - 0.000001: return i
	return durations.size() - 1
