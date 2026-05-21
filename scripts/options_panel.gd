# res://scripts/options_panel.gd
extends PanelContainer

@onready var volume_slider : HSlider = $MarginContainer/VBoxContainer/HBoxContainer/VolumeSlider
@onready var mute_btn      : Button  = $MarginContainer/VBoxContainer/MuteBtn

func _ready() -> void:
	volume_slider.value = AudioManager.get_volume()
	_refresh_mute_btn()
	volume_slider.value_changed.connect(func(v): AudioManager.set_volume(v))
	mute_btn.pressed.connect(_on_mute_pressed)

func _on_mute_pressed() -> void:
	AudioManager.toggle_mute()
	_refresh_mute_btn()

func _refresh_mute_btn() -> void:
	mute_btn.text = "🔇 Unmute" if AudioManager.get_muted() else "🔊 Mute"

func refresh() -> void:
	volume_slider.value = AudioManager.get_volume()
	_refresh_mute_btn()
