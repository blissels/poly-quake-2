extends VBoxContainer

@onready var build_timer: Timer = $BuildTimer
@onready var timer_label: Label = $TimerLabel

const BUILD_DURATION := 60.0
var is_building_phase := true

func _ready() -> void:
	build_timer.wait_time = BUILD_DURATION
	build_timer.one_shot = true
	build_timer.timeout.connect(_on_build_timer_timeout)
	build_timer.start()
	
	EarthquakeManager.earthquake_ended.connect(_on_earthquake_ended)

	
func _process(_delta: float) -> void:
	if is_building_phase:
		_update_timer_display()
		
func _update_timer_display() -> void:
	var sisa_waktu := ceili(build_timer.time_left) # Dibulatkan ke atas
	timer_label.text = "Timer: %d" % sisa_waktu
	
	if sisa_waktu <= 10:
		timer_label.modulate = Color.RED
	elif sisa_waktu <= 50:
		timer_label.modulate = Color.YELLOW
	else:
		timer_label.modulate = Color.WHITE
		
func _on_build_timer_timeout() -> void:
	is_building_phase = false
	timer_label.text = "Timer: 0"
	timer_label.modulate = Color.DARK_RED
	
	print("Fase Membangun selesai! Memulai Fase Gempa...")
	EarthquakeManager.start_earthquake()
	
func _on_earthquake_ended(scale: float, survived: int) -> void:
	timer_label.text     = "SR %.1f — %d blok selamat!" % [scale, survived]
	timer_label.modulate = Color.WHITE  # ✅ reset warna
	timer_label.visible  = true         # ✅ pastikan tidak ter-flash
