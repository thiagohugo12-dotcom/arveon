class_name SwordTechniqueEffect
extends Node2D
## Presentation only: ClassCombat owns damage, reach, cooldowns and guard timing.
const ESTOCADA: Texture2D = preload("res://assets/art/sword_techniques/estocada_precisa.png")
const GUARDA: Texture2D = preload("res://assets/art/sword_techniques/guarda_reativa.png")
const KAMUSARI: Texture2D = preload("res://assets/art/sword_techniques/kamusari.png")
const CELL := 512.0

var kind := ""
var direction := Vector2.RIGHT
var remaining := 0.0
var duration := 0.72
var guard_follow: Node2D
var counter_elapsed := -1.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func cast(id: String, at: Vector2, aim: Vector2, guard_time: float = 0.0) -> void:
	kind = id
	direction = aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
	global_position = at
	duration = maxf(0.1, guard_time) if id == "guarda_reativa" else (0.78 if id == "danca_laminas" else 0.66)
	remaining = duration
	guard_follow = get_parent().get_parent() as Node2D
	counter_elapsed = -1.0
	queue_redraw()

func counter(at: Vector2, aim: Vector2) -> void:
	if kind != "guarda_reativa" or remaining <= 0.0: return
	global_position = at
	direction = aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
	counter_elapsed = 0.0
	queue_redraw()

func clear() -> void:
	kind = ""
	remaining = 0.0
	guard_follow = null
	counter_elapsed = -1.0
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
			return 3 if counter_elapsed < 0.10 else (4 if counter_elapsed < 0.29 else 5)
		var elapsed := duration - remaining
		return 0 if elapsed < 0.09 else (1 if elapsed < 0.19 else 2)
	var progress := 1.0 - remaining / duration
	return mini(5, int(progress * 6.0))

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
