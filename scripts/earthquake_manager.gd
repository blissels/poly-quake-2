# AI GENERATED SCRIPT
extends Node

signal earthquake_ended(scale: float, blocks_survived: int)

const SHAKE_DURATION      := 10.0
const FALL_THRESHOLD      := 1.5

var earthquake_scale : float = 0.0
var is_shaking       : bool  = false
var shake_timer      : float = 0.0
var block_origins    : Dictionary = {}

# =============================================
func start_earthquake() -> void:
	var placed_blocks = get_tree().get_nodes_in_group("placed_blocks")

	if placed_blocks.is_empty():
		print("⚠️ Tidak ada blok! Langsung selesai.")
		emit_signal("earthquake_ended", 0.0, 0)
		return

	earthquake_scale = randf_range(4.0, 7.5)
	is_shaking       = true
	shake_timer      = SHAKE_DURATION
	block_origins.clear()

	for block in placed_blocks:
		block_origins[block] = block.global_position

	# --- PANGGIL TANAH UNTUK BERGUNCANG FISIK ---
	# Mencari node "ground" di dalam scene yang sedang aktif
	var ground_node = get_tree().current_scene.find_child("ground", true, false)
	
	if ground_node and ground_node.has_method("trigger_earthquake"):
		# Picu guncangan fisik pada node ground
		ground_node.trigger_earthquake(earthquake_scale, SHAKE_DURATION)
		print("🌍 GEMPA FISIK DIMULAI! Skala: %.1f SR" % earthquake_scale)
	else:
		print("❌ ERROR: Node 'ground' tidak ditemukan atau script ground.gd belum terpasang!")

# =============================================
func _process(delta: float) -> void:
	if not is_shaking:
		return

	shake_timer -= delta

	# Gempa selesai saat timer habis
	if shake_timer <= 0.0:
		_finish_earthquake()

# =============================================
func _finish_earthquake() -> void:
	is_shaking = false

	var placed_blocks = get_tree().get_nodes_in_group("placed_blocks")
	var survived := 0
	
	for block in placed_blocks:
		if not is_instance_valid(block):
			continue
			
		if block_origins.has(block):
			var origin : Vector3 = block_origins[block]
			var drop   : float   = origin.y - block.global_position.y
			
			# Jika blok jatuh melebihi batas, dianggap hancur
			if drop < FALL_THRESHOLD:
				survived += 1

	print("✅ Gempa fisik selesai!")
	emit_signal("earthquake_ended", earthquake_scale, survived)
	
	# --- [TAMBAHKAN KODE INI] PANGGIL UI SECARA PAKSA ---
	var ui_node = get_tree().current_scene.find_child("ResultUI", true, false)
	if ui_node and ui_node.has_method("show_result"):
		ui_node.show_result(earthquake_scale, survived)
