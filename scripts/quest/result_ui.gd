# res://scripts/result_ui.gd
extends CanvasLayer

@onready var message_label   = %MessageLabel
@onready var star_label      = %StarLabel
@onready var objektif_label  = %ObjektifLabel
@onready var restart_btn     = %RestartBtn
@onready var next_btn        = %NextBtn
@onready var main_menu_btn   = %MainMenuBtn

var target_lubang: int = 0
var lubang_terisi: int = 0
var quest_completed: bool = false
const SUCCESS_THRESHOLD := 1.0 # 3 stars only at 100%

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# ✅ Hide the result panel at start
	self.visible  = true
	$Panel.visible = false

	# Setup target lubang
	_update_target_lubang(GameState.current_level)
	
	if objektif_label:
		objektif_label.text = "🔧 Perbaiki Rumah: 0/" + str(target_lubang)

	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)
	
	if next_btn:
		next_btn.pressed.connect(_on_next_pressed)
	
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_main_menu_pressed)

	# Sambungkan ke QuestManager
	QuestManager.quest_step_updated.connect(_on_quest_step_updated)
	QuestManager.quest_step_done.connect(_on_quest_step_done)
	QuestManager.all_quests_done.connect(_on_all_quests_done)
	GameState.level_changed.connect(_on_level_changed)

func _update_target_lubang(level_name: String) -> void:
	var steps = QuestManager.QUEST_DATA.get(level_name, [])
	target_lubang = 0
	for s in steps:
		if s.get("trigger", "") == "slot_filled":
			target_lubang = max(target_lubang, int(s.get("count", 0)))
	
	if target_lubang == 0:
		target_lubang = (3 if level_name == "tutorial" else 6)

func tambah_objektif():
	lubang_terisi += 1
	if objektif_label:
		objektif_label.text = "🔧 Perbaiki Rumah: %d/%d" % [lubang_terisi, target_lubang]

func _on_quest_step_updated(description: String, progress: int, total: int) -> void:
	lubang_terisi = progress
	target_lubang = total
	if objektif_label:
		objektif_label.text = "%s: %d/%d" % [description, progress, total]

func _on_quest_step_done(_description: String, _coins_earned: int) -> void:
	if objektif_label:
		objektif_label.modulate = Color.GREEN
		await get_tree().create_timer(0.4).timeout
		objektif_label.modulate = Color.WHITE

func _on_all_quests_done() -> void:
	quest_completed = true

func _on_level_changed(level_name: String) -> void:
	lubang_terisi = 0
	_update_target_lubang(level_name)
	quest_completed = false
	if objektif_label:
		objektif_label.text = "🔧 Perbaiki Rumah: 0/" + str(target_lubang)
	if next_btn:
		next_btn.hide()

func show_result(_scale: float, _survived_blocks: int) -> void:
	$Panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

	if objektif_label:
		objektif_label.text = "🔧 Perbaiki Rumah: %d/%d" % [lubang_terisi, target_lubang]

	# Always show Restart and Main Menu
	restart_btn.show()
	main_menu_btn.show()

	# Logic for Stars and Next Level Button
	var stars = 1
	
	if GameState.structural_failure:
		stars = 0
		star_label.text = ""
		message_label.text = "Failed: Improper structural placement"
	elif lubang_terisi >= target_lubang:
		stars = 3
		star_label.text = "⭐⭐⭐"
		message_label.text = "Rumah lengkap! Sempurna!"
	elif lubang_terisi >= 2: # 2 stars for 2 or more (but not all)
		stars = 2
		star_label.text = "⭐⭐"
		message_label.text = "Rumah hampir lengkap. Teruskan!"
	else:
		stars = 1
		star_label.text = "⭐"
		message_label.text = "Rumah belum lengkap. Coba lagi!"

	# Button Visibility Logic:
	# - Only "tutorial" level can show Next Level button.
	# - Only shows if 3 stars achieved.
	if GameState.current_level == "tutorial" and stars == 3:
		next_btn.show()
	else:
		next_btn.hide()

func _on_restart_pressed():
	get_tree().paused = false
	GameState.reset_level_state()
	get_tree().reload_current_scene()

func _on_next_pressed():
	get_tree().paused = false
	GameState.go_to_level("level_01")
	$Panel.visible = false

func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/interface/main_menu.tscn")
