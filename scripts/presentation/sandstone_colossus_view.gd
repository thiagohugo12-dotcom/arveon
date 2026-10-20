class_name SandstoneColossusView
extends GuardianView

const GOLEM := preload("res://assets/art/andar2/refined/sandstone-guardian-atlas.png")
var golem_time := 0.0

func _process(delta: float) -> void:
	super._process(delta)
	golem_time += delta
	queue_redraw()

func _frame() -> Vector2i:
	if defeat_left > 0.0:
		return Vector2i(clampi(int((1.0 - defeat_left / 0.22) * 6.0), 0, 5), 4)
	if flash_left > 0.0:
		return Vector2i(int(golem_time * 12.0) % 3, 3)
	if attack_left > 0.0 or warning:
		return Vector2i(int(golem_time * 10.0) % 6, 2)
	return Vector2i(int(golem_time * (7.0 if walking else 2.0)) % (6 if walking else 4), 1 if walking else 0)

func _draw_body() -> void:
	var frame := _frame()
	draw_texture_rect_region(GOLEM, Rect2(-128, -192, 256, 192),
		Rect2(frame.x * 128, frame.y * 96, 128, 96),
		Color(1.3, 1.2, 1.05) if flash_left > 0.0 else Color.WHITE)

func _draw() -> void:
	if warning:
		var fill := Color("#bb814c66")
		var edge := Color("#ffe0a0")
		match telegraph_kind:
			0:
				draw_circle(Vector2.ZERO, 110.0, fill)
				draw_arc(Vector2.ZERO, 110.0, 0.0, TAU, 36, edge, 3.0)
			1:
				var side := telegraph_direction.orthogonal() * 36.0
				var end := telegraph_direction * 210.0
				draw_colored_polygon(PackedVector2Array([-side, side, end + side, end - side]), fill)
				draw_line(Vector2.ZERO, end, edge, 3.0)
			2:
				for angle in [-0.38, 0.0, 0.38]:
					draw_line(Vector2.ZERO, telegraph_direction.rotated(angle) * 200.0, edge, 3.0)
	_draw_body()
	_draw_caption("Colosso de Arenito")

func _draw_caption(title: String) -> void:
	draw_rect(Rect2(-48, -164, 96, 6), Color("#30271d"))
	draw_rect(Rect2(-48, -164, 96 * hp_ratio, 6), Color("#e3aa57"))
	draw_string(ThemeDB.fallback_font, Vector2(-74, -172), title,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#fff1ca"))
	_draw_hit_feedback(-180.0)
