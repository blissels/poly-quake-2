# AI GENERATED SCRIPT
# res://scripts/earthquake_manager.gd
# res://scripts/earthquake_manager.gd
extends Node

signal earthquake_ended(scale: float, blocks_survived: int)

const SHAKE_DURATION      := 10.0
const IMPULSE_INTERVAL    := 0.12
const FALL_THRESHOLD      := 1.5

# --- Camera Shake ---
const CAM_SHAKE_INTENSITY := 0.08   # Seberapa jauh kamera bergeser
const CAM_SHAKE_SPEED     := 18.0   # Seberapa cepat kamera bergetar

var earthquake_scale : float = 0.0
var is_shaking       : bool  = false
var shake_timer      : float = 0.0
var impulse_timer    : float = 0.0
var block_origins    : Dictionary = {}

# Camera shake state
var cam_shake_amount  : float = 0.0
var cam_origin        : Vector3 = Vector3.ZERO
var camera_node       : Camera3D = null
var cam_shake_time    : float = 0.0

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

	# Setup camera shake
	var cameras = get_tree().get_nodes_in_group("main_camera")
	if cameras.size() > 0:
		camera_node  = cameras[0]
		cam_origin   = camera_node.position
		# Intensitas kamera sesuai skala gempa
		cam_shake_amount = CAM_SHAKE_INTENSITY * ((earthquake_scale - 4.0) / 3.5)
	
	print("🌍 GEMPA! Skala: %.1f SR | Total blok: %d" % [earthquake_scale, placed_blocks.size()])

# =============================================
func _process(delta: float) -> void:
	if not is_shaking:
		return

	shake_timer   -= delta
	impulse_timer -= delta
	cam_shake_time += delta

	# --- Camera Shake per frame ---
	_update_camera_shake(delta)

	if shake_timer <= 0.0:
		_finish_earthquake()
		return

	if impulse_timer <= 0.0:
		impulse_timer = IMPULSE_INTERVAL
		_shake_all_blocks()

# =============================================
func _update_camera_shake(delta: float) -> void:
	if camera_node == null:
		return

	# Gunakan noise berbasis waktu agar gerakan smooth & natural
	var t : float = cam_shake_time * CAM_SHAKE_SPEED
	var shake_offset := Vector3(
		sin(t * 1.7) * cam_shake_amount,
		sin(t * 2.3) * cam_shake_amount * 0.6,
		sin(t * 1.1) * cam_shake_amount * 0.3
	)
	camera_node.position = cam_origin + shake_offset

# =============================================
func _shake_all_blocks() -> void:
	var placed_blocks = get_tree().get_nodes_in_group("placed_blocks")
	
	var intensity    : float = (earthquake_scale - 4.0) / 3.5
	var pos_strength : float = lerp(0.03, 0.3, intensity)
	var rot_strength : float = lerp(0.01, 0.1, intensity)

	# ✅ BINDING: Satu vektor dasar untuk semua blok
	# Semua blok bergerak ke arah yang sama = terasa saling terikat
	var base_offset := Vector3(
		randf_range(-pos_strength, pos_strength),
		randf_range(-pos_strength * 0.1, 0.0),  # Sedikit ke bawah saja
		randf_range(-pos_strength, pos_strength)
	)
	var base_rot := Vector3(
		randf_range(-rot_strength, rot_strength) * 0.5,
		0.0,
		randf_range(-rot_strength, rot_strength) * 0.5
	)

	for block in placed_blocks:
		if not is_instance_valid(block):
			continue

		# ✅ Noise kecil per blok (10% dari base) agar tidak 100% kaku
		var noise_pos := Vector3(
			randf_range(-1.0, 1.0) * pos_strength * 0.1,
			randf_range(-1.0, 1.0) * pos_strength * 0.05,
			randf_range(-1.0, 1.0) * pos_strength * 0.1
		)
		var noise_rot := Vector3(
			randf_range(-1.0, 1.0) * rot_strength * 0.1,
			0.0,
			randf_range(-1.0, 1.0) * rot_strength * 0.1
		)

		var final_pos : Vector3 = block.global_position + base_offset + noise_pos
		var final_rot : Vector3 = block.rotation + base_rot + noise_rot

		var tween = create_tween()
		tween.tween_property(block, "global_position", final_pos, 0.06)
		tween.tween_property(block, "rotation", final_rot, 0.06)

# =============================================
func _finish_earthquake() -> void:
	is_shaking = false

	# Reset kamera ke posisi semula
	if camera_node != null:
		var tween = create_tween()
		tween.tween_property(camera_node, "position", cam_origin, 0.3)
		camera_node = null

	var placed_blocks = get_tree().get_nodes_in_group("placed_blocks")
	var survived := 0
	for block in placed_blocks:
		if not is_instance_valid(block):
			continue
		if block_origins.has(block):
			var origin : Vector3 = block_origins[block] as Vector3
			var drop   : float   = origin.y - block.global_position.y
			if drop < FALL_THRESHOLD:
				survived += 1

	print("✅ Gempa selesai! Selamat: %d / %d blok" % [survived, placed_blocks.size()])
	emit_signal("earthquake_ended", earthquake_scale, survived)
