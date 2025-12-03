extends Camera3D
# You can also use: extends Node3D
# if you attach this to your Pivot instead.

@export var enabled: bool = true

@export var bob_amplitude: float = 0.05      # up/down amount (meters)
@export var bob_speed: float = 0.25          # cycles per second

@export var sway_amplitude: float = 0.03     # left/right amount (meters)
@export var sway_speed: float = 0.18         # cycles per second

@export var roll_amplitude_deg: float = 0.6  # subtle roll tilt
@export var roll_speed: float = 0.12         # cycles per second

var _base_position: Vector3
var _base_rotation: Vector3
var _time: float = 0.0


func _ready() -> void:
	# Remember the starting transform so we only add a *tiny* offset.
	_base_position = position
	_base_rotation = rotation


func _process(delta: float) -> void:
	if not enabled:
		return

	_time += delta

	# Smooth looping movement using sine waves.
	var bob_offset := sin(_time * TAU * bob_speed) * bob_amplitude           # Y
	var sway_offset := sin(_time * TAU * sway_speed + PI * 0.5) * sway_amplitude  # X
	var roll_angle_rad := deg_to_rad(
		sin(_time * TAU * roll_speed) * roll_amplitude_deg
	)

	# Apply offsets relative to the base transform.
	position = _base_position + Vector3(sway_offset, bob_offset, 0.0)
	rotation = Vector3(
		_base_rotation.x,
		_base_rotation.y,
		_base_rotation.z + roll_angle_rad
	)
