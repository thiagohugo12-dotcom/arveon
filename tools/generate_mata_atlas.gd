extends SceneTree

func _initialize() -> void:
	var result := MataArt.generate_image().save_png("res://assets/art/mata_clean_atlas.png")
	print("MATA_ATLAS_EXPORT: ",result)
	quit(0 if result == OK else 1)
