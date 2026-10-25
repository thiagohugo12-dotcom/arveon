class_name Andar1Obstacles
extends FloorWorld

# Solids share the deterministic feet drawn by FloorView. Grass is decorative;
# shrubs have small bases so their foliage can still overlap the explorer.
@onready var floor_view: FloorView = $FloorView
var legacy_solids: Array[CollisionShape2D] = []
var village_solids: Array[CollisionShape2D] = []
var hidden_village_trunks: Array[CollisionShape2D] = []
var expansion_solids: Array[CollisionShape2D] = []
var legacy_tower_shape: CollisionShape2D

func _ready() -> void:
	legacy_tower_shape = _add_box(TowerEntrance.LEGACY_BODY)
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
	for feet: Vector2 in FloorV2View.new().bush_positions():
		_add_circle(feet+Vector2(0,-6),10.0)
	# The chest sprite ends near y=507; its previous collider was below the art.
	_add_box(Rect2(482,489,38,20))
	_add_box(Rect2(592,515,12,10))
	# The burning logs sit above the nominal sprite feet at y=570.
	_add_circle(Vector2(534,555),13.0)
	for i in range(legacy_count,walls.get_child_count()):
		village_solids.append(walls.get_child(i) as CollisionShape2D)
	set_village_solids(floor_view.visual_v2)
	_set_world_boundaries(FloorConfig.DEFAULT_WORLD_SIZE)

func set_village_solids(enabled: bool) -> void:
	for shape in legacy_solids: shape.set_deferred("disabled",enabled)
	for shape in village_solids: shape.set_deferred("disabled",not enabled)
	for shape in hidden_village_trunks: shape.set_deferred("disabled",enabled)

func set_expanded_world(enabled: bool) -> void:
	floor_view.set_expanded_world(enabled)
	legacy_tower_shape.set_deferred("disabled",enabled)
	if enabled and expansion_solids.is_empty():
		_build_expansion_solids()
	for shape in expansion_solids: shape.set_deferred("disabled",not enabled)
	_set_world_boundaries(FloorConfig.ANDAR1_WORLD_SIZE if enabled else FloorConfig.DEFAULT_WORLD_SIZE)

func _build_expansion_solids() -> void:
	for side: Rect2 in TowerEntrance.ANDAR1_SIDES:
		expansion_solids.append(_add_box(side))
	expansion_solids.append(_add_box(TowerEntrance.ANDAR1_UPPER))
	for feet: Vector2 in floor_view.expansion_tree_positions():
		expansion_solids.append(_add_circle(feet+Vector2(0,1),9.0))
	for rock: Rect2 in FloorView.EXPANSION_ROCKS:
		# The visible boulders are scaled up; collide at their visible base so the
		# enlarged art does not let the player walk through the rock silhouette.
		expansion_solids.append(_add_box(Rect2(rock.position+Vector2(rock.size.x*0.2,rock.size.y-13),Vector2(rock.size.x*0.6,12))))
	for block: Rect2 in FloorView._ruin_blocks():
		expansion_solids.append(_add_box(block))
	# Match the altar base and fallen-log silhouettes to their visible footprints.
	expansion_solids.append(_add_box(Rect2(1474,214,52,12)))
	for log: Rect2 in FloorView.DEEPWOOD_LOGS:
		expansion_solids.append(_add_box(log))
	for feet: Vector2 in floor_view.expansion_bush_positions():
		expansion_solids.append(_add_circle(feet+Vector2(0,-6),10.0))
	expansion_solids.append(_add_circle(Vector2(1510,1161),16.0))
	for shape in expansion_solids: shape.set_deferred("disabled",true)
