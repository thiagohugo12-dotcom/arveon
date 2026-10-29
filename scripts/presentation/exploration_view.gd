class_name ExplorationView
extends Node2D

var visual_v2 := false
var current_floor := 1
var progress: GameProgress
var current_time := 0
var motion_time := 0.0
var resource_available: Dictionary = {}
var resource_fades: Dictionary = {}
var cache_opened: Dictionary = {}
var cache_motion: Dictionary = {}
var pieces: Dictionary = {}

func _piece(id: String, at: Vector2) -> Node2D:
	if not pieces.has(id):
		var node := Node2D.new()
		node.set_script(preload("res://scripts/presentation/village_pickup_view.gd"))
		node.position = at
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		node.z_as_relative = false
		node.z_index = roundi(at.y)+100
		add_child(node)
		pieces[id] = node
	return pieces[id]

func _process(delta: float) -> void:
	if not visual_v2 or progress == null:
		for node: Node2D in pieces.values(): node.hide()
		return
	motion_time += delta
	for spot: Dictionary in Exploration.resources_for_floor(current_floor):
		var available := int(progress.harvested_until.get(spot.id,0)) <= current_time
		if resource_available.get(spot.id,available) and not available:
			resource_fades[spot.id] = 0.22
		resource_available[spot.id] = available
		if resource_fades.has(spot.id):
			resource_fades[spot.id] = maxf(0.0,resource_fades[spot.id]-delta)
			if resource_fades[spot.id] == 0.0: resource_fades.erase(spot.id)
		var node := _piece(spot.id,spot.position)
		node.visible = available or resource_fades.has(spot.id)
		var pose := 8 if spot.item == "Pedras" else 3 if spot.item == "Ervas" else 6 if spot.item == "Madeira" else (4 if int(motion_time*2.0+spot.position.x)%8 != 0 else 5)
		var tint := Color.WHITE
		if resource_fades.has(spot.id):
			var remaining: float = resource_fades[spot.id]
			tint.a = remaining/0.22
			if spot.item == "Madeira": pose = 7
			elif spot.item == "Cogumelos": pose = 5
		node.set_pose(pose,tint)
	for cache: Dictionary in Exploration.chests_for_floor(current_floor):
		var opened := progress.opened_caches.has(cache.id)
		if opened and not cache_opened.get(cache.id,opened): cache_motion[cache.id] = 0.24
		cache_opened[cache.id] = opened
		if cache_motion.has(cache.id):
			cache_motion[cache.id] = maxf(0.0,cache_motion[cache.id]-delta)
			if cache_motion[cache.id] == 0.0: cache_motion.erase(cache.id)
		var node := _piece(cache.id,cache.position)
		node.show()
		node.set_pose(1 if cache_motion.get(cache.id,0.0) > 0.12 else 2 if opened else 0)

func _draw() -> void:
	if progress == null:
		return
	if current_floor == 1:
		var altar := Vector2(1060, 155)
		draw_rect(Rect2(altar - Vector2(24, 20), Vector2(48, 40)), Color("#4b5740"))
		draw_rect(Rect2(altar - Vector2(10, 30), Vector2(20, 44)), Color("#8a7854"))
		draw_string(ThemeDB.fallback_font, altar + Vector2(-54, -38), "Guardião · opcional", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#decb91"))
	if visual_v2: return # V4 pieces share actor/tree depth, created once above.
	for spot: Dictionary in Exploration.resources_for_floor(current_floor):
		if int(progress.harvested_until.get(spot.id, 0)) > current_time:
			continue
		_draw_resource(spot.position, spot.item)
	for cache: Dictionary in Exploration.chests_for_floor(current_floor):
		_draw_cache(cache.position, progress.opened_caches.has(cache.id))

func _draw_resource(at: Vector2, item: String) -> void:
	draw_rect(Rect2(at + Vector2(-13, 9), Vector2(26, 4)), Color("#172b23"))
	match item:
		"Ervas":
			draw_rect(Rect2(at + Vector2(-2, -5), Vector2(4, 15)), Color("#589250"))
			draw_rect(Rect2(at + Vector2(-10, -10), Vector2(9, 7)), Color("#83ae5c"))
			draw_rect(Rect2(at + Vector2(2, -13), Vector2(9, 8)), Color("#a1c66f"))
		"Cogumelos":
			for dx in [-7, 5]:
				draw_rect(Rect2(at + Vector2(dx, -2), Vector2(4, 12)), Color("#d8c9a4"))
				draw_rect(Rect2(at + Vector2(dx - 4, -8), Vector2(12, 6)), Color("#bb705a"))
		"Madeira":
			draw_rect(Rect2(at + Vector2(-12, -6), Vector2(24, 16)), Color("#614531"))
			draw_rect(Rect2(at + Vector2(-9, -3), Vector2(18, 4)), Color("#9a7147"))
			draw_rect(Rect2(at + Vector2(4, 3), Vector2(5, 4)), Color("#b48d5b"))
		"Pedras":
			draw_rect(Rect2(at + Vector2(-12, -2), Vector2(23, 12)), Color("#4d6767"))
			draw_rect(Rect2(at + Vector2(-6, -8), Vector2(14, 9)), Color("#82938c"))
			draw_rect(Rect2(at + Vector2(0, -8), Vector2(4, 5)), Color("#a7aaa0"))

func _draw_cache(at: Vector2, opened: bool) -> void:
	draw_rect(Rect2(at + Vector2(-13, 10), Vector2(28, 5)), Color("#1d2824"))
	draw_rect(Rect2(at + Vector2(-12, -6), Vector2(25, 17)), Color("#715431"))
	if opened:
		draw_rect(Rect2(at + Vector2(-12, -13), Vector2(25, 6)), Color("#a58853"))
		draw_rect(Rect2(at + Vector2(-8, -3), Vector2(17, 8)), Color("#2b3429"))
	else:
		draw_rect(Rect2(at + Vector2(-12, -10), Vector2(25, 5)), Color("#b59149"))
		draw_rect(Rect2(at + Vector2(-3, -8), Vector2(6, 16)), Color("#e1cb75"))
