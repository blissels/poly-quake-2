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
	
	add_to_group("placed_blocks")

func destroy():
	animation.play("destroy")
