extends RigidBody3D

@onready var model: MeshInstance3D = get_node_or_null("model")
@onready var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")
@onready var clipping_hitbox: Area3D = get_node_or_null("clippingHitBox")
@onready var floating_hitbox: Area3D = get_node_or_null("floatingHitBox")
@onready var animation: AnimationPlayer = get_node_or_null("animation")

var red_material: Material = load("res://assets/materials/red_material.tres")
var blue_material: Material = load("res://assets/materials/blue_material.tres")

var can_place = true
var is_ghost = true

func _ready():
	# Saat pertama kali muncul (sebagai ghost block), bekukan fisiknya
	freeze = true
	if collision_shape:
		collision_shape.disabled = true

func _process(delta: float) -> void:
	# Hanya jalankan deteksi warna biru/merah JIKA masih berupa ghost block
	if is_ghost:
		if model:
			model.transparency = 0.6
		var clip_ok := true
		if clipping_hitbox:
			clip_ok = clipping_hitbox.get_overlapping_bodies().is_empty()
		var float_ok := true
		if floating_hitbox:
			float_ok = not floating_hitbox.get_overlapping_bodies().is_empty()
		can_place = clip_ok and float_ok
		if model:
			if can_place:
				model.material_override = blue_material
			else:
				model.material_override = red_material
		
	if self.scale.x == 0.01:
		queue_free()

func place():
	SFXManager.play("place")
	# 1. OBJEKTIF: Pengecekan Akurat Menggunakan Jarak!
	# Tambahkan ke group placed_blocks lebih awal supaya sensors & Area3D mendeteksi tubuh ini
	add_to_group("placed_blocks")
	# Aktifkan collision shape segera agar Area3D dapat mendeteksi jika perlu
	if collision_shape:
		collision_shape.disabled = false
	freeze = true
	# Tunggu satu frame agar physics/Area3D sinkron
	await get_tree().process_frame
	var ui_node = get_tree().current_scene.find_child("result_ui", true, false)
	var sensors = get_tree().get_nodes_in_group("sensor_lubang")
	print("[Object] sensors found: %d" % sensors.size())
	var notified := false
	for sensor in sensors:
		if is_instance_valid(sensor):
			# Jika blok ini ditaruh di dekat sensor (radius 3 meter)
			var dist = global_position.distance_to(sensor.global_position)
			print("[Object] checking sensor %s at dist=%.3f" % [str(sensor), dist])
			if dist < 3.0:
				# Beri tahu sensor agar menangani trigger quest dan visual
				if sensor.has_method("notify_block_placed"):
					print("[Object] calling notify_block_placed on %s" % [str(sensor)])
					sensor.notify_block_placed()
					notified = true
				else:
					print("[Object] queue_free sensor %s (no method)" % [str(sensor)])
					sensor.queue_free()
					notified = true
				break
	# Fallback: jika tidak ada sensor dalam radius, panggil sensor terdekat jika cukup dekat (5m)
	if not notified and sensors.size() > 0:
		var nearest: Node = null
		var min_dist := 1e9
		for sensor in sensors:
			if is_instance_valid(sensor):
				var d = global_position.distance_to(sensor.global_position)
				if d < min_dist:
					min_dist = d
					nearest = sensor
		print("[Object] fallback nearest sensor dist=%.3f" % min_dist)
		if nearest and min_dist <= 5.0:
			if nearest.has_method("notify_block_placed"):
				print("[Object] fallback calling notify_block_placed on nearest sensor")
				nearest.notify_block_placed()
			else:
				print("[Object] fallback queue_free nearest sensor (no method)")
				nearest.queue_free()
			notified = true

	is_ghost = false
	if animation:
		animation.play("place")
	
	if clipping_hitbox: clipping_hitbox.queue_free()
	if floating_hitbox: floating_hitbox.queue_free()
		
	if model:
		model.material_override = null
		model.transparency = 0.0
	
	if collision_shape:
		collision_shape.disabled = false
	freeze = true # Tahan gravitasi saat build mode
	
	# 3. SEMEN BESI (JARAK DIPERBESAR + ENGSEL KAKU)
	var placed_blocks = get_tree().get_nodes_in_group("placed_blocks")
	for block in placed_blocks:
		if is_instance_valid(block) and block != self:
			if global_position.distance_to(block.global_position) < 4.1: # Jarak diperlebar
				var joint = Generic6DOFJoint3D.new() # Pakai engsel kaku!
				get_parent().add_child(joint)
				joint.global_position = (global_position + block.global_position) / 2.0
				joint.node_a = joint.get_path_to(self)
				joint.node_b = joint.get_path_to(block)
				

func destroy():
	SFXManager.play("destroy")
	if animation:
		animation.play("destroy")
