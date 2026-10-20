extends RefCounted

static func run(suite, main) -> void:
	var view: FloorView = main.get_node("Andar1/FloorView")
	var player: PlayerActor = main.player
	var before := player.position
	var trees := view.tree_positions()
	var original_trees := view._base_tree_positions()
	suite.check(original_trees.size() == 28 and trees.size() > original_trees.size(), "expanded Andar 1 preserves the original tree placements and adds forest trees")
	for at: Vector2 in trees:
		suite.check(player.test_move(Transform2D(0,at-Vector2(30,0)),Vector2(30,0)), "each drawn tree retains a physical trunk at " + str(at))
	for at: Vector2 in FloorView.REMOVED_SECONDARY:
		suite.check(not player.test_move(Transform2D(0,at),Vector2(1,0)), "removed tree leaves no invisible collider " + str(at))
	suite.check(view.atlas == MataArt.texture() and view.atlas.get_size() == Vector2(128,48), "five floors share one cached tiny pixel atlas")
	var image := view.atlas.get_image()
	suite.check(image.get_pixel(0,0).a == 0 and image.get_pixel(15,35).a == 1, "atlas has true alpha outside silhouettes and a visible grounded trunk")
	suite.check(FloorView.ROCKS == [Rect2(340,300,130,50),Rect2(760,520,90,110)] and TowerEntrance.POSITION == Vector2(830,1290), "original rocks and southern Tower are placed inside Andar 1")
	var walls: Node = main.get_node("Andar1/Walls")
	for name: String in ["Top","Bottom","Left","Right"]:
		var shape: CollisionShape2D = walls.get_node(name)
		var size := (shape.shape as RectangleShape2D).size
		var expected_size := Vector2(1700,32) if name in ["Top","Bottom"] else Vector2(32,1350)
		suite.check(size == expected_size, "Andar 1 boundary expanded without changing its edge thickness " + name)
	suite.check(FloorConfig.world_size(2) == Floor2Layout.WORLD_SIZE and FloorConfig.world_size(3) == FloorConfig.DEFAULT_WORLD_SIZE, "the Vale uses its own bounds and later floors retain theirs")
	player.position = before
