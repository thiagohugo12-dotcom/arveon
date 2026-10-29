class_name Floor3MonsterView
extends ActorView

# Criaturas do Pântano com a arte oficial do pacote do Andar 3. O Limo do Brejo usa as
# duas folhas aprovadas (respiração 4 quadros e ataque 6 quadros) num AnimatedSprite2D;
# Sapo, Vulto e Jacaré usam a arte estática aprovada. A jogabilidade fica no ator:
# esta vista só avisa o quadro de impacto do ataque do Limo e o fim da animação.
signal impact
signal attack_finished

const IDLE_SHEET := preload("res://assets/art/andar3/monsters/limo_idle.png")
const ATTACK_SHEET := preload("res://assets/art/andar3/monsters/limo_ataque.png")
const ART := {
	9: preload("res://assets/art/andar3/monsters/sapo_venenoso.png"),
	10: preload("res://assets/art/andar3/monsters/vulto_do_brejo.png"),
	11: preload("res://assets/art/andar3/monsters/jacare_anciao.png")}
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

func _process(delta: float) -> void:
	super._process(delta)
	if telegraph_left > 0.0:
		telegraph_left -= delta
		if telegraph_left <= 0.0: telegraph = ""
	if dying_left > 0.0:
		dying_left = maxf(0.0, dying_left - delta)
		modulate.a = dying_left / 0.7
	if slime != null:
		slime.modulate = Color(1.8, 1.8, 1.4) if flash_left > 0.0 else Color.WHITE
	queue_redraw()

func _height() -> float:
	if kind == 8: return 39.0
	var texture: Texture2D = ART.get(kind)
	return float(texture.get_height()) if texture != null else 60.0

func _draw() -> void:
	var height := _height()
	var width := 52.0 if kind == 8 else float((ART[kind] as Texture2D).get_width())
	_draw_telegraph()
	# Sombra no chão sob o corpo.
	draw_set_transform(Vector2(0, -2), 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, width * 0.42, Color(0.04, 0.08, 0.05, 0.38))
	draw_set_transform(Vector2.ZERO)
	if kind != 8:
		var texture: Texture2D = ART[kind]
		var tint := Color(1.8, 1.8, 1.4) if flash_left > 0.0 else (Color(1.25, 0.9, 0.82) if fury else Color.WHITE)
		var flip := facing.x < -0.2
		if flip: draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
		draw_texture(texture, Vector2(-floorf(texture.get_width() * 0.5), -texture.get_height() + 4), tint)
		if flip: draw_set_transform(Vector2.ZERO)
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
