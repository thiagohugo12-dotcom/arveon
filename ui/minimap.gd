class_name MiniMap
extends Control

const MAP_ORIGIN := Vector2(4, 12)
const MAP_SIZE := Vector2(88, 66)
const WORLD_SIZE := Vector2(1200, 900)

var arena_bounds := Rect2()
var progress: GameProgress
var player_position := SafeCamp.RESPAWN

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func update_player(point: Vector2) -> void:
	if player_position.distance_squared_to(point) >= 16.0:
		player_position = point
		queue_redraw()

func _map_point(point: Vector2) -> Vector2:
	var map_size := size - Vector2(8, 8)
	if arena_bounds.has_area():
		var local := point - arena_bounds.position
		return Vector2(4, 4) + Vector2(clampf(local.x, 0, arena_bounds.size.x) * map_size.x / arena_bounds.size.x, clampf(local.y, 0, arena_bounds.size.y) * map_size.y / arena_bounds.size.y)
	var current_size := _world_size()
	return Vector2(4, 4) + Vector2(clampf(point.x, 0, current_size.x) * map_size.x / current_size.x,
		clampf(point.y, 0, current_size.y) * map_size.y / current_size.y)

func _world_size() -> Vector2:
	return FloorConfig.world_size(progress.ascension.current_floor) if progress != null else WORLD_SIZE

func _map_rect(world_rect: Rect2) -> Rect2:
	var start := _map_point(world_rect.position)
	var finish := _map_point(world_rect.end)
	return Rect2(start,finish-start)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#162b25"))
	draw_rect(Rect2(Vector2.ZERO, size), Color("#baa778"), false, 2.0)
	draw_rect(Rect2(Vector2(4, 4), size - Vector2(8, 8)), Color("#264634"))
	if arena_bounds.has_area():
		draw_rect(Rect2(Vector2(4, 4), size - Vector2(8, 8)), Color("#66796b"))
		for point: Vector2 in [TowerTrial.ORIGIN + Vector2(360, 45), TowerTrial.EXIT]:
			draw_rect(Rect2(_map_point(point) - Vector2(3, 2), Vector2(6, 4)), Color("#dac080"))
		draw_rect(Rect2(_map_point(player_position) - Vector2(2, 2), Vector2(5, 5)), Color("#f2f0d6"))
		return
	var floor_id := progress.ascension.current_floor if progress != null else 1
	if floor_id == 2:
		_draw_vale()
		return
	if floor_id == 1:
		draw_rect(_map_rect(Rect2(1240,70,410,365)),Color(0.78,0.69,0.48,0.42))
		draw_rect(_map_rect(Rect2(1260,440,410,400)),Color(0.62,0.34,0.27,0.34))
		draw_rect(_map_rect(Rect2(0,900,1300,420)),Color(0.20,0.39,0.25,0.40))
		draw_rect(_map_rect(Rect2(1300,930,370,390)),Color(0.37,0.39,0.53,0.38))
	for trail: Array in FloorView.TRAILS:
		var points := PackedVector2Array()
		for point: Vector2 in trail:
			points.append(_map_point(point))
		draw_polyline(points, Color("#a49363"), 2.0, false)
	if floor_id == 1:
		for i in range(FloorView.EXPANSION_TRAILS.size()):
			var points := PackedVector2Array()
			for point: Vector2 in FloorView.EXPANSION_TRAILS[i].points:
				points.append(_map_point(point))
			draw_polyline(points,Color("#a49363"),2.0,false)
		if progress != null and progress.discovered_pois.has("secretwood_wood_southeast"):
			var secret_points := PackedVector2Array()
			for point: Vector2 in FloorView.SECRET_TRAIL: secret_points.append(_map_point(point))
			draw_polyline(secret_points,Color("#d8be77"),2.0,false)
	for rock: Rect2 in FloorView.ROCKS:
		var start := _map_point(rock.position)
		var end := _map_point(rock.end)
		draw_rect(Rect2(start, end - start), Color("#667973"))
	var camp_start := _map_point(SafeCamp.AREA.position)
	var camp_end := _map_point(SafeCamp.AREA.end)
	draw_rect(Rect2(camp_start, camp_end - camp_start), Color("#9ec681"))
	if progress != null:
		if progress.introduction_active():
			var smith := _map_point(SafeCamp.DISPLAY_STATIONS.Ferreiro)
			draw_rect(Rect2(smith-Vector2(3,3),Vector2(7,7)),Color("#e7b867"),false,2.0)
		for spot: Dictionary in Exploration.resources_for_floor(floor_id):
			if progress.discovered_pois.has(spot.id):
				draw_rect(Rect2(_map_point(spot.position) - Vector2(2, 2), Vector2(4, 4)), Color("#c0d586"))
		for cache: Dictionary in Exploration.chests_for_floor(floor_id):
			if progress.opened_caches.has(cache.id):
				draw_rect(Rect2(_map_point(cache.position) - Vector2(2, 2), Vector2(5, 5)), Color("#e7b867"))
	draw_rect(Rect2(_map_point(player_position) - Vector2(2, 2), Vector2(5, 5)), Color("#f2f0d6"))

func _draw_vale() -> void:
	draw_rect(Rect2(Vector2(4, 4), size - Vector2(8, 8)), Color("#a8b75e"))
	for area: Rect2 in [Rect2(205, 95, 600, 430), Rect2(1010, 145, 350, 300), Rect2(1080, 625, 405, 350), Rect2(1160, 920, 390, 345)]:
		draw_rect(_map_rect(area), Color("#d7c28070"))
	for path: Array in Floor2Layout.PATHS:
		var points := PackedVector2Array()
		for point: Vector2 in path: points.append(_map_point(point))
		draw_polyline(points, Color("#ead092"), 2.0, false)
	for rock: Rect2 in [Rect2(200, 120, 500, 90), Rect2(1040, 280, 330, 40), Rect2(1130, 990, 380, 45)]:
		draw_rect(_map_rect(rock), Color("#97815b"))
	draw_rect(_map_rect(Floor2Layout.CAMP_AREA), Color("#9dc07896"))
	draw_rect(Rect2(_map_point(Floor2Layout.TOWER_POSITION) - Vector2(2, 2), Vector2(4, 4)), Color("#e8c982"))
	if progress != null:
		for spot: Dictionary in Exploration.resources_for_floor(2):
			if progress.discovered_pois.has(spot.id):
				draw_rect(Rect2(_map_point(spot.position) - Vector2(2, 2), Vector2(4, 4)), Color("#c6df94"))
		for cache: Dictionary in Exploration.chests_for_floor(2):
			if progress.opened_caches.has(cache.id):
				draw_rect(Rect2(_map_point(cache.position) - Vector2(2, 2), Vector2(5, 5)), Color("#e7b867"))
	draw_rect(Rect2(_map_point(player_position) - Vector2(2, 2), Vector2(5, 5)), Color("#f2f0d6"))
