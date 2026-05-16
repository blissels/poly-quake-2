# res://scripts/audio_manager.gd
extends Node

var music_bus  := AudioServer.get_bus_index("Master")
var is_muted   := false
var volume_pct : float = 0.8  # 0.0 – 1.0

func _ready():
	set_volume(volume_pct)

func set_volume(value: float) -> void:
	volume_pct = clamp(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(volume_pct))
	# Jika volume > 0 dan sedang mute, otomatis unmute
	if volume_pct > 0.0 and is_muted:
		is_muted = false
		AudioServer.set_bus_mute(music_bus, false)

func toggle_mute() -> void:
	is_muted = not is_muted
	AudioServer.set_bus_mute(music_bus, is_muted)

func get_volume() -> float:
	return volume_pct

func get_muted() -> bool:
	return is_muted
