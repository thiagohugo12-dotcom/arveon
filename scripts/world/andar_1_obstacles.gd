extends Node2D

# Solids share the deterministic feet drawn by FloorView. Grass and shrubs have no shapes.
@onready var floor_view: FloorView = $FloorView
@onready var walls: StaticBody2D = $Walls

func _ready() -> void:
	_add_box(TowerEntrance.BODY)
	for foot in floor_view.tree_positions():
		_add_circle(foot + Vector2(0, 1), 9.0)
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
