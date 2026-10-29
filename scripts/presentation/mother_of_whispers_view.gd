class_name MotherOfWhispersView
extends ActorView

# Mãe dos Sussurros com as duas artes oficiais (fase 1 e fase 2). Na troca de fase só
# a arte muda, com um aviso visual simples ("Vozes do Fundo"); não há animação nova.
const PHASE_ONE := preload("res://assets/art/andar3/monsters/mae_dos_sussurros_fase1.png")
const PHASE_TWO := preload("res://assets/art/andar3/monsters/mae_dos_sussurros_fase2.png")

var telegraph := ""
var telegraph_direction := Vector2.DOWN
var telegraph_radius := 150.0
var _shown_phase := 1
var _banner_left := 0.0
var _time := 0.0
var _dying_left := 0.0

func _phase() -> int:
	var boss := get_parent()
	if boss == null or not ("phases" in boss): return 1
	return int(boss.phases.phase)

func play_defeat() -> void:
	super.play_defeat()
	_dying_left = 1.0

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
	queue_redraw()

func _draw() -> void:
	var texture: Texture2D = PHASE_TWO if _shown_phase >= 2 else PHASE_ONE
	_draw_telegraph()
	draw_set_transform(Vector2(0, -4), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 120.0, Color(0.03, 0.07, 0.05, 0.42))
	draw_set_transform(Vector2.ZERO)
	var tint := Color(1.6, 1.6, 1.3) if flash_left > 0.0 else Color.WHITE
	if _banner_left > 1.6: tint = Color(1.7, 1.9, 1.5)
	draw_texture(texture, Vector2(-floorf(texture.get_width() * 0.5), -texture.get_height() + 18), tint)
	var top := -float(texture.get_height()) + 4.0
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
