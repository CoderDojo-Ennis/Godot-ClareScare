extends Timer

@onready var girl_eyes_geo: MeshInstance3D = $"../Armature/Skeleton3D/Girl_Eyes_Geo"

# How quickly a blink happens
@export var blink_speed_seconds: float = 0.1

# Range of time between blinks
@export_group("Blink Rate")
@export var blink_rate_min_seconds: float = 2.0
@export var blink_rate_max_seconds: float = 6.0

# How long have I been blinking
var blink_time: float = 0.0

func _ready() -> void:
	pick_random_blink_time()

func _physics_process(delta: float) -> void:
	if blink_time > 0:
		blink_time -= delta
	else :
		girl_eyes_geo.visible = true

func _on_timeout() -> void:
	blink_now()

func blink_now() -> void:
	girl_eyes_geo.visible = false
	blink_time = blink_speed_seconds
	pick_random_blink_time()

func pick_random_blink_time() -> void:
	wait_time = randf_range(blink_rate_min_seconds, blink_rate_max_seconds)
