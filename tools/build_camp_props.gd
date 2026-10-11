extends SceneTree

const OUT := "res://assets/art/mata_v2/camp_props.png"
const DARK := Color("#493326")
const WOOD := Color("#8e5a34")
const WOOD_LIGHT := Color("#bd8045")
const CREAM := Color("#e3bb72")
const STONE := Color("#747a70")
const STONE_LIGHT := Color("#b5b39a")
const FIRE := Color("#d76628")
const FIRE_LIGHT := Color("#ffd36a")

func box(image: Image, at: Vector2i, size: Vector2i, colour: Color) -> void:
	image.fill_rect(Rect2i(at,size),colour)

func _initialize() -> void:
	var image := Image.create(128,64,false,Image.FORMAT_RGBA8)
	# Fence: broad posts and one clean rail.
	box(image,Vector2i(1,9),Vector2i(30,5),DARK)
	box(image,Vector2i(2,8),Vector2i(28,4),WOOD)
	for x in [3,25]:
		box(image,Vector2i(x,2),Vector2i(5,14),DARK)
		box(image,Vector2i(x+1,3),Vector2i(3,12),WOOD)
		box(image,Vector2i(x+1,3),Vector2i(3,2),CREAM)
	# Direction sign: post, board and one simple arrow.
	box(image,Vector2i(39,5),Vector2i(4,23),DARK)
	box(image,Vector2i(40,6),Vector2i(2,21),WOOD)
	box(image,Vector2i(33,8),Vector2i(16,9),DARK)
	box(image,Vector2i(34,9),Vector2i(13,7),WOOD_LIGHT)
	box(image,Vector2i(42,11),Vector2i(4,3),CREAM)
	box(image,Vector2i(45,10),Vector2i(2,5),CREAM)
	# Barrel and crate.
	box(image,Vector2i(56,8),Vector2i(15,15),DARK)
	box(image,Vector2i(58,7),Vector2i(11,16),WOOD)
	box(image,Vector2i(59,9),Vector2i(9,3),WOOD_LIGHT)
	for y in [11,19]: box(image,Vector2i(57,y),Vector2i(13,2),Color("#4b5550"))
	box(image,Vector2i(77,7),Vector2i(17,17),DARK)
	box(image,Vector2i(79,9),Vector2i(13,13),WOOD)
	box(image,Vector2i(80,10),Vector2i(11,2),WOOD_LIGHT)
	for offset in range(3):
		box(image,Vector2i(80+offset*3,12+offset*3),Vector2i(3,2),CREAM)
		box(image,Vector2i(88-offset*3,12+offset*3),Vector2i(3,2),CREAM)
	# Campfire: five broad stones and a compact flame.
	for at in [Vector2i(4,49),Vector2i(10,45),Vector2i(17,46),Vector2i(22,51),Vector2i(10,54)]:
		box(image,at,Vector2i(7,5),STONE)
		box(image,at+Vector2i(1,0),Vector2i(4,2),STONE_LIGHT)
	box(image,Vector2i(11,47),Vector2i(8,6),DARK)
	box(image,Vector2i(13,40),Vector2i(4,12),FIRE)
	box(image,Vector2i(11,45),Vector2i(8,7),FIRE)
	box(image,Vector2i(14,44),Vector2i(3,7),FIRE_LIGHT)
	# Lantern post: simple upright timber and gold window.
	box(image,Vector2i(39,36),Vector2i(4,24),DARK)
	box(image,Vector2i(40,36),Vector2i(2,22),WOOD)
	box(image,Vector2i(40,37),Vector2i(13,3),WOOD_LIGHT)
	box(image,Vector2i(49,40),Vector2i(2,5),DARK)
	box(image,Vector2i(47,45),Vector2i(7,10),DARK)
	box(image,Vector2i(49,47),Vector2i(3,6),FIRE_LIGHT)
	# Bench and pebble group.
	box(image,Vector2i(65,49),Vector2i(27,5),DARK)
	box(image,Vector2i(66,47),Vector2i(25,5),WOOD_LIGHT)
	box(image,Vector2i(68,54),Vector2i(3,6),WOOD)
	box(image,Vector2i(86,54),Vector2i(3,6),WOOD)
	for at in [Vector2i(100,51),Vector2i(107,47),Vector2i(114,52)]:
		box(image,at,Vector2i(7,5),STONE)
		box(image,at+Vector2i(1,0),Vector2i(4,2),STONE_LIGHT)
	image.save_png(OUT)
	print("Wrote ",OUT)
	quit()
