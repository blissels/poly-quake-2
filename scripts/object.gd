extends StaticBody3D

@onready var model: MeshInstance3D = $model
@onready var collision_shape: CollisionObject3D = $CollisionShape3D
@onready var clipping_hitbox: Area3D = $clippingHitBox
@onready var floating_hitbox: Area3D = $floatingHitBox

var red_material: Material = load("res://assets/materials/red_material.tres")
var blue_material: Material = load("res://assets/materials/blue_material.tres")

var can_place = true

func _process(delta: float) -> void:
	if clipping_hitbox:
		model.transparency = 0.6
		can_place = clipping_hitbox.get_overlapping_bodies().is_empty() and not floating_hitbox.get_overlapping_bodies().is_empty()
		if can_place:
			model.material_override = blue_material
		else:
			model.material_override = red_material

func place():
	clipping_hitbox.queue_free()
	floating_hitbox.queue_free()
	model.material_override = null
	model.transparency = 0.0
	collision_shape.disabled = false
	
func destroy():
	queue_free()
