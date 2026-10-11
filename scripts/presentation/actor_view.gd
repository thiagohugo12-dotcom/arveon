class_name ActorView
extends Node2D

# Small hand-authored frames; visual state is independent of hitboxes/gameplay.
const ATLAS := preload("res://assets/art/actor_atlas.png")
const EXPLORER_ATLAS := preload("res://assets/art/explorer_atlas.png")
# Approved image assets, not replacement geometry drawn procedurally.
const MONSTERS_APPROVED := preload("res://assets/art/monsters_approved.png")
const WALK_PIXELS_PER_FRAME := 16.0 # 11.25 frames/s at the unchanged 180 px/s.
@export_enum("Aventureiro", "Javali", "Aranha", "Mandacaru") var appearance: int = 0
var facing := Vector2.DOWN
var hp_ratio: float = 1.0
var flash_left: float = 0.0
var attack_left: float = 0.0
var attack_direction := Vector2.DOWN
var attack_distance := 27.0
var damage_left: float = 0.0
var damage_amount: int = 0
var previous_damage_left := 0.0
var previous_damage_amount := 0
var impact_left := 0.0
const IMPACT_DURATION := 0.12
const DAMAGE_DURATION := 0.85
var damage_occluders: Array[Rect2] = [] # Shared HUD rectangles, updated only on layout.
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
	# Two bounded labels retain closely spaced basic/skill hits without spawning nodes.
	previous_damage_amount = damage_amount
	previous_damage_left = damage_left
	damage_amount = amount
	damage_left = DAMAGE_DURATION
	impact_left = IMPACT_DURATION
	flash()

