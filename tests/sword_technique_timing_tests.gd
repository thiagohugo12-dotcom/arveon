extends RefCounted

static func run(suite) -> void:
	var effect := SwordTechniqueEffect.new()
	for scenario in [
		{"id": "estocada_precisa", "times": SwordTechniqueEffect.ESTOCADA_FRAMES},
		{"id": "danca_laminas", "times": SwordTechniqueEffect.KAMUSARI_FRAMES}
	]:
		var times: Array = scenario.times
		effect.kind = scenario.id
		effect.duration = SwordTechniqueEffect.frame_duration_total(times)
		var sample_time := 0.0
		for index in range(times.size()):
			effect.elapsed = sample_time + 0.001
			effect.remaining = effect.duration - effect.elapsed
			suite.check(effect._frame() == index, "%s shows approved frame %d in order" % [scenario.id, index + 1])
			sample_time += float(times[index])
		suite.check(effect.duration < 0.6, "%s finishes within a responsive combat beat" % scenario.id)
	effect.kind = "guarda_reativa"
	effect.guard_time = 3.0
	effect.duration = 3.0 + SwordTechniqueEffect.GUARDA_FRAMES[5]
	effect.counter_elapsed = -1.0
	for sample in [[0.01, 0], [0.06, 1], [0.13, 2], [3.01, 5]]:
		effect.elapsed = float(sample[0])
		effect.remaining = effect.duration - float(sample[0])
		suite.check(effect._frame() == int(sample[1]), "guard startup, hold and recovery match approved order")
	for sample in [[0.01, 3], [0.05, 4], [0.13, 5]]:
		effect.counter_elapsed = float(sample[0])
		suite.check(effect._frame() == int(sample[1]), "guard block and counter match approved order")
	effect.elapsed = 1.0
	effect.counter_elapsed = 0.23
	effect._process(0.01)
	suite.check(effect._frame() == 2 and not effect.replaces_body(), "guard returns to a moving native body after its brief counter")
	effect.elapsed = 3.0
	effect.counter_elapsed = 0.01
	effect.remaining = 0.22
	effect._process(0.23)
	suite.check(effect.remaining == 0.0, "late guard counter finishes without leaving a stuck replacement body")
	for id: String in ["estocada_precisa","guarda_reativa","danca_laminas"]:
		effect.kind = id
		var impact_outline := effect.source_outline(4)
		suite.check(Geometry2D.triangulate_polygon(impact_outline).size() > 0 and Geometry2D.is_point_in_polygon(Vector2(550,280),impact_outline), id + " preserves the impact beyond the old 512 px cell")
		if id != "guarda_reativa":
			var stroke_outline := effect.source_outline(3)
			suite.check(Geometry2D.triangulate_polygon(stroke_outline).size() > 0 and Geometry2D.is_point_in_polygon(Vector2(600,250),stroke_outline), id + " preserves the complete forward stroke")
	effect.free()
