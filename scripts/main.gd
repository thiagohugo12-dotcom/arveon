extends Node2D

@onready var player: PlayerActor = $Player
@onready var enemy: EnemyActor = $Enemy
@onready var input_driver: InputDriver = $InputDriver
@onready var hud: GameHUD = $Interface/HUD

func _ready() -> void:
	player.input_driver = input_driver
	enemy.target = player
	hud.movement_changed.connect(input_driver.set_touch_direction)
	hud.dash_pressed.connect(input_driver.request_dash)
	hud.restart_pressed.connect(func(): get_tree().reload_current_scene())
	player.health.changed.connect(hud.set_health)
	player.health.died.connect(hud.show_death)
	hud.set_health(player.health.current, player.health.maximum)
	get_window().size_changed.connect(_adapt_orientation)
	_adapt_orientation()

func _process(_delta: float) -> void:
	hud.set_dash_cooldown(player.dash.cooldown_left)

func _adapt_orientation() -> void:
	var window := get_window()
	# Logical short side 360 keeps touch targets readable in either orientation.
	var desired := Vector2i(360, 640) if window.size.y > window.size.x else Vector2i(640, 360)
	if window.content_scale_size != desired:
		window.content_scale_size = desired
	hud.call_deferred("_layout")
