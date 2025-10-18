class_name EyeExpressions
extends RefCounted

# Enum for eye expressions - makes it easier to select different expressions
enum EyeType {
	NORMAL,      # 0,0 - Default expression
	BLINK,       # 1,8 - Blinking eyes
	CLOSED,      # 1,2 - Eyes closed
	TIRED,       # 2,0 - Tired/sleepy expression
	FRIGHTENED,  # 2,9 - Scared/frightened expression
	DEAD,        # 2,7 - Dead/unconscious expression
	LOVE,        # 2,6 - Love/heart eyes expression
	ANGRY,       # 0,1 - Angry expression
	SURPRISED,   # 0,2 - Surprised expression
	WINK         # 1,0 - Winking expression
}

# Mapping from EyeType enum to UV coordinates
static var coordinates: Dictionary = {
	EyeType.NORMAL: Vector2i(0, 0),
	EyeType.BLINK: Vector2i(1, 8),
	EyeType.CLOSED: Vector2i(1, 2),
	EyeType.TIRED: Vector2i(2, 0),
	EyeType.FRIGHTENED: Vector2i(2, 9),
	EyeType.DEAD: Vector2i(2, 7),
	EyeType.LOVE: Vector2i(2, 6),
	EyeType.ANGRY: Vector2i(0, 1),
	EyeType.SURPRISED: Vector2i(0, 2),
	EyeType.WINK: Vector2i(1, 0)
}

## Get the UV coordinates for a given expression
static func get_coordinates(expression: EyeType) -> Vector2i:
	if expression in coordinates:
		return coordinates[expression]
	else:
		print("EyeExpressions: Invalid expression enum value: ", expression)
		return Vector2i(0, 0)  # Return normal expression as fallback

## Get the expression enum from UV coordinates (if it matches a known expression)
static func get_expression_from_coordinates(coords: Vector2i) -> EyeType:
	for expression in coordinates:
		if coordinates[expression] == coords:
			return expression
	# Return NORMAL if coordinates don't match any known expression
	return EyeType.NORMAL

## Get a readable name for an expression
static func get_expression_name(expression: EyeType) -> String:
	return EyeType.keys()[expression]
