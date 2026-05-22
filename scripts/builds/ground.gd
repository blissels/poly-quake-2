extends CharacterBody3D

@export var shake_intensity: float = 3.0
@export var shake_duration: float = 10.0
@export var frequency: float = 15.0

var _noise := FastNoiseLite.new()
var _shaking: bool = false
var _elapsed: float = 0.0
var _original_origin: Vector3

func _ready() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = frequency * 0.01
	_original_origin = global_position

func trigger_earthquake(intensity: float = 4.0, duration: float = 10.0) -> void:
	shake_intensity = intensity
	shake_duration = duration
	_elapsed = 0.0
	_shaking = true

func _physics_process(delta: float) -> void:
	if _shaking:
		_elapsed += delta
		if _elapsed < shake_duration:
			var t := _elapsed / shake_duration
			var falloff := 1.0 - t # Gempa semakin lama semakin pelan
			
			var time_val = Time.get_ticks_msec() / 1000.0 * frequency
			
			# Tambahkan * 0.05 di ujungnya agar guncangan tidak brutal
			var ox = _noise.get_noise_2d(time_val, 0.0) * shake_intensity * falloff * 0.05
			var oz = _noise.get_noise_2d(time_val, 100.0) * shake_intensity * falloff * 0.05
			
			var target_pos = _original_origin + Vector3(ox, 0, oz)
			velocity = (target_pos - global_position) / delta
			velocity.y = 0 # Kunci sumbu Y
			move_and_slide()
			global_position.y = _original_origin.y
			
			
		else:
			_shaking = false
			global_position = _original_origin
			velocity = Vector3.ZERO
