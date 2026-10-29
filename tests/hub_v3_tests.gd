extends RefCounted

static func run(suite, main) -> void:
	var view: FloorView = main.world.get_node("FloorView")
	var player: PlayerActor = main.player
	var before := player.position
	for shape: CollisionShape2D in main.world.legacy_solids:
		suite.check(shape.disabled,"village disables obsolete camp obstacle")
	for shape: CollisionShape2D in main.world.hidden_village_trunks:
		suite.check(shape.disabled,"no invisible trunk beneath village building")
	for base: Rect2 in FloorV2View.BUILDING_BASES:
		player.position = Vector2(base.get_center().x,base.end.y+30)
		suite.check(player.test_move(player.transform,Vector2(0,-40)),"visible building base stops player "+str(base))
	for npc in view.get_children():
		if npc is CampNpcView:
			var service := "Ferreiro" if npc.kind == 0 else "Vendedor"
			suite.check(npc.position+Vector2(0,21) == SafeCamp.DISPLAY_STATIONS[service],"NPC feet align to "+service)
			var planted: Vector2 = npc.position
			for i in range(100): npc._process(0.1)
			suite.check(npc.position == planted,"idle animation never slides NPC or changes service anchor "+service)
	suite.check(player.view.village_scale,"floor-one explorer uses village presentation without scaling physics")
	for name: String in SafeCamp.DISPLAY_STATIONS:
		var anchor: Vector2 = SafeCamp.DISPLAY_STATIONS[name]
		player.position = anchor+Vector2(24,0)
		# The chest shares this corner with the visible campfire. Its flame core is
		# intentionally solid, so reachability is verified through the real prompt.
		if name != "Baú": suite.check(not player.test_move(player.transform,Vector2(1,0)),"service approach has no leftover collider "+name)
		suite.check(main._interaction_target().get("id","") == name,"actual gameplay opens visible service "+name)
		suite.check(SafeCamp.in_clearance(anchor),"service remains inside protected perimeter "+name)
	player.position = Vector2(500,540)
	suite.check(not player.test_move(player.transform,Vector2(0,-15)) and player.test_move(player.transform,Vector2(0,-42)),"chest can be approached but its visible base blocks passage")
	player.position = Vector2(534,590)
	suite.check(player.test_move(player.transform,Vector2(0,-42)),"campfire logs block passage through the flame")
	player.position = Vector2(280,410)
	suite.check(player.test_move(player.transform,Vector2(60,0)),"village bush has a solid base without filling its canopy")
	player.position = before
