extends Node3D

func _ready():
	var all_blocks = []
	_get_all_rigidbodies(self, all_blocks)
	
	# 1. BONGKAR MODE GHOST: Jadikan bangunan fisik nyata (bukan merah/biru lagi)
	for block in all_blocks:
		block.is_ghost = false
		if block.has_node("model"):
			block.get_node("model").material_override = null
			block.get_node("model").transparency = 0.0
			
		block.freeze = false
		if block.has_node("CollisionShape3D"):
			block.get_node("CollisionShape3D").disabled = false
			
		if block.has_node("clippingHitBox"):
			block.get_node("clippingHitBox").queue_free()
		if block.has_node("floatingHitBox"):
			block.get_node("floatingHitBox").queue_free()
			
		block.add_to_group("placed_blocks")
		
	# 2. SEMEN TEMPLATE RUMAH DENGAN BENAR
	for i in range(all_blocks.size()):
		var block_a = all_blocks[i]
		for j in range(i + 1, all_blocks.size()):
			var block_b = all_blocks[j]
			var dist = block_a.global_position.distance_to(block_b.global_position)
			
			if dist < 2.5: 
				var joint = PinJoint3D.new()
				self.call_deferred("add_child", joint) # Pasang engsel di luar blok!
				joint.global_position = (block_a.global_position + block_b.global_position) / 2.0
				
				# set_deferred menghindari error fisika di detik pertama game
				joint.set_deferred("node_a", joint.get_path_to(block_a))
				joint.set_deferred("node_b", joint.get_path_to(block_b))

func _get_all_rigidbodies(node: Node, array: Array):
	if node is RigidBody3D:
		array.append(node)
	for child in node.get_children():
		_get_all_rigidbodies(child, array)
