extends VBoxContainer

@onready var build_timer: Timer = $BuildTimer
@onready var timer_label: Label = $TimerLabel
@onready var skip_button: Button = $"../Button"

const BUILD_DURATION := 60.0
var is_building_phase := true

func _ready() -> void:
	build_timer.wait_time = BUILD_DURATION
	build_timer.one_shot  = true
	build_timer.timeout.connect(_on_build_timer_timeout)
	build_timer.start()
	
	if skip_button:
		skip_button.pressed.connect(_on_skip_button_pressed)
		skip_button.visible = true
	
	EarthquakeManager.earthquake_ended.connect(_on_earthquake_ended)
	QuestManager.all_quests_done.connect(_on_all_quests_done)
	GameState.level_changed.connect(_on_level_changed)

func _on_level_changed(_level_name: String) -> void:
	# Reset state untuk level baru
	is_building_phase     = true
	timer_label.modulate  = Color.WHITE
	build_timer.wait_time = BUILD_DURATION
	build_timer.start()
	if skip_button:
		skip_button.visible = true
	print("⏰ Timer direset untuk level baru: ", _level_name)

func _on_skip_button_pressed() -> void:
	if is_building_phase:
		print("Skip button pressed. Skipping building phase...")
		build_timer.stop()
		_on_build_timer_timeout()

func _on_all_quests_done() -> void:
	if GameState.current_level == "tutorial":
		# Semua objektif terpenuhi — jangan langsung pindah.
		# Biarkan timer berjalan sampai habis supaya gempa tetap terjadi,
		# lalu ResultUI yang akan memutuskan lanjut atau restart.
		timer_label.text     = "✅ Objektif Selesai — Tunggu Gempa"
		timer_label.modulate = Color.GREEN
		print("Semua objektif selesai. Menunggu akhir timer untuk memicu gempa...")
		return
	# Untuk level_01: biarkan timer jalan hingga gempa

func _transition_to_level_01() -> void:
	GameState.tutorial_done = true
	GameState.go_to_level("level_01")
	# Reset timer untuk level baru
	is_building_phase     = true
	timer_label.modulate  = Color.WHITE
	build_timer.wait_time = BUILD_DURATION
	build_timer.start()
	
func _process(_delta: float) -> void:
	if is_building_phase:
		_update_timer_display()
		
func _update_timer_display() -> void:
	var sisa_waktu := ceili(build_timer.time_left) # Dibulatkan ke atas
	timer_label.text = "%d" % sisa_waktu
	
	if sisa_waktu <= 10:
		timer_label.modulate = Color.RED
	elif sisa_waktu <= 50:
		timer_label.modulate = Color.YELLOW
	else:
		timer_label.modulate = Color.WHITE
		
func _on_build_timer_timeout() -> void:
	is_building_phase = false
	if skip_button:
		skip_button.visible = false
	# Tampilkan alert gempa di tengah atas layar sebelum dimulai
	timer_label.text = "TERJADI GEMPA"
	timer_label.modulate = Color.RED
	print("Fase Membangun selesai! Menampilkan alert gempa dan memulai fase gempa...")
	await get_tree().create_timer(1.1).timeout
	EarthquakeManager.start_earthquake()
	
func _on_earthquake_ended(scale: float, survived: int) -> void:
	timer_label.text     = "SR %.1f" % [scale]
	timer_label.modulate = Color.WHITE  # ✅ reset warna
	timer_label.visible  = true         # ✅ pastikan tidak ter-flash
