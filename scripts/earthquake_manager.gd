# AI GENERATED SCRIPT
# res://scripts/earthquake_manager.gd
extends Node

signal earthquake_ended(scale: float, blocks_survived: int)

const SHAKE_DURATION   := 10.0
const IMPULSE_INTERVAL := 0.12
const FALL_THRESHOLD   := 1.5

var earthquake_scale : float = 0.0
var is_shaking       : bool  = false
var shake_timer      : float = 0.0
var impulse_timer    : float = 0.0
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
	impulse_timer    = 0.0
	block_origins.clear()

	for block in placed_blocks:
		block_origins[block] = block.global_position

	print("🌍 GEMPA! Skala: %.1f SR | Total blok: %d" % [earthquake_scale, placed_blocks.size()])

# =============================================
func _process(delta: float) -> void:
	if not is_shaking:
		return

	shake_timer   -= delta
	impulse_timer -= delta

	if shake_timer <= 0.0:
		_finish_earthquake()
		return

	if impulse_timer <= 0.0:
		impulse_timer = IMPULSE_INTERVAL
		_shake_all_blocks()

# =============================================
func _shake_all_blocks() -> void:
	var placed_blocks = get_tree().get_nodes_in_group("placed_blocks")
	
	# Intensitas 0.0 (SR 4.0) sampai 1.0 (SR 7.5)
	var intensity    : float = (earthquake_scale - 4.0) / 3.5
	var pos_strength : float = lerp(0.03, 0.3, intensity)
	var rot_strength : float = lerp(0.01, 0.1, intensity)

	for block in placed_blocks:
		if not is_instance_valid(block):
			continue

		var offset := Vector3(
			randf_range(-pos_strength, pos_strength),
			randf_range(-pos_strength * 0.2, pos_strength * 0.05),
			randf_range(-pos_strength, pos_strength)
		)
		var rot_delta := Vector3(
			randf_range(-rot_strength, rot_strength),
			randf_range(-rot_strength * 0.3, rot_strength * 0.3),
			randf_range(-rot_strength, rot_strength)
		)

		var tween = create_tween()
		tween.tween_property(block, "global_position", block.global_position + offset, 0.06)
		tween.tween_property(block, "rotation", block.rotation + rot_delta, 0.06)

# =============================================
func _finish_earthquake() -> void:
	is_shaking = false
	var placed_blocks = get_tree().get_nodes_in_group("placed_blocks")

	var survived := 0
	for block in placed_blocks:
		if not is_instance_valid(block):
			continue
		if block_origins.has(block):
			var origin := block_origins[block] as Vector3          # ✅ fix
			var drop: float = origin.y - block.global_position.y  # ✅ fix
			if drop < FALL_THRESHOLD:
				survived += 1

	print("✅ Gempa selesai! Selamat: %d / %d blok" % [survived, placed_blocks.size()])
	emit_signal("earthquake_ended", earthquake_scale, survived)
