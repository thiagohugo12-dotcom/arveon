extends SceneTree
## Capture every actual AnimatedSprite2D frame from the running Godot preview.

const PREVIEW := preload("res://scenes/demos/floor2_monsters_preview.tscn")
const ACTOR := preload("res://scripts/demos/floor2_monster_actor.gd")
var output := ""

func _initialize() -> void:
	call_deferred("_run")

func _capture(path: String) -> void:
	for _i in range(2): await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.save_png(path) != OK: push_error("Falha na captura: " + path)

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	if output.is_empty():
		push_error("QA_RENDER_DIR obrigatório")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var preview := PREVIEW.instantiate()
	root.add_child(preview)
	await process_frame
	preview.set_isolated(true)
	var total := 0
	for i in range(3):
		preview.select_monster(i)
		var sprite := preview.actors[i].get_node("AnimatedSprite2D") as AnimatedSprite2D
		for state: String in ACTOR.STATE_ROWS[i]:
			preview.set_state(state)
			sprite.pause()
			for frame in range(sprite.sprite_frames.get_frame_count(state)):
				sprite.frame = frame
				await _capture(output.path_join("%s-%s-%02d.png" % [ACTOR.NAMES[i], state, frame]))
				total += 1
	print("FLOOR2_MONSTERS_ANIMATIONS: %d quadros capturados na Godot em %s" % [total,output])
	quit()
