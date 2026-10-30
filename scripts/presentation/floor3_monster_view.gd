class_name Floor3MonsterView
extends ActorView

# Criaturas do Pântano com a arte oficial do pacote do Andar 3. O Limo do Brejo usa as
# duas folhas aprovadas (respiração 4 quadros e ataque 6 quadros) num AnimatedSprite2D;
# o Sapo Venenoso usa a Cuspida Tóxica aprovada (6 quadros), com o quadro escolhido pelo
# relógio do ataque no ator (SwampEnemy.spit_time), e a reação ao dano aprovada (3
# quadros) sempre que é ferido e continua vivo; o Vulto do Brejo usa as cinco folhas
# aprovadas (repouso, movimento, golpe de garras pelo relógio SwampEnemy.strike_time,
# dano e morte); o Jacaré Ancião também usa as cinco folhas aprovadas (mordida pelo relógio
# AncientCaiman.bite_time; a investida usa o movimento acelerado e a cauda não tem folha
# própria, então o aviso aparece sobre o repouso). A jogabilidade fica no ator: esta vista
# só avisa o quadro de impacto do ataque do Limo e o fim da animação.
signal impact
signal attack_finished

const IDLE_SHEET := preload("res://assets/art/andar3/monsters/limo_idle.png")
const ATTACK_SHEET := preload("res://assets/art/andar3/monsters/limo_ataque.png")
# Cuspida Tóxica: célula e âncora (base dos pés) geradas por tools/build_andar3_sapo_cuspe.gd.
# O quadro 1 (pose neutra) é também o Sapo parado.
const TOAD_SHEET := preload("res://assets/art/andar3/monsters/sapo_cuspe.png")
const TOAD_CELL := Vector2i(90, 75)
const TOAD_ANCHOR := Vector2i(43, 67)
const TOAD_WIDTH := 84.0
# Dano do Sapo (pose neutra, impacto, recuperação), da mesma ferramenta e na mesma escala;
# alinhado pelas patas. Início de cada quadro (s) e duração total.
const TOAD_HURT_SHEET := preload("res://assets/art/andar3/monsters/sapo_dano.png")
const TOAD_HURT_CELL := Vector2i(95, 70)
const TOAD_HURT_ANCHOR := Vector2i(50, 63)
const TOAD_HURT_STARTS := [0.0, 0.04, 0.18]
const TOAD_HURT_LENGTH := 0.32
# Movimento do Sapo (saltos curtos), mesma ferramenta e escala; cada pose mantém a altura
# desenhada na folha. Andando: loop de 0,12 s por quadro. Salto rápido de reposição:
# um ciclo inteiro acompanhando o salto.
const TOAD_MOVE_SHEET := preload("res://assets/art/andar3/monsters/sapo_movimento.png")
const TOAD_MOVE_CELL := Vector2i(95, 79)
const TOAD_MOVE_ANCHOR := Vector2i(49, 73)
const TOAD_MOVE_FRAMES := 4
const TOAD_MOVE_STEP := 0.12
# Vulto do Brejo: as cinco folhas de tools/build_andar3_vulto.gd, na mesma escala visual e
# com os pés na âncora. [folha, célula, âncora, quadros]. A arte olha para a direita.
const WRAITH := {
	"idle": [preload("res://assets/art/andar3/monsters/vulto_idle.png"), Vector2i(78, 86), Vector2i(37, 81), 4],
	"movimento": [preload("res://assets/art/andar3/monsters/vulto_movimento.png"), Vector2i(74, 86), Vector2i(35, 80), 4],
	"ataque": [preload("res://assets/art/andar3/monsters/vulto_ataque.png"), Vector2i(93, 94), Vector2i(33, 88), 6],
	"dano": [preload("res://assets/art/andar3/monsters/vulto_dano.png"), Vector2i(89, 86), Vector2i(43, 82), 3],
	"morte": [preload("res://assets/art/andar3/monsters/vulto_morte.png"), Vector2i(76, 88), Vector2i(36, 82), 6]}
