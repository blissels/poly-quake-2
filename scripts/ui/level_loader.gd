# res://scripts/level_loader.gd
# Attach ke Node3D baru bernama "LevelLoader" di dalam map (world.tscn)
extends Node3D

const LEVELS := {
	"tutorial" : "res://scenes/level/level_tutorial.tscn",
	"level_01" : "res://scenes/level/level_01.tscn",
}

var current_instance : Node = null

func _ready() -> void:
	GameState.level_changed.connect(_on_level_changed)
	# Load level pertama langsung
	load_level(GameState.current_level)

func load_level(level_name: String) -> void:
	# Bersihkan objek yang ditempatkan player di level sebelumnya
	_clear_placed_objects()

	# Hapus level lama
	if current_instance and is_instance_valid(current_instance):
		current_instance.queue_free()
		await get_tree().process_frame

	var path : String = LEVELS.get(level_name, "")
	if path.is_empty():
		push_error("Level tidak ditemukan: " + level_name)
		return

	var packed := load(path) as PackedScene
	if not packed:
		push_error("Gagal memuat scene level: " + path)
		return
	current_instance = packed.instantiate()
	add_child(current_instance)

	# Reset slot dan mulai quest baru
	await get_tree().process_frame
	_setup_all_slots()
	QuestManager.start_quest(level_name)
	print("🗺️ Level dimuat: %s" % level_name)

func _on_level_changed(level_name: String) -> void:
	load_level(level_name)

func _clear_placed_objects() -> void:
	# 1. Hapus berdasarkan Group (Metode Utama)
	var blocks := get_tree().get_nodes_in_group("placed_blocks")
	for block in blocks:
		if is_instance_valid(block):
			block.queue_free()
	
	var joints := get_tree().get_nodes_in_group("placed_joints")
	for joint in joints:
		if is_instance_valid(joint):
			joint.queue_free()
	
	# 2. Pembersihan Agresif (Fallback)
	# Cari semua RigidBody3D dan Joint yang merupakan sibling dari LevelLoader (anak dari 'map')
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child is RigidBody3D or child is Joint3D:
				# Jangan hapus jika itu adalah player atau level_loader sendiri (tapi tipenya beda, jadi aman)
				child.queue_free()
	
	print("🧹 LevelLoader: Cleanup complete (Groups + Siblings)")

func _setup_all_slots() -> void:
	# Pastikan semua sensor under the level's "sensor_lubang" node terdaftar di group
	if current_instance == null:
		print("🔌 current_instance null, skipping slot setup")
		return
	var parent = current_instance.get_node_or_null("sensor_lubang")
	if parent:
		var count := 0
		for child in parent.get_children():
			if child is Area3D:
				if not child.is_in_group("sensor_lubang"):
					child.add_to_group("sensor_lubang")
				if not child.is_in_group("slot_sensor"):
					child.add_to_group("slot_sensor")
				# Connect slot signal to QuestManager if not already connected
				var slot_cb := Callable(QuestManager, "trigger_slot_filled")
				if not child.is_connected("slot_filled", slot_cb):
					child.connect("slot_filled", slot_cb)
				count += 1
		print("🔌 Slot ditemukan (from parent): %d" % count)
	else:
		var slots := get_tree().get_nodes_in_group("sensor_lubang")
		print("🔌 Slot ditemukan (group): %d" % slots.size())
