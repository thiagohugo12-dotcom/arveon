extends SceneTree

# Folha de contato dos ícones em alta definição, ampliados 4x (QA_RENDER_DIR recebe icones-hd.png).
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var cell := 208
	var columns := 5
	var ids: Array = SlotArtHD.IDS
	var rows := ceili(float(ids.size()) / columns)
	var sheet := Image.create(cell * columns,cell * rows,false,Image.FORMAT_RGBA8)
	sheet.fill(Color("#2a4a38"))
	for index in range(ids.size()):
		var big := SlotArtHD.texture(ids[index],48).get_image()
		big.resize(192,192,Image.INTERPOLATE_NEAREST)
		sheet.blend_rect(big,Rect2i(0,0,192,192),Vector2i((index % columns) * cell + 8,(index / columns) * cell + 8))
	var directory := OS.get_environment("QA_RENDER_DIR")
	DirAccess.make_dir_recursive_absolute(directory)
	sheet.save_png(directory.path_join("icones-hd.png"))
	quit(0)
