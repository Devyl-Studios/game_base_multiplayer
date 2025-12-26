extends Camera3D

@export var pan_speed: float = 20.0
@onready var unit: CharacterBody3D = get_node("../Unit") # Path to your unit

func _process(delta: float):
	# This returns a Vector2 where x is (right - left) and y is (back - forward)
	# It handles normalization for you!
	var input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# 2. Get Vertical Movement (Y)
	# get_axis returns a float: (positive_action - negative_action)
	var vertical_input = Input.get_axis("move_down", "move_up")
	
	# Convert that 2D input to 3D movement
	var direction = Vector3(input_vector.x, vertical_input, input_vector.y)
	
	global_position += direction * pan_speed * delta

func _unhandled_input(event: InputEvent):
	# 2. Unit Command (Right Click to move)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var target_pos = _get_raycast_result(event.position)
			if target_pos != Vector3.ZERO:
				unit.set_movement_target(target_pos)

func _get_raycast_result(mouse_pos: Vector2) -> Vector3:
	var space_state = get_world_3d().direct_space_state
	var from = project_ray_origin(mouse_pos)
	var to = from + project_ray_normal(mouse_pos) * 1000.0
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result:
		print("Result: ", result.position, "  Unit: ", unit)
		return result.position
	return Vector3.ZERO
