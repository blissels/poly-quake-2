# res://scripts/result_ui.gd
extends CanvasLayer

@onready var message_label   = %MessageLabel
@onready var star_label      = %StarLabel
@onready var objektif_label  = %ObjektifLabel
@onready var restart_btn     = %RestartBtn

var target_lubang  := 0
var lubang_terisi  := 0
var quest_completed := false
var next_btn: Button = null
const SUCCESS_THRESHOLD := 0.5

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# ✅ JANGAN hide seluruh CanvasLayer — hanya Panel-nya
	self.visible  = true
	$Panel.visible = false

	# Tentukan target berdasarkan data QuestManager agar selalu sinkron
	var steps = QuestManager.QUEST_DATA.get(GameState.current_level, [])
	for s in steps:
		if s.get("trigger", "") == "slot_filled":
			target_lubang += int(s.get("count", 0))
	if target_lubang == 0:
		# fallback default
		target_lubang = 6
	if objektif_label:
		objektif_label.text = "🔧 Perbaiki Rumah: 0/" + str(target_lubang)

	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)

	# Pastikan ada tombol "Lanjut Level" di Panel/VBoxContainer
	var container := $Panel.get_node("VBoxContainer")
	next_btn = null
	if container.has_node("NextBtn"):
		next_btn = container.get_node("NextBtn")
	else:
		next_btn = Button.new()
		next_btn.name = "NextBtn"
		next_btn.text = "Lanjut Level"
		container.add_child(next_btn)
	next_btn.visible = false
	next_btn.pressed.connect(_on_next_pressed)

	# Sambungkan ke QuestManager untuk menampilkan objektif dinamis
	QuestManager.quest_step_updated.connect(_on_quest_step_updated)
	QuestManager.quest_step_done.connect(_on_quest_step_done)
	QuestManager.all_quests_done.connect(_on_all_quests_done)
	# Dengarkan pergantian level agar UI dapat direset ketika level berganti
	GameState.level_changed.connect(_on_level_changed)

func tambah_objektif():
	lubang_terisi += 1
	print("[ResultUI] tambah_objektif called. lubang_terisi=%d, target=%d" % [lubang_terisi, target_lubang])
	if objektif_label:
		objektif_label.text = "🔧 Perbaiki Rumah: %d/%d" % [lubang_terisi, target_lubang]

	# Efek flash hijau saat berhasil
	if objektif_label:
		objektif_label.modulate = Color.GREEN
		await get_tree().create_timer(0.4).timeout
		objektif_label.modulate = Color.WHITE

func _on_quest_step_updated(description: String, progress: int, total: int) -> void:
	# Update internal counters from QuestManager so ResultUI always reflects final values
	print("[ResultUI] quest_step_updated: '%s' %d/%d" % [description, progress, total])
	lubang_terisi = progress
	target_lubang = total
	if objektif_label:
		objektif_label.text = "%s: %d/%d" % [description, progress, total]

func _on_quest_step_done(description: String, coins_earned: int) -> void:
	print("[ResultUI] quest_step_done: '%s' (+%d coins)" % [description, coins_earned])
	# Berikan umpan balik singkat
	if objektif_label:
		objektif_label.modulate = Color(0.6, 1.0, 0.6)
		await get_tree().create_timer(0.4).timeout
		objektif_label.modulate = Color.WHITE

func _on_all_quests_done() -> void:
	quest_completed = true

func _on_level_changed(level_name: String) -> void:
	# Reset local UI counters when switching levels
	lubang_terisi = 0
	target_lubang = 0
	quest_completed = false
	# Recompute target based on new level
	var steps = QuestManager.QUEST_DATA.get(level_name, [])
	for s in steps:
		if s.get("trigger", "") == "slot_filled":
			target_lubang += int(s.get("count", 0))
	if target_lubang == 0:
		# fallback default
		target_lubang = 6
	if objektif_label:
		objektif_label.text = "🔧 Perbaiki Rumah: 0/" + str(target_lubang)
	# Ensure Next button hidden until conditions met
	if next_btn:
		next_btn.visible = false

func show_result(scale: float, survived_blocks: int) -> void:
	# Tampilkan panel hasil terlebih dahulu (jangan pause langsung jika akan auto-transition)
	$Panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Pastikan objektif_label menampilkan nilai terakhir dari quest
	if objektif_label:
		objektif_label.text = "🔧 Perbaiki Rumah: %d/%d" % [lubang_terisi, target_lubang]

	# Tentukan bintang dan teks evaluasi berdasarkan jumlah objektif yang selesai
	var level_ready := false
	if target_lubang > 0:
		if lubang_terisi >= target_lubang:
			star_label.text = "⭐⭐⭐"
			message_label.text = "Rumah lengkap!"
			level_ready = true
		elif lubang_terisi == target_lubang - 1:
			star_label.text = "⭐⭐"
			message_label.text = "Rumah tidak lengkap!"
			level_ready = false
		else:
			star_label.text = "⭐"
			message_label.text = "Rumah tidak lengkap!"
			level_ready = false
	else:
		# fallback jika target tidak diketahui: gunakan survival rate
		var total_blocks = get_tree().get_nodes_in_group("placed_blocks").size()
		if total_blocks == 0: total_blocks = 1
		var survival_rate : float = float(survived_blocks) / float(total_blocks)
		if survival_rate >= 0.9:
			star_label.text = "⭐⭐⭐  Sangat Kokoh!"
			message_label.text = "Rumah lengkap!"
			level_ready = true
		elif survival_rate >= 0.5:
			star_label.text = "⭐⭐  Ada kerusakan."
			message_label.text = "Rumah tidak lengkap!"
			level_ready = false
		else:
			star_label.text = "⭐ Rumah tidak lengkap!"
			message_label.text = "Rumah tidak lengkap!"
			level_ready = false

	# Next button disabled — players must use Restart to retry the level
	next_btn = $Panel/VBoxContainer.get_node("NextBtn")
	if next_btn:
		next_btn.visible = false

	# Block UI: pause the game and require explicit player action (Next/Restart)
	# This ensures the player is stuck on the Result UI until they click a button.
	get_tree().paused = true

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_next_pressed():
	# Lanjut ke level_01 ketika NextBtn ditekan
	get_tree().paused = false
	GameState.go_to_level("level_01")
	$Panel.visible = false
