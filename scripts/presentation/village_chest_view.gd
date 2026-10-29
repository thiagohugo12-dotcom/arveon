extends Node2D
var opened := false
var transition := 0.0
var frame := 0

func set_open(value: bool) -> void:
	if value == opened: return
	opened = value
	transition = 0.24
	set_process(true)

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	transition = maxf(0.0,transition-delta)
	var next := (1 if transition > 0.12 else 2) if opened else (1 if transition > 0.12 else 0)
	if next != frame:
		frame = next
		queue_redraw()
	if transition == 0.0: set_process(false)

func _draw() -> void:
	VillageActorArt.pickup(self,Vector2.ZERO,frame)
