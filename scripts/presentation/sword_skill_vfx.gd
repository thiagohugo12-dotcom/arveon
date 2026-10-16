class_name SwordSkillVfx
extends Node2D

# Presentation only: no hitboxes, damage, random rolls, or new timers in saves.
# The legacy "danca_laminas" internal ID is intentionally retained for Kamusari.
const GUARDA := "guarda_reativa"
const ESTOCADA := "estocada_precisa"
const KAMUSARI := "danca_laminas"
const BLUE := Color(0.24, 0.68, 1.0)
const BLUE_WHITE := Color(0.78, 0.94, 1.0)
const RED := Color(0.96, 0.13, 0.19)
const RED_WHITE := Color(1.0, 0.81, 0.76)

var active_id := ""
var direction := Vector2.RIGHT
var reach := 155.0
var half_width := 22.0
var remaining := 0.0
var duration := 0.0
var guard_left := 0.0
var guard_impact_left := 0.0
var activations := 0

func _ready() -> void:
	top_level = true
	z_as_relative = false

func play_skill(id: String, facing: Vector2, geometry: Dictionary, guard_seconds: float = 0.0) -> void:
	if id not in [GUARDA, ESTOCADA, KAMUSARI]:
		return
	direction = Vector2.RIGHT if facing.is_zero_approx() else facing.normalized()
	reach = float(geometry.get("reach", 155.0))
	half_width = float(geometry.get("width", 22.0))
	if get_parent() is Node2D:
		global_position = (get_parent() as Node2D).global_position
	z_index = clampi(roundi(global_position.y) + 102, -4096, 4096)
	activations += 1
	if id == GUARDA:
		guard_left = maxf(0.0, guard_seconds)
		guard_impact_left = 0.0
	else:
		active_id = id
		duration = 0.38 if id == ESTOCADA else 0.60
		remaining = duration
	queue_redraw()

func guard_impact() -> void:
	if guard_left <= 0.0:
		return
	guard_impact_left = 0.22
	queue_redraw()

func clear() -> void:
	if active_id.is_empty() and remaining <= 0.0 and guard_left <= 0.0 and guard_impact_left <= 0.0:
		return
	active_id = ""
	remaining = 0.0
	guard_left = 0.0
	guard_impact_left = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if remaining <= 0.0 and guard_left <= 0.0 and guard_impact_left <= 0.0:
		return
	remaining = maxf(0.0, remaining - delta)
	guard_left = maxf(0.0, guard_left - delta)
	guard_impact_left = maxf(0.0, guard_impact_left - delta)
	if remaining <= 0.0:
		active_id = ""
		# The active guard follows the hero, rather than remaining at cast origin.
		if guard_left > 0.0 and get_parent() is Node2D:
			global_position = (get_parent() as Node2D).global_position
			z_index = clampi(roundi(global_position.y) + 102, -4096, 4096)
	queue_redraw()

func _draw() -> void:
	if guard_left > 0.0:
		_draw_guard()
	if remaining <= 0.0:
		return
	var progress := clampf(1.0 - remaining / maxf(0.01, duration), 0.0, 1.0)
	if active_id == ESTOCADA:
		_draw_estocada(progress)
	elif active_id == KAMUSARI:
		_draw_kamusari(progress)

func _draw_guard() -> void:
	var fade := minf(1.0, guard_left * 4.0)
	var pulse := 0.70 + guard_impact_left * 1.2
	for segment in range(18):
		var angle := TAU * float(segment) / 18.0
		var a := (Vector2.RIGHT.rotated(angle) * 34.0).round()
		var b := (Vector2.RIGHT.rotated(angle + TAU / 26.0) * 34.0).round()
		draw_line(a, b, Color(BLUE.r, BLUE.g, BLUE.b, 0.66 * fade * pulse), 3.0, false)
		if segment % 3 == 0:
			draw_rect(Rect2((Vector2.RIGHT.rotated(angle) * 39.0).round(), Vector2(3, 3)), Color(BLUE_WHITE.r, BLUE_WHITE.g, BLUE_WHITE.b, 0.65 * fade))
	if guard_impact_left > 0.0:
		var shine := guard_impact_left / 0.22
		for index in range(7):
			var angle := -PI / 2.0 + float(index) * PI / 6.0
			var axis := direction.rotated(angle)
			draw_line((axis * 32.0).round(), (axis * (37.0 + shine * 14.0)).round(), Color(BLUE_WHITE.r, BLUE_WHITE.g, BLUE_WHITE.b, shine), 3.0, false)

func _draw_estocada(progress: float) -> void:
	var opacity := clampf(remaining / 0.16, 0.0, 1.0)
	var side := direction.orthogonal()
	var head := direction * lerpf(46.0, reach, minf(1.0, progress * 1.8))
	var tail := direction * 16.0
	draw_line(tail.round(), head.round(), Color(BLUE.r, BLUE.g, BLUE.b, 0.34 * opacity), 13.0, false)
	draw_line(tail.round(), head.round(), Color(BLUE_WHITE.r, BLUE_WHITE.g, BLUE_WHITE.b, 0.96 * opacity), 5.0, false)
	var tip := PackedVector2Array([
		(head + direction * 15.0).round(),
		(head - direction * 16.0 + side * half_width).round(),
		(head - direction * 10.0).round(),
		(head - direction * 16.0 - side * half_width).round()
	])
	draw_colored_polygon(tip, Color(BLUE.r, BLUE.g, BLUE.b, 0.85 * opacity))
	for streak in [-1.0, 1.0]:
		var offset: Vector2 = side * float(streak) * (11.0 + progress * 8.0)
		draw_line((tail + offset - direction * 10.0).round(), (head - direction * 24.0 + offset).round(), Color(BLUE.r, BLUE.g, BLUE.b, 0.54 * opacity), 2.0, false)

func _draw_kamusari(progress: float) -> void:
	var opacity := clampf(remaining / 0.18, 0.0, 1.0)
	var side := direction.orthogonal()
	var head := direction * lerpf(58.0, reach, minf(1.0, progress * 1.8))
	var tail := direction * maxf(20.0, head.length() - 156.0)
	var spread := lerpf(20.0, 78.0, minf(1.0, progress * 2.3))
	var outer := PackedVector2Array([
		(tail + side * 8.0).round(),
		(head - direction * 22.0 + side * spread).round(),
		(head + direction * 14.0).round(),
		(head - direction * 22.0 - side * spread).round(),
		(tail - side * 8.0).round()
	])
	draw_colored_polygon(outer, Color(RED.r, RED.g, RED.b, 0.76 * opacity))
	var core := PackedVector2Array([
		(tail + side * 3.0).round(),
		(head - direction * 14.0 + side * spread * 0.44).round(),
		(head + direction * 12.0).round(),
		(head - direction * 14.0 - side * spread * 0.44).round(),
		(tail - side * 3.0).round()
	])
	draw_colored_polygon(core, Color(RED_WHITE.r, RED_WHITE.g, RED_WHITE.b, 0.92 * opacity))
	for index in range(6):
		var side_sign := -1.0 if index % 2 == 0 else 1.0
		var offset := side * side_sign * (15.0 + float(index) * 9.0)
		var start := head - direction * (45.0 + float(index) * 22.0)
		draw_line((start + offset).round(), (start - direction * (22.0 + float(index) * 4.0) + offset * 1.24).round(), Color(RED.r, RED.g, RED.b, opacity * 0.75), 3.0, false)
