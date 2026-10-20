class_name FloorWorld
extends Node2D

@onready var walls: StaticBody2D = $Walls

# Shared scene contract. Individual floors add only their own decoration and solids.
func set_expanded_world(_enabled: bool) -> void:
	pass

func _set_world_boundaries(world_size: Vector2) -> void:
	_set_boundary("Top", Vector2(world_size.x * 0.5, 0), Vector2(world_size.x, 32))
	_set_boundary("Bottom", Vector2(world_size.x * 0.5, world_size.y), Vector2(world_size.x, 32))
	_set_boundary("Left", Vector2(0, world_size.y * 0.5), Vector2(32, world_size.y))
	_set_boundary("Right", Vector2(world_size.x, world_size.y * 0.5), Vector2(32, world_size.y))

func _set_boundary(name: String, at: Vector2, size: Vector2) -> void:
	var boundary := walls.get_node(name) as CollisionShape2D
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	boundary.shape = rectangle
	boundary.position = at

func _add_circle(at: Vector2, radius: float) -> CollisionShape2D:
	var node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	node.shape = shape
	node.position = at
	walls.add_child(node)
	return node

func _add_box(area: Rect2) -> CollisionShape2D:
	var node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = area.size
	node.shape = shape
	node.position = area.get_center()
	walls.add_child(node)
	return node
