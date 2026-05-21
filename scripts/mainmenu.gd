# res://scripts/main_menu.gd
extends Control

@onready var options_panel = $OptionsPanel  # sesuaikan path

func _on_start_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_option_btn_pressed() -> void:
	options_panel.visible = not options_panel.visible
	if options_panel.visible and options_panel.has_method("refresh"):
		options_panel.refresh()
