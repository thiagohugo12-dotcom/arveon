class_name Floor2View
extends FloorView

const GROUND := preload("res://assets/art/andar2/refined/terrain-full.png")
const CHEST_VIEW := preload("res://scripts/presentation/village_chest_view.gd")
var floor2_chest: Node2D
var mining_sprites: Dictionary = {}

func _object_art(kind: String, feet: Vector2) -> String:
	var refined := "res://assets/art/andar2/refined/"
	match kind:
		"rocha-arenito": return refined + "sandstone-boulder.png"
		"paredao":
			return refined + ("arena-stones.png" if feet.x > 1050.0 and feet.y > 900.0 else "sandstone-outcrop.png")
		"deposito-mineral": return refined + "iron-deposit.png"
		"arvore-media":
			return refined + ("cerrado-tree-medium-b.png" if int(feet.x + feet.y) % 3 == 0 else "cerrado-tree-medium.png")
		"arvore-pequena": return refined + "cerrado-tree-small.png"
		"arbusto":
			return refined + ("cerrado-shrub-b.png" if int(feet.x) % 3 == 0 else "cerrado-shrub.png")
		"coluna-quebrada": return refined + ("ruin-pillar-b.png" if int(feet.x) % 3 == 0 else "ruin-pillar.png")
		"marco-ancestral": return refined + ("ruin-marker-b.png" if int(feet.x) % 3 == 0 else "ruin-marker.png")
		"muro-antigo": return refined + "ruin-wall.png"
		"altar-antigo": return refined + "ruin-altar.png"
	return "res://assets/art/andar2/%s.png" % kind

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for object: Dictionary in Floor2Layout.OBJECTS:
		var kind: String = object.kind
		var feet: Vector2 = object.feet
		if kind == "bau":
			floor2_chest = CHEST_VIEW.new()
			floor2_chest.position = feet - Vector2(0, 14)
			floor2_chest.z_as_relative = false
			floor2_chest.z_index = roundi(feet.y) + 100
			add_child(floor2_chest)
			continue
		var sprite := Sprite2D.new()
		sprite.texture = load(_object_art(kind, feet)) as Texture2D
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = false
		sprite.offset = Vector2(-sprite.texture.get_width() * 0.5, -sprite.texture.get_height())
		sprite.position = feet
		sprite.scale = Vector2(2, 2)
		sprite.z_as_relative = false
		sprite.z_index = roundi(feet.y) + 100
		add_child(sprite)
		if kind == "deposito-mineral":
			for deposit: Dictionary in MiningRules.deposits(2):
				if deposit.position == feet: mining_sprites[deposit.id] = sprite
	for station: String in ["Ferreiro", "Vendedor"]:
		var npc := NPC_VIEW.new() as CampNpcView
		npc.kind = 0 if station == "Ferreiro" else 1
		npc.visual_v2 = true
		npc.position = Floor2Layout.STATIONS[station] - Vector2(0, 21)
		npc.z_as_relative = false
		npc.z_index = roundi(Floor2Layout.STATIONS[station].y) + 100
		add_child(npc)

func _draw() -> void:
	# A visao afastada e as telas verticais podem mostrar alem do limite do mundo.
	# Continue a cor do Cerrado para evitar uma moldura verde de outro bioma.
	draw_rect(Rect2(-Floor2Layout.WORLD_SIZE, Floor2Layout.WORLD_SIZE * 3.0), Color("#d9bc55"))
	draw_texture_rect(GROUND, Rect2(Vector2.ZERO, Floor2Layout.WORLD_SIZE), false)

func set_chest_open(opened: bool) -> void:
	if is_instance_valid(floor2_chest):
		floor2_chest.set_open(opened)

func set_mining_state(progress: GameProgress, now: int) -> void:
	for id: String in mining_sprites:
		var state := progress.mining_snapshot(2, id, now)
		(mining_sprites[id] as Sprite2D).modulate = Color("#92978a") if state.remaining == 0 else Color.WHITE

func play_mining(player_at: Vector2, deposit_at: Vector2) -> void:
	var effect := MiningEffect.new()
	add_child(effect)
	effect.setup(player_at, deposit_at)

func set_visual_v2(_enabled: bool) -> void:
	pass

func set_expanded_world(_enabled: bool) -> void:
	pass
