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
		var elapsed := 0.0
		for index in range(times.size()):
			effect.remaining = effect.duration - elapsed - 0.01
			suite.check(effect._frame() == index, "%s shows approved frame %d in order" % [scenario.id, index + 1])
			elapsed += float(times[index])
	effect.kind = "guarda_reativa"
	effect.guard_time = 3.0
	effect.duration = 3.0 + SwordTechniqueEffect.GUARDA_FRAMES[5]
	effect.counter_elapsed = -1.0
	for sample in [[0.01, 0], [0.51, 1], [0.89, 2], [3.01, 5]]:
		effect.remaining = effect.duration - float(sample[0])
		suite.check(effect._frame() == int(sample[1]), "guard startup, hold and recovery match approved order")
	for sample in [[0.01, 3], [0.46, 4], [0.84, 5]]:
		effect.counter_elapsed = float(sample[0])
		suite.check(effect._frame() == int(sample[1]), "guard block and counter match approved order")
