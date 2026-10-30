class_name Andar3World
extends FloorWorld

# Física do Pântano: água funda bloqueia (retângulos da máscara, com as pontes
# já abertas), troncos de árvore, ruínas e peças do acampamento têm base sólida.
func _ready() -> void:
	_set_world_boundaries(Floor3Layout.WORLD_SIZE)
	for rect: Rect2 in Floor3Layout.water_rects():
		var node := _add_box(rect)
		node.set_meta("pantano_agua", true)
	for structure: Dictionary in Floor3Layout.STRUCTURES:
		var solid: Dictionary = structure.get("solid", {})
		var feet: Vector2 = structure.feet
		if solid.has("radius"):
			_add_circle(feet + Vector2(0, -4), float(solid.radius))
		elif solid.has("legs"):
			var spread := float(solid.legs)
			_add_circle(feet + Vector2(-spread, -6), 12.0)
			_add_circle(feet + Vector2(spread, -6), 12.0)
		elif solid.has("box"):
			var half: Vector2 = solid.box
			_add_box(Rect2(feet - Vector2(half.x, half.y * 2.0), half * 2.0))
	for at: Vector2 in Floor3Layout.decor().trees:
		_add_circle(at + Vector2(0, 4), 15.0)
