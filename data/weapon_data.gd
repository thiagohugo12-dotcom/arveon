class_name WeaponData
extends Resource

@export_range(1, 2000) var reach: float = 120.0
@export_range(1, 10000) var damage: int = 12
@export_range(0.05, 10) var interval: float = 0.65

@export var category := "espada"
@export var projectile_kind := ""
@export var projectile_speed := 440.0
