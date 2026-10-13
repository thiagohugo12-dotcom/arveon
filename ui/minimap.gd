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
	return Vector2(4, 4) + Vector2(clampf(point.x, 0, WORLD_SIZE.x) * map_size.x / WORLD_SIZE.x,
		clampf(point.y, 0, WORLD_SIZE.y) * map_size.y / WORLD_SIZE.y)

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
	for trail: Array in FloorView.TRAILS:
		var points := PackedVector2Array()
		for point: Vector2 in trail:
			points.append(_map_point(point))
		draw_polyline(points, Color("#a49363"), 2.0, false)
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
		for spot: Dictionary in Exploration.RESOURCE_SPOTS:
			if progress.discovered_pois.has(spot.id):
				draw_rect(Rect2(_map_point(spot.position) - Vector2(2, 2), Vector2(4, 4)), Color("#c0d586"))
		for cache: Dictionary in Exploration.HIDDEN_CHESTS:
			if progress.opened_caches.has(cache.id):
				draw_rect(Rect2(_map_point(cache.position) - Vector2(2, 2), Vector2(5, 5)), Color("#e7b867"))
	draw_rect(Rect2(_map_point(player_position) - Vector2(2, 2), Vector2(5, 5)), Color("#f2f0d6"))