const WRAITH_WIDTH := 72.0
# Repouso e movimento em loop (s por quadro); dano como o do Sapo (neutra, impacto,
# recuperação); morte em 6 quadros de 0,1 s, e os restos de raízes somem entre 0,7 s e
# 1 s, quando o ator sai de cena.
const WRAITH_IDLE_STEP := 0.2
const WRAITH_MOVE_STEP := 0.1
const WRAITH_HURT_STARTS := [0.0, 0.04, 0.18]
const WRAITH_HURT_LENGTH := 0.32
const WRAITH_DEATH_STEP := 0.1
const WRAITH_DEATH_FADE := Vector2(0.7, 1.0)
# Jacaré Ancião: as cinco folhas de tools/build_andar3_jacare.gd, com a mesma área visível
# do Jacaré estático anterior e os pés na âncora. [folha, célula, âncora, quadros]. A arte
# olha para a esquerda.
const CAIMAN := {
	"idle": [preload("res://assets/art/andar3/monsters/jacare_idle.png"), Vector2i(201, 177), Vector2i(89, 160), 4],
	"movimento": [preload("res://assets/art/andar3/monsters/jacare_movimento.png"), Vector2i(198, 180), Vector2i(86, 164), 4],
	"ataque": [preload("res://assets/art/andar3/monsters/jacare_ataque.png"), Vector2i(177, 198), Vector2i(84, 185), 6],
	"dano": [preload("res://assets/art/andar3/monsters/jacare_dano.png"), Vector2i(225, 156), Vector2i(99, 137), 3],
	"morte": [preload("res://assets/art/andar3/monsters/jacare_morte.png"), Vector2i(205, 186), Vector2i(95, 171), 6]}
const CAIMAN_WIDTH := 198.0
# Repouso e passos pesados em loop (s por quadro); na investida os mesmos passos, mais
# rápidos. Dano e morte com os tempos do Vulto (a morte some entre 0,7 s e 1 s).
const CAIMAN_IDLE_STEP := 0.2
const CAIMAN_MOVE_STEP := 0.15
const CAIMAN_CHARGE_STEP := 0.07
const CAIMAN_HURT_STARTS := [0.0, 0.04, 0.18]
const CAIMAN_HURT_LENGTH := 0.32
const CAIMAN_DEATH_STEP := 0.1
const CAIMAN_DEATH_FADE := Vector2(0.7, 1.0)
# Células e âncoras (base do corpo) geradas por tools/build_andar3_assets.gd.
const IDLE_CELL := Vector2i(55, 41)
const IDLE_ANCHOR := Vector2i(28, 37)
const ATTACK_CELL := Vector2i(70, 53)
const ATTACK_ANCHOR := Vector2i(29, 46)
# Quarto quadro da folha de ataque: o lodo atinge o alcance máximo.
const IMPACT_FRAME := 3

var kind := 8
var slime: AnimatedSprite2D
var telegraph := ""
var telegraph_direction := Vector2.RIGHT
var telegraph_radius := 0.0
var telegraph_left := 0.0
var dying_left := 0.0
var _impact_sent := false
# Tempo da reação ao dano do Sapo (-1 = sem reação).
var toad_hurt_time := -1.0
# Tempo do loop de movimento do Sapo (volta a zero quando ele para) e duração do salto atual.
var toad_move_time := 0.0
var toad_hop_total := 0.0
# Vulto: relógio do loop (volta a zero ao começar ou parar de andar), dano e morte (-1 = sem).
var wraith_loop_time := 0.0
var wraith_was_walking := false
var wraith_hurt_time := -1.0
var wraith_death_time := -1.0
# Jacaré: os mesmos relógios do Vulto e o lado (só muda com um passo claro para um dos
# lados, e fica fixo da mandíbula fechando até o fim da mordida).
var caiman_loop_time := 0.0
var caiman_was_walking := false
var caiman_hurt_time := -1.0
var caiman_death_time := -1.0
var caiman_flipped := false

func _ready() -> void:
	super._ready()
	var actor := get_parent() as EnemyActor
	if actor != null: kind = actor.kind
	if kind == 8: _build_slime()

