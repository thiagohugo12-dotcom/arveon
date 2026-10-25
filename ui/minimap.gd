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
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)

func update_player(point: Vector2) -> void:
	if player_position.distance_squared_to(point) >= 16.0:
		player_position = point
		queue_redraw()

func _map_point(point: Vector2) -> Vector2:
	if styled and not arena_bounds.has_area():
		return _styled_point(point)
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
	if styled and not arena_bounds.has_area():
		_draw_styled()
		return
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

# ── Mapa expandido estilizado (Interface 2.0) ───────────────────────────────────────────
# Mesmos dados reais do minimapa (trilhas, rochas, acampamento, coletas e baús descobertos,
# posição do jogador), desenhados em escala uniforme com ícones. O minimapa pequeno não usa isto.
static var _dot: ImageTexture

# Bolinha verde do jogador, com contorno claro (mapa e legenda).
static func dot_texture() -> ImageTexture:
	if _dot == null:
		var image := Image.create(18,18,false,Image.FORMAT_RGBA8)
		for y in range(18):
			for x in range(18):
				var distance := Vector2(x + 0.5,y + 0.5).distance_to(Vector2(9,9))
				if distance <= 4.8: image.set_pixel(x,y,Color("#5fdc5a") if distance > 2.0 else Color("#a6f59a"))
				elif distance <= 6.2: image.set_pixel(x,y,Color("#173d1f"))
				elif distance <= 8.6: image.set_pixel(x,y,Color("#f4ecc2") if distance <= 7.4 else Color(0,0,0,0.0))
		_dot = ImageTexture.create_from_image(image)
	return _dot
var styled := false

func _fit() -> Rect2:
	var world := _world_size()
	var avail := size - Vector2(12,12)
	var factor := minf(avail.x / world.x,avail.y / world.y)
	var fitted := world * factor
	return Rect2(((size - fitted) / 2.0).floor(),fitted.floor())

func _styled_point(point: Vector2) -> Vector2:
	var world := _world_size()
	var field := _fit()
	return (field.position + Vector2(clampf(point.x,0,world.x) * field.size.x / world.x,clampf(point.y,0,world.y) * field.size.y / world.y)).floor()

func _blob(center: Vector2, radius: int, color: Color) -> void:
	for dy in range(-radius,radius + 1):
		var half := roundi(sqrt(maxf(0.0,float(radius * radius - dy * dy))))
		draw_rect(Rect2(center.x - half,center.y + dy,half * 2,1),color)

func _dashed(rect: Rect2, color: Color) -> void:
	var edges := [[rect.position,Vector2.RIGHT,rect.size.x],[rect.position + Vector2(0,rect.size.y),Vector2.RIGHT,rect.size.x],[rect.position,Vector2.DOWN,rect.size.y],[rect.position + Vector2(rect.size.x,0),Vector2.DOWN,rect.size.y]]
	for edge: Array in edges:
		var travelled := 0.0
		while travelled < float(edge[2]):
			var from: Vector2 = edge[0] + (edge[1] as Vector2) * travelled
			draw_rect(Rect2(from,(edge[1] as Vector2) * minf(4.0,float(edge[2]) - travelled) + Vector2(1,1)),color)
			travelled += 7.0

func _draw_styled() -> void:
	var floor_id := progress.ascension.current_floor if progress != null else 1
	var field := _fit()
	var vale := floor_id == 2
	draw_rect(Rect2(Vector2.ZERO,size),Color("#0f241b"))
	draw_rect(field,Color("#b3a35f") if vale else Color("#1e4a2c"))
	_styled_trees(field,vale)
	_styled_regions(floor_id)
	_styled_rocks(floor_id)
	_styled_trails(floor_id)
	_styled_camp(floor_id)
	_styled_discoveries(floor_id)
	_styled_player(field)
	draw_rect(field.grow(2),Color("#2f5a3d"),false,3.0)
	draw_rect(Rect2(Vector2.ZERO,size),Color("#0b1a13"),false,2.0)

func _styled_trees(field: Rect2, vale: bool) -> void:
	var step := 18.0
	var columns := int(field.size.x / step) + 1
	var rows := int(field.size.y / step) + 1
	for gy in range(rows):
		for gx in range(columns):
			var seed_value: int = absi((gx * 73856093) ^ (gy * 19349663))
			if seed_value % 100 < 22:
				continue
			var at := field.position + Vector2(gx * step + float(seed_value % 9),gy * step + float((seed_value / 9) % 9))
			if not field.has_point(at):
				continue
			var radius := 4 + seed_value % 3
			if vale:
				_blob(at,radius - 1,Color("#9a8a4a"))
				_blob(at + Vector2(-1,-1),radius - 2,Color("#cdb979"))
			else:
				_blob(at + Vector2(1,2),radius,Color("#122d1a"))
				_blob(at,radius,Color("#1a4426"))
				_blob(at + Vector2(-1,-2),radius - 2,Color("#2f6b3a"))
				if seed_value % 5 == 0:
					draw_rect(Rect2(at + Vector2(-2,-3),Vector2(2,2)),Color("#4f9a52"))

