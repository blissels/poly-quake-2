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

func _setup_all_slots() -> void:
	# Hubungkan semua slot sensor yang ada di level
	var slots := get_tree().get_nodes_in_group("slot_sensor")
	print("🔌 Slot ditemukan: %d" % slots.size())