func _build_slime() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for entry: Array in [["idle", IDLE_SHEET, IDLE_CELL, 4, 6.0, true], ["ataque", ATTACK_SHEET, ATTACK_CELL, 6, 9.0, false]]:
		var name: String = entry[0]
		frames.add_animation(name)
		frames.set_animation_speed(name, float(entry[4]))
		frames.set_animation_loop(name, bool(entry[5]))
		var cell: Vector2i = entry[2]
		for index in range(int(entry[3])):
			var frame := AtlasTexture.new()
			frame.atlas = entry[1]
			frame.region = Rect2(index * cell.x, 0, cell.x, cell.y)
			frames.add_frame(name, frame)
	slime = AnimatedSprite2D.new()
	slime.sprite_frames = frames
	slime.centered = false
	slime.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(slime)
	slime.frame_changed.connect(_on_slime_frame)
	slime.animation_finished.connect(_on_slime_finished)
	_play_slime("idle")

# A âncora (base do corpo) fica sempre na origem do ator, inclusive espelhado.
func _place_slime() -> void:
	var attack := slime.animation == "ataque"
	var cell: Vector2i = ATTACK_CELL if attack else IDLE_CELL
	var anchor: Vector2i = ATTACK_ANCHOR if attack else IDLE_ANCHOR
	slime.flip_h = facing.x < -0.2
	slime.offset = Vector2(-(cell.x - anchor.x) if slime.flip_h else -anchor.x, -anchor.y)

func _play_slime(name: String) -> void:
	slime.play(name)
	_place_slime()

func play_slime_attack() -> void:
	if slime == null or slime.animation == "ataque": return
	_impact_sent = false
	_play_slime("ataque")

func slime_attacking() -> bool:
	return slime != null and slime.animation == "ataque" and slime.is_playing()

func _on_slime_frame() -> void:
	if slime.animation == "ataque" and slime.frame == IMPACT_FRAME and not _impact_sent:
		_impact_sent = true
		impact.emit()

func _on_slime_finished() -> void:
	if slime.animation == "ataque":
		_play_slime("idle")
		attack_finished.emit()

func set_facing(value: Vector2) -> void:
	super.set_facing(value)
	# O Limo não vira no meio do golpe: o lodo sai para o lado avisado.
	if slime != null and slime.animation != "ataque": _place_slime()

func set_telegraph(kind_name: String, direction: Vector2, radius: float, duration: float = 0.0) -> void:
	telegraph = kind_name
	telegraph_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	telegraph_radius = radius
	telegraph_left = duration
	queue_redraw()

func play_defeat() -> void:
	super.play_defeat()
	dying_left = 0.7
	if slime != null: slime.pause()
	toad_hurt_time = -1.0
	wraith_hurt_time = -1.0
	if kind == 10: wraith_death_time = 0.0
	caiman_hurt_time = -1.0
	if kind == 11: caiman_death_time = 0.0

# Sapo, Vulto e Jacaré reagem a cada dano enquanto vivos; um novo golpe durante a reação
# volta ao impacto. O golpe fatal chega aqui depois de play_defeat e não inicia a reação. O
# preparo e o contato das garras do Vulto e da mordida do Jacaré, e a investida, não são
# interrompidos (o clarão já marca o acerto).
func show_damage(amount: int, critical: bool = false) -> void:
	super.show_damage(amount, critical)
	var actor := get_parent() as EnemyActor
	if amount <= 0 or dying_left > 0.0 or actor == null or not actor.health.is_alive(): return
	if kind == 9:
		toad_hurt_time = 0.0 if toad_hurt_time < 0.0 else float(TOAD_HURT_STARTS[1])
	elif kind == 10:
		var strike := float(actor.get("strike_time")) if actor is SwampEnemy else -1.0
		if strike >= 0.0 and SwampEnemy.strike_frame(strike) <= SwampEnemy.WRAITH_CONTACT_FRAME: return
		wraith_hurt_time = 0.0 if wraith_hurt_time < 0.0 else float(WRAITH_HURT_STARTS[1])
	elif kind == 11:
		var bite := caiman_bite_frame()
		if (bite >= 0 and bite <= AncientCaiman.BITE_CONTACT_FRAME) or caiman_charging(): return
		caiman_hurt_time = 0.0 if caiman_hurt_time < 0.0 else float(CAIMAN_HURT_STARTS[1])

func wraith_hurt_frame() -> int:
	return SwampEnemy.frame_at(WRAITH_HURT_STARTS, wraith_hurt_time) if wraith_hurt_time >= 0.0 else -1

