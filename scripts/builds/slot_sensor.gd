# res://scripts/slot_sensor.gd
# Attach ke Area3D di tiap slot kosong template
extends Area3D

@export var slot_id : String = "slot_01"

signal slot_filled(slot_id: String, block_type: String)

var is_filled : bool = false
var filled_block_type : String = ""

func _ready() -> void:
	add_to_group("slot_sensor")
	monitoring = true
	# Deteksi body yang masuk (StaticBody3D placed blocks)
	connect("body_entered", Callable(self, "_on_body_entered"))
	# Tampilkan ghost mesh indikator slot kosong
	_set_ghost_visible(true)

func _on_body_entered(body: Node) -> void:
	if is_filled: return
	if body.is_in_group("placed_blocks") and not body.is_in_group("template_blocks"):
		var type: String = body.get("block_type") if "block_type" in body else "Unknown"
		_fill_slot(type)

func notify_block_placed(type: String) -> void:
	if not is_filled:
		_fill_slot(type)

func _fill_slot(type: String) -> void:
	is_filled = true
	filled_block_type = type
	_set_ghost_visible(false)
	emit_signal("slot_filled", slot_id, type)
	print("✅ Slot %s terisi!" % slot_id)
	# Efek partikel/visual bisa ditambah di sini

func _set_ghost_visible(visible_state: bool) -> void:
	# Cari child mesh (ghost indikator)
	for child in get_children():
		if child is MeshInstance3D:
			child.visible = visible_state
