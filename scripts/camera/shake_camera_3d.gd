class_name ShakeCamera3D
extends Camera3D

@export var trauma_reduction_rate: float = 0.8
@export var max_x: float = 15.0
@export var max_y: float = 15.0
@export var max_z: float = 10.0

@export var noise: FastNoiseLite = FastNoiseLite.new()
@export var noise_speed: float = 50.0

var trauma: float = 0.0
var time: float = 0.0

@onready var initial_rotation: Vector3 = rotation

func _ready() -> void:
	randomize()
	noise.seed = randi()
	noise.frequency = 0.1
	noise.fractal_octaves = 2

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	if trauma > 0:
		time += delta * noise_speed
		trauma = max(trauma - trauma_reduction_rate * delta, 0.0)
		
		# "Juiciness" comes from using a power of the trauma (usually 2 or 3)
		# This makes the shake intensity drop off non-linearly.
		var shake: float = pow(trauma, 3.0)
		
		# Procedural rotation offset using noise
		rotation.x = initial_rotation.x + deg_to_rad(max_x * shake * noise.get_noise_2d(time, 0))
		rotation.y = initial_rotation.y + deg_to_rad(max_y * shake * noise.get_noise_2d(0, time))
		rotation.z = initial_rotation.z + deg_to_rad(max_z * shake * noise.get_noise_2d(time, time))
	else:
		# Return to initial rotation smoothly when trauma is 0
		rotation = rotation.lerp(initial_rotation, delta * 5.0)
