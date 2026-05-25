class_name ObjectBlock
extends RigidBody3D

@onready var model: MeshInstance3D = get_node_or_null("model")
@onready var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")
@onready var clipping_hitbox: Area3D = get_node_or_null("clippingHitBox")
@onready var floating_hitbox: Area3D = get_node_or_null("floatingHitBox")
@onready var animation: AnimationPlayer = get_node_or_null("animation")

var red_material: Material = load("res://assets/materials/red_material.tres")
var blue_material: Material = load("res://assets/materials/blue_material.tres")
var green_material: Material = load("res://assets/materials/green_material.tres")

var can_place: bool = false
var is_ghost: bool = true

var ghost_material_valid: StandardMaterial3D
var ghost_material_invalid: StandardMaterial3D

func _ready() -> void:
	# Setup ghost materials
	ghost_material_valid = StandardMaterial3D.new()
	ghost_material_valid.albedo_color = Color(0.0, 0.8, 0.6, 0.4) # Cyan/Green-Blue
	# ghost_material_valid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	ghost_material_invalid = StandardMaterial3D.new()
	ghost_material_invalid.albedo_color = Color(1.0, 0.1, 0.1, 0.4) # Red
	# ghost_material_invalid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Saat pertama kali muncul (sebagai ghost block), bekukan fisiknya
	freeze = true
	if collision_shape:
		collision_shape.disabled = true

func _process(_delta: float) -> void:
	if is_ghost:
		if model:
			model.transparency = 0.5
		
		update_validation()
		
		if model:
			if can_place:
				model.material_override = ghost_material_valid
			else:
				model.material_override = ghost_material_invalid
		
	if self.scale.x == 0.01:
		queue_free()

func update_validation() -> void:
	# Validation logic: check distance to any sensor in the "sensor_lubang" group
	var sensors: Array = get_tree().get_nodes_in_group("sensor_lubang")
	var found_valid_sensor: bool = false
	for sensor in sensors:
		if is_instance_valid(sensor) and sensor is Node3D:
			if global_position.distance_to(sensor.global_position) < 3.0:
				found_valid_sensor = true
				break
	
	can_place = found_valid_sensor

func place() -> void:
	SFXManager.play("place")
	is_ghost = false
	
	# Update validation one last time at current position before finalizing
	update_validation()
	
	if model:
		model.material_override = null
		model.transparency = 0.0
	
	if collision_shape:
		collision_shape.disabled = false
	
	# Structural Penalty Check
	if not can_place:
		print("[Object] Penalty: Improper structural placement!")
		GameState.structural_failure = true
		freeze = false # Falls to the ground immediately
		# Remove from building group to ensure it doesn't count for welding or objectives
		remove_from_group("placed_blocks")
		return # Stop execution here so it's not welded
	
	# Valid placement logic
	freeze = true
	add_to_group("placed_blocks")
	
	# Notify sensors for quest/objective updates
	var sensors: Array = get_tree().get_nodes_in_group("sensor_lubang")
	var notified: bool = false
	for sensor in sensors:
		if is_instance_valid(sensor) and sensor is Node3D:
			var dist: float = global_position.distance_to(sensor.global_position)
			if dist < 3.0:
				if sensor.has_method("notify_block_placed"):
					sensor.notify_block_placed()
					notified = true
					break
	
	# Fallback sensor notification if not notified yet but close enough
	if not notified:
		var nearest: Node3D = null
		var min_dist: float = 1e9
		for sensor in sensors:
			if is_instance_valid(sensor) and sensor is Node3D:
				var d: float = global_position.distance_to(sensor.global_position)
				if d < min_dist:
					min_dist = d
					nearest = sensor
		if nearest and min_dist <= 5.0:
			if nearest.has_method("notify_block_placed"):
				nearest.notify_block_placed()
	
	if animation:
		animation.play("place")
	
	if clipping_hitbox: clipping_hitbox.queue_free()
	if floating_hitbox: floating_hitbox.queue_free()
	
	# Weld to other placed blocks
	var placed_blocks: Array = get_tree().get_nodes_in_group("placed_blocks")
	for block in placed_blocks:
		if is_instance_valid(block) and block != self:
			if global_position.distance_to(block.global_position) < 4.1:
				var joint: Generic6DOFJoint3D = Generic6DOFJoint3D.new()
				joint.add_to_group("placed_joints")
				get_parent().add_child(joint)
				joint.global_position = (global_position + block.global_position) / 2.0
				joint.node_a = joint.get_path_to(self)
				joint.node_b = joint.get_path_to(block)
				

func destroy():
	SFXManager.play("destroy")
	if animation:
		animation.play("destroy")
