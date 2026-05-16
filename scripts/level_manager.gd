# res://scripts/level_manager.gd
extends Node3D

func _ready():
	var all_blocks = []
	_get_all_rigidbodies(self, all_blocks)
	
	for block in all_blocks:
		# Matikan mode ghost
		block.is_ghost = false
		if block.has_node("model"):
			block.get_node("model").material_override = null
			block.get_node("model").transparency = 0.0
		
		# KUNCI MATI — template tidak pernah pakai fisika
		block.freeze = true
		block.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		
		if block.has_node("CollisionShape3D"):
			block.get_node("CollisionShape3D").disabled = false
		if block.has_node("clippingHitBox"): block.get_node("clippingHitBox").queue_free()
		if block.has_node("floatingHitBox"): block.get_node("floatingHitBox").queue_free()
		
		# Dua group berbeda: template = diguncang Tween, placed = fisika player
		block.add_to_group("template_blocks")
		block.add_to_group("placed_blocks")

func _get_all_rigidbodies(node: Node, array: Array):
	if node is RigidBody3D:
		array.append(node)
	for child in node.get_children():
		_get_all_rigidbodies(child, array)
