class_name SwordTechniqueEffect
extends Node2D
## Presentation only: ClassCombat owns damage, reach, cooldowns and guard timing.
const ESTOCADA: Texture2D = preload("res://assets/art/sword_techniques/estocada_precisa.png")
const GUARDA: Texture2D = preload("res://assets/art/sword_techniques/guarda_reativa.png")
const KAMUSARI: Texture2D = preload("res://assets/art/sword_techniques/kamusari.png")
const CELL := 512.0
const ESTOCADA_FRAMES := [0.55, 0.35, 0.26, 0.33, 0.42, 0.62]
const GUARDA_FRAMES := [0.50, 0.38, 0.80, 0.45, 0.38, 0.65]
const KAMUSARI_FRAMES := [0.50, 0.55, 0.26, 0.39, 0.42, 0.72]

var kind := ""
var direction := Vector2.RIGHT
var remaining := 0.0
var duration := 0.72
var guard_follow: Node2D
var counter_elapsed := -1.0
var bursts := 0 # Compatibility with the existing guard feedback contract.
var guard_time := 0.0

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
	queue_redraw()

func _process(delta: float) -> void:
	if remaining <= 0.0: return
	remaining = maxf(0.0, remaining - delta)
	if is_instance_valid(guard_follow): global_position = guard_follow.global_position
	if counter_elapsed >= 0.0: counter_elapsed += delta
	if remaining <= 0.0: clear()
	else: queue_redraw()

func _frame() -> int:
	if kind == "guarda_reativa":
		if counter_elapsed >= 0.0:
			return 3 if counter_elapsed < GUARDA_FRAMES[3] else (4 if counter_elapsed < GUARDA_FRAMES[3] + GUARDA_FRAMES[4] else 5)
		var elapsed := duration - remaining
		return 0 if elapsed < GUARDA_FRAMES[0] else (1 if elapsed < GUARDA_FRAMES[0] + GUARDA_FRAMES[1] else (2 if elapsed < guard_time else 5))
	var frames: Array = KAMUSARI_FRAMES if kind == "danca_laminas" else ESTOCADA_FRAMES
	var elapsed := duration - remaining
	var boundary := 0.0
	for index in range(frames.size() - 1):
		boundary += float(frames[index])
		if elapsed < boundary: return index
	return 5

func _draw() -> void:
	if remaining <= 0.0: return
	var atlas: Texture2D = GUARDA if kind == "guarda_reativa" else (KAMUSARI if kind == "danca_laminas" else ESTOCADA)
	var frame := _frame()
	var side := 224.0 if kind == "danca_laminas" else 192.0
	# The character's feet are near 85% of the source cell height.
	var target := Rect2(-side * 0.5, -side * 0.84, side, side)
	var source := Rect2(float(frame % 3) * CELL, float(floori(frame / 3.0)) * CELL, CELL, CELL)
	# The reference faces right. Mirroring preserves its poses for leftward casts.
	if direction.x < -0.3: draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))
	draw_texture_rect_region(atlas, target, source)
	draw_set_transform(Vector2.ZERO)
