class_name ActorView
extends Node2D

# Procedural pixel-style actors: temporary art, independent of hitboxes/gameplay.
@export_enum("Aventureiro", "Javali", "Aranha", "Mandacaru") var appearance: int = 0
var facing := Vector2.DOWN
var hp_ratio: float = 1.0
var flash_left: float = 0.0
var attack_left: float = 0.0
var damage_left: float = 0.0
var damage_amount: int = 0
var defeat_left: float = 0.0
var warning: bool = false
var walking: bool = false
var anim_time: float = 0.0
var anim_frame: int = 0
var skill_left := 0.0
var skill_effect := 0
var fury := false
var elite := false

func play_skill(index: int) -> void:
	skill_effect = index
	skill_left = 0.28
	queue_redraw()

func set_fury(value: bool) -> void:
	if fury != value:
		fury = value
		queue_redraw()

const LINE := Color("#172822")
const PALE := Color("#f1d5a2")
const LIGHT := Color("#e7f4d7")

func set_facing(value: Vector2) -> void:
	if not value.is_zero_approx() and not facing.is_equal_approx(value):
		facing = value.normalized()
		queue_redraw()

func set_moving(value: bool) -> void:
	if walking != value:
		walking = value
		queue_redraw()

func set_health(current: int, maximum: int) -> void:
	hp_ratio = clampf(float(current) / maxf(1.0, float(maximum)), 0.0, 1.0)
	queue_redraw()

func flash() -> void:
	flash_left = 0.14
	queue_redraw()

func show_damage(amount: int) -> void:
	if amount <= 0:
		return
	damage_amount = amount
	damage_left = 0.85
	flash()

func play_attack() -> void:
	attack_left = 0.24
	queue_redraw()

func play_defeat() -> void:
	defeat_left = 0.22
	set_moving(false)
	queue_redraw()

func set_warning(value: bool) -> void:
	if warning != value:
		warning = value
		queue_redraw()

func _process(delta: float) -> void:
	if skill_left > 0.0:
		skill_left = maxf(0.0, skill_left - delta)
		queue_redraw()
	if flash_left > 0.0:
		flash_left = maxf(0.0, flash_left - delta)
		queue_redraw()
	if attack_left > 0.0:
		attack_left = maxf(0.0, attack_left - delta)
		queue_redraw()
	if damage_left > 0.0:
		damage_left = maxf(0.0, damage_left - delta)
		queue_redraw()
	if defeat_left > 0.0:
		defeat_left = maxf(0.0, defeat_left - delta)
		modulate = Color(1.0, 1.0, 1.0, maxf(0.0, defeat_left / 0.22))
		queue_redraw()
	anim_time += delta
	if anim_time >= (0.14 if walking else 0.55):
		anim_time = 0.0
		anim_frame = (anim_frame + 1) % 4
		queue_redraw()

func px(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(x, y, w, h), color)