func play_attack(target_offset := Vector2.ZERO) -> void:
	attack_direction = facing if target_offset.is_zero_approx() else target_offset.normalized()
	attack_distance = 27.0 if target_offset.is_zero_approx() else target_offset.length()
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
	if previous_damage_left > 0.0:
		previous_damage_left = maxf(0.0, previous_damage_left - delta)
		queue_redraw()
	if impact_left > 0.0:
		impact_left = maxf(0.0, impact_left - delta)
		queue_redraw()
	if defeat_left > 0.0:
		defeat_left = maxf(0.0, defeat_left - delta)
		modulate = Color(1.0, 1.0, 1.0, maxf(0.0, defeat_left / 0.22))
		queue_redraw()
	if appearance == 0:
		if walking:
			# A planted stride follows travel rather than the display frame rate.
			walk_distance += minf(global_position.distance_to(last_visual_position), 24.0)
			if walk_distance >= WALK_PIXELS_PER_FRAME:
				var advanced := int(walk_distance / WALK_PIXELS_PER_FRAME)
				walk_distance = fmod(walk_distance, WALK_PIXELS_PER_FRAME)
				anim_frame = (anim_frame + advanced) % 4
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
		var elite_y := -54.0 if appearance == 3 else -45.0 if appearance != 0 else -36.0
		draw_rect(Rect2(-22,elite_y,44,3),Color("#e5b968"))
		draw_string(ThemeDB.fallback_font,Vector2(-15,elite_y-6),"ELITE",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#e5b968"))
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
	# Values above one brighten the existing sprite; the old <=1 tint darkened it.
	var tint := Color(2.0, 1.75, 1.35) if flash_left > 0.0 else Color.WHITE
	if appearance == 0:
		# Held passing pose uses the approved appearance even when stopped.
		var column := anim_frame + 2 if walking or settle_left > 0.0 else 0
		draw_texture_rect_region(EXPLORER_ATLAS, Rect2(-24, -32, 48, 48), Rect2(column * 48, _explorer_direction() * 48, 48, 48), tint)
	else:
		var frame := anim_frame if walking else 0
		_draw_monster(frame, step)
	if elite:
		# Ochre mantle, bright crest and eye tint distinguish elite enemies at a glance.
		px(-16, -24 + step, 7, 5, Color("#bd844b"))
		px(9, -24 + step, 7, 5, Color("#bd844b"))
		px(-8, -27 + step, 16, 3, Color("#e5b968"))
		px(-3, -32 + step, 6, 5, Color("#cf6c48"))
	if warning:
		var warning_y := -57.0 if appearance == 3 else -48.0 if appearance != 0 else -39.0
		px(-11,warning_y,22,5,Color("#f4b942"))
		px(-2,warning_y-8,4,7,Color("#ffe39a"))
	if flash_left > 0.0:
		for i in range(4):
			var p := Vector2(-19 + i * 11, -24 + (i % 2) * 26)
			px(p.x, p.y, 3, 3, Color("#ffe6aa", flash_left / 0.14))
	if attack_left > 0.0:
		_draw_strike()
	_draw_hit_feedback()
	if defeat_left > 0.0:
		var drift := (0.22 - defeat_left) * 22.0
		for side in [-1, 1]:
			px(side * (10 + drift), -13 - drift, 6, 6, Color("#d0aa71"))
			px(side * (8 + drift), 3 + drift, 4, 4, Color("#685641"))
	if appearance != 0:
		var bar_y := -46.0 if appearance == 3 else -37.0
		px(-17,bar_y,34,4,LINE)
		px(-16,bar_y+1,32.0*hp_ratio,2,Color("#8ce395"))


func _monster_tone(value: String) -> Color:
	var color := Color(value)
	return color.lightened(0.52) if flash_left > 0.0 else color

func _monster_rect(area: Rect2, value: String, step: float) -> void:
	draw_rect(Rect2(area.position + Vector2(0,step),area.size),_monster_tone(value))

func _monster_poly(points: Array[Vector2], value: String, step: float) -> void:
	var shifted := PackedVector2Array()
	for point in points:
		shifted.append(point + Vector2(0,step))
	draw_colored_polygon(shifted,_monster_tone(value))

func _draw_monster(_frame: int, step: float) -> void:
	# Sprite index 0=boar, 1=spider, 2=mandacaru. Feet remain at actor origin.
	var sprite_index := appearance - 1
	if sprite_index < 0 or sprite_index >= 3:
		return
	var source := Rect2(sprite_index * 64, 0, 64, 64)
	var destination := Rect2(-32, -48 + step, 64, 64)
	var hit_tint := Color(1.8, 1.8, 1.35) if flash_left > 0.0 else Color.WHITE
	draw_texture_rect_region(MONSTERS_APPROVED, destination, source, hit_tint)

func _draw_boar(frame: int, step: float) -> void:
	# Low body, large snout and paired tusks read immediately as a boar.
	var hoof_shift := 2.0 if frame % 2 else 0.0
	_monster_rect(Rect2(-16,2+hoof_shift,7,9),"#352a25",step)
	_monster_rect(Rect2(9,2+(0.0 if hoof_shift else 2.0),7,9),"#352a25",step)
	_monster_poly([Vector2(-20,-12),Vector2(-17,-23),Vector2(-9,-28),Vector2(7,-28),Vector2(17,-21),Vector2(21,-9),Vector2(18,2),Vector2(12,8),Vector2(-12,8),Vector2(-19,2)],"#332820",step)
	_monster_poly([Vector2(-17,-12),Vector2(-13,-21),Vector2(-6,-24),Vector2(8,-23),Vector2(15,-17),Vector2(17,-6),Vector2(13,2),Vector2(-12,3),Vector2(-16,-4)],"#8f4f2f",step)
	_monster_poly([Vector2(-13,-18),Vector2(-7,-24),Vector2(8,-22),Vector2(13,-16),Vector2(10,-12),Vector2(-9,-12)],"#bd7440",step)
	_monster_poly([Vector2(-16,-21),Vector2(-19,-28),Vector2(-9,-25),Vector2(-8,-19)],"#5f3728",step)
	_monster_poly([Vector2(9,-21),Vector2(18,-27),Vector2(17,-18),Vector2(12,-16)],"#5f3728",step)
	_monster_rect(Rect2(-13,-10,26,14),"#d08a53",step)
	_monster_rect(Rect2(-9,-5,18,10),"#a85f43",step)
	_monster_rect(Rect2(-3,0,6,3),"#3a2927",step)
	_monster_rect(Rect2(-10,-15,4,3),"#211f1d",step)
	_monster_rect(Rect2(6,-15,4,3),"#211f1d",step)
	_monster_poly([Vector2(-13,-8),Vector2(-18,-3),Vector2(-15,3),Vector2(-10,-2)],"#f2dc9f",step)
	_monster_poly([Vector2(13,-8),Vector2(18,-3),Vector2(15,3),Vector2(10,-2)],"#f2dc9f",step)

func _draw_spider(frame: int, step: float) -> void:
	# Three grouped legs per side keep the silhouette wide without visual noise.
	var reach := 2.0 if frame % 2 else 0.0
	var leg_dark := _monster_tone("#39283f")
	var leg_mid := _monster_tone("#68405d")
	for side in [-1.0,1.0]:
		for row in range(3):
			var root := Vector2(11.0*side,-13.0+row*8.0+step)
			var knee := Vector2((19.0+reach+row)*side,-18.0+row*10.0+step)
			var foot := Vector2((23.0+reach)*side,-14.0+row*11.0+step)
			draw_line(root,knee,leg_dark,5.0)
			draw_line(knee,foot,leg_mid,4.0)
	_monster_poly([Vector2(-14,-24),Vector2(-7,-30),Vector2(8,-30),Vector2(15,-23),Vector2(14,-11),Vector2(8,-6),Vector2(-9,-6),Vector2(-15,-12)],"#34273b",step)
	_monster_poly([Vector2(-10,-23),Vector2(-5,-27),Vector2(7,-27),Vector2(11,-21),Vector2(9,-12),Vector2(-8,-12)],"#74445f",step)
	_monster_poly([Vector2(-11,-10),Vector2(-7,-16),Vector2(8,-16),Vector2(13,-9),Vector2(9,3),Vector2(-8,3)],"#4a2e4b",step)
	_monster_rect(Rect2(-7,-11,14,10),"#8f5067",step)
	for eye in [Vector2(-5,-8),Vector2(3,-8),Vector2(-2,-4)]:
		_monster_rect(Rect2(eye,Vector2(3,3)),"#ef765c",step)
	_monster_rect(Rect2(-3,-1,6,3),"#d39a73",step)

func _draw_cactus(frame: int, step: float) -> void:
	# One tall trunk, two arms and broad feet give the mandacaru a clean icon.
	var sway := 1.0 if frame == 1 else -1.0 if frame == 3 else 0.0
	_monster_rect(Rect2(-12+sway,3,9,8),"#314334",step)
	_monster_rect(Rect2(4+sway,3,9,8),"#314334",step)
	_monster_poly([Vector2(-11+sway,-25),Vector2(-7+sway,-31),Vector2(7+sway,-31),Vector2(11+sway,-25),Vector2(11+sway,4),Vector2(6+sway,9),Vector2(-6+sway,9),Vector2(-11+sway,4)],"#294c36",step)
	_monster_rect(Rect2(-7+sway,-27,14,31),"#4f8a50",step)
	_monster_rect(Rect2(-4+sway,-25,4,26),"#82ad59",step)
	_monster_poly([Vector2(-9+sway,-14),Vector2(-17+sway,-19),Vector2(-21+sway,-16),Vector2(-21+sway,-3),Vector2(-17+sway,1),Vector2(-11+sway,-2)],"#315d3d",step)
	_monster_rect(Rect2(-19+sway,-15,5,11),"#5c9852",step)
	_monster_poly([Vector2(9+sway,-19),Vector2(16+sway,-24),Vector2(21+sway,-21),Vector2(21+sway,-7),Vector2(17+sway,-3),Vector2(11+sway,-7)],"#315d3d",step)
	_monster_rect(Rect2(15+sway,-20,5,12),"#5c9852",step)
	_monster_rect(Rect2(-7+sway,-36,14,8),"#3d713f",step)
	_monster_rect(Rect2(-3+sway,-39,6,7),"#d7b954",step)
	_monster_rect(Rect2(-5+sway,-17,3,4),"#20382d",step)
	_monster_rect(Rect2(3+sway,-17,3,4),"#20382d",step)
	_monster_rect(Rect2(-3+sway,-8,6,3),"#335d3b",step)

func _draw_strike() -> void:
	var progress := clampf((0.24 - attack_left) / 0.24, 0.0, 1.0)
	var alpha := clampf(attack_left / 0.12, 0.0, 1.0)
	var centre := Vector2(0, -10)
	if appearance == 0:
		# Rotate the lightweight blade around the target direction, including up/down.
		var blade := attack_direction.rotated(lerpf(-0.65, 0.35, minf(1.0, progress * 3.0)))
		draw_line((centre + blade * 14.0).floor(), (centre + blade * 34.0).floor(), Color("#27392d", alpha), 5.0)
		draw_line((centre + blade * 17.0).floor(), (centre + blade * 33.0).floor(), Color("#fff0b9", alpha), 3.0)
		var hilt := centre + blade * 15.0
		draw_line((hilt - blade.orthogonal() * 4.0).floor(), (hilt + blade.orthogonal() * 4.0).floor(), Color("#d9a759", alpha), 3.0)
	# A brief slash connects the swing to the actual hit distance, not a 27px ring.
	var distance := maxf(20.0, attack_distance)
	var tip := centre + attack_direction * distance
	if appearance == 0 and distance > 35.0 and progress < 0.42:
		draw_line((centre + attack_direction * 30.0).floor(), tip.floor(), Color(0.96, 0.83, 0.49, alpha * 0.55), 2.0)
	for i in range(5):
		var mark := (tip + attack_direction.orthogonal() * (i - 2) * 4.0 - attack_direction * absf(i - 2) * 2.0).floor()
		px(mark.x, mark.y, 3, 3, Color("#f7d47c", alpha))

func _draw_hit_feedback(base_y := -42.0) -> void:
	if impact_left > 0.0:
		var spread := 5.0 + (1.0 - impact_left / IMPACT_DURATION) * 6.0
		var alpha := impact_left / IMPACT_DURATION
		for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			var start: Vector2 = (Vector2(0, -12) + direction * spread).floor()
			draw_line(start, (start + direction * 4.0).floor(), Color("#fff0b9", alpha), 2.0)
		px(-1, -13, 3, 3, Color("#fff6d2", alpha))
	if previous_damage_left > 0.0:
		_draw_damage_value(previous_damage_amount, previous_damage_left, Vector2(12, base_y - 17.0), true)
	if damage_left > 0.0:
		_draw_damage_value(damage_amount, damage_left, Vector2(0, base_y))

func _draw_damage_value(amount: int, remaining: float, at: Vector2, older := false) -> void:
	var number := "-%d" % amount
	var font := ThemeDB.fallback_font
	var alpha := clampf(remaining / 0.22, 0.0, 1.0)
	var color := Color("#ffae8b", alpha) if appearance == 0 else Color("#fff0bd", alpha)
	var width := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	at += Vector2(-width * 0.5, -(DAMAGE_DURATION - remaining) * 24.0)
	var readable := _readable_damage_position(at, width)
	if older and not readable.is_equal_approx(at):
		# Labels displaced by the same HUD panel must not collapse onto one line.
		readable.y += 24.0
	at = readable
	draw_string_outline(font, at.floor(), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, 4, Color("#17201c", alpha))
	draw_string(font, at.floor(), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, color)

func _readable_damage_position(at: Vector2, width: float) -> Vector2:
	if damage_occluders.is_empty():
		return at
	var canvas := get_global_transform_with_canvas()
	var bounds: Rect2 = canvas * Rect2(at - Vector2(4, 21), Vector2(width + 8, 26))
	for blocker: Rect2 in damage_occluders:
		if bounds.intersects(blocker):
			var shift := Vector2(0, blocker.end.y + 3.0 - bounds.position.y)
			at += canvas.affine_inverse().basis_xform(shift)
			bounds.position += shift
	return at

