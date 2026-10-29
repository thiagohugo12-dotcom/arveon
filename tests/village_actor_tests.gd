extends RefCounted

static func run(suite, main) -> void:
	for entry: Array in [[VillageActorArt.PEOPLE,6,40],[VillageActorArt.MONSTERS,3,32]]:
		var image: Image = entry[0].get_image()
		for row in range(entry[1]):
			var poses: Array[PackedByteArray] = []
			for frame in range(4):
				var cell := image.get_region(Rect2i(frame*32,row*entry[2],32,entry[2]))
				var opaque := 0
				for y in range(cell.get_height()):
					for x in range(32):
						if cell.get_pixel(x,y).a > 0.95: opaque += 1
				suite.check(opaque > 180 and cell.get_pixel(0,0).a == 0.0,"new actor pose has solid interior and transparent margin %d/%d" % [row,frame])
				poses.append(cell.get_data())
			suite.check(poses[1] != poses[3],"opposite stride/action frames are distinct row %d" % row)
	var view := ActorView.new()
	suite.root.add_child(view)
	view.village_scale = true
	view.appearance = 1
	view.set_moving(true)
	view.global_position += Vector2(12,0)
	view._process(0.1)
	var frame := view.anim_frame
	view._process(1.0)
	suite.check(frame == 1 and view.anim_frame == frame,"new monster stride follows movement and cannot walk in place against walls")
	view.queue_free()
	var explore := ExplorationView.new()
	explore.visual_v2 = true
	explore.progress = GameProgress.new()
	explore.current_time = 1000
	suite.root.add_child(explore)
	explore._process(0.01)
	explore.progress.harvested_until["wood_north"] = 1300
	explore.progress.opened_caches["west_roots"] = true
	explore._process(0.01)
	suite.check(explore.resource_fades.has("wood_north") and explore.cache_motion.has("west_roots"),"collection and real chest state changes start visual transitions")
	explore._process(0.3)
	suite.check(explore.resource_fades.is_empty() and explore.cache_motion.is_empty(),"pickup and chest transitions finish with no lingering visual objects")
	suite.check(explore.progress.harvested_until["wood_north"] == 1300 and explore.progress.opened_caches["west_roots"],"animations cannot change resource cooldown or chest rewards state")
	explore.queue_free()
	var floor_view: FloorView = main.world.get_node("FloorView")
	main.player.position = SafeCamp.DISPLAY_STATIONS["Baú"]+Vector2(20,0)
	main._interact()
	suite.check(main.hud.station_name == "Baú" and floor_view.chest_view.opened,"actual storage interaction opens the village chest art")
	main.hud.close_station()
	suite.check(not floor_view.chest_view.opened,"closing storage returns chest art to closed pose")
	main.player.position = SafeCamp.RESPAWN
