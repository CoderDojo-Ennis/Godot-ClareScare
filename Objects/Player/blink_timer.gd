extends Timer

@onready var player: Claire = get_parent() as Claire

# How quickly a blink happens
@export var blink_speed_seconds: float = 0.15

# Range of time between blinks
@export_group("Blink Rate")
@export var blink_rate_min_seconds: float = 2.0
@export var blink_rate_max_seconds: float = 6.0

# How long have I been blinking
var blink_time: float = 0.0
var previous_eyes: EyeExpressions.EyeType = EyeExpressions.EyeType.NORMAL

func _ready() -> void:
	pick_random_blink_time()

func _physics_process(delta: float) -> void:
	# End blink
	if blink_time > 0:
		blink_time -= delta
		if (blink_time <= 0):
			player.SetEyeExpression(previous_eyes)

func _on_timeout() -> void:
	blink_now()

func blink_now() -> void:
	previous_eyes = player.GetCurrentEyeExpression()
	player.SetEyeExpression(EyeExpressions.EyeType.BLINK)
	blink_time = blink_speed_seconds
	pick_random_blink_time()

func pick_random_blink_time() -> void:
	wait_time = randf_range(blink_rate_min_seconds, blink_rate_max_seconds)
