extends SceneTree

# Ferramenta de inspeção: encontra as peças de uma folha original do Andar 3 pelos
# pixels opacos (componentes conectados numa grade reduzida) e grava uma imagem com
# cada peça numerada, para escolher os recortes sem presumir grade fixa.
# Uso (janela): SHEET=<arquivo em art_source/andar3> OUT=<pasta> godot --path . -s res://tools/andar3_components.gd
const CELL := 4

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var sheet_name := OS.get_environment("SHEET")
	var out := OS.get_environment("OUT")
	var image := Image.load_from_file("res://art_source/andar3/" + sheet_name)
	image.convert(Image.FORMAT_RGBA8)
	var boxes := components(image, CELL, float(OS.get_environment("ALPHA") if not OS.get_environment("ALPHA").is_empty() else "0.5"), int(OS.get_environment("GAP") if not OS.get_environment("GAP").is_empty() else "1"))
	var lines := PackedStringArray()
	for index in range(boxes.size()):
		var box: Rect2i = boxes[index]
		lines.append("%d %d %d %d %d" % [index, box.position.x, box.position.y, box.size.x, box.size.y])
	var file := FileAccess.open(out.path_join(sheet_name.get_basename() + "_boxes.txt"), FileAccess.WRITE)
	file.store_string("\n".join(lines))
	file.close()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = image.get_size()
	var canvas := Control.new()
	canvas.size = image.get_size()
	root.add_child(canvas)
	var back := ColorRect.new()
	back.color = Color("#202020")
	back.size = image.get_size()
	canvas.add_child(back)
	var picture := TextureRect.new()
	picture.texture = ImageTexture.create_from_image(image)
	picture.size = image.get_size()
	canvas.add_child(picture)
	for index in range(boxes.size()):
		var box: Rect2i = boxes[index]
		var frame := ReferenceRect.new()
		frame.position = box.position
		frame.size = box.size
		frame.border_color = Color.MAGENTA
		frame.border_width = 2
		frame.editor_only = false
		canvas.add_child(frame)
		var label := Label.new()
		label.text = str(index)
		label.position = box.position + Vector2i(2, 0)
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", Color.YELLOW)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 6)
		canvas.add_child(label)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(sheet_name.get_basename() + "_boxes.png"))
	print("COMPONENTS ", boxes.size())
	quit(0)

# Componentes de pixels opacos numa grade de `cell` pixels; `gap` funde peças a até
# `gap` células de distância (resíduos soltos de borda viram parte da peça vizinha).
static func components(image: Image, cell: int, alpha: float, gap: int) -> Array:
	var w := ceili(float(image.get_width()) / cell)
	var h := ceili(float(image.get_height()) / cell)
	var solid := PackedByteArray()
	solid.resize(w * h)
	for gy in range(h):
		for gx in range(w):
			var count := 0
			for y in range(gy * cell, mini((gy + 1) * cell, image.get_height())):
				for x in range(gx * cell, mini((gx + 1) * cell, image.get_width())):
					if image.get_pixel(x, y).a >= alpha: count += 1
			solid[gy * w + gx] = 1 if count * 3 >= cell * cell else 0
	var label := PackedInt32Array()
	label.resize(w * h)
	label.fill(-1)
	var boxes: Array = []
	for start in range(w * h):
		if solid[start] == 0 or label[start] >= 0: continue
		var id := boxes.size()
		var stack := [start]
		label[start] = id
		var min_x := w
		var min_y := h
		var max_x := 0
		var max_y := 0
		var size := 0
		while not stack.is_empty():
			var current: int = stack.pop_back()
			var cx := current % w
			var cy := current / w
			size += 1
			min_x = mini(min_x, cx)
			min_y = mini(min_y, cy)
			max_x = maxi(max_x, cx)
			max_y = maxi(max_y, cy)
			for dy in range(-gap, gap + 1):
				for dx in range(-gap, gap + 1):
					var nx := cx + dx
					var ny := cy + dy
					if nx < 0 or ny < 0 or nx >= w or ny >= h: continue
					var next := ny * w + nx
					if solid[next] == 1 and label[next] < 0:
						label[next] = id
						stack.append(next)
		boxes.append({"rect": Rect2i(min_x * cell, min_y * cell, (max_x - min_x + 1) * cell, (max_y - min_y + 1) * cell), "size": size})
	var result: Array = []
	for entry: Dictionary in boxes:
		if int(entry.size) >= 12: result.append(entry.rect)
	result.sort_custom(func(a: Rect2i, b: Rect2i) -> bool:
		var row_a := a.position.y / 96
		var row_b := b.position.y / 96
		return row_a < row_b if row_a != row_b else a.position.x < b.position.x)
	return result
