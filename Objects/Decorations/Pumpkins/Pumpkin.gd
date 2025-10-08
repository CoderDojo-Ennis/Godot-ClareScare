class_name Pumpkin
extends RigidBody3D
## Pumpkin Enemy AI with state system
##
## Features:
## - WANDER: Moves randomly while staying near spawn point and avoiding cliffs
## - CHASE: Pursues player when in sight, with pathfinding around obstacles
## - STUNNED: Can be extended for knockback effects
##
## The enemy automatically registers with GameManager.Player at startup
## Set show_debug to true in editor to see state information printed to console

## Enemy states
enum State {
	WANDER,
	CHASE,
	STUNNED
}

var SplatType = preload("res://Objects/Decorations/Pumpkins/PumpkinSplat.tscn")

## Current state
@export var current_state: State = State.WANDER

## Movement properties
@export var wander_speed: float = 1.0
@export var chase_speed: float = 3.0
@export var sight_range: float = 8.0
@export var lose_sight_range: float = 12.0
@export var wander_range: float = 5.0

## Wander behavior
var wander_direction: Vector3 = Vector3.ZERO
var wander_timer: float = 0.0
var wander_change_time: float = 3.0
var spawn_position: Vector3
var player_last_seen_position: Vector3

## References
var player: Node3D

## Fall detection
var ground_check_distance: float = 1.0
var cliff_detection_distance: float = 2.0

## Debug visualization
@export var show_debug: bool = false

func _ready() -> void:
	# Final initialization - all nodes should be ready now
	player = GameManager.Player
	spawn_position = global_position

	# Set initial wander direction
	_choose_new_wander_direction()

	# Connect to physics process for movement
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not player:
		return

	match current_state:
		State.WANDER:
			_process_wander_state(delta)
		State.CHASE:
			_process_chase_state(delta)
		State.STUNNED:
			_process_stunned_state(delta)

func _process_wander_state(delta: float) -> void:
	# Check if player is in sight
	if _can_see_player():
		_change_state(State.CHASE)
		return

	# Update wander timer
	wander_timer -= delta
	if wander_timer <= 0.0:
		_choose_new_wander_direction()

	# Check for cliffs or obstacles before moving
	if _is_safe_to_move(wander_direction):
		_move_in_direction(wander_direction, wander_speed)
	else:
		# Change direction if we hit an obstacle or cliff
		_choose_new_wander_direction()

func _process_chase_state(_delta: float) -> void:
	# Check if player is still in range
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player > lose_sight_range or not _can_see_player():
		_change_state(State.WANDER)
		return

	# Chase the player
	var direction_to_player = (player.global_position - global_position).normalized()
	direction_to_player.y = 0  # Keep movement horizontal

	# Check if it's safe to move toward player (avoid falling off cliffs)
	if _is_safe_to_move(direction_to_player):
		_move_in_direction(direction_to_player, chase_speed)
	else:
		# If we can't move directly toward player, try to find alternate path
		var alternate_direction = _find_safe_alternate_direction(direction_to_player)
		if alternate_direction != Vector3.ZERO:
			_move_in_direction(alternate_direction, chase_speed * 0.5)

func _process_stunned_state(_delta: float) -> void:
	# For now, stunned state just stops movement
	# Could be extended for knockback effects, etc.
	pass

func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return

	# Log state change
	if show_debug:
		print("Pumpkin ", name, ": State changed from ", get_state_name(), " to ", _get_state_name(new_state))

	# Exit current state
	match current_state:
		State.WANDER:
			pass
		State.CHASE:
			pass
		State.STUNNED:
			pass

	# Enter new state
	current_state = new_state
	match new_state:
		State.WANDER:
			_choose_new_wander_direction()
		State.CHASE:
			player_last_seen_position = player.global_position
		State.STUNNED:
			linear_velocity = Vector3.ZERO

func _can_see_player() -> bool:
	if not player:
		return false

	var distance = global_position.distance_to(player.global_position)
	if distance > sight_range:
		return false

	# Simple line of sight check - could be enhanced with raycasting
	var space_state = get_world_3d().direct_space_state
	var ray_start = global_position + Vector3(0, 0.5, 0)
	var ray_end = player.global_position + Vector3(0, 0.5, 0)

	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	# Exclude the pumpkin's own rigid body from the raycast
	query.exclude = [get_rid()]

	var result = space_state.intersect_ray(query)
	if result:
		# Check if we hit the player or something else
		var collider = result.get("collider")

		# Check if we hit the player using group lookup
		# First check if the collider itself is in the Players group
		var hit_player = null
		if collider.is_in_group("Players"):
			hit_player = collider
		else:
			# If not, check its parents
			hit_player = Utils.FindParentWithGroup(collider, "Players")

		if hit_player:
			return true
		else:
			return false
	else:
		# No obstruction
		return true

