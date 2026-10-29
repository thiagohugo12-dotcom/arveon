class_name Floor2TowerView
extends TowerView

const TOWER := preload("res://assets/art/andar2/refined/sandstone-ascension-tower.png")

func _draw() -> void:
	draw_texture_rect(TOWER, Rect2(-60, -148, 120, 148), false)
	if unlocked:
		draw_rect(Rect2(-11, -48, 22, 30), Color("#e9b45255"))
	if nearby:
		draw_rect(Rect2(-16, 1, 32, 3), Color("#e1c880"))
