class_name MiningEffect
extends Node2D

var elapsed := 0.0
var lifetime := MiningRules.DURATION
var hit_position := Vector2.ZERO
var swing_position := Vector2.ZERO
var impact_played := false

func setup(player_at: Vector2, deposit_at: Vector2) -> void:
	position = player_at
	hit_position = deposit_at - player_at + Vector2(0, -16)
	swing_position = (deposit_at - player_at) * 0.48 + Vector2(0, -18)
	z_as_relative = false
	z_index = roundi(maxf(player_at.y, deposit_at.y)) + 201
	set_process(true)

func _process(delta: float) -> void:
	elapsed += delta
	if not impact_played and elapsed >= lifetime * 0.42:
		impact_played = true
		_play_impact()
	queue_redraw()
	if elapsed >= lifetime: queue_free()

func _play_impact() -> void:
	var samples := PackedByteArray()
	samples.resize(2600 * 2)
	for i in range(2600):
		var decay := pow(1.0 - float(i) / 2600.0, 2.3)
		var tone := sin(float(i) * 0.075) * 0.55 + sin(float(i) * 0.39) * 0.20
		samples.encode_s16(i * 2, roundi(tone * decay * 9000.0))
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	wave.data = samples
	var player := AudioStreamPlayer2D.new()
	player.volume_db = -18.0
	player.stream = wave
	add_child(player)
	player.play()

func _draw() -> void:
	var progress := minf(1.0, elapsed / lifetime)
	var handle_from := swing_position + Vector2(-10, -12).rotated(progress * 1.45)
	var handle_to := swing_position + Vector2(9, 15).rotated(progress * 1.45)
	draw_line(handle_from, handle_to, Color("#6a3e28"), 5.0)
	draw_line(handle_from, handle_to, Color("#c49a62"), 2.0)
	draw_colored_polygon(PackedVector2Array([handle_from + Vector2(-7,-3),handle_from + Vector2(7,-3),handle_from + Vector2(5,3),handle_from + Vector2(-5,3)]), Color("#8e9d99"))
	if progress >= 0.42 and progress <= 0.92:
		var fade := (0.92-progress)/0.5
		for i in range(5):
			var direction := Vector2(cos(float(i)*1.25),sin(float(i)*1.25)-0.45)
			var at := hit_position + direction * (4.0 + (progress-0.42)*28.0)
			draw_rect(Rect2(at, Vector2(3,3)), Color(0.94,0.80,0.52,fade))
