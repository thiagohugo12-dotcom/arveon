extends SceneTree

# Versão de TESTE (data/test_build.gd): viagem livre pela Torre e ouro infinito.
# Sem a flag, as regras da campanha continuam exatamente as mesmas.
var failures := 0
var checks := 0
var save_path := ""

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("TEST_BUILD OK: " + label)
	else:
		failures += 1
		push_error("TEST_BUILD_FAIL: " + label)

func _run() -> void:
	OS.unset_environment("ARVEON_TEST_BUILD")
	_check(not TestBuild.ENABLED, "arquivo versionado mantém o modo teste desligado (produção)")
	var normal := GameProgress.new()
	_check(not normal.ascension.can_travel(2) and not normal.ascension.can_travel(3), "sem a flag, Andares 2 e 3 seguem bloqueados")
	OS.set_environment("ARVEON_TEST_BUILD", "1")
	var free := GameProgress.new()
	_check(free.ascension.can_travel(2) and free.ascension.can_travel(3), "com a flag, a Torre viaja livre aos Andares 2 e 3")
	_check(not free.ascension.can_travel(4) and not free.ascension.can_travel(6), "andares que não existem continuam fechados")
	free.ascension.current_floor = 3
	free.ascension.defeats["3"] = 12
	var copy := GameProgress.new()
	_check(copy.load_text(free.to_json()) and copy.ascension.current_floor == 3 and int(copy.ascension.defeats["3"]) == 12, "save no Andar 3 sem Provas anteriores reabre na versão de teste")
	OS.unset_environment("ARVEON_TEST_BUILD")
	_check(not GameProgress.new().load_text(free.to_json()), "fora da versão de teste esse save continua inválido (regra da campanha intacta)")
	OS.set_environment("ARVEON_TEST_BUILD", "1")

	save_path = "user://qa_test_build_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for _frame in range(3): await process_frame
	_check(main.progress.gold == TestBuild.GOLD and main.earned_gold == TestBuild.GOLD, "ouro começa cheio")
	main.progress.gold -= 5000
	main.earned_gold = main.progress.gold
	for _frame in range(2): await process_frame
	_check(main.progress.gold == TestBuild.GOLD and main.earned_gold == TestBuild.GOLD, "ouro gasto volta a encher")
	_check(main.progress.ascension.completed_trials["1"] == false, "viagem livre não marca Provas como concluídas")
	await main._travel_floor(3)
	_check(main.progress.ascension.current_floor == 3 and main.world is Andar3World, "viaja direto do Andar 1 ao Pântano")
	await main._travel_floor(2)
	_check(main.progress.ascension.current_floor == 2 and main.world.scene_file_path == "res://scenes/world/andar_2.tscn", "volta para o Andar 2")
	main._save_progress()
	var reopened := GameProgress.new()
	reopened.save_path = save_path
	_check(reopened.load_save() and reopened.ascension.current_floor == 2 and reopened.gold == TestBuild.GOLD, "save gravado reabre no andar atual com o ouro cheio")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("ARVEON_SAVE_PATH")
	OS.unset_environment("ARVEON_TEST_BUILD")
	print("TEST_BUILD_RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
