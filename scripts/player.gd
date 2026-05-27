extends CharacterBody3D

@onready var camera: Camera3D = $head/Camera3D
@onready var head: Node3D = $head
@onready var collsion_shape: CollisionShape3D = $CollisionShape3D
@onready var hand_marker: Marker3D = $head/hand_marker
@onready var raycast: RayCast3D = $head/raycast

# Camera shake (Trauma + FastNoiseLite)
@export var trauma_reduction_rate: float = 0.8
@export var frequency: float = 1.5
@export var max_x: float = 4.0
@export var max_y: float = 6.0
@export var max_z: float = 2.5
@export var noise_seed: int = 1337

var trauma: float = 0.0
var time_acc: float = 0.0
var noise: FastNoiseLite = null
var initial_camera_rotation_degrees: Vector3 = Vector3.ZERO

const MOUSE_SENSITIVITY = 0.4
const GRAVITY = 10
const JUMMP_SPEED = 4.0
const SPEED = 4.0
const ACCEL = 9.0

var currentvel = Vector3.ZERO
var velocity_y = 0

const BOB_FREQ = 2
const BOB_AMP = 0.08
var t_bob = 0.0

var grid_size = 0.25
var ghost_block: ObjectBlock = null
var objects = []
var current_object_index = 0

var new_rot = 0.0
var rotation_complete = true

# AI Generated {for toggle build_mode on/off}
var in_build_mode: bool = false
# AI Generated {for toggle destroy mode}
var in_destroy_mode: bool = false

func _ready():
	objects.append(preload("res://scenes/build/floor/floor.tscn"))
	objects.append(preload("res://scenes/build/wall/wall.tscn"))
	objects.append(preload("res://scenes/build/column/column-thin.tscn"))
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Initialize camera shake noise and base rotation
	initial_camera_rotation_degrees = camera.rotation_degrees
	noise = FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = 1.0
	
	# Connect to level change signal to reset player state
	if GameState.has_signal("level_changed"):
		GameState.level_changed.connect(_on_level_changed)

func _on_level_changed(_level_name: String) -> void:
	# Reset build mode and destroy mode
	in_build_mode = false
	in_destroy_mode = false
	
	# Clean up ghost block
	if ghost_block:
		ghost_block.queue_free()
		ghost_block = null
	
	# Reset internal state
	current_object_index = 0
	rotation_complete = true
	
	# Optional: Reset velocity and trauma
	velocity = Vector3.ZERO
	currentvel = Vector3.ZERO
	velocity_y = 0
	trauma = 0.0
	
	print("👤 Player: Reset state for new level")
@warning_ignore("unused_parameter")
func building(delta):
	var snap_pos: Vector3 = snap_to_grid(hand_marker.global_position, grid_size)
	ghost_block.global_position = lerp(ghost_block.global_position, snap_pos, 0.1)
	
	if Input.is_action_just_pressed("rotate") and rotation_complete:
		rotation_complete = false
		new_rot = ghost_block.rotation.y
		new_rot += deg_to_rad(90.0)
		
	if not rotation_complete:
		ghost_block.rotation.y = lerp(ghost_block.rotation.y, new_rot, 0.1)
		if abs(ghost_block.rotation.y - new_rot) < 0.01:
			ghost_block.rotation.y = new_rot # Paskan posisinya persis di target
			rotation_complete = true
		
	if Input.is_action_just_pressed("left_click"):
		var block_instance = objects[current_object_index].instantiate()
		get_parent().add_child(block_instance)
		# Place at snapped position/rotation before calling place() so sensors and distance checks work
		block_instance.global_transform.origin = snap_to_grid(ghost_block.global_transform.origin, grid_size)
		block_instance.global_rotation = ghost_block.global_rotation
		block_instance.place()
	
@warning_ignore("shadowed_variable_base_class")
func snap_to_grid(position: Vector3, grid_snap: float) -> Vector3:
	var x = round(position.x / grid_snap) * grid_snap
	var y = round(position.y / grid_snap) * grid_snap
	var z = round(position.z / grid_snap) * grid_snap
	return Vector3(x, y, z)
	
func spawn_ghost_block():
	ghost_block = objects[current_object_index].instantiate() as ObjectBlock
	get_parent().add_child(ghost_block)
	ghost_block.global_position = self.global_position
	ghost_block.global_position.y -= 1.0
	
