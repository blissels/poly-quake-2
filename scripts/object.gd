extends StaticBody3D

@onready var model: MeshInstance3D = $model
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var clipping_hitbox: Area3D = $clippingHitBox
@onready var floating_hitbox: Area3D = $floatingHitBox
@onready var animation: AnimationPlayer = $animation

var red_material: Material = load("res://assets/materials/red_material.tres")
var blue_material: Material = load("res://assets/materials/blue_material.tres")

var can_place = true

func _process(delta: float) -> void:
	if clipping_hitbox:
		model.transparency = 0.6
		can_place = clipping_hitbox.get_overlapping_bodies().is_empty() and not floating_hitbox.get_overlapping_bodies().is_empty()
		
		var clipping_nabrak = clipping_hitbox.get_overlapping_bodies()
		var floating_nyentuh = floating_hitbox.get_overlapping_bodies()
		
		# Print ke panel Output di bawah layar:
		print("Isi Clipping: ", clipping_nabrak.size(), " benda. Isi Floating: ", floating_nyentuh.size(), " benda.")
		if can_place:
			model.material_override = blue_material
		else:
			model.material_override = red_material
	if self.scale.x == 0.01:
		queue_free()

func place():
	animation.play("place")
	clipping_hitbox.queue_free()
	floating_hitbox.queue_free()
	model.material_override = null
	model.transparency = 0.0
	collision_shape.disabled = false
	
func destroy():
	animation.play("destroy")
