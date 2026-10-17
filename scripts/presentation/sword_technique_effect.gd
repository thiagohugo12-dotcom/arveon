class_name SwordTechniqueEffect
extends Node2D
## Presentation only: ClassCombat owns damage, reach, cooldowns and guard timing.
const ESTOCADA: Texture2D = preload("res://assets/art/sword_techniques/estocada_precisa_fx.png")
const GUARDA: Texture2D = preload("res://assets/art/sword_techniques/guarda_reativa_fx.png")
const KAMUSARI: Texture2D = preload("res://assets/art/sword_techniques/kamusari_fx.png")
const CELL := 512.0
const ESTOCADA_FRAMES := SwordTechniqueTiming.FRAMES["estocada_precisa"]
const GUARDA_FRAMES := [0.05, 0.07, 0.0, 0.045, 0.075, 0.10]
const KAMUSARI_FRAMES := SwordTechniqueTiming.FRAMES["danca_laminas"]
# Each source pose was placed differently in its cell. Register the body at its
# feet, then normalize its height to the original 60 px explorer silhouette.
const BODY_HEIGHT := 60.0
const ESTOCADA_FEET := [Vector2(220,478), Vector2(215,478), Vector2(210,478), Vector2(175,368), Vector2(185,368), Vector2(280,368)]
const GUARDA_FEET := [Vector2(245,460), Vector2(235,460), Vector2(255,460), Vector2(225,386), Vector2(230,386), Vector2(270,386)]
const KAMUSARI_FEET := [Vector2(230,436), Vector2(225,436), Vector2(210,436), Vector2(175,388), Vector2(235,388), Vector2(270,388)]
const ESTOCADA_HEIGHTS := [254.0, 238.0, 238.0, 225.0, 225.0, 250.0]
const GUARDA_HEIGHTS := [264.0, 264.0, 264.0, 258.0, 230.0, 258.0]
const KAMUSARI_HEIGHTS := [228.0, 228.0, 185.0, 188.0, 200.0, 234.0]

var kind := ""
var direction := Vector2.RIGHT
var remaining := 0.0
var duration := 0.72
var guard_follow: Node2D
var counter_elapsed := -1.0
var bursts := 0 # Compatibility with the existing guard feedback contract.
var guard_time := 0.0
var elapsed := 0.0
var externally_clocked := false

static func frame_duration_total(frames: Array) -> float:
	var total := 0.0
	for frame_time in frames: total += float(frame_time)
	return total

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func cast(id: String, at: Vector2, aim: Vector2, guard_time: float = 0.0) -> void:
	kind = id
	direction = aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
	global_position = at
	self.guard_time = maxf(0.1, guard_time)
	duration = self.guard_time + GUARDA_FRAMES[5] if id == "guarda_reativa" else (frame_duration_total(KAMUSARI_FRAMES) if id == "danca_laminas" else frame_duration_total(ESTOCADA_FRAMES))
	remaining = duration
	elapsed = 0.0
	externally_clocked = false
	guard_follow = get_parent().get_parent() as Node2D
	counter_elapsed = -1.0
	bursts = 0
	queue_redraw()

func counter(at: Vector2, aim: Vector2) -> void:
	if kind != "guarda_reativa" or remaining <= 0.0: return
	global_position = at
	direction = aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
	counter_elapsed = 0.0
	bursts = 1
	remaining = maxf(remaining, GUARDA_FRAMES[3] + GUARDA_FRAMES[4] + GUARDA_FRAMES[5])
	queue_redraw()

func clear() -> void:
	kind = ""
	remaining = 0.0
	guard_follow = null
	counter_elapsed = -1.0
	bursts = 0
	guard_time = 0.0
	elapsed = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if remaining <= 0.0: return
	if not externally_clocked:
		remaining = maxf(0.0, remaining - delta)
		elapsed += delta
	if is_instance_valid(guard_follow):
		global_position = guard_follow.global_position
		z_index = clampi(roundi(global_position.y) + 99, -4096, 4096)
	if counter_elapsed >= 0.0:
		counter_elapsed += delta
		if counter_elapsed >= GUARDA_FRAMES[3] + GUARDA_FRAMES[4] + GUARDA_FRAMES[5] and elapsed < guard_time:
			counter_elapsed = -1.0
	if remaining <= 0.0: clear()
	else: queue_redraw()

func _frame() -> int:
	if SwordTechniqueTiming.FRAMES.has(kind): return SwordTechniqueTiming.frame(kind,elapsed)
	if kind == "guarda_reativa":
		if counter_elapsed >= 0.0:
			return 3 if counter_elapsed < GUARDA_FRAMES[3] else (4 if counter_elapsed < GUARDA_FRAMES[3] + GUARDA_FRAMES[4] else 5)
		return 0 if elapsed < GUARDA_FRAMES[0] else (1 if elapsed < GUARDA_FRAMES[0] + GUARDA_FRAMES[1] else (2 if elapsed < guard_time else 5))
	var frames: Array = KAMUSARI_FRAMES if kind == "danca_laminas" else ESTOCADA_FRAMES
	var boundary := 0.0
	for index in range(frames.size() - 1):
		boundary += float(frames[index])
		if elapsed < boundary: return index
	return 5

