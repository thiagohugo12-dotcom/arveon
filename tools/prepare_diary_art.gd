extends SceneTree

func _initialize() -> void:
	# Preserve the generated masters; prepare a tiny nearest-neighbor UI skin.
	var book := Image.load_from_file("res://assets/art/diary_v2/book.png")
	book.resize(384,256,Image.INTERPOLATE_NEAREST)
	book.save_png("res://assets/art/diary_v2/book_skin.png")
	var items := Image.load_from_file("res://assets/art/diary_v2/items.png")
	items.resize(256,256,Image.INTERPOLATE_NEAREST)
	items.save_png("res://assets/art/diary_v2/items_skin.png")
	quit()
