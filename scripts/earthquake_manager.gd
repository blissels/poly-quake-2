extends Node

signal earthquake_ended(scale: float, blocks_survived: int)

const SHAKE_DURATION = 10.0
const FALL_THRESHOLD = 1.5

var earthquake_scale : float = 0.0
var is_shaking : bool = false
var shake_timer : float = 0.0
var block_origins : Dictionary = {}
var camera_node: Camera3D
var cam_original_pos: Vector3

func start_earthquake() -> void:
	var placed_blocks = get_tree().get_nodes_in_group("placed_blocks")
	if placed_blocks.is_empty(): return

	earthquake_scale = randf_range(4.0, 7.5)
	is_shaking = true
	shake_timer = SHAKE_DURATION
	block_origins.clear()

	# 1. GETARKAN TANAH
	var ground_node = get_tree().current_scene.find_child("ground", true, false)
	if ground_node and ground_node.has_method("trigger_earthquake"):
		ground_node.trigger_earthquake(earthquake_scale, SHAKE_DURATION)

	# 2. SIAPKAN KAMERA
	camera_node = get_viewport().get_camera_3d()
	if camera_node: cam_original_pos = camera_node.position

	# 3. LEPAS SEGEL BEKU (Fisika murni yang ambil alih)
	for block in placed_blocks:
		if is_instance_valid(block):
			block_origins[block] = block.global_position
			block.freeze = false

func _process(delta: float) -> void:
	if not is_shaking: return
	shake_timer -= delta
	
	if camera_node:
		var intensity = (earthquake_scale / 15.0) 
		camera_node.position = cam_original_pos + Vector3(
			randf_range(-intensity, intensity), randf_range(-intensity, intensity), randf_range(-intensity, intensity)
		)

	if shake_timer <= 0.0:
		_finish_earthquake()

func _finish_earthquake() -> void:
	is_shaking = false
	if camera_node: camera_node.position = cam_original_pos
		
	var placed_blocks = get_tree().get_nodes_in_group("placed_blocks")
	var survived := 0
	
	for block in placed_blocks:
		if is_instance_valid(block) and block_origins.has(block):
			var drop = block_origins[block].y - block.global_position.y
			if drop < FALL_THRESHOLD: survived += 1

	var ui_node = get_tree().current_scene.find_child("ResultUI", true, false)
	if ui_node and ui_node.has_method("show_result"):
		ui_node.show_result(earthquake_scale, survived)
