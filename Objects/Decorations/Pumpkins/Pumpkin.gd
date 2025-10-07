class_name Pumpkin
extends Node3D

var SplatType = preload("res://Objects/Decorations/Pumpkins/PumpkinSplat.tscn")

# Called when the node enters the scene tree for the first time.
# func _ready() -> void:
# 	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta: float) -> void:
# 	pass

func stomped() -> void:
	var splat = SplatType.instantiate()
	splat.global_transform = global_transform
	get_parent().add_child(splat)

	queue_free()
