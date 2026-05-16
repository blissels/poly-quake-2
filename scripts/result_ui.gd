extends CanvasLayer

@onready var message_label = %MessageLabel
@onready var star_label = %StarLabel
@onready var objektif_label = %ObjektifLabel # Pastikan node label skor ini ada di bawah root ResultUI
@onready var restart_btn = %RestartBtn # Pastikan node tombol ini ada di dalam Panel

var target_lubang = 6
var lubang_terisi = 0

func _ready():
	# Membuat UI ini kebal dari status Pause game
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Sembunyikan pop-up hasil di awal game
	self.visible = false
	$Panel.visible = false 
	
	# Set tulisan awal target bangunan di layar
	if objektif_label:
		objektif_label.text = "Perbaiki Rumah: 0/" + str(target_lubang)
	
	# Hubungkan tombol klik ke fungsi restart di bawah
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)

func tambah_objektif():
	lubang_terisi += 1
	if objektif_label:
		objektif_label.text = "Perbaiki Rumah: " + str(lubang_terisi) + "/" + str(target_lubang)

func show_result(scale: float, survived_blocks: int):
	self.visible = true
	$Panel.visible = true
	
	# Munculkan kursor mouse & hentikan waktu dunia game (Pause fisik)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	
	# Evaluasi 1: Cek apakah lubang sudah ditutup semua
	if lubang_terisi < target_lubang:
		message_label.text = "GAGAL!\nKamu belum menutup semua lubang sebelum gempa terjadi!"
		star_label.text = "❌ (0 Bintang)"
		return
		
	# Evaluasi 2: Hitung persentase bangunan yang selamat
	var total_blocks = get_tree().get_nodes_in_group("placed_blocks").size()
	if total_blocks == 0: total_blocks = 1 # Menghindari pembagian angka 0
	
	var survival_rate = float(survived_blocks) / float(total_blocks)
	message_label.text = "Gempa %.1f SR Selesai!\nBlok Selamat: %d dari %d" % [scale, survived_blocks, total_blocks]
	
	# Penilaian Bintang
	if survival_rate >= 0.9:
		star_label.text = "⭐⭐⭐\nKonstruksi Sangat Kokoh!"
	elif survival_rate >= 0.5:
		star_label.text = "⭐⭐\nLumayan, ada kerusakan struktural."
	else:
		star_label.text = "⭐\nBerbahaya, rumah runtuh!"

func _on_restart_pressed():
	get_tree().paused = false # LEPAS PAUSE DI SINI
	get_tree().reload_current_scene() # LOAD SCENE UTAMA
