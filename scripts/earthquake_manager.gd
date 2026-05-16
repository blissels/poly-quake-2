# res://scripts/earthquake_manager.gd
extends Node

signal earthquake_ended(scale: float, blocks_survived: int)

const SHAKE_DURATION   := 10.0
const IMPULSE_INTERVAL := 0.15
const FALL_THRESHOLD   := 1.5

var earthquake_scale   : float = 0.0
var is_shaking         : bool  = false
var shake_timer        : float = 0.0
var impulse_timer      : float = 0.0
var block_origins      : Dictionary = {}
var camera_node        : Camera3D = null
var cam_original_pos   : Vector3 = Vector3.ZERO
var cam_shake_time     : float = 0.0

func start_earthquake() -> void:
	var placed_blocks = get_tree().get_nodes_in_group("placed_blocks")
	if placed_blocks.is_empty(): return

	earthquake_scale = randf_range(4.0, 7.5)
	is_shaking       = true
	shake_timer      = SHAKE_DURATION
	impulse_timer    = 0.0
	cam_shake_time   = 0.0
	block_origins.clear()

	# Setup kamera
	camera_node = get_viewport().get_camera_3d()
	if camera_node: cam_original_pos = camera_node.position

	for block in placed_blocks:
		if is_instance_valid(block):
			block_origins[block] = block.global_position
			# Hanya player blocks yang dapat fisika
			if not block.is_in_group("template_blocks"):
				block.freeze = false

	print("🌍 GEMPA! Skala: %.1f SR" % earthquake_scale)

func _process(delta: float) -> void:
	if not is_shaking: return

	shake_timer    -= delta
	impulse_timer  -= delta
	cam_shake_time += delta

	# Guncang kamera
	if camera_node:
		var intensity : float = earthquake_scale / 15.0
		camera_node.position = cam_original_pos + Vector3(
			sin(cam_shake_time * 13.7) * intensity,
			sin(cam_shake_time * 9.3)  * intensity * 0.5,
			sin(cam_shake_time * 11.1) * intensity * 0.3
		)

	if shake_timer <= 0.0:
		_finish_earthquake()
		return

	# Guncang template blocks via Tween (bukan fisika)
	if impulse_timer <= 0.0:
		impulse_timer = IMPULSE_INTERVAL
		_shake_template_blocks()

func _shake_template_blocks() -> void:
	var template_blocks = get_tree().get_nodes_in_group("template_blocks")
	var intensity    : float = clamp((earthquake_scale - 4.0) / 3.5, 0.0, 1.0)
	var pos_strength : float = lerp(0.03, 0.18, intensity)

	# Satu arah bersama agar terasa mengikat
	var base := Vector3(
		randf_range(-pos_strength, pos_strength),
		randf_range(-pos_strength * 0.1, 0.0),
		randf_range(-pos_strength, pos_strength)
	)

	for block in template_blocks:
		if not is_instance_valid(block): continue
		if not block_origins.has(block): continue
		var origin : Vector3 = block_origins[block] as Vector3
		var noise  : Vector3 = Vector3(
			randf_range(-1.0, 1.0) * pos_strength * 0.1,
			0.0,
			randf_range(-1.0, 1.0) * pos_strength * 0.1
		)
		var target : Vector3 = origin + base + noise
		target.y = max(target.y, 0.05)
		var tw = create_tween()
		tw.tween_property(block, "global_position", target, 0.06)

func _finish_earthquake() -> void:
	is_shaking = false

	# Reset kamera smooth
	if camera_node:
		var tw = create_tween()
		tw.tween_property(camera_node, "position", cam_original_pos, 0.4)
		camera_node = null

	# Reset template blocks ke posisi awal
	for block in get_tree().get_nodes_in_group("template_blocks"):
		if is_instance_valid(block) and block_origins.has(block):
			var tw = create_tween()
			tw.tween_property(block, "global_position", block_origins[block] as Vector3, 0.5)

	# Hitung blok player yang selamat
	var player_blocks = []
	for b in get_tree().get_nodes_in_group("placed_blocks"):
		if is_instance_valid(b) and not b.is_in_group("template_blocks"):
			player_blocks.append(b)

	var survived := 0
	for block in player_blocks:
		if block_origins.has(block):
			var drop : float = (block_origins[block] as Vector3).y - block.global_position.y
			if drop < FALL_THRESHOLD: survived += 1

	var ui_node = get_tree().current_scene.find_child("ResultUI", true, false)
	if ui_node and ui_node.has_method("show_result"):
		ui_node.show_result(earthquake_scale, survived)

	emit_signal("earthquake_ended", earthquake_scale, survived)