# Animação do Vulto agora: [folha, quadro]. Prioridade: morte > golpe (preparo e contato) >
# dano > golpe (recolher as garras) > movimento > repouso.
func wraith_animation() -> Array:
	if wraith_death_time >= 0.0:
		return ["morte", mini(int(WRAITH.morte[3]) - 1, int(wraith_death_time / WRAITH_DEATH_STEP))]
	var actor := get_parent() as SwampEnemy
	var strike := actor.strike_time if actor != null else -1.0
	var hurt := wraith_hurt_frame()
	if strike >= 0.0:
		var frame := SwampEnemy.strike_frame(strike)
		if hurt < 0 or frame <= SwampEnemy.WRAITH_CONTACT_FRAME: return ["ataque", frame]
	if hurt >= 0: return ["dano", hurt]
	if walking: return ["movimento", int(wraith_loop_time / WRAITH_MOVE_STEP) % int(WRAITH.movimento[3])]
	return ["idle", int(wraith_loop_time / WRAITH_IDLE_STEP) % int(WRAITH.idle[3])]

func _wraith_flipped() -> bool:
	var actor := get_parent() as SwampEnemy
	if actor != null and actor.strike_time >= 0.0 and wraith_death_time < 0.0: return actor.strike_flipped
	return facing.x < -0.2

func _draw_wraith(tint: Color) -> void:
	var current := wraith_animation()
	var sheet: Array = WRAITH[current[0]]
	var cell: Vector2i = sheet[1]
	var anchor: Vector2i = sheet[2]
	if _wraith_flipped(): draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	draw_texture_rect_region(sheet[0], Rect2(-Vector2(anchor), Vector2(cell)), Rect2(int(current[1]) * cell.x, 0, cell.x, cell.y), tint)
	draw_set_transform(Vector2.ZERO)

func caiman_hurt_frame() -> int:
	return SwampEnemy.frame_at(CAIMAN_HURT_STARTS, caiman_hurt_time) if caiman_hurt_time >= 0.0 else -1

func caiman_bite_frame() -> int:
	var actor := get_parent() as AncientCaiman
	if actor == null or actor.bite_time < 0.0: return -1
	return SwampEnemy.frame_at(AncientCaiman.BITE_FRAME_STARTS, actor.bite_time)

func caiman_charging() -> bool:
	var actor := get_parent() as AncientCaiman
	return actor != null and actor.active > 0.0 and actor.act == AncientCaiman.Act.CHARGE

# Animação do Jacaré agora: [folha, quadro]. Prioridade: morte > mordida (aviso e contato) >
# investida > dano > mordida (mandíbula voltando) > passos > repouso.
func caiman_animation() -> Array:
	if caiman_death_time >= 0.0:
		return ["morte", mini(int(CAIMAN.morte[3]) - 1, int(caiman_death_time / CAIMAN_DEATH_STEP))]
	var bite := caiman_bite_frame()
	var hurt := caiman_hurt_frame()
	if bite >= 0 and (hurt < 0 or bite <= AncientCaiman.BITE_CONTACT_FRAME): return ["ataque", bite]
	if caiman_charging(): return ["movimento", int(caiman_loop_time / CAIMAN_CHARGE_STEP) % int(CAIMAN.movimento[3])]
	if hurt >= 0: return ["dano", hurt]
	if walking: return ["movimento", int(caiman_loop_time / CAIMAN_MOVE_STEP) % int(CAIMAN.movimento[3])]
	return ["idle", int(caiman_loop_time / CAIMAN_IDLE_STEP) % int(CAIMAN.idle[3])]

func _draw_caiman(tint: Color) -> void:
	var current := caiman_animation()
	var sheet: Array = CAIMAN[current[0]]
	var cell: Vector2i = sheet[1]
	var anchor: Vector2i = sheet[2]
	if caiman_flipped: draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	draw_texture_rect_region(sheet[0], Rect2(-Vector2(anchor), Vector2(cell)), Rect2(int(current[1]) * cell.x, 0, cell.x, cell.y), tint)
	draw_set_transform(Vector2.ZERO)

func toad_hurt_frame() -> int:
	if toad_hurt_time < 0.0: return -1
	var frame := 0
	for index in range(TOAD_HURT_STARTS.size()):
		if toad_hurt_time >= float(TOAD_HURT_STARTS[index]): frame = index
	return frame

