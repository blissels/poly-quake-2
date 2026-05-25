# res://scripts/result_ui.gd
extends CanvasLayer

@onready var message_label   = %MessageLabel
@onready var star_label      = %StarLabel
@onready var objektif_label  = %ObjektifLabel
@onready var restart_btn     = %RestartBtn

var target_lubang: int = 0
var lubang_terisi: int = 0
var quest_completed: bool = false
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
	# Tampilkan panel hasil terlebih dahulu
	$Panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Pastikan objektif_label menampilkan nilai terakhir dari quest
	if objektif_label:
		objektif_label.text = "🔧 Perbaiki Rumah: %d/%d" % [lubang_terisi, target_lubang]

	# Hitung nilai 'progress' sensor (0..3) berdasarkan jumlah bagian yang ditempel
	var progress: int = clamp(lubang_terisi, 0, 3)

	# Sembunyikan tombol Next selalu (level selanjutnya dibatalkan)
	var local_next := $Panel/VBoxContainer.get_node_or_null("NextBtn")
	if local_next:
		local_next.hide()

	# Tampilkan bintang sesuai progress dan trigger collapse untuk 0 atau 1
	if progress == 0:
		# Bintang 0: pemain tidak melakukan objektif yang valid
		star_label.text = ""  # tidak ada bintang
		message_label.text = "Tidak ada bagian terpasang."
		_trigger_collapse_level()
	elif progress == 1:
		# Bintang 1: setidaknya 1 bagian terpasang
		star_label.text = "⭐"
		message_label.text = "Hanya 1 bagian terpasang."
		_trigger_collapse_level()
	elif progress == 2:
		# Bintang 2: dua bagian terpasang — tetap berdiri
		star_label.text = "⭐⭐"
		message_label.text = "Dua bagian terpasang."
	else:
		# Bintang 3: lengkap — tetap berdiri
		star_label.text = "⭐⭐⭐"
		message_label.text = "Rumah lengkap!"

	# Block UI: pause the game and require explicit player action (Restart)
	get_tree().paused = true


func _trigger_collapse_level() -> void:
	# Coba panggil trigger_collapse() pada node Level01 (root level_tutorial)
	var root_scene = get_tree().get_current_scene()
	if root_scene:
		var lvl = root_scene.get_node_or_null("Level01")
		if lvl and lvl.has_method("trigger_collapse"):
			lvl.trigger_collapse()
			return
	# Fallback: cari node yang punya method trigger_collapse di seluruh tree
	for n in get_tree().get_nodes_in_group("placed_blocks"):
		# Jika parent scene mempunyai method, panggil saja
		var parent_scene = n.get_owner()
		if parent_scene and parent_scene.has_method("trigger_collapse"):
			parent_scene.trigger_collapse()
			return

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_next_pressed():
	# Lanjut ke level_01 ketika NextBtn ditekan
	get_tree().paused = false
	GameState.go_to_level("level_01")
	$Panel.visible = false
