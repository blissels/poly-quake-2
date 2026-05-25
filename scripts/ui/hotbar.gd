extends CanvasLayer

# Hotbar UI controller (attach to CanvasLayer root)
@export var hotbar_path: NodePath = NodePath("HotbarContainer")  # path to HBoxContainer
@export var idle_scale: Vector2 = Vector2(1.0, 1.0)
@export var selected_scale: Vector2 = Vector2(1.3, 1.3)
@export var tween_duration: float = 0.15

@onready var hotbar: HBoxContainer = get_node_or_null(hotbar_path)
# explicit onready vars for known slots (per spec)
@onready var panel_dinding: PanelContainer = hotbar.get_node_or_null("PanelDinding") if hotbar else null
@onready var panel_lantai: PanelContainer = hotbar.get_node_or_null("PanelLantai") if hotbar else null

# collect slots dynamically (keeps order as children in HBoxContainer)
var slots: Array = []
var _current_index: int = -1
var _active_tweens: Dictionary = {} # node -> SceneTreeTween

var in_build_mode: bool = false # Ubah jadi false kalau pas game mulai nggak langsung masuk build mode

func _ready() -> void:
	# gather slots from hotbar children
	if hotbar:
		for child in hotbar.get_children():
			if child is Control:
				slots.append(child)
				# Pastikan pivot point ada di tengah agar membesar dari tengah
				child.pivot_offset = child.size / 2.0
				
	# set initial scales
	setup_initial_scale()
	#select_item(0)
	reset_all_slots()

func setup_initial_scale() -> void:
	for s in slots:
		if s:
			s.scale = idle_scale # Di Godot 4 menggunakan 'scale' bukan 'rect_scale'

func select_item(item_index: int) -> void:
	if slots.size() == 0: return
	var idx: int = clamp(item_index, 0, slots.size() - 1)
	_current_index = idx
	for i in range(slots.size()):
		var s: Control = slots[i]
		if not s: continue
		if i == idx:
			_play_scale_tween(s, selected_scale)
		else:
			_play_scale_tween(s, idle_scale)

# Fungsi baru untuk mereset semua slot ke ukuran default (dipanggil saat keluar build mode)
func reset_all_slots() -> void:
	_current_index = -1 # Reset index aktif
	for s in slots:
		if s:
			_play_scale_tween(s, idle_scale)

func _play_scale_tween(target: Control, target_scale: Vector2) -> void:
	# stop existing tween for this node
	if _active_tweens.has(target):
		var existing = _active_tweens[target]
		if is_instance_valid(existing):
			existing.kill()
		_active_tweens.erase(target)
		
	# create tween on this node and animate scale
	var tw = target.create_tween()
	tw.tween_property(target, "scale", target_scale, tween_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_active_tweens[target] = tw
	
	# remove reference when finished
	tw.finished.connect(func(): if _active_tweens.has(target): _active_tweens.erase(target))

# Input handling: number keys (1,2,3...) and mouse wheel to cycle
# Input handling: Q/E keys to cycle
# Input handling: B for Build Mode, Q/E to cycle (only when building)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			# --- LOGIKA TOMBOL B (BUILD MODE) ---
			KEY_B:
				in_build_mode = !in_build_mode # Membalikkan status (On/Off)
				if in_build_mode:
					select_item(0) # Otomatis membesarkan floor (index 0)
				else:
					reset_all_slots() # Otomatis mengecilkan semua icon
					
			# --- LOGIKA TOMBOL Q & E ---
			KEY_Q:
				if in_build_mode: # Hanya jalan kalau lagi Build Mode
					_cycle_selection(-1)
			KEY_E:
				if in_build_mode: # Hanya jalan kalau lagi Build Mode
					_cycle_selection(1)
func _cycle_selection(dir: int) -> void:
	if slots.size() == 0: return
	# Jika sedang tidak ada yang dipilih (misal habis reset), mulai dari 0
	if _current_index == -1:
		select_item(0)
		return
		
	var new_index = (_current_index + dir) % slots.size()
	if new_index < 0: new_index += slots.size()
	select_item(new_index)
