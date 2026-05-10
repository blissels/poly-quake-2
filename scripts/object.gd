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
	# 1. CEK SENSOR OBJEKTIF (LUBANG)
	var ui_node = get_tree().current_scene.find_child("ResultUI", true, false)
	if clipping_hitbox:
		for area in clipping_hitbox.get_overlapping_areas():
			if area.is_in_group("sensor_lubang"):
				if ui_node: 
					ui_node.tambah_objektif() # Lapor ke UI bahwa lubang tertutup
				area.queue_free() # Hapus sensor agar tidak dihitung ganda
				break
				
	# 2. UBAH DARI GHOST MENJADI BLOK FISIK NYATA
	is_ghost = false
	animation.play("place")
	
	if clipping_hitbox:
		clipping_hitbox.queue_free()
	if floating_hitbox:
		floating_hitbox.queue_free()
		
	model.material_override = null
	model.transparency = 0.0
	
	collision_shape.disabled = false
	freeze = false # Blok sekarang bisa terpengaruh gravitasi dan gempa
	
	# 3. SISTEM SEMEN (MENGHUBUNGKAN BLOK BARU DENGAN BLOK LAIN)
	var placed_blocks = get_tree().get_nodes_in_group("placed_blocks")
	for block in placed_blocks:
		if is_instance_valid(block) and block != self:
			var dist = global_position.distance_to(block.global_position)
			
			if dist < 2.5: # Jarak dipendekkan jadi 2.5 agar tidak narik pintu
				var joint = PinJoint3D.new()
				get_parent().add_child(joint) # PENTING: Dipasang di parent!
				joint.global_position = (global_position + block.global_position) / 2.0
				joint.node_a = joint.get_path_to(self)
				joint.node_b = joint.get_path_to(block)
				
	# 4. DAFTARKAN KE GRUP GEMPA
	add_to_group("placed_blocks")

func destroy():
	animation.play("destroy")
