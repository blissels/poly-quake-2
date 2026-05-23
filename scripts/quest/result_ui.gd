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

func tambah_objektif():
	lubang_terisi += 1
	if objektif_label:
		objektif_label.text = "🔧 Perbaiki Rumah: %d/%d" % [lubang_terisi, target_lubang]

	# Efek flash hijau saat berhasil
	if objektif_label:
		objektif_label.modulate = Color.GREEN
		await get_tree().create_timer(0.4).timeout
		objektif_label.modulate = Color.WHITE

func _on_quest_step_updated(description: String, progress: int, total: int) -> void:
	if objektif_label:
		objektif_label.text = "%s: %d/%d" % [description, progress, total]

func _on_quest_step_done(description: String, coins_earned: int) -> void:
	# Berikan umpan balik singkat
	if objektif_label:
		objektif_label.modulate = Color(0.6, 1.0, 0.6)
		await get_tree().create_timer(0.4).timeout
		objektif_label.modulate = Color.WHITE

func _on_all_quests_done() -> void:
	quest_completed = true

func show_result(scale: float, survived_blocks: int) -> void:
	$Panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

	var total_blocks = get_tree().get_nodes_in_group("placed_blocks").size()
	if total_blocks == 0: total_blocks = 1
	var survival_rate : float = float(survived_blocks) / float(total_blocks)

	message_label.text = "Gempa %.1f SR!" % scale

	if survival_rate >= 0.9:
		star_label.text = "⭐⭐⭐  Sangat Kokoh!"
	elif survival_rate >= 0.5:
		star_label.text = "⭐⭐  Ada kerusakan."
	else:
		star_label.text = "⭐  Rumah runtuh!"

	# Tampilkan tombol lanjut hanya jika semua quest selesai DAN level dianggap berhasil
	next_btn = $Panel/VBoxContainer.get_node("NextBtn")
	var level_succeeded := survival_rate >= SUCCESS_THRESHOLD
	if quest_completed and level_succeeded:
		next_btn.visible = true
	else:
		next_btn.visible = false

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_next_pressed():
	# Lanjut ke level_01 ketika NextBtn ditekan
	get_tree().paused = false
	GameState.go_to_level("level_01")
	$Panel.visible = false
