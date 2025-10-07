extends Node3D

var original_scale: Vector3
var tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Store the original scale
	original_scale = scale

	# Create a tween for the scaling animation
	tween = create_tween()

	# Scale down to 10% over 0.5 seconds
	tween.tween_property(self, "scale", original_scale * 0.1, 0.5)

	# Queue the object for deletion after the animation
	tween.tween_callback(queue_free)