func _process(delta: float) -> void:
	super._process(delta)
	if telegraph_left > 0.0:
		telegraph_left -= delta
		if telegraph_left <= 0.0: telegraph = ""
	if wraith_death_time >= 0.0:
		wraith_death_time += delta
		dying_left = maxf(0.0, dying_left - delta)
		modulate.a = 1.0 - clampf((wraith_death_time - WRAITH_DEATH_FADE.x) / (WRAITH_DEATH_FADE.y - WRAITH_DEATH_FADE.x), 0.0, 1.0)
	elif caiman_death_time >= 0.0:
		caiman_death_time += delta
		dying_left = maxf(0.0, dying_left - delta)
		modulate.a = 1.0 - clampf((caiman_death_time - CAIMAN_DEATH_FADE.x) / (CAIMAN_DEATH_FADE.y - CAIMAN_DEATH_FADE.x), 0.0, 1.0)
	elif dying_left > 0.0:
		dying_left = maxf(0.0, dying_left - delta)
		modulate.a = dying_left / 0.7
	if slime != null:
		slime.modulate = Color(1.8, 1.8, 1.4) if flash_left > 0.0 else Color.WHITE
	if toad_hurt_time >= 0.0:
		toad_hurt_time += delta
		if toad_hurt_time >= TOAD_HURT_LENGTH: toad_hurt_time = -1.0
	if kind == 9:
		toad_move_time = toad_move_time + delta if walking else 0.0
	if kind == 10:
		if wraith_hurt_time >= 0.0:
			wraith_hurt_time += delta
			if wraith_hurt_time >= WRAITH_HURT_LENGTH: wraith_hurt_time = -1.0
		if walking != wraith_was_walking:
			wraith_was_walking = walking
			wraith_loop_time = 0.0
		wraith_loop_time += delta
	if kind == 11:
		if caiman_hurt_time >= 0.0:
			caiman_hurt_time += delta
			if caiman_hurt_time >= CAIMAN_HURT_LENGTH: caiman_hurt_time = -1.0
		if walking != caiman_was_walking:
			caiman_was_walking = walking
			caiman_loop_time = 0.0
		caiman_loop_time += delta
		if caiman_death_time < 0.0 and caiman_bite_frame() < AncientCaiman.BITE_CONTACT_FRAME and absf(facing.x) > 0.2:
			caiman_flipped = facing.x > 0.0
	queue_redraw()

func _height() -> float:
	if kind == 8: return 39.0
	if kind == 9: return float(TOAD_ANCHOR.y - 1)
	if kind == 10: return float((WRAITH.idle[2] as Vector2i).y - 1)
	if kind == 11: return float((CAIMAN.idle[2] as Vector2i).y - 1)
	return 60.0

# Quadro atual da Cuspida Tóxica (0 = parado) e lado: a arte cospe para a esquerda.
func toad_frame() -> int:
	var actor := get_parent()
	return SwampEnemy.spit_frame(float(actor.get("spit_time"))) if actor is SwampEnemy else 0

func _toad_flipped() -> bool:
	var actor := get_parent()
	if actor is SwampEnemy and (actor as SwampEnemy).spit_time >= 0.0: return (actor as SwampEnemy).spit_flipped
	return facing.x > 0.2

# Quadro de movimento (-1 = sem movimento): o salto rápido segue o próprio progresso; a
# caminhada repete o ciclo. A Cuspida em andamento tem prioridade sobre o movimento.
func toad_move_frame() -> int:
	var actor := get_parent() as SwampEnemy
	if actor == null or actor.spit_time >= 0.0: return -1
	if actor.hop_left > 0.0:
		toad_hop_total = maxf(toad_hop_total, actor.hop_left)
		return mini(TOAD_MOVE_FRAMES - 1, int((1.0 - actor.hop_left / toad_hop_total) * TOAD_MOVE_FRAMES))
	toad_hop_total = 0.0
	if not walking: return -1
	return int(toad_move_time / TOAD_MOVE_STEP) % TOAD_MOVE_FRAMES

