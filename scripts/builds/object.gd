extends RigidBody3D

@onready var model: MeshInstance3D = $model
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var clipping_hitbox: Area3D = $clippingHitBox
@onready var floating_hitbox: Area3D = $floatingHitBox
@onready var animation: AnimationPlayer = $animation

var red_material: Material = load("res://assets/materials/red_material.tres")
var blue_material: Material = load("res://assets/materials/blue_material.tres")

var can_place = true
var is_ghost = true

func _ready():
	# Saat pertama kali muncul (sebagai ghost block), bekukan fisiknya
	freeze = true
	collision_shape.disabled = true

func _process(delta: float) -> void:
	# Hanya jalankan deteksi warna biru/merah JIKA masih berupa ghost block
	if is_ghost and clipping_hitbox:
		model.transparency = 0.6
		can_place = clipping_hitbox.get_overlapping_bodies().is_empty() and not floating_hitbox.get_overlapping_bodies().is_empty()
		
		if can_place:
			model.material_override = blue_material
		else:
			model.material_override = red_material
			
	if self.scale.x == 0.01:
		queue_free()

func place():
	SFXManager.play("place")
	# 1. OBJEKTIF: Pengecekan Akurat Menggunakan Jarak!
	var ui_node = get_tree().current_scene.find_child("ResultUI", true, false)
	var sensors = get_tree().get_nodes_in_group("sensor_lubang")
	
	for sensor in sensors:
		if is_instance_valid(sensor):
			# Jika blok ini ditaruh di dekat sensor (radius 3 meter)
			if global_position.distance_to(sensor.global_position) < 3.0:
				if ui_node and ui_node.has_method("tambah_objektif"):
					ui_node.tambah_objektif()
				sensor.queue_free() # Hilangkan sensornya
				break

	is_ghost = false
	animation.play("place")
	
	if clipping_hitbox: clipping_hitbox.queue_free()
	if floating_hitbox: floating_hitbox.queue_free()
		
	model.material_override = null
	model.transparency = 0.0
	
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
				
	add_to_group("placed_blocks")

func destroy():
	SFXManager.play("destroy")
	animation.play("destroy")
