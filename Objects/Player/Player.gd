class_name Claire
extends CharacterBody3D

@onready var FootstepSound: AudioStreamPlayer = $Sounds/ShoeStepGrassMediumA
@onready var JumpLandSound: AudioStreamPlayer = $Sounds/LandStepGrassB
@onready var girl_eyes_geo: MeshInstance3D = $"Armature/Skeleton3D/Girl_Eyes_Geo"

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera3rdPerson = $CameraPivot

@export var gravity: float = -40.0
@export var rotate_speed: float = 3.0
@export var walk_speed: float = 1.0
@export var run_speed: float = 4.0
@export var jump_velocity: float = 15.0

var falling: bool = false
var jumped: bool = false # Track if player actually jumped
var eyes: Vector2i = Vector2i(0, 0) # Current eye texture coordinates

# Buffer for collision detection - track bodies that recently entered StompArea
var recent_stomp_bodies: Array[Node3D] = []
var stomp_buffer_time: float = 1.0 # Keep bodies in buffer for 1 second

## How long has the punch animation been playing
var punch_time: float = 0.0

## Animation blending time
var blend_speed: float = 5.0

# blending between animation tree states
var idle_walk: float = 0.0
var fall_jump: float = 0.0
var ground_air: float = 0.0

var eye_material: Material = null

func _enter_tree() -> void:
	add_to_group("Players")

func _ready() -> void:
	GameManager.Player = self

	# Initialize velocity to prevent sliding at startup
	velocity = Vector3.ZERO

	# Enable collision shape visualization for debugging
	# Multiple methods to ensure collision shapes are visible
	get_tree().debug_collisions_hint = true
	get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED # Reset first
	# Note: In Godot 4, collision shapes are typically enabled via:
	# 1. Debug menu -> Visible Collision Shapes (most reliable)
	# 2. get_tree().debug_collisions_hint = true (what we're using)
	print("Collision debug enabled: ", get_tree().debug_collisions_hint)

	SetEyeExpression(EyeExpressions.EyeType.NORMAL)

func get_eye_material() -> Material:
		# Get or create override material
	var material = eye_material
	if material == null:
		material = girl_eyes_geo.get_surface_override_material(0)
		if material == null:
			# Create override material from the base material
			var base_material = girl_eyes_geo.get_surface_override_material(0)
			if base_material == null:
				base_material = girl_eyes_geo.mesh.surface_get_material(0)
			if base_material != null:
				material = base_material.duplicate()
				girl_eyes_geo.set_surface_override_material(0, material)
			else:
				print("get_eye_material: No base material found on surface 0")
	eye_material = material
	return material


## Handle visual updates - runs every frame
func _process(_delta: float) -> void:
	# Non-physics visual updates can go here if needed
	pass

