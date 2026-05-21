# res://scripts/pause_menu.gd
extends Control

@onready var options_panel = $PanelContainer/VBoxContainer/OptionsPanel

func _ready() -> void:
	add_to_group("pause_menu")
	visible = false

func show_pause() -> void:
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Refresh slider supaya nilai selalu up-to-date
	if options_panel and options_panel.has_method("refresh"):
		options_panel.refresh()

func hide_pause() -> void:
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_btn_pressed() -> void:  
	hide_pause()
	
func _on_main_menu_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/interface/main_menu.tscn")