func _choose_new_wander_direction() -> void:
	# Choose a random direction
	var angle = randf() * TAU
	wander_direction = Vector3(cos(angle), 0, sin(angle))
	wander_timer = wander_change_time + randf() * 2.0  # Add some randomness

	# Make sure we don't wander too far from spawn
	var distance_from_spawn = global_position.distance_to(spawn_position)
	if distance_from_spawn > wander_range:
		# Head back toward spawn
		wander_direction = (spawn_position - global_position).normalized()
		wander_direction.y = 0

func _is_safe_to_move(direction: Vector3) -> bool:
	if direction == Vector3.ZERO:
		return false

	var space_state = get_world_3d().direct_space_state
	var start_pos = global_position + Vector3(0, 0.5, 0)
	var check_pos = start_pos + direction * cliff_detection_distance

	# Check for ground ahead
	var ground_query = PhysicsRayQueryParameters3D.create(
		check_pos,
		check_pos - Vector3(0, ground_check_distance, 0)
	)

	var ground_result = space_state.intersect_ray(ground_query)
	if not ground_result:
		# No ground found - would fall
		return false

	# Check for obstacles
	var obstacle_query = PhysicsRayQueryParameters3D.create(
		start_pos,
		start_pos + direction * 1.0
	)

	var obstacle_result = space_state.intersect_ray(obstacle_query)
	if obstacle_result:
		var collider = obstacle_result.get("collider")
		# Allow movement toward player, but not toward walls/obstacles
		if collider and collider.get_parent() != player:
			return false

	return true

func _find_safe_alternate_direction(preferred_direction: Vector3) -> Vector3:
	# Try directions to the left and right of preferred direction
	var angles_to_try = [PI/4, -PI/4, PI/2, -PI/2, 3*PI/4, -3*PI/4]

	for angle_offset in angles_to_try:
		var test_direction = preferred_direction.rotated(Vector3.UP, angle_offset)
		if _is_safe_to_move(test_direction):
			return test_direction

	return Vector3.ZERO

func _move_in_direction(direction: Vector3, speed: float) -> void:
	if direction == Vector3.ZERO:
		return

	# Apply movement force
	var movement_force = direction * speed * mass
	apply_central_force(movement_force)

	# Limit maximum velocity to prevent unrealistic speeds
	var max_velocity = speed * 2.0
	if linear_velocity.length() > max_velocity:
		linear_velocity = linear_velocity.normalized() * max_velocity

	# Face movement direction
	if direction.length() > 0.1:
		var target_transform = transform
		target_transform = target_transform.looking_at(global_position + direction, Vector3.UP)
		transform = transform.interpolate_with(target_transform, 0.1)

func stomped() -> void:
	var splat = SplatType.instantiate()
	splat.global_transform = global_transform
	get_parent().add_child(splat)

	queue_free()

## Debug function to visualize state
func get_state_name() -> String:
	return _get_state_name(current_state)

func _get_state_name(state: State) -> String:
	match state:
		State.WANDER:
			return "WANDER"
		State.CHASE:
			return "CHASE"
		State.STUNNED:
			return "STUNNED"
		_:
			return "UNKNOWN"

## Debug visualization using print statements
var debug_timer: float = 0.0
var debug_interval: float = 5.0  # Print debug info every 5 seconds

func _debug_print() -> void:
	if not show_debug:
		return

	var distance_to_player = "N/A"
	var can_see = false

	if player:
		distance_to_player = str(global_position.distance_to(player.global_position)).pad_decimals(2)
		can_see = _can_see_player()

	print("Pumpkin ", name, ": State=", get_state_name(), ", DistToPlayer=", distance_to_player, ", CanSee=", can_see, ", Pos=", global_position)

func _process(delta: float) -> void:
	if show_debug:
		debug_timer += delta
		if debug_timer >= debug_interval:
			debug_timer = 0.0
			_debug_print()
