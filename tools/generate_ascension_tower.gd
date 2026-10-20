extends SceneTree

# Small reusable pixel sprite, drawn on the same 2x grid as the village art.
const OUTPUT := "res://assets/art/hub_v3/ascension_tower.png"
const OUTLINE := Color("#493a2d")
const SHADOW := Color("#665747")
const STONE := Color("#9b9276")
const LIGHT := Color("#c6b895")
const HIGHLIGHT := Color("#dfcba2")
const MOSS := Color("#6f8d47")
const MOSS_LIGHT := Color("#9eaf55")
const GOLD := Color("#d7a850")
var art: Image

func _init() -> void:
	art = Image.create(80,108,false,Image.FORMAT_RGBA8)
	art.fill(Color.TRANSPARENT)
	_structure()
	_bricks()
	_door()
	_emblem()
	_moss()
	var result := art.save_png(OUTPUT)
	print("Ascension tower: ", OUTPUT, " (", result, ")")
	quit(0 if result == OK else 1)

func box(x: int,y: int,w: int,h: int,color: Color) -> void:
	art.fill_rect(Rect2i(x,y,w,h),color)

func _structure() -> void:
	# Uneven battlements and a narrow stone body give this a tower silhouette.
	for battlement: Array in [[8,18,15,13],[32,10,16,19],[57,17,15,14]]:
		box(battlement[0]-2,battlement[1]-2,battlement[2]+4,battlement[3]+4,OUTLINE)
		box(battlement[0],battlement[1],battlement[2],battlement[3],STONE)
		box(battlement[0]+2,battlement[1]+2,battlement[2]-5,3,HIGHLIGHT)
	box(9,29,63,7,OUTLINE)
	box(11,30,59,4,LIGHT)
	box(13,35,55,62,OUTLINE)
	box(16,37,48,59,SHADOW)
	box(20,38,39,56,STONE)
	box(21,38,34,4,LIGHT)
	box(15,42,5,49,Color("#756b57"))
	box(64,43,3,48,Color("#5a5044"))
	# Broken stone steps lead toward the dark doorway.
	box(8,94,64,6,OUTLINE)
	box(11,94,58,4,STONE)
	box(6,100,68,7,OUTLINE)
	box(9,100,62,4,LIGHT)
	box(15,102,17,2,HIGHLIGHT)
	box(47,102,15,2,HIGHLIGHT)
	box(19,105,12,2,STONE)
	box(54,105,14,2,STONE)

func _bricks() -> void:
	var rows := [38,46,54,62,70,78,86]
	for row in range(rows.size()):
		var y: int = rows[row]
		var shifted := 0 if row%2==0 else 8
		for x in range(20-shifted,66,16):
			var left := maxi(17,x)
			var right := mini(63,x+14)
			if right<=left: continue
			box(left,y,right-left,1,SHADOW)
			box(left+2,y+2,maxi(1,right-left-5),1,LIGHT)
			if (row+x)%3==0: box(left+5,y+4,3,2,Color("#817a63"))
	for edge: Array in [[14,44],[62,52],[17,73],[60,82],[13,88]]:
		box(edge[0],edge[1],2,4,HIGHLIGHT)

func _door() -> void:
	# A stepped arch reads cleanly at the game's normal scale.
	box(27,62,26,35,OUTLINE)
	box(29,58,22,38,OUTLINE)
	box(32,55,16,42,OUTLINE)
	box(34,53,12,44,OUTLINE)
	box(32,64,16,34,Color("#182d30"))
	box(30,68,20,30,Color("#182d30"))
	box(35,62,10,36,Color("#203e40"))
	box(32,72,3,25,Color("#34524a"))
	box(49,72,2,25,Color("#0e232a"))
	box(27,65,3,32,LIGHT)
	box(51,65,3,32,SHADOW)
	box(30,60,3,5,HIGHLIGHT)
	box(49,60,3,5,STONE)

func _emblem() -> void:
	# Gold mark remains visible before the tower is unlocked.
	box(36,39,8,2,OUTLINE)
	box(34,41,12,7,OUTLINE)
	box(36,48,8,3,OUTLINE)
	box(38,40,4,9,GOLD)
	box(36,43,8,3,GOLD)
	box(39,42,2,4,Color("#ffe5a0"))

func _moss() -> void:
	for clump: Array in [[12,27,7,3],[60,30,8,3],[14,69,7,3],[58,78,8,4],
		[10,95,12,3],[62,96,11,3],[20,101,7,2]]:
		box(clump[0],clump[1],clump[2],clump[3],MOSS)
		box(clump[0]+2,clump[1],maxi(2,clump[2]-4),1,MOSS_LIGHT)
