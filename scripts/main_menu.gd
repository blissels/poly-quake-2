extends Control

@onready var options_menu = $OptionsMenu  # sesuaikan path

func _on_start_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_option_btn_pressed() -> void:
	options_menu.show_options()
	get_tree().change_scene_to_file("res://scenes/interface/OptionsMenu.tscn")
