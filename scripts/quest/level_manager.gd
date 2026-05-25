# res://scripts/level_manager.gd
extends Node3D

func _ready():
	var all_blocks = []
	_get_all_rigidbodies(self, all_blocks)
	
	for block in all_blocks:
		# Matikan mode ghost
		if block.get("is_ghost") != null:
			block.set("is_ghost", false)
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


func trigger_collapse() -> void:
	# Cari semua RigidBody3D yang termasuk group "placed_blocks" (bagian bangunan)
	var bodies := get_tree().get_nodes_in_group("placed_blocks")
	# Jika tidak ada yang terdaftar, kumpulkan semua RigidBody di bawah level ini
	if bodies.is_empty():
		var all_blocks = []
		_get_all_rigidbodies(self, all_blocks)
		bodies = all_blocks

	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for b in bodies:
		if not (b is RigidBody3D):
			continue
		# Unfreeze / aktifkan fisika sehingga benda bisa rubuh
		# Properti 'freeze' digunakan di template — matikan agar physics aktif
		if b.has_method("set_freeze"): # compatibility check
			b.freeze = false
		# Pastikan physics aktif: unfreeze dan bangunkan dari sleeping
		b.freeze = false
		b.sleeping = false
		# Beri sedikit impuls acak supaya efek gempa/runtuh lebih nyata
		var impulse = Vector3(
			rng.randf_range(-1.0, 1.0),
			rng.randf_range(0.5, 2.0),
			rng.randf_range(-1.0, 1.0)
		) * 5.0
		b.apply_impulse(Vector3.ZERO, impulse)
