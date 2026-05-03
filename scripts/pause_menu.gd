extends Control

func _ready() -> void:
	# Sembunyikan saat pertama load
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		if visible:
			hide_pause()
		else:
			show_pause()

func show_pause() -> void:
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hide_pause() -> void:
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_btn_pressed() -> void:
	hide_pause()

func _on_main_menu_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/interface/main_menu.tscn")
