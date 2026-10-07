class_name ActorData
extends Resource

@export_range(1, 10000) var max_hp: int = 100
@export_range(0, 1000) var move_speed: float = 180.0
@export_range(0, 1000) var contact_damage: int = 8
@export_range(0.1, 10) var contact_interval: float = 1.0
@export_range(0, 2000) var detection_range: float = 480.0
@export_range(0, 200) var contact_range: float = 36.0
@export_range(0.01, 2) var dash_duration: float = 0.14
@export_range(0, 2000) var dash_speed: float = 620.0
@export_range(0.1, 10) var dash_cooldown: float = 1.2
