class_name Camera3rdPerson
extends Node3D

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera_3d: Camera3D = $Camera3D

@export var mouse_sensitivity: float = 0.005
@export var zoom_sensitivity: float = 1.0

@export var camera_global_rotation: Vector3
@export var camera_transform: Transform3D

@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var min_vertical_angle: float = -PI/2
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var max_vertical_angle: float = PI/4

@export var zoom_min_distance: float = 1.0
@export var zoom_max_distance: float = 10.0

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

## Handle mouse input for camera rotation
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensitivity
		rotation.y = clampf(rotation.y, 0.0, TAU)

		rotation.x -= event.relative.y * mouse_sensitivity
		rotation.x = clampf(rotation.x, min_vertical_angle, max_vertical_angle)

	if event.is_action_pressed("wheel_up"):
		spring_arm.spring_length -= zoom_sensitivity

	if event.is_action_pressed("wheel_down"):
		spring_arm.spring_length += zoom_sensitivity

	spring_arm.spring_length = clampf(spring_arm.spring_length, zoom_min_distance, zoom_max_distance)

	if event.is_action_pressed("toggle_mouse_capture"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(_delta: float) -> void:
	camera_global_rotation = camera_3d.global_rotation
	camera_transform = camera_3d.transform
