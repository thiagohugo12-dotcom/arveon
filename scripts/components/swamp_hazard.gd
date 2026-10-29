class_name SwampHazard
extends Node2D

# Área perigosa temporária do Pântano. Primeiro aparece só o aviso no chão; depois:
# "lodo" fere em intervalos enquanto o jogador estiver dentro (mancha do Limo e da Mãe),
# "raiz" fere uma única vez ao emergir (Raízes da Mãe, fase 2). Some sozinha.
var target: PlayerActor
var radius := 34.0
var warn_left := 0.0
var active_left := 2.5
var damage := 5
var interval := 0.8
var style := "lodo"
var source_name := ""
var _tick_left := 0.0
var _struck := false
var _time := 0.0

static func spawn(parent: Node, at: Vector2, player: PlayerActor, setup: Dictionary) -> SwampHazard:
	var hazard := SwampHazard.new()
	hazard.position = at
	hazard.target = player
	for key: String in setup: hazard.set(key, setup[key])
	# A mancha só fere depois de um intervalo: nunca soma dano ao golpe que a criou.
	hazard._tick_left = hazard.interval
	hazard.z_as_relative = false
	hazard.z_index = -20
	hazard.add_to_group("swamp_hazards")
	parent.add_child(hazard)
	return hazard

func active() -> bool:
	return warn_left <= 0.0

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if warn_left > 0.0:
		warn_left -= delta
		if warn_left <= 0.0 and style == "raiz": _strike()
		return
	active_left -= delta
	if active_left <= 0.0:
		queue_free()
		return
	if style == "lodo":
		_tick_left -= delta
		if _tick_left <= 0.0:
			_tick_left = interval
			_strike()

func _strike() -> void:
	if style == "raiz":
		if _struck: return
		_struck = true
	if not is_instance_valid(target) or not target.health.is_alive() or SafeCamp.in_clearance(target.global_position):
		return
	var offset := target.global_position - global_position
	if Vector2(offset.x, offset.y * 1.6).length() <= radius:
		target.receive_damage(damage, "physical", source_name)

func _draw() -> void:
	var squash := Vector2(1.0, 0.62)
	draw_set_transform(Vector2.ZERO, 0.0, squash)
	if warn_left > 0.0:
		var blink := 0.5 + 0.5 * sin(_time * 18.0)
		var tone := Color("#e8c45a") if style == "raiz" else Color("#b9e05a")
		draw_circle(Vector2.ZERO, radius, Color(tone, 0.16 + 0.12 * blink))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(tone, 0.85), 2.0)
		draw_set_transform(Vector2.ZERO)
		return
	if style == "lodo":
		var fade := clampf(active_left / 0.4, 0.0, 1.0)
		draw_circle(Vector2.ZERO, radius, Color(0.33, 0.47, 0.10, 0.55 * fade))
		draw_circle(Vector2(-radius * 0.25, -radius * 0.2), radius * 0.45, Color(0.55, 0.70, 0.18, 0.45 * fade))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(0.20, 0.30, 0.06, 0.8 * fade), 2.0)
		draw_set_transform(Vector2.ZERO)
	else:
		draw_set_transform(Vector2.ZERO)
		# Raízes emergindo: pontas de madeira em pixels, como as raízes da Mãe.
		var rise := clampf((0.55 - active_left) * 6.0 + 1.0, 0.0, 1.0)
		for i in range(5):
			var x := -radius * 0.7 + i * radius * 0.35
			var height := (14.0 + (i % 2) * 10.0) * rise
			draw_colored_polygon(PackedVector2Array([Vector2(x - 5, 4), Vector2(x + 5, 4), Vector2(x + 1, 4 - height)]), Color("#6b4423"))
			draw_line(Vector2(x - 2, 2), Vector2(x, 4 - height * 0.8), Color("#a3743f"), 2.0)
