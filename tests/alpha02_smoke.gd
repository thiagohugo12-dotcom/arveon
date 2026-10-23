extends SceneTree

var failures := 0

func _initialize() -> void:
	create_timer(35.0).timeout.connect(func(): quit(1))
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value:
		print("ALPHA02 OK: " + label)
	else:
		failures += 1
		push_error("ALPHA02 FAIL: " + label)

func _run() -> void:
	var path := "user://qa_alpha02_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", path)
	var title := (load("res://scenes/title.tscn") as PackedScene).instantiate()
	root.add_child(title)
	await process_frame
	_check(title.continue_button.disabled, "abertura oferece novo jogo sem save")
	var settings_button: Button = title.touch_buttons[2]
	var touch := InputEventScreenTouch.new()
	touch.index = 7
	touch.pressed = true
	touch.position = settings_button.get_global_rect().get_center()
	root.push_input(touch, true)
	touch = touch.duplicate()
	touch.pressed = false
	root.push_input(touch, true)
	await process_frame
	_check(title.settings_panel.visible, "entrada Godot abre Configurações (não substitui teste Web)")
	title.settings_panel.hide()
	title._start_game(true)
	await process_frame
	var main := current_scene as Node2D
	_check(main != null and main.progress.introduction_active(), "Jogar inicia personagem no Andar 1")
	_check(FileAccess.file_exists(path), "novo jogo salva no armazenamento local")
	var probe := GameProgress.new()
	probe.save_path = path
	_check(probe.load_save() and probe.ascension.current_floor == 1, "save recarrega progresso do Andar 1")
	main.set_process(false)
	main.player.set_physics_process(false)
	main.progress.meet_smith()
	_check(main.progress.claim_first_weapon("espada", true), "Ferreiro conclui o primeiro equipamento")
	main.progress.ascension.defeats["1"] = 50
	_check(main.progress.ascension.complete_forest_trial(), "Torre libera o segundo andar")
	await main._travel_floor(2)
	main.set_process(false)
	main.player.set_physics_process(false)
	_check(main.world is Andar2World and main.progress.ascension.current_floor == 2, "cenário próprio do Andar 2 carrega")
	main._save_progress()
	var floor2 := GameProgress.new()
	floor2.save_path = path
	_check(floor2.load_save() and floor2.ascension.current_floor == 2, "continuação preserva andar após viagem")
	main.queue_free()
	await process_frame
	var again := (load("res://scenes/title.tscn") as PackedScene).instantiate()
	root.add_child(again)
	_check(not again.continue_button.disabled, "Continuar habilita com save válido")
	again._start_game(false)
	await process_frame
	var resumed := current_scene as Node2D
	_check(resumed != null and resumed.world is Andar2World, "Continuar retoma no Vale")
	print("ALPHA02 RESULT: %d falhas" % failures)
	quit(0 if failures == 0 else 1)
