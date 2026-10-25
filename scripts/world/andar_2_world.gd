class_name Andar2World
extends FloorWorld

# Solid footprints use the same authored placement list as the renderer.
func _ready() -> void:
	_set_world_boundaries(Floor2Layout.WORLD_SIZE)
	for side: Rect2 in TowerEntrance.ANDAR2_SIDES:
		_add_box(side)
	for object: Dictionary in Floor2Layout.OBJECTS:
		var kind: String = object.kind
		var feet: Vector2 = object.feet
		match kind:
			"arvore-pequena", "arvore-media":
				_add_circle(feet + Vector2(0, -9), 17.0)
			"arbusto":
				_add_circle(feet + Vector2(0, -7), 11.0)
			"rocha-arenito", "deposito-mineral":
				var width := 76.0 if kind == "deposito-mineral" else 82.0
				_add_box(Rect2(feet - Vector2(width * 0.5, 21), Vector2(width, 18)))
			"paredao":
				_add_box(Rect2(feet - Vector2(84, 28), Vector2(168, 24)))
			"coluna-quebrada", "marco-ancestral", "barril":
				_add_circle(feet + Vector2(0, -10), 12.0 if kind == "barril" else 17.0)
			"muro-antigo":
				_add_box(Rect2(feet - Vector2(64, 17), Vector2(128, 18)))
			"altar-antigo":
				_add_box(Rect2(feet - Vector2(55, 19), Vector2(110, 18)))
			"carrinho", "caixa-minerios":
				_add_box(Rect2(feet - Vector2(27, 15), Vector2(54, 16)))
			"suporte-madeira":
				_add_circle(feet + Vector2(-40, -10), 8.0)
				_add_circle(feet + Vector2(40, -10), 8.0)
			"forja":
				_add_box(Rect2(feet - Vector2(57, 22), Vector2(114, 23)))
			"mercado":
				_add_box(Rect2(feet - Vector2(51, 21), Vector2(102, 21)))
			"bau":
				_add_box(Rect2(feet - Vector2(24, 19), Vector2(48, 19)))
			"fogueira":
				_add_circle(feet + Vector2(0, -13), 18.0)
