class_name ActorView
extends Node2D

# Small hand-authored frames; visual state is independent of hitboxes/gameplay.
const ATLAS := preload("res://assets/art/actor_atlas.png")
const EXPLORER_ATLAS := preload("res://assets/art/explorer_atlas.png")
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
var idle_frame: int = 0
var walk_distance := 0.0
var settle_left := 0.0
var last_visual_position := Vector2.ZERO
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

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	last_visual_position = global_position

func set_facing(value: Vector2) -> void:
	if not value.is_zero_approx() and not facing.is_equal_approx(value):
		facing = value.normalized()
		queue_redraw()

func set_moving(value: bool) -> void:
	if walking != value:
		var previous_frame := anim_frame
		walking = value
		if appearance == 0:
			anim_frame = 0 if value or previous_frame < 2 else 2
			settle_left = 0.0 if value else 0.08
			idle_frame = 0
			walk_distance = 0.0
			anim_time = 0.0
			last_visual_position = global_position
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
	if appearance == 0:
		if walking:
			# A planted stride follows travel rather than the display frame rate.
			walk_distance += minf(global_position.distance_to(last_visual_position), 24.0)
			if walk_distance >= 12.0:
				walk_distance = fmod(walk_distance, 12.0)
				anim_frame = (anim_frame + 1) % 4
				queue_redraw()
		else:
			if settle_left > 0.0:
				settle_left = maxf(0.0, settle_left - delta)
				if settle_left == 0.0:
					queue_redraw()
			anim_time += delta
			if anim_time >= 0.65:
				anim_time = 0.0
				idle_frame = 1 - idle_frame
				queue_redraw()
		last_visual_position = global_position
	else:
		anim_time += delta
		if anim_time >= (0.14 if walking else 0.55):
			anim_time = 0.0
			anim_frame = (anim_frame + 1) % 4
			queue_redraw()

func _explorer_direction() -> int:
	if absf(facing.x) > absf(facing.y):
		return 2 if facing.x < 0.0 else 3
	return 1 if facing.y < 0.0 else 0

func px(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(x, y, w, h), color)

func _draw() -> void:
	if elite:
		draw_rect(Rect2(-22, -36, 44, 3), Color("#e5b968"))
		draw_string(ThemeDB.fallback_font, Vector2(-15, -42), "ELITE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e5b968"))
	if fury:
		for i in range(8):
			var mote := (Vector2.RIGHT.rotated((i + anim_frame * 0.15) * TAU / 8.0) * 24.0).floor()
			px(mote.x, mote.y, 3, 3, Color("#e7a15b"))
	if skill_left > 0.0:
		if skill_effect == 0:
			var radius := 21.0 + (0.28 - skill_left) * 245.0
			for i in range(16):
				var spark := (Vector2.RIGHT.rotated(i * TAU / 16.0) * radius).floor()
				px(spark.x, spark.y, 5, 3, Color("#f7d47c") if i % 2 else Color("#e4a95e"))
		else:
			if skill_effect == 1:
				for i in range(3):
					var mark := (-facing * (20 + i * 10)).floor()
					px(mark.x - 3, mark.y - 3, 6 - i, 6 - i, Color("#f28d61") if i % 2 else Color("#f6c57a"))
			else:
				for i in range(8):
					var mark := (Vector2.RIGHT.rotated(i * TAU / 8) * (30 + (0.28 - skill_left) * 50)).floor()
					px(mark.x - 2, mark.y - 2, 4, 4, Color("#f7d47c"))
	var step: float = -2.0 if walking and anim_frame % 2 == 0 else 0.0
	px(-15, 13, 30, 5, Color(0.02, 0.08, 0.06, 0.40))
	var tint := Color("#ffdbc0") if flash_left > 0.0 else Color.WHITE
	if appearance == 0:
		var column := anim_frame + 2 if walking or settle_left > 0.0 else idle_frame
		draw_texture_rect_region(EXPLORER_ATLAS, Rect2(-24, -32, 48, 48), Rect2(column * 48, _explorer_direction() * 48, 48, 48), tint)
	else:
		var frame := anim_frame if walking else 0
		draw_texture_rect_region(ATLAS, Rect2(-24, -32 + step, 48, 48), Rect2(frame * 48, appearance * 48, 48, 48), tint)
	if elite:
		# Ochre mantle, bright crest and eye tint distinguish elite enemies at a glance.
		px(-16, -24 + step, 7, 5, Color("#bd844b"))
		px(9, -24 + step, 7, 5, Color("#bd844b"))
		px(-8, -27 + step, 16, 3, Color("#e5b968"))
		px(-3, -32 + step, 6, 5, Color("#cf6c48"))
	if attack_left > 0.0 and appearance == 0:
		var side: float = -1.0 if facing.x < -0.3 else 1.0
		px(side * 15.0 - 3.0, -22.0, 5, 31, Color("#fce7a1"))
		px(side * 20.0 - 3.0, -17.0, 4, 22, LIGHT)
	if warning:
		px(-11, -39, 22, 5, Color("#f4b942"))
		px(-2, -47, 4, 7, Color("#ffe39a"))
	if flash_left > 0.0:
		for i in range(4):
			var p := Vector2(-19 + i * 11, -24 + (i % 2) * 26)
			px(p.x, p.y, 3, 3, Color("#ffe6aa", flash_left / 0.14))
	if attack_left > 0.0:
		for i in range(7):
			var slash := (Vector2.RIGHT.rotated(facing.angle() - 0.9 + i * 0.26) * 27.0).floor()
			px(slash.x, slash.y, 5, 3, Color("#f7d47c"))
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
	if appearance != 0:
		px(-17, -30, 34, 4, LINE)
		px(-16, -29, 32.0 * hp_ratio, 2, Color("#8ce395"))

