class_name CandleFlame
extends Node3D

@onready var candle_mesh: MeshInstance3D = $CandleMesh
@onready var candle_light: OmniLight3D = $CandleLight

@export var rotate_speed: float = 3.0
@export var resize_seconds: float = 0.5
@export var resize_time: float = 0.0
@export var size_min: float = 1.0
@export var size_max: float = 3.0
@export var light_energy_min: float = 0.2
@export var light_energy_max: float = 2.0

var size: float = 10.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate_y(rotate_speed * delta)
	scale = lerp(scale, Vector3(size, size, size), delta)
	var scale_variance: float = (size - size_min) / (size_max - size_min)
	candle_mesh.rotation_degrees.x = lerp(candle_mesh.rotation_degrees.x, (scale_variance * 2 - 1) * 20.0, delta * 50)
	candle_light.light_energy = lerp(candle_light.light_energy,
		light_energy_min + (light_energy_max - light_energy_min) * scale_variance,
		delta)

func _physics_process(delta: float) -> void:
	resize_time += delta
	if (resize_time > resize_seconds):
		resize_time = 0
		size = randf_range(size_min, size_max)
