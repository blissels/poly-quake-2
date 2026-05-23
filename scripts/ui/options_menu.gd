# res://scripts/options_menu.gd
extends Control

@onready var volume_slider : HSlider = $Panel/VBoxContainer/HBoxContainer/VolumeSlider
@onready var mute_btn      : Button  = $Panel/VBoxContainer/MuteBtn
@onready var close_btn     : Button  = $Panel/VBoxContainer/CloseBtn

func _ready():
	visible = false
	volume_slider.value = AudioManager.get_volume()
	_update_mute_icon()
	
	volume_slider.value_changed.connect(_on_volume_changed)
	mute_btn.pressed.connect(_on_mute_pressed)
	close_btn.pressed.connect(func(): visible = false)

func show_options():
	visible = true
	volume_slider.value = AudioManager.get_volume()
	_update_mute_icon()

func _on_volume_changed(value: float) -> void:
	AudioManager.set_volume(value)
	_update_mute_icon()

func _on_mute_pressed() -> void:
	AudioManager.toggle_mute()
	_update_mute_icon()

func _update_mute_icon() -> void:
	mute_btn.text = "🔇 Unmute" if AudioManager.get_muted() else "🔊 Mute"

func _on_close_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/interface/main_menu.tscn")
