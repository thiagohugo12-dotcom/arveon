extends RefCounted

static func run(suite, main) -> void:
	var view: FloorView = main.get_node("Andar1/FloorView")
	var bounds := FloorConfig.ANDAR1_WORLD_SIZE
	suite.check(bounds == Vector2(1700,1350) and view.expanded_world, "only the active Andar 1 enables the expanded world")
	suite.check(FloorConfig.world_size(2) == Floor2Layout.WORLD_SIZE and FloorConfig.world_size(5) == FloorConfig.DEFAULT_WORLD_SIZE, "Andar 2 owns its map while later floors retain their dimensions")
	suite.check(Exploration.resources_for_floor(1).size() == 12 and Exploration.resources_for_floor(2).size() == 8, "four added collection points are available only on Andar 1")
	suite.check(Exploration.chests_for_floor(1).size() == 5 and Exploration.chests_for_floor(2).size() == 3, "two added hidden chests are available only on Andar 1")
	var new_resource: Dictionary = Exploration.RESOURCE_SPOTS.back()
	suite.check(new_resource.position.x < bounds.x and new_resource.position.y < bounds.y, "secret grove resource is inside the expanded physical limits")
	var resource_only_first := GameProgress.new()
	var now := int(Time.get_unix_time_from_system())
	suite.check(resource_only_first.collect_resource("ruins_herb_east",now,1) == "Ervas" and resource_only_first.collect_resource("danger_stone_east",now,2).is_empty(), "new resources use the existing collection and cooldown system only on floor 1")
	suite.check(resource_only_first.open_exploration_chest("ruins_cache_east",2).is_empty() and resource_only_first.open_exploration_chest("ruins_cache_east",1).gold == 12, "new caches use the current chest reward and opened-state system only on floor 1")
	resource_only_first.save_path = "user://qa_andar1_expansion_%d.json" % Time.get_ticks_usec()
	suite.check(resource_only_first.save(), "existing save format accepts the additional exploration IDs")
	var restored := GameProgress.new()
	restored.save_path = resource_only_first.save_path
	suite.check(restored.load_save() and restored.harvested_until.has("ruins_herb_east") and restored.opened_caches.has("ruins_cache_east"), "new exploration progress survives the current save/load path")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(resource_only_first.save_path))
	var world := main.get_node("Andar1") as Andar1Obstacles
	var expected_points := [Vector2(1210,410),Vector2(1430,260),Vector2(1480,635),Vector2(760,1185),Vector2(1250,1255)]
	var walkable := true
	for point: Vector2 in expected_points:
		if main.player.test_move(Transform2D(0,point),Vector2(3,0)):
			walkable = false
			suite.check(false,"main trail stays walkable at " + str(point))
	suite.check(walkable, "main paths connect ruins, dangerous region, deep forest and secret grove")
	var authored_trees := view.expansion_tree_positions()
	suite.check(authored_trees.size() >= 36, "expanded biomes use authored tree groups instead of sparse random trees")
	suite.check(main.player.test_move(Transform2D(0,Vector2(172,1086)),Vector2(1,0)), "fallen deepwood log art has a matching physical obstacle")
	suite.check(main.player.test_move(Transform2D(0,Vector2(1500,220)),Vector2(1,0)), "ancient altar art has a matching physical obstacle")
	var walls: Node = world.get_node("Walls")
	var right_boundary := walls.get_node("Right") as CollisionShape2D
	suite.check(right_boundary.position == Vector2(1700,675) and (right_boundary.shape as RectangleShape2D).size == Vector2(32,1350), "east physical boundary matches the enlarged terrain")
	suite.check(FloorConfig.world_size(2) == Floor2Layout.WORLD_SIZE and FloorConfig.world_scene(2) != FloorConfig.world_scene(1), "Andar 2 shares planned bounds but keeps its own scene")
