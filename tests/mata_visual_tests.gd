extends RefCounted

static func run(suite, main) -> void:
	var view: FloorView = main.get_node("Andar1/FloorView")
	var player: PlayerActor = main.player
	var before := player.position
	var trees := view.tree_positions()
	suite.check(trees.size() == 28, "Mata removes six secondary trunks without rerolling remaining placements")
	for at: Vector2 in trees:
		suite.check(player.test_move(Transform2D(0,at-Vector2(30,0)),Vector2(30,0)), "each drawn tree retains a physical trunk at " + str(at))
	for at: Vector2 in FloorView.REMOVED_SECONDARY:
		suite.check(not player.test_move(Transform2D(0,at),Vector2(1,0)), "removed tree leaves no invisible collider " + str(at))
	suite.check(view.atlas == MataArt.texture() and view.atlas.get_size() == Vector2(128,48), "five floors share one cached tiny pixel atlas")
	var image := view.atlas.get_image()
	suite.check(image.get_pixel(0,0).a == 0 and image.get_pixel(15,35).a == 1, "atlas has true alpha outside silhouettes and a visible grounded trunk")
	suite.check(FloorView.ROCKS == [Rect2(340,300,130,50),Rect2(760,520,90,110)] and TowerEntrance.POSITION == Vector2(1130,455), "rocks and eastern Tower keep original footprints and positions")
	var walls: Node = main.get_node("Andar1/Walls")
	for name: String in ["Top","Bottom","Left","Right"]:
		var shape: CollisionShape2D = walls.get_node(name)
		var size := (shape.shape as RectangleShape2D).size
		suite.check(size == (Vector2(1200,32) if name in ["Top","Bottom"] else Vector2(32,900)), "original world boundary unchanged " + name)
	player.position = before