## Happens about 30 times a second
func _physics_process(delta: float) -> void:
	var move_dir: Vector3 = transform.basis.z
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
		speed = - walk_speed

	if Input.is_action_just_pressed("punch") and punch_time <= 0:
		animation_tree.set("parameters/PunchOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		punch_time = 0.5

	punch_time -= delta
	if punch_time > 0.0:
		speed = 0

	if speed != 0:
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
	else:
		velocity.x = 0
		velocity.z = 0

	if !is_on_floor():
		velocity.y += gravity * delta
		falling = true
	else:
		if falling == true and jumped == true:
			# Only call Landed() if we were actually jumping, not just falling off small ledges
			falling = false
			jumped = false
			Landed()
		elif falling == true:
			# Reset falling state without calling Landed() for minor terrain variations
			falling = false

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		jumped = true # Mark that we actually jumped

	move_and_slide()

	# Handle camera rotation when moving - moved to physics process for interpolation
	if velocity.length() > 0.1: # Only adjust camera when actually moving
		# When moving forward, face the same direction as the camera
		rotation.y = lerp_angle(rotation.y, rotation.y + camera.rotation.y + deg_to_rad(180), 5 * delta)
		camera.rotation.y = lerp_angle(camera.rotation.y, deg_to_rad(180), 5 * delta)

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

func ShowEyes(x: int, y: int) -> void:
	print ("ShowEyes: Setting eyes to (", x, ", ", y, ")")
	if (x < 0 or x > 2 or y < 0 or y > 9):
		print("ShowEyes: Invalid eye coordinates (", x, ", ", y, ")")
		return
	eyes = Vector2i(x, y)
	var uvOffset = Vector2(x * 0.2, y * 0.1)
	get_eye_material().set("uv1_offset", uvOffset)

## Set eye expression using the EyeExpressions enum - easier to use!
func SetEyeExpression(expression: EyeExpressions.EyeType) -> void:
	var coords = EyeExpressions.get_coordinates(expression)
	ShowEyes(coords.x, coords.y)
	print("SetEyeExpression: Set to ", EyeExpressions.get_expression_name(expression), " (", coords.x, ", ", coords.y, ")")

## Get the current eye expression as an enum (if it matches a known expression)
func GetCurrentEyeExpression() -> EyeExpressions.EyeType:
	return EyeExpressions.get_expression_from_coordinates(eyes)

func Landed() -> void:
	print("Landed")
	JumpLandSound.play()
	JumpLandSound.pitch_scale = randf_range(0.8, 1.2)

	# Check for pumpkins in stomp area
	var stomp_area = $StompArea
	if stomp_area:
		var overlapping_bodies = stomp_area.get_overlapping_bodies()
		print("Landed count: ", overlapping_bodies.size())

		# Primary method: check overlapping bodies
		var stomped_something = false
		for body in overlapping_bodies:
			print("Checking Stomp on: ", body.name, " (Type: ", body.get_class(), ", Groups: ", body.get_groups(), ")")
			var stompableThing = Utils.FindParentWithGroup(body, "Stompable")
			print("  -> Stompable found: ", stompableThing)
			if stompableThing:
				print("Stomped on: ", stompableThing.name)
				stompableThing.call_deferred("stomped")
				stomped_something = true

		# Buffered collision detection - check bodies that recently entered StompArea
		# if not stomped_something:
		# 	print("Checking recent stomp bodies buffer (", recent_stomp_bodies.size(), " bodies)")
		# 	for body in recent_stomp_bodies:
		# 		if is_instance_valid(body):  # Make sure body still exists
		# 			print("Buffered Stomp check: ", body.name, " (Type: ", body.get_class(), ", Groups: ", body.get_groups(), ")")
		# 			var stompableThing = Utils.FindParentWithGroup(body, "Stompable")
		# 			if stompableThing:
		# 				print("Buffered Stomped on: ", stompableThing.name)
		# 				stompableThing.call_deferred("stomped")
		# 				stomped_something = true
		# 				break

		# 	# Clear the buffer after use
		# 	recent_stomp_bodies.clear()# func PunchHit() -> void:
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

# Helper function to recursively find all physics bodies in the scene
func _find_physics_bodies_recursive(node: Node, bodies_list: Array) -> void:
	if node is RigidBody3D or node is CharacterBody3D or node is StaticBody3D:
		bodies_list.append(node)

	for child in node.get_children():
		_find_physics_bodies_recursive(child, bodies_list)

# Stomp area signal handlers - buffer system
func _on_stomp_area_body_entered(body: Node3D) -> void:
	print(">> Body ENTERED StompArea: ", body.name, " (Type: ", body.get_class(), ", Groups: ", body.get_groups(), ")")
	# Add to buffer for recent collision tracking
	# if body not in recent_stomp_bodies:
		# recent_stomp_bodies.append(body)
		# print("   Added to stomp buffer. Buffer size: ", recent_stomp_bodies.size())

func _on_stomp_area_body_exited(body: Node3D) -> void:
	print("<< Body EXITED StompArea: ", body.name)
	# if body in recent_stomp_bodies:
	# 	recent_stomp_bodies.erase(body)
	# 	print("   Removed from stomp buffer. Buffer size: ", recent_stomp_bodies.size())