func _draw() -> void:
	if elite:
		draw_rect(Rect2(-22, -36, 44, 3), Color("#e5b968"))
		draw_string(ThemeDB.fallback_font, Vector2(-15, -42), "ELITE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e5b968"))
	if fury:
		draw_arc(Vector2.ZERO, 24, 0, TAU, 12, Color("#e7a15b"), 3)
	if skill_left > 0.0:
		if skill_effect == 0:
			draw_arc(Vector2.ZERO, 90 * (1.0 - skill_left / 0.4), 0, TAU, 20, Color("#f7d47c"), 4)
		else:
			if skill_effect == 1:
				for i in range(3):
					var mark := (-facing * (20 + i * 10)).floor()
					draw_rect(Rect2(mark - Vector2(3, 3), Vector2(6, 6)), Color("#f28d61"))
			else:
				for i in range(8):
					var mark := (Vector2.RIGHT.rotated(i * TAU / 8) * (30 + (0.28 - skill_left) * 50)).floor()
					draw_rect(Rect2(mark - Vector2(2, 2), Vector2(4, 4)), Color("#f7d47c"))
	var step: float = -2.0 if walking and anim_frame % 2 == 0 else 0.0
	px(-15, 13, 30, 5, Color(0.02, 0.08, 0.06, 0.40))
	match appearance:
		0: _draw_adventurer(step)
		1: _draw_boar(step)
		2: _draw_spider(step)
		3: _draw_cactus(step)
	if attack_left > 0.0 and appearance == 0:
		var side: float = -1.0 if facing.x < -0.3 else 1.0
		px(side * 15.0 - 3.0, -22.0, 5, 31, Color("#fce7a1"))
		px(side * 20.0 - 3.0, -17.0, 4, 22, LIGHT)
	if warning:
		px(-11, -39, 22, 5, Color("#f4b942"))
		px(-2, -47, 4, 7, Color("#ffe39a"))
	if flash_left > 0.0:
		px(-15, -22, 30, 37, Color(1.0, 1.0, 1.0, flash_left * 2.5))
	if attack_left > 0.0:
		var attack_color := Color("#f7d47c")
		draw_arc(Vector2.ZERO, 27.0, facing.angle() - 0.9, facing.angle() + 0.7, 10, attack_color, 4.0)
	if damage_left > 0.0:
		var float_y := -42.0 - (0.85 - damage_left) * 24.0
		var number := "-%d" % damage_amount
		draw_string(ThemeDB.fallback_font, Vector2(-10, float_y + 1), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.08, 0.12, 0.11, damage_left / 0.85))
		draw_string(ThemeDB.fallback_font, Vector2(-11, float_y), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffcf85", damage_left / 0.85))
	if defeat_left > 0.0:
		var drift := (0.22 - defeat_left) * 22.0
		for side in [-1, 1]:
			px(side * (10 + drift), -13 - drift, 6, 6, Color("#d0aa71"))
			px(side * (8 + drift), 3 + drift, 4, 4, Color("#685641"))
	px(-17, -30, 34, 4, LINE)
	px(-16, -29, 32.0 * hp_ratio, 2, Color("#8ce395"))

func _draw_adventurer(b: float) -> void:
	# Boots / gait animation, cloak, hair, face and short sword.
	var swing: float = 3.0 if walking and anim_frame % 2 == 0 else -3.0 if walking else 0.0
	px(-11, 6 + b, 9, 9 + swing * 0.3, LINE)
	px(2, 6 + b, 9, 9 - swing * 0.3, LINE)
	px(-9, 6 + b, 5, 7, Color("#70543d"))
	px(4, 6 + b, 5, 7, Color("#70543d"))
	px(-13, -10 + b, 26, 19, LINE)
	px(-10, -9 + b, 20, 16, Color("#307ba0"))
	px(-7, 1 + b, 14, 5, Color("#b7a06a"))
	px(-15, -7 + b + swing * 0.5, 6, 12, PALE)
	px(9, -7 + b - swing * 0.5, 6, 12, PALE)
	px(-10, -24 + b, 20, 17, LINE)
	px(-8, -20 + b, 16, 13, Color("#e6b989"))
	px(-10, -24 + b, 20, 7, Color("#41372f"))
	px(-5, -13 + b, 3, 3, LINE)
	px(4, -13 + b, 3, 3, LINE)
	var side: float = -1.0 if facing.x < -0.3 else 1.0
	px(side * 14.0 - 2.0, -5 + b, 4, 19, Color("#d5e1d9"))
	px(side * 12.0 - 3.0, 4 + b, 8, 3, Color("#aa8b51"))

func _draw_boar(b: float) -> void:
	var stride: float = 2.0 if walking and anim_frame % 2 == 0 else 0.0
	px(-14, 8, 9, 8 - stride, LINE)
	px(6, 8, 9, 8 + stride, LINE)
	px(-17, -11 + b, 34, 24, LINE)
	px(-15, -9 + b, 30, 20, Color("#8e4d32"))
	px(-15, -8 + b, 9, 16, Color("#a76339"))
	px(8, -8 + b, 9, 16, Color("#a76339"))
	px(-18, -17 + b, 9, 8, LINE)
	px(9, -17 + b, 9, 8, LINE)
	px(-8, -5 + b, 16, 13, Color("#bd7547"))
	px(-5, 1 + b, 10, 6, Color("#6b392b"))
	px(-12, -5 + b, 4, 4, PALE)
	px(8, -5 + b, 4, 4, PALE)
	px(-10, -10 + b, 4, 4, Color("#fcdb84"))
	px(6, -10 + b, 4, 4, Color("#fcdb84"))

func _draw_spider(b: float) -> void:
	var stride: float = 4.0 if walking and anim_frame % 2 == 0 else -2.0 if walking else 0.0
	for side in [-1, 1]:
		for leg in range(4):
			var yy: float = -13.0 + float(leg) * 8.0
			px(float(side * 15) - 3, yy + b, 7, 4, LINE)
			px(float(side * 19) - 3, yy + b + stride * (1.0 if leg % 2 == 0 else -1.0), 5, 9, Color("#5b456f"))
	px(-12, -13 + b, 24, 24, LINE)
	px(-9, -11 + b, 18, 19, Color("#674b78"))
	px(-7, -20 + b, 14, 12, LINE)
	px(-5, -18 + b, 10, 8, Color("#9979a1"))
	px(-6, -12 + b, 5, 4, Color("#ffe086"))
	px(2, -12 + b, 5, 4, Color("#ffe086"))
	px(-4, 1 + b, 8, 4, Color("#a98ab7"))

func _draw_cactus(b: float) -> void:
	px(-12, 9, 9, 7, LINE)
	px(3, 9, 9, 7, LINE)
	px(-10, 8, 20, 7, Color("#426c3e"))
	px(-13, -14 + b, 26, 25, LINE)
	px(-10, -12 + b, 20, 22, Color("#4e965e"))
	px(-6, -12 + b, 4, 19, Color("#6db777"))
	px(5, -12 + b, 3, 19, Color("#37794c"))
	px(-18, -6 + b, 8, 17, LINE)
	px(-16, -4 + b, 6, 12, Color("#4e965e"))
	px(10, -14 + b, 8, 18, LINE)
	px(10, -12 + b, 6, 14, Color("#6db777"))
	px(-5, -21 + b, 10, 9, Color("#f5b66b"))
	px(-2, -25 + b, 4, 7, Color("#ffdb76"))
	px(-8, -4 + b, 3, 3, LINE)
	px(5, -4 + b, 3, 3, LINE)
	px(-2, 4 + b, 5, 3, Color("#204d38"))

