class_name WeaponInstanceIcon
extends Control

var category := "espada"
var rarity := "comum"
var level := 0

func _init(value: String = "espada", quality: String = "comum", upgrade: int = 0) -> void:
	category = value
	rarity = quality
	level = upgrade
	custom_minimum_size = Vector2(38,38)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var art := PixelItemIcon.new(category)
	art.framed = false
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.offset_left = 4
	art.offset_top = 4
	art.offset_right = -4
	art.offset_bottom = -4
	add_child(art)

func _draw() -> void:
	var accent := Color(ArsenalRules.RARITIES[rarity].color)
	draw_rect(Rect2(0,0,size.x,size.y),Color("#4c3824"),false,2)
	draw_rect(Rect2(2,2,size.x-4,size.y-4),accent,false,2)
	if rarity != "comum":
		draw_colored_polygon(PackedVector2Array([Vector2(size.x-10,4),Vector2(size.x-4,4),Vector2(size.x-4,10)]),accent.lightened(0.18))
	var marks := 3 if level >= 20 else 2 if level >= 15 else 1 if level >= 10 else 0
	for i in range(marks): draw_rect(Rect2(5+i*6,size.y-7,4,3),Color("#f8d979"))
