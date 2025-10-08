extends Node

@export var LevelNumber: int = 0
@export var Player: Claire

var Score: int = 0

func _ready() -> void:
	Signals.LevelStart.connect(self._on_level_start)

func _on_level_start(newLevel: int) -> void:
	LevelNumber = newLevel