func _physics_process(delta):
	if Input.is_action_just_pressed("build_mode"):
		in_build_mode = !in_build_mode 
		
		if in_build_mode == false:
			if ghost_block != null:
				ghost_block.queue_free()
				ghost_block = null
		else:
			spawn_ghost_block()
			QuestManager.trigger_build_mode_opened()

			
	# --- TOGGLE DESTROY MODE ---
	elif Input.is_action_just_pressed("destroy_mode"):
		in_destroy_mode = !in_destroy_mode
		if in_destroy_mode:
			in_build_mode = false # Matikan mode build kalau masuk hancur
			if ghost_block != null:
				ghost_block.queue_free()
				ghost_block = null
	
	if Input.is_action_just_pressed("unlock_mouse"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	if ghost_block:
		building(delta)
		if Input.is_action_just_pressed("next_item"):
			object_change(1)
		elif Input.is_action_just_pressed("previous_item"):
			object_change(-1)
	elif raycast.is_colliding():
		if Input.is_action_just_pressed("right_click"):
			var collider = raycast.get_collider()
			if collider.is_in_group("Object") or collider.is_in_group("placed_blocks"):
				if collider.has_method("destroy"):
					collider.destroy()
				else:
					# Fallback for objects without custom destroy logic
					collider.queue_free()
	movement(delta)
	
func object_change(direction):
	if ghost_block:
		ghost_block.queue_free()
		current_object_index += direction
		if (current_object_index < 0):
			current_object_index += objects.size()
		elif current_object_index >= objects.size():
			current_object_index -= objects.size()
		spawn_ghost_block()
	
func movement(delta):
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.position = headbob(t_bob)
	
	var horizontal_velocity = Input.get_vector("left", "right", "forward", "backward").normalized() * SPEED
	var wish_dir = horizontal_velocity.x * global_transform.basis.x + horizontal_velocity.y * global_transform.basis.z
	
	currentvel = currentvel.lerp(wish_dir, ACCEL * delta)
	
	var current_pos = global_position
	var candidate_pos = current_pos + (currentvel * delta)
	var map_rid = get_world_3d().navigation_map
	if map_rid:
		var closest_point = NavigationServer3D.map_get_closest_point(map_rid, candidate_pos)
		var candidate_pos_2d = Vector2(candidate_pos.x, candidate_pos.z)
		var closest_point_2d = Vector2(closest_point.x, closest_point.z)
		if candidate_pos_2d.distance_to(closest_point_2d) > 0.2:
			currentvel.x = 0
			currentvel.z = 0
	# Jika map belum siap, lewati pemeriksaan navigasi untuk sementara
	
	velocity.x = currentvel.x
	velocity.z = currentvel.z
	
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity_y = JUMMP_SPEED
		else:
			velocity_y = 0
	else:
		if is_on_ceiling():
			velocity_y = -0.01
		velocity_y -= GRAVITY * delta
	
	velocity.y = velocity_y
	move_and_slide()
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_x(deg_to_rad(event.relative.y * -MOUSE_SENSITIVITY))
		head.rotation_degrees.x = clamp(head.rotation_degrees.x, -90, 60)
		self.rotate_y(deg_to_rad(event.relative.x * -MOUSE_SENSITIVITY))
		
	if event.is_action_pressed("ui_cancel"):
		var pause_menu = get_tree().get_first_node_in_group("pause_menu")
		if pause_menu:
			if get_tree().paused:
				pause_menu.hide_pause()
			else:
				pause_menu.show_pause()
	
func headbob(speed) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(speed * BOB_FREQ) * BOB_AMP
	pos.x = cos(speed * BOB_FREQ / 2) * BOB_AMP
	return pos
	 
	
# Process: update trauma and apply rotational camera shake (uses FastNoiseLite)
func _process(delta: float) -> void:
	# advance time
	time_acc += delta

	# reduce trauma
	trauma = clamp(trauma - trauma_reduction_rate * delta, 0.0, 1.0)

	# compute intensity squared
	var intensity: float = trauma * trauma

	if intensity <= 0.0:
		# restore exact initial rotation
		camera.rotation_degrees = initial_camera_rotation_degrees
		return

	# sample noise for each axis
	var nx: float = noise.get_noise_1d(time_acc * frequency + 11.1)
	var ny: float = noise.get_noise_1d(time_acc * frequency + 22.2)
	var nz: float = noise.get_noise_1d(time_acc * frequency + 33.3)

	# apply rotation only (degrees)
	var x_rot: float = initial_camera_rotation_degrees.x + nx * intensity * max_x
	var y_rot: float = initial_camera_rotation_degrees.y + ny * intensity * max_y
	var z_rot: float = initial_camera_rotation_degrees.z + nz * intensity * max_z

	camera.rotation_degrees = Vector3(x_rot, y_rot, z_rot)

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)
