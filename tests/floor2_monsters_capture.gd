extends SceneTree

const PREVIEW := preload("res://scenes/demos/floor2_monsters_preview.tscn")
const ACTOR := preload("res://scripts/demos/floor2_monster_actor.gd")
var output := ""
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func capture(name: String) -> void:
	for _i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	check(img.save_png(output.path_join(name + ".png")) == OK, "capture " + name)

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	if output.is_empty():
		push_error("QA_RENDER_DIR required")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var preview := PREVIEW.instantiate()
	root.add_child(preview)
	await process_frame
	check(preview.actors.size() == 3, "three preview actors")
	for i in range(3):
		var actor: Node2D = preview.actors[i]
		check(actor.get_node("AnimatedSprite2D") is AnimatedSprite2D, "animated sprite " + str(i))
		var sprite := actor.get_node("AnimatedSprite2D") as AnimatedSprite2D
		for state: String in ACTOR.STATE_ROWS[i]:
			check(sprite.sprite_frames.has_animation(state), "missing %s %s" % [ACTOR.NAMES[i],state])
			var expected: int = ACTOR.FRAME_COUNTS[ACTOR.STATE_ROWS[i].find(state)]
			check(sprite.sprite_frames.get_frame_count(state) == expected, "%d frames %s %s" % [expected,ACTOR.NAMES[i],state])
			preview.select_monster(i)
			preview.set_state(state)
			check(sprite.animation == state and sprite.is_playing(), "playback %s %s" % [ACTOR.NAMES[i],state])
		preview.select_monster(i)
		preview.set_state("idle")
		preview.set_isolated(true)
		await capture(ACTOR.NAMES[i])
		preview.set_state("charge" if i == 1 else "attack")
		await capture(ACTOR.NAMES[i] + "-ataque")
	preview.set_isolated(false)
	preview.select_monster(0)
	preview.set_state("idle")
	await capture("comparacao-escala")
	root.size = Vector2i(390, 844)
	root.content_scale_size = Vector2i(390, 844)
	await process_frame
	preview.select_monster(2)
	preview.set_state("attack")
	await capture("celular-vertical")
	print("FLOOR2_MONSTERS_CAPTURE: %d falhas, 8 capturas, %s" % [failures,output])
	quit(1 if failures else 0)
