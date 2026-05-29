# res://scripts/quest/shake_camera_3d.gd
extends Camera3D

@export_group("Trauma Settings")
@export var trauma_reduction_rate: float = 1.0
@export var max_x: float = 10.0
@export var max_y: float = 10.0
@export var max_z: float = 5.0
@export var noise_frequency: float = 4.0

@onready var noise: FastNoiseLite = FastNoiseLite.new()

var trauma: float = 0.0
var time: float = 0.0

func _ready() -> void:
	noise.seed = randi()
	noise.frequency = noise_frequency

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	if trauma > 0:
		time += delta * 100.0 # Speed of noise traversal
		trauma = max(trauma - trauma_reduction_rate * delta, 0.0)
		_apply_shake()
	else:
		rotation_degrees = Vector3.ZERO

func _apply_shake() -> void:
	var shake: float = trauma * trauma # Quadratic trauma for better feel
	
	# Noise-based offsets for procedural movement
	rotation_degrees.x = max_x * shake * noise.get_noise_2d(time, 0)
	rotation_degrees.y = max_y * shake * noise.get_noise_2d(0, time)
	rotation_degrees.z = max_z * shake * noise.get_noise_2d(time, time)
