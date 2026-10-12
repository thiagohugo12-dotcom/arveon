class_name PixelIcon
extends RefCounted

# Integer cells keep the existing pixel art vocabulary; no textures or per-frame resources.
const SHAPES := {
	"book": ["01100110", "11111111", "11111111", "11011011", "11011011", "11011011", "11111111", "01100110"],
	"coin": ["00111100", "01111110", "11111111", "11101111", "11101111", "11111111", "01111110", "00111100"],
	"heart": ["01100110", "11111111", "11111111", "11111111", "01111110", "00111100", "00011000", "00000000"],
	"potion": ["00111100", "00011000", "00011000", "00111100", "01111110", "01111110", "01111110", "00111100"],
	"bag": ["00111100", "01100110", "01111110", "11000011", "11111111", "11011011", "11011011", "01111110"],
	"character": ["00111100", "00111100", "00011000", "01111110", "11011011", "00011000", "00100100", "01100110"],
	"map": ["11100111", "10111101", "10011001", "10101001", "10010101", "10101001", "10111101", "11100111"],
	"cut": ["00011100", "00100010", "01000001", "10001001", "10010001", "10100010", "01100100", "11011000"],
	"charge": ["00001000", "00101100", "01111110", "11111111", "01111110", "00101100", "00001000", "00000000"],
	"fury": ["01000010", "01100110", "00111100", "01111110", "11011011", "11111111", "00111100", "00011000"],
	"dash": ["00001000", "00011000", "00111110", "01111100", "00011000", "00110000", "01100000", "01000000"]
}

static func illustrate(canvas: CanvasItem, id: String, area: Rect2, color: Color) -> void:
	paint(canvas,id,Rect2(area.position+Vector2(1,2),area.size),Color("#38281e"))
	paint(canvas,id,area,color)
	var cells: Array = SHAPES.get(id,SHAPES.dash)
	var step := floorf(minf(area.size.x,area.size.y)/8)
	var origin := (area.position+(area.size-Vector2.ONE*step*8)*0.5).floor()
	for y in range(8):
		for x in range(8):
			if cells[y][x] == "1" and (y == 0 or cells[y-1][x] == "0"):
				canvas.draw_rect(Rect2(origin+Vector2(x,y)*step,Vector2(step,1)),color.lightened(0.3))

static func paint(canvas: CanvasItem, id: String, area: Rect2, color: Color) -> void:
	var cells: Array = SHAPES.get(id, SHAPES.dash)
	var step := floorf(minf(area.size.x, area.size.y) / 8.0)
	var origin := (area.position + (area.size - Vector2.ONE * step * 8) * 0.5).floor()
	for y in range(8):
		for x in range(8):
			if cells[y][x] == "1":
				canvas.draw_rect(Rect2(origin + Vector2(x, y) * step, Vector2.ONE * step), color)
