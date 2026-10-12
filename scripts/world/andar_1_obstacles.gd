extends Node2D

# Solids share the deterministic feet drawn by FloorView. Grass and shrubs have no shapes.
@onready var floor_view: FloorView = $FloorView
@onready var walls: StaticBody2D = $Walls
var legacy_solids: Array[CollisionShape2D] = []
var village_solids: Array[CollisionShape2D] = []
var hidden_village_trunks: Array[CollisionShape2D] = []

func _ready() -> void:
	_add_box(TowerEntrance.BODY)
	for foot in floor_view.tree_positions():
		_add_circle(foot + Vector2(0, 1), 9.0)
		if FloorV2View.canopy_conflicts(foot): hidden_village_trunks.append(walls.get_child(-1) as CollisionShape2D)
	var shared_count := walls.get_child_count()
	# Building, the three service fixtures and wooden props retain their art positions.
	for area: Rect2 in [
		Rect2(463, 340, 62, 34), # cottage wall, clear of the northern path
		Rect2(492, 382, 26, 14), # chest at its door
		Rect2(590, 380, 36, 28), # smith
		Rect2(590, 503, 36, 28), # vendor
		Rect2(477, 349, 39, 7), Rect2(583, 349, 58, 7),
		Rect2(477, 545, 39, 7), Rect2(583, 545, 58, 7)
	]:
		_add_box(area)
	for post: Vector2 in [Vector2(474, 380), Vector2(474, 400), Vector2(474, 490), Vector2(474, 510),
		Vector2(644, 380), Vector2(644, 400), Vector2(644, 490), Vector2(644, 510),
		Vector2(480, 411), Vector2(633, 420), Vector2(484, 526), Vector2(631, 535)]:
		_add_circle(post, 5.0)
	for i in range(shared_count,walls.get_child_count()):
		legacy_solids.append(walls.get_child(i) as CollisionShape2D)
	var legacy_count := walls.get_child_count()
	for area: Rect2 in FloorV2View.BUILDING_BASES:
		_add_box(area)
	for feet: Vector2 in [Vector2(346,462),Vector2(444,610),Vector2(714,420),Vector2(714,662)]:
		_add_box(Rect2(feet-Vector2(32,8),Vector2(64,8)))
	_add_box(Rect2(487,515,26,14))
	_add_box(Rect2(592,515,12,10))
	for i in range(legacy_count,walls.get_child_count()):
		village_solids.append(walls.get_child(i) as CollisionShape2D)
	set_village_solids(floor_view.visual_v2)

func set_village_solids(enabled: bool) -> void:
	for shape in legacy_solids: shape.set_deferred("disabled",enabled)
	for shape in village_solids: shape.set_deferred("disabled",not enabled)
	for shape in hidden_village_trunks: shape.set_deferred("disabled",enabled)

func _add_circle(at: Vector2, radius: float) -> void:
	var node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	node.shape = shape
	node.position = at
	walls.add_child(node)

func _add_box(area: Rect2) -> void:
	var node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = area.size
	node.shape = shape
	node.position = area.get_center()
	walls.add_child(node)
