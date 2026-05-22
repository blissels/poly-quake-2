# res://scripts/slot_sensor.gd
# Attach ke Area3D di tiap slot kosong template
extends Area3D

@export var slot_id : String = "slot_01"

var is_filled : bool = false

func _ready() -> void:
	add_to_group("slot_sensor")
	monitoring = true
	# Deteksi body yang masuk (StaticBody3D placed blocks)
	body_entered.connect(_on_body_entered)
	# Tampilkan ghost mesh indikator slot kosong
	_set_ghost_visible(true)

func _on_body_entered(body: Node) -> void:
	if is_filled: return
	# Hanya trigger pada blok yang diletakkan player
	# bukan template blocks dan bukan ground/player
	if body.is_in_group("placed_blocks") and not body.is_in_group("template_blocks"):
		_fill_slot()

func _fill_slot() -> void:
	is_filled = true
	_set_ghost_visible(false)
	QuestManager.trigger_slot_filled()
	print("✅ Slot %s terisi!" % slot_id)
	# Efek partikel/visual bisa ditambah di sini

func _set_ghost_visible(visible_state: bool) -> void:
	# Cari child mesh (ghost indikator)
	for child in get_children():
		if child is MeshInstance3D:
			child.visible = visible_state