func replaces_body() -> bool:
	return false # All three atlases contain only VFX; the original explorer is always drawn.

func frame_rect(frame: int) -> Rect2:
	var feet: Array = GUARDA_FEET if kind == "guarda_reativa" else (KAMUSARI_FEET if kind == "danca_laminas" else ESTOCADA_FEET)
	var heights: Array = GUARDA_HEIGHTS if kind == "guarda_reativa" else (KAMUSARI_HEIGHTS if kind == "danca_laminas" else ESTOCADA_HEIGHTS)
	var scale_factor := BODY_HEIGHT / float(heights[frame])
	return Rect2(Vector2(0,12) - feet[frame] * scale_factor, Vector2.ONE * CELL * scale_factor)

func source_outline(frame: int) -> PackedVector2Array:
	# These illustrations are not a regular atlas: attack tips cross into the
	# next column. Trace the complete effect and exclude the neighboring body.
	if frame == 3 and kind == "danca_laminas":
		return PackedVector2Array([Vector2(0,0),Vector2(512,0),Vector2(650,260),Vector2(675,285),Vector2(650,310),Vector2(512,390),Vector2(512,512),Vector2(0,512)])
	if frame == 3 and kind == "estocada_precisa":
		return PackedVector2Array([Vector2(0,0),Vector2(512,0),Vector2(512,212),Vector2(630,225),Vector2(630,270),Vector2(512,285),Vector2(512,512),Vector2(0,512)])
	if frame == 4 and kind == "danca_laminas":
		return PackedVector2Array([Vector2(55,405),Vector2(80,350),Vector2(140,300),Vector2(125,260),Vector2(170,230),Vector2(210,215),Vector2(165,150),Vector2(130,40),Vector2(480,0),Vector2(610,100),Vector2(610,512),Vector2(55,512)])
	if frame == 4 and kind == "estocada_precisa":
		return PackedVector2Array([Vector2(25,390),Vector2(50,330),Vector2(120,270),Vector2(95,210),Vector2(155,160),Vector2(180,120),Vector2(610,0),Vector2(610,512),Vector2(25,512)])
	if frame == 4 and kind == "guarda_reativa":
		return PackedVector2Array([Vector2(0,0),Vector2(610,0),Vector2(610,512),Vector2(0,512)])
	return PackedVector2Array()

func _draw_complete_frame(atlas: Texture2D, target: Rect2, source: Rect2, outline: PackedVector2Array) -> void:
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	var scale_factor := target.size.x / CELL
	for point in outline:
		points.append(target.position + point * scale_factor)
		uv.append((source.position + point) / atlas.get_size())
	draw_polygon(points, PackedColorArray([Color.WHITE]), uv, atlas)

func _draw() -> void:
	if remaining <= 0.0: return
	var atlas: Texture2D = GUARDA if kind == "guarda_reativa" else (KAMUSARI if kind == "danca_laminas" else ESTOCADA)
	var frame := _frame()
	if kind == "guarda_reativa" and frame == 2:
		# Keep the normal walking body during the three-second protection window.
		draw_set_transform(Vector2(0,-24), 0.0, Vector2(0.80,1.0))
		draw_arc(Vector2.ZERO, 35.0, 0.0, TAU, 40, Color(0.25,0.65,1.0,0.20), 4.0)
		draw_arc(Vector2.ZERO, 35.0, -1.2, 1.2, 24, Color(0.55,0.88,1.0,0.85), 1.5)
		draw_arc(Vector2.ZERO, 35.0, 1.8, 4.4, 24, Color(0.25,0.65,1.0,0.65), 1.5)
		draw_set_transform(Vector2.ZERO)
		return
	var target := frame_rect(frame)
	if frame >= 3 and frame <= 4: target.position.y += 8.0 if kind == "guarda_reativa" else 14.0
	var source := Rect2(float(frame % 3) * CELL, float(floori(frame / 3.0)) * CELL, CELL, CELL)
	# Direction now applies only to energy; the original explorer keeps its
	# matching four-direction body art and never gets rotated with the overlay.
	if absf(direction.y) > absf(direction.x):
		var pivot := Vector2(0,-24)
		var angle := direction.angle()
		draw_set_transform(pivot-pivot.rotated(angle),angle)
	elif direction.x < 0.0: draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))
	var outline := source_outline(frame)
	if outline.is_empty(): draw_texture_rect_region(atlas, target, source)
	else: _draw_complete_frame(atlas, target, source, outline)
	draw_set_transform(Vector2.ZERO)
