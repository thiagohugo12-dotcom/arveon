class_name MiniMap
extends Control

const MAP_ORIGIN := Vector2(4, 12)
const MAP_SIZE := Vector2(88, 66)
const WORLD_SIZE := Vector2(1200, 900)

var progress: GameProgress
var player_position := SafeCamp.RESPAWN

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(96, 80)
	var title := Label.new()
	title.text = "Mapa"
	title.position = Vector2(6, -2)
	title.add_theme_font_size_override("font_size", 9)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

func update_player(point: Vector2) -> void:
	if player_position.distance_squared_to(point) >= 16.0:
		player_position = point
		queue_redraw()

func _map_point(point: Vector2) -> Vector2:
	return MAP_ORIGIN + Vector2(clampf(point.x, 0, WORLD_SIZE.x) * MAP_SIZE.x / WORLD_SIZE.x,
		clampf(point.y, 0, WORLD_SIZE.y) * MAP_SIZE.y / WORLD_SIZE.y)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#162b25"))
	draw_rect(Rect2(Vector2.ZERO, size), Color("#baa778"), false, 2.0)
	draw_rect(Rect2(MAP_ORIGIN, MAP_SIZE), Color("#264634"))
	for trail: Array in FloorView.TRAILS:
		var points := PackedVector2Array()
		for point: Vector2 in trail:
			points.append(_map_point(point))
		draw_polyline(points, Color("#76694a"), 2.0, false)
	for rock: Rect2 in FloorView.ROCKS:
		var start := _map_point(rock.position)
		var end := _map_point(rock.end)
		draw_rect(Rect2(start, end - start), Color("#667973"))
	var camp_start := _map_point(SafeCamp.AREA.position)
	var camp_end := _map_point(SafeCamp.AREA.end)
	draw_rect(Rect2(camp_start, camp_end - camp_start), Color("#9ec681"))
	if progress != null:
		for spot: Dictionary in Exploration.RESOURCE_SPOTS:
			if progress.discovered_pois.has(spot.id):
				draw_rect(Rect2(_map_point(spot.position) - Vector2(2, 2), Vector2(4, 4)), Color("#c0d586"))
		for cache: Dictionary in Exploration.HIDDEN_CHESTS:
			if progress.opened_caches.has(cache.id):
				draw_rect(Rect2(_map_point(cache.position) - Vector2(2, 2), Vector2(5, 5)), Color("#e7b867"))
	draw_rect(Rect2(_map_point(player_position) - Vector2(2, 2), Vector2(5, 5)), Color("#f2f0d6"))