func _draw_toad(tint: Color) -> void:
	var frame := toad_frame()
	var hurt := toad_hurt_frame()
	var move := toad_move_frame()
	if _toad_flipped(): draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	# Prioridade: dano (menos no quadro do disparo, que mostra a esfera no instante em que
	# o projétil real sai) > Cuspida > movimento > parado.
	if hurt >= 0 and frame != SwampEnemy.SPIT_SHOT_FRAME:
		draw_texture_rect_region(TOAD_HURT_SHEET, Rect2(-Vector2(TOAD_HURT_ANCHOR), Vector2(TOAD_HURT_CELL)), Rect2(hurt * TOAD_HURT_CELL.x, 0, TOAD_HURT_CELL.x, TOAD_HURT_CELL.y), tint)
	elif move >= 0:
		draw_texture_rect_region(TOAD_MOVE_SHEET, Rect2(-Vector2(TOAD_MOVE_ANCHOR), Vector2(TOAD_MOVE_CELL)), Rect2(move * TOAD_MOVE_CELL.x, 0, TOAD_MOVE_CELL.x, TOAD_MOVE_CELL.y), tint)
	else:
		draw_texture_rect_region(TOAD_SHEET, Rect2(-Vector2(TOAD_ANCHOR), Vector2(TOAD_CELL)), Rect2(frame * TOAD_CELL.x, 0, TOAD_CELL.x, TOAD_CELL.y), tint)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	var height := _height()
	var width := 52.0 if kind == 8 else (TOAD_WIDTH if kind == 9 else (WRAITH_WIDTH if kind == 10 else CAIMAN_WIDTH))
	_draw_telegraph()
	# Sombra no chão sob o corpo.
	draw_set_transform(Vector2(0, -2), 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, width * 0.42, Color(0.04, 0.08, 0.05, 0.38))
	draw_set_transform(Vector2.ZERO)
	var tint := Color(1.8, 1.8, 1.4) if flash_left > 0.0 else (Color(1.25, 0.9, 0.82) if fury else Color.WHITE)
	if kind == 9:
		_draw_toad(tint)
	elif kind == 10:
		_draw_wraith(tint)
	elif kind == 11:
		_draw_caiman(tint)
	var top := -height - 6.0
	if warning:
		px(-11, top - 18, 22, 5, Color("#f4b942"))
		px(-2, top - 26, 4, 7, Color("#ffe39a"))
	if targeted:
		var marker := Color("#c9f4e5")
		draw_colored_polygon(PackedVector2Array([Vector2(0, top - 4), Vector2(-6, top - 12), Vector2(6, top - 12)]), marker)
	var bar := clampf(width * 0.5, 34.0, 90.0)
	px(-bar * 0.5 - 1, top, bar + 2, 5, LINE)
	px(-bar * 0.5, top + 1, bar * hp_ratio, 3, Color("#8ce395") if kind != 11 else Color("#e8c45a"))
	if kind == 11:
		draw_string(ThemeDB.fallback_font, Vector2(-44, top - 6), "JACARÉ ANCIÃO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#f0dfa8"))
	_draw_hit_feedback(top - 10.0)

# Avisos no chão antes dos golpes fortes (Jacaré e ataque do Limo).
func _draw_telegraph() -> void:
	if telegraph.is_empty(): return
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.018)
	var fill := Color(0.95, 0.55, 0.20, 0.20 + 0.12 * pulse)
	var edge := Color(1.0, 0.78, 0.36, 0.9)
	match telegraph:
		"mordida":
			var points := PackedVector2Array([Vector2.ZERO])
			for i in range(9):
				points.append(telegraph_direction.rotated(-0.6 + i * 0.15) * telegraph_radius)
			draw_colored_polygon(points, fill)
			draw_polyline(points + PackedVector2Array([Vector2.ZERO]), edge, 2.0)
		"investida":
			var side := Vector2(-telegraph_direction.y, telegraph_direction.x) * 24.0
			var end := telegraph_direction * telegraph_radius
			var lane := PackedVector2Array([side, end + side, end - side, -side])
			draw_colored_polygon(lane, fill)
			draw_polyline(lane + PackedVector2Array([side]), edge, 2.0)
		"cauda", "lodo":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.62))
			draw_circle(Vector2.ZERO, telegraph_radius, fill)
			draw_arc(Vector2.ZERO, telegraph_radius, 0.0, TAU, 40, edge, 2.0)
			draw_set_transform(Vector2.ZERO)
