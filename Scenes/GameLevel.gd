class_name GameLevel
extends Node3D

@export var levelNumber: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signals.LevelStart.emit(levelNumber)
