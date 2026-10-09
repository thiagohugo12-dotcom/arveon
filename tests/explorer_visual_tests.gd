extends RefCounted

static func run(suite: SceneTree) -> void:
	var image := (load("res://assets/art/explorer_atlas.png") as Texture2D).get_image()
	suite.check(image.get_size() == Vector2i(288, 192), "explorer atlas has four directions and six aligned frames")
	for direction in range(4):
		var idle := image.get_region(Rect2i(0, direction * 48, 48, 48))
		var breath := image.get_region(Rect2i(48, direction * 48, 48, 48))
		var left_step := image.get_region(Rect2i(96, direction * 48, 48, 48))
		var passing_a := image.get_region(Rect2i(144, direction * 48, 48, 48))
		var right_step := image.get_region(Rect2i(192, direction * 48, 48, 48))
		var passing_b := image.get_region(Rect2i(240, direction * 48, 48, 48))
		suite.check(idle.get_pixel(0, 0).a == 0.0 and idle.get_pixel(47, 47).a == 0.0, "explorer frame keeps transparent margins (%d)" % direction)
		suite.check(idle.get_data() != breath.get_data(), "explorer idle breath has its own frame (%d)" % direction)
		suite.check(left_step.get_data() != right_step.get_data(), "explorer opposite strides differ (%d)" % direction)
		suite.check(passing_a.get_data() != passing_b.get_data(), "explorer passing strides differ (%d)" % direction)
	var view := ActorView.new()
	suite.root.add_child(view)
	view.appearance = 0
	for direction in [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]:
		view.set_facing(direction)
		suite.check(view._explorer_direction() == [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT].find(direction), "explorer picks cardinal facing %s" % direction)
	view.set_moving(true)
	view.global_position += Vector2(12, 0)
	view._process(1.0 / 60.0)
	suite.check(view.anim_frame == 1, "explorer stride advances after actual travel")
	view._process(1.0)
	suite.check(view.anim_frame == 1, "explorer does not walk in place without travel")
	for phase in [2, 3, 0]:
		view.global_position += Vector2(12, 0)
		view._process(1.0 / 60.0)
		suite.check(view.anim_frame == phase, "explorer completes alternating contact and passing poses %d" % phase)
	view.set_moving(false)
	suite.check(view.anim_frame == 0, "explorer settles into idle when stopped")
	view.queue_free()
