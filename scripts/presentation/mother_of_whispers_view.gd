class_name MotherOfWhispersView
extends ActorView

# Mãe dos Sussurros. Fase 1 com as quatro folhas aprovadas (repouso, movimento, ataque e
# dano, de tools/build_andar3_mae.gd); fase 2 com a arte estática oficial. Na troca de fase
# a arte muda com o aviso visual simples ("Vozes do Fundo"): a transformação ainda não foi
# aprovada, então não há animação de troca, de fase 2 nem de morte (some como antes).
const PHASE_TWO := preload("res://assets/art/andar3/monsters/mae_dos_sussurros_fase2.png")
# [folha, célula, âncora, quadros]. Âncora = base das raízes da pose 1; o quadro 1 do repouso
# tem a mesma área visível da Guardiã estática anterior da fase 1.
const PHASE_ONE := {
	"idle": [preload("res://assets/art/andar3/monsters/mae_f1_idle.png"), Vector2i(218, 277), Vector2i(103, 264), 4],
	"movimento": [preload("res://assets/art/andar3/monsters/mae_f1_movimento.png"), Vector2i(275, 252), Vector2i(131, 236), 4],
	"ataque": [preload("res://assets/art/andar3/monsters/mae_f1_ataque.png"), Vector2i(272, 343), Vector2i(134, 312), 6],
	"dano": [preload("res://assets/art/andar3/monsters/mae_f1_dano.png"), Vector2i(226, 253), Vector2i(105, 240), 3]}
# A base das raízes fica onde ficava a da arte estática (18 px abaixo da origem).
const PHASE_ONE_GROUND := 18.0
# Repouso e movimento em loop (s por quadro); dano com os tempos do Vulto e do Jacaré.
const IDLE_STEP := 0.2
const MOVE_STEP := 0.15
const HURT_STARTS := [0.0, 0.04, 0.18]
const HURT_LENGTH := 0.32

var telegraph := ""
var telegraph_direction := Vector2.DOWN
var telegraph_radius := 150.0
var _shown_phase := 1
var _banner_left := 0.0
var _time := 0.0
var _dying_left := 0.0
var loop_time := 0.0
var was_walking := false
var hurt_time := -1.0

func _phase() -> int:
	var boss := get_parent()
	if boss == null or not ("phases" in boss): return 1
	return int(boss.phases.phase)

func play_defeat() -> void:
	super.play_defeat()
	_dying_left = 1.0

# Dano na fase 1: reação de 3 quadros, que não interrompe o aviso nem o contato do ataque.
func show_damage(amount: int, critical: bool = false) -> void:
	super.show_damage(amount, critical)
	if amount <= 0 or _shown_phase >= 2 or _dying_left > 0.0: return
	var attack := attack_frame()
	if attack >= 0 and attack <= MotherOfWhispers.ATTACK_CONTACT_FRAME: return
	hurt_time = 0.0 if hurt_time < 0.0 else float(HURT_STARTS[1])

func hurt_frame() -> int:
	return SwampEnemy.frame_at(HURT_STARTS, hurt_time) if hurt_time >= 0.0 else -1

func attack_frame() -> int:
	var boss := get_parent() as MotherOfWhispers
	if boss == null or boss.attack_time < 0.0: return -1
	return SwampEnemy.frame_at(MotherOfWhispers.ATTACK_FRAME_STARTS, boss.attack_time)

# Animação da fase 1 agora: [folha, quadro]. Prioridade: ataque (aviso e contato) > dano >
# ataque (raízes voltando) > movimento > repouso.
func phase_one_animation() -> Array:
	var attack := attack_frame()
	var hurt := hurt_frame()
	if attack >= 0 and (hurt < 0 or attack <= MotherOfWhispers.ATTACK_CONTACT_FRAME): return ["ataque", attack]
	if hurt >= 0: return ["dano", hurt]
	if walking: return ["movimento", int(loop_time / MOVE_STEP) % int(PHASE_ONE.movimento[3])]
	return ["idle", int(loop_time / IDLE_STEP) % int(PHASE_ONE.idle[3])]

