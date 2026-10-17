extends SceneTree
var checks := 0
var failures := 0
var output := "C:/Users/Thiago/Documents/Codex/2026-10-16/o-c/outputs/refinamento-local"
func _initialize() -> void:
	create_timer(60).timeout.connect(func(): push_error("REVIEW_TIMEOUT"); quit(1))
	call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; print("FAIL: ",label)
func capture(name: String) -> void:
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1280,800)
	root.content_scale_size=Vector2i(1280,800)
	var review:=preload("res://scenes/demos/local_combat_review.tscn").instantiate()
	root.add_child(review)
	review.playing=false
	for i in range(6): await process_frame
	for kind in range(5):
		review.actor_kind=kind
		review.actor_choice.select(kind)
		review._populate_attacks()
		var abilities: Array=["estocada_precisa","guarda_reativa","danca_laminas"] if kind == 0 else ["roots","guardian_idle"] if kind == 1 else ["roots"]
		for ability: String in abilities:
			review.ability=ability
			if kind == 0: review.attack_choice.select(abilities.find(ability))
			if kind == 1: review.attack_choice.select(1 if ability == "roots" else 0)
			for direction in range(4):
				review.direction_index=direction
				review.rebuild()
				review.seek(review.contact_time-0.001)
				check(review.actual_contact_events == 0,"no early damage in review "+str(kind)+ability)
				review.seek(review.contact_time)
				check(review.actual_contact_events == (0 if kind == 4 or ability == "guardian_idle" else 1),"real contact marker "+str(kind)+ability)
				if ability == "guardian_idle": check(not review.new_enemy.view.warning and review.new_enemy.view.sprite_frame() < 2,"idle is animated without attack warning")
				if kind == 0 and ability != "guarda_reativa":
					check(review.new_player.view.sword_technique._frame() == 3,"body/effect contact frame")
					check(review.panels[0].enemy.health.current == review.panels[0].enemy.health.maximum,"comparison world cannot receive damage")
				if kind == 4:
					review.seek(1.1)
					check(review.fired and review.real_damage > 0,"spine launches then collides")
				if direction == 3 or kind == 1:
					await capture("%d-%s-dir%d-contact" % [kind,ability,direction])
				review.seek(review.duration)
				review.step_frame(-1)
				check(review.time < review.duration,"frame stepping backwards")
				review.step_frame(1)
				check(is_equal_approx(review.time,review.duration),"frame stepping forwards")
	# Exercise the actual control signals and shared playback clock.
	review.actor_kind=0
	review._populate_attacks()
	review.rebuild()
	var speed_control: OptionButton
	for control in review.attack_choice.get_parent().get_children():
		if control is OptionButton and control.get_item_text(0) == "0,25×": speed_control=control
		if control is Button: check(control.size.y >= 44,"touch control has 44px minimum")
	speed_control.item_selected.emit(0)
	review.playing=true
	review._process(0.04)
	check(is_equal_approx(review.time,0.01),"0.25x control drives shared combat clock")
	review.play_button.pressed.emit()
	var held: float=review.time
	review._process(0.1)
	check(not review.playing and review.time == held,"pause button holds pose and damage clock")
	review.slider.value=0.135
	check(review.actual_contact_events == 1 and not review.playing,"scrubbing replays one real deterministic contact")
	review.seek(review.duration)
	review.playing=true
	review._process(0.01)
	check(review.time == 0 and review.actual_contact_events == 0,"loop starts a clean cast")
	review.playing=false
	# Layout/touch controls at phone size, actual Godot UI.
	root.size=Vector2i(390,844)
	root.content_scale_size=Vector2i(390,844)
	review.actor_kind=1
	review.actor_choice.select(1)
	review._populate_attacks()
	review.rebuild()
	review.seek(review.contact_time)
	await capture("review-mobile-390x844")
	check(review.panel_row.vertical,"phone stacks comparison vertically")
	review.queue_free()
	await process_frame
	print("LOCAL_REVIEW_RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
