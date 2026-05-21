# res://scripts/result_ui.gd
extends CanvasLayer

@onready var message_label   = %MessageLabel
@onready var star_label      = %StarLabel
@onready var objektif_label  = %ObjektifLabel
@onready var restart_btn     = %RestartBtn

var target_lubang  := 6
var lubang_terisi  := 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# ✅ JANGAN hide seluruh CanvasLayer — hanya Panel-nya
	self.visible  = true
	$Panel.visible = false

	if objektif_label:
		objektif_label.text = "🔧 Perbaiki Rumah: 0/" + str(target_lubang)

	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)

func tambah_objektif():
	lubang_terisi += 1
	if objektif_label:
		objektif_label.text = "🔧 Perbaiki Rumah: %d/%d" % [lubang_terisi, target_lubang]

	# Efek flash hijau saat berhasil
	if objektif_label:
		objektif_label.modulate = Color.GREEN
		await get_tree().create_timer(0.4).timeout
		objektif_label.modulate = Color.WHITE

func show_result(scale: float, survived_blocks: int):
	$Panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

	if lubang_terisi < target_lubang:
		message_label.text = "GAGAL!\nBelum semua lubang ditutup sebelum gempa!"
		star_label.text = "❌  0 Bintang"
		return

	var total_blocks = get_tree().get_nodes_in_group("placed_blocks").size()
	if total_blocks == 0: total_blocks = 1
	var survival_rate : float = float(survived_blocks) / float(total_blocks)

	message_label.text = "Gempa %.1f SR!" # \nBlok Selamat: %d dari %d" % [scale, survived_blocks, total_blocks]

	if survival_rate >= 0.9:
		star_label.text = "⭐⭐⭐  Sangat Kokoh!"
	elif survival_rate >= 0.5:
		star_label.text = "⭐⭐  Ada kerusakan."
	else:
		star_label.text = "⭐  Rumah runtuh!"

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
