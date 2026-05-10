extends CanvasLayer

@onready var message_label = %MessageLabel
@onready var star_label = %StarLabel
@onready var objektif_label = %ObjektifLabel
@onready var restart_btn = %RestartBtn

var target_lubang = 6
var lubang_terisi = 0

func _ready():
	# Sembunyikan panel pop-up di awal, tapi biarkan label objektif menyala
	$Panel.visible = false 
	objektif_label.text = "Perbaiki Rumah: 0/" + str(target_lubang)
	
	var eq_manager = get_tree().current_scene.find_child("EarthquakeManager*", true, false)
	#if eq_manager:
		#eq_manager.earthquake_ended.connect(show_result)

func tambah_objektif():
	lubang_terisi += 1
	objektif_label.text = "Perbaiki Rumah: " + str(lubang_terisi) + "/" + str(target_lubang)

func show_result(scale: float, survived_blocks: int):
	$Panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Evaluasi 1: Apakah pemain menyelesaikan perbaikan sebelum gempa?
	if lubang_terisi < target_lubang:
		message_label.text = "GAGAL!\nKamu belum menutup semua lubang sebelum gempa terjadi!"
		star_label.text = "❌ (0 Bintang)"
		return
		
	# Evaluasi 2: Apakah bangunan kuat bertahan dari gempa?
	var total_blocks = get_tree().get_nodes_in_group("placed_blocks").size()
	var survival_rate = float(survived_blocks) / float(total_blocks)
	
	message_label.text = "Gempa %.1f SR Selesai!\nBlok Selamat: %d dari %d" % [scale, survived_blocks, total_blocks]
	
	if survival_rate >= 0.9:
		star_label.text = "⭐⭐⭐\nKonstruksi Sangat Kokoh!"
	elif survival_rate >= 0.5:
		star_label.text = "⭐⭐\nLumayan, ada kerusakan struktural."
	else:
		star_label.text = "⭐\nBerbahaya, rumah runtuh!"