func _styled_regions(floor_id: int) -> void:
	if floor_id == 1:
		var sand := _map_rect(Rect2(1240,70,410,365))
		draw_rect(sand,Color(0.80,0.78,0.52,0.28))
		_dashed(sand,Color("#d9d29a"))
		var danger := _map_rect(Rect2(1260,440,410,400))
		draw_rect(danger,Color(0.45,0.31,0.17,0.55))
		_dashed(danger,Color("#b58a55"))
		draw_rect(_map_rect(Rect2(0,900,1300,420)),Color(0.04,0.14,0.07,0.28))
		var water := _map_rect(Rect2(1300,930,370,390))
		draw_rect(water,Color("#2a65a8"))
		draw_rect(water.grow(-3),Color("#2f73bd"))
		_dashed(water,Color("#8fc3ee"))
		draw_rect(Rect2(water.position + Vector2(8,water.size.y * 0.55),Vector2(24,6)),Color("#8a5a30"))
	else:
		for area: Rect2 in [Rect2(205,95,600,430),Rect2(1010,145,350,300),Rect2(1080,625,405,350),Rect2(1160,920,390,345)]:
			var zone := _map_rect(area)
			draw_rect(zone,Color(0.55,0.43,0.2,0.4))
			_dashed(zone,Color("#e3cf8c"))

func _styled_rocks(floor_id: int) -> void:
	var rocks: Array = [Rect2(200,120,500,90),Rect2(1040,280,330,40),Rect2(1130,990,380,45)] if floor_id == 2 else FloorView.ROCKS + (FloorView.EXPANSION_ROCKS if floor_id == 1 else [])
	for rock: Rect2 in rocks:
		var area := _map_rect(rock)
		var center := area.position + area.size / 2.0
		var span := maxi(2,int(minf(area.size.x,area.size.y) / 2.0) + 1)
		var tone := Color("#8f7d5c") if floor_id == 2 else Color("#59615d")
		_blob(center + Vector2(1,1),span,Color("#2b302d") if floor_id != 2 else Color("#6e5f43"))
		_blob(center,span,tone)
		_blob(center + Vector2(-1,-1),maxi(1,span - 2),tone.lightened(0.25))

func _styled_trails(floor_id: int) -> void:
	var trails: Array = []
	if floor_id == 2:
		trails.append_array(Floor2Layout.PATHS)
	else:
		trails.append_array(FloorView.TRAILS)
		if floor_id == 1:
			for item: Dictionary in FloorView.EXPANSION_TRAILS: trails.append(item.points)
			if progress != null and progress.discovered_pois.has("secretwood_wood_southeast"): trails.append(FloorView.SECRET_TRAIL)
	for trail: Array in trails:
		var points := PackedVector2Array()
		for point: Vector2 in trail: points.append(_styled_point(point))
		var shadow := PackedVector2Array()
		for point: Vector2 in points: shadow.append(point + Vector2(1,1))
		draw_polyline(shadow,Color(0,0,0,0.45),4.0,false)
		draw_polyline(points,Color("#dcc58c") if floor_id != 2 else Color("#f0dba0"),3.0,false)
		for end_point: Vector2 in [points[0],points[points.size() - 1]]:
			draw_rect(Rect2(end_point - Vector2(2,2),Vector2(5,5)),Color("#f1e2b0"))

func _styled_camp(floor_id: int) -> void:
	var area := SafeCamp.area_for_floor(floor_id)
	var zone := _map_rect(area)
	draw_rect(zone,Color(0.62,0.78,0.5,0.4))
	var fire := DefeatArt.texture("fire",2)
	draw_texture(fire,(zone.position + zone.size / 2.0 - fire.get_size() / 2.0).floor())
	if floor_id == 2:
		draw_rect(Rect2(_styled_point(Floor2Layout.TOWER_POSITION) - Vector2(3,3),Vector2(6,6)),Color("#e8c982"))

func _styled_discoveries(floor_id: int) -> void:
	if progress == null:
		return
	var leaf := DefeatArt.texture("leaf_badge",2)
	for spot: Dictionary in Exploration.resources_for_floor(floor_id):
		if progress.discovered_pois.has(spot.id):
			draw_texture(leaf,(_styled_point(spot.position) - leaf.get_size() / 2.0).floor())
	var chest := DefeatArt.texture("chest",2)
	for cache: Dictionary in Exploration.chests_for_floor(floor_id):
		if progress.opened_caches.has(cache.id):
			draw_texture(chest,(_styled_point(cache.position) - chest.get_size() / 2.0).floor())

func _styled_player(field: Rect2) -> void:
	var center := _styled_point(player_position).clamp(field.position + Vector2(18,18),field.end - Vector2(18,28))
	draw_texture(dot_texture(),(center - dot_texture().get_size() / 2.0).floor())
	var font := DefeatView.font()
	var label := "Você"
	var width := font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
	var plate := Rect2(center + Vector2(-width / 2.0 - 7,11),Vector2(width + 14,19))
	draw_rect(plate.grow(1),Color("#e8d6a0"))
	draw_rect(plate,Color("#10261b"))
	draw_string(font,plate.position + Vector2(7,14),label,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#fff0c3"))
