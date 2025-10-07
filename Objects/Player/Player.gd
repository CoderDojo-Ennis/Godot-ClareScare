class_name Claire
extends CharacterBody3D

@onready var FootstepSound: AudioStreamPlayer = $Sounds/ShoeStepGrassMediumA

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera3rdPerson = $CameraPivot

@export var gravity: float = -40.0
@export var rotate_speed: float = 3.0
@export var walk_speed: float = 1.0
@export var run_speed: float = 4.0
@export var jump_velocity: float = 15.0

## How long has the punch animation been playing
var punch_time: float = 0.0

## Animation blending time
var blend_speed: float = 5.0

# blending between animation tree states
var idle_walk: float = 0.0
var fall_jump: float = 0.0
var ground_air: float = 0.0

## Happens about 30 times a second
# func _physics_process(delta: float) -> void:
# 	var SPEED: float = run_speed

# 	# Add the gravity.
# 	if not is_on_floor():
# 		velocity += get_gravity() * delta

# 	# Handle jump.
# 	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
# 		velocity.y = jump_velocity

# 	# Get the input direction and handle the movement/deceleration.
# 	# As good practice, you should replace UI actions with custom gameplay actions.
# 	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
# 	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

# 	# print(camera.camera_global_rotation.y)
# 	# direction = direction.rotated(Vector3.UP, camera.camera_global_rotation.y)

# 	if direction:
# 		velocity.x = direction.x * SPEED
# 		velocity.z = direction.z * SPEED
# 	else:
# 		velocity.x = move_toward(velocity.x, 0, SPEED)
# 		velocity.z = move_toward(velocity.z, 0, SPEED)

# 	move_and_slide()

func _physics_process(delta: float) -> void:
	var move_dir: Vector3 = transform.basis.z
	# camera.camera_transform.basis.z
	var speed: float = 0.0

	if Input.is_action_pressed("move_left"):
		rotate_y(rotate_speed * delta)
	if Input.is_action_pressed("move_right"):
		rotate_y(rotate_speed * delta * -1)
	if Input.is_action_pressed("move_forward"):
		animation_tree.set("parameters/TimeScaleRun/scale", 1.0)
		animation_tree.set("parameters/TimeScaleWalk/scale", 1.0)
		speed = run_speed
	if Input.is_action_pressed("move_back"):
		animation_tree.set("parameters/TimeScaleRun/scale", -2.0)
		animation_tree.set("parameters/TimeScaleWalk/scale", -2.0)
		speed = -walk_speed

	if Input.is_action_just_pressed("punch") and punch_time <= 0:
		animation_tree.set("parameters/PunchOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		punch_time = 0.5

	punch_time -= delta
	if punch_time > 0.0:
		speed = 0

	if speed != 0:
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed

		# When moving forward, face the same direction as the camera
		rotation.y = lerp_angle(rotation.y, rotation.y + camera.rotation.y + deg_to_rad(180), 5 * delta)
		camera.rotation.y = lerp_angle(camera.rotation.y, deg_to_rad(180), 5 * delta)

	else:
		velocity.x = 0
		velocity.z = 0

	if !is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()
	blend_idle_walk(delta)
	blend_land_air(delta)
	blend_down_up(delta)

## Blend between idle and walk/run based on speed
func blend_idle_walk(delta: float) -> void:
	var target_speed: float = clamp(velocity.length() / run_speed, 0.0, 1.0) * 2 - 1.0
	idle_walk = lerp(idle_walk,
		target_speed,
		blend_speed * delta)
	animation_tree.set("parameters/BlendIdleRun/blend_amount", idle_walk)

## Blend between land and air based on whether on floor
func blend_land_air(delta: float) -> void:
	var target_air_blend = 1.0 if not is_on_floor() else 0.0
	ground_air = lerp(
		ground_air,
		target_air_blend,
		blend_speed * delta
	)
	animation_tree.set("parameters/BlendLandAir/blend_amount", ground_air)

## Blend between jump and fall animations based on vertical speed
func blend_down_up(_delta: float) -> void:
	var vertical_speed: float = clamp(
		velocity.y * 10 / jump_velocity,
		0.0,
		1.0)
	animation_tree.set("parameters/BlendDownUp/blend_amount", vertical_speed)

## Sound effects
func Footstep() -> void:
	FootstepSound.play()
	FootstepSound.pitch_scale = randf_range(0.8, 1.2)

# func Landed() -> void:
# 	$LandSound.play()
# 	$LandSound.pitch_scale = randf_range(0.8, 1.2)

# func PunchHit() -> void:
# 	$PunchSound.play()
# 	$PunchSound.pitch_scale = randf_range(0.8, 1.2)

# func JumpSound() -> void:
# 	$JumpSound.play()
# 	$JumpSound.pitch_scale = randf_range(0.8, 1.2)

# func HurtSound() -> void:
# 	$HurtSound.play()
# 	$HurtSound.pitch_scale = randf_range(0.8, 1.2)

# func DeathSound() -> void:
# 	$DeathSound.play()
# 	$DeathSound.pitch_scale = randf_range(0.8, 1.2)

# func RespawnSound() -> void:
# 	$RespawnSound.play()
# 	$RespawnSound.pitch_scale = randf_range(0.8, 1.2)

# func PickupSound() -> void:
# 	$PickupSound.play()
# 	$PickupSound.pitch_scale = randf_range(0.8, 1.2)

# func ThrowSound() -> void:
# 	$ThrowSound.play()
# 	$ThrowSound.pitch_scale = randf_range(0.8, 1.2)