func _process(delta: float) -> void:
	super._process(delta)
	_time += delta
	if _phase() != _shown_phase:
		_shown_phase = _phase()
		_banner_left = 2.2
	_banner_left = maxf(0.0, _banner_left - delta)
	if _dying_left > 0.0:
		_dying_left = maxf(0.0, _dying_left - delta)
		modulate.a = _dying_left
	elif _shown_phase == 1:
		# Na derrota o quadro atual fica parado enquanto ela some.
		if hurt_time >= 0.0:
			hurt_time += delta
			if hurt_time >= HURT_LENGTH: hurt_time = -1.0
		if walking != was_walking:
			was_walking = walking
			loop_time = 0.0
		loop_time += delta
	queue_redraw()

func _draw() -> void:
	_draw_telegraph()
	draw_set_transform(Vector2(0, -4), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 120.0, Color(0.03, 0.07, 0.05, 0.42))
	draw_set_transform(Vector2.ZERO)
	var tint := Color(1.6, 1.6, 1.3) if flash_left > 0.0 else Color.WHITE
	if _banner_left > 1.6: tint = Color(1.7, 1.9, 1.5)
	var top := 0.0
	if _shown_phase >= 2:
		draw_texture(PHASE_TWO, Vector2(-floorf(PHASE_TWO.get_width() * 0.5), -PHASE_TWO.get_height() + 18), tint)
		top = -float(PHASE_TWO.get_height()) + 4.0
	else:
		var current := phase_one_animation()
		var sheet: Array = PHASE_ONE[current[0]]
		var cell: Vector2i = sheet[1]
		var anchor: Vector2i = sheet[2]
		draw_texture_rect_region(sheet[0], Rect2(Vector2(-anchor.x, PHASE_ONE_GROUND - anchor.y), Vector2(cell)), Rect2(int(current[1]) * cell.x, 0, cell.x, cell.y), tint)
		# Barra e título na altura do repouso, sem pular com as raízes erguidas do ataque.
		top = PHASE_ONE_GROUND - float((PHASE_ONE.idle[2] as Vector2i).y) - 14.0
	if warning:
		px(-13, top - 20, 26, 6, Color("#f4b942"))
		px(-2, top - 30, 5, 9, Color("#ffe39a"))
	px(-76, top - 2, 152, 7, LINE)
	px(-75, top - 1, 150.0 * hp_ratio, 5, Color("#9be27d") if _shown_phase == 1 else Color("#5de0b0"))
	var title := "MÃE DOS SUSSURROS · " + ("NÉVOA VIVA" if _shown_phase == 1 else "VOZES DO FUNDO")
	draw_string(ThemeDB.fallback_font, Vector2(-92, top - 8), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#f0dfa8"))
	if _banner_left > 0.0:
		var alpha := clampf(_banner_left / 0.6, 0.0, 1.0)
		draw_rect(Rect2(-110, top - 48, 220, 26), Color(0.05, 0.12, 0.09, 0.8 * alpha))
		draw_string(ThemeDB.fallback_font, Vector2(-98, top - 30), "As Vozes do Fundo despertam!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.75, 1.0, 0.85, alpha))
	_draw_hit_feedback(top - 40.0)

func _draw_telegraph() -> void:
	if telegraph.is_empty(): return
	var pulse := 0.5 + 0.5 * sin(_time * 16.0)
	var fill := Color(0.62, 0.86, 0.30, 0.16 + 0.10 * pulse)
	var edge := Color(0.86, 1.0, 0.55, 0.85)
	match telegraph:
		"onda":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.62))
			draw_circle(Vector2.ZERO, telegraph_radius, fill)
			draw_arc(Vector2.ZERO, telegraph_radius, 0.0, TAU, 48, edge, 3.0)
			draw_set_transform(Vector2.ZERO)
		"rajada", "raizes":
			var length := 260.0
			var side := Vector2(-telegraph_direction.y, telegraph_direction.x) * (40.0 if telegraph == "rajada" else 22.0)
			var end := telegraph_direction * length
			var lane := PackedVector2Array([side, end + side * (2.2 if telegraph == "rajada" else 1.0), end - side * (2.2 if telegraph == "rajada" else 1.0), -side])
			draw_colored_polygon(lane, Color(0.86, 0.62, 0.25, 0.16 + 0.1 * pulse) if telegraph == "raizes" else fill)
			draw_polyline(lane + PackedVector2Array([side]), edge, 2.0)
		"manchas":
			# As poças aparecem no chão com o próprio aviso; aqui só o brilho da conjuração.
			draw_arc(Vector2(0, -90), 40.0 + pulse * 8.0, 0.0, TAU, 32, edge, 2.0)
