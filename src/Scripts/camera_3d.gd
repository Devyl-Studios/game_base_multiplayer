extends Camera3D

@export var pan_speed: float = 20.0
#@onready var unit: CharacterBody3D = get_node("../Units/Unit") # Path to your unit

var selected_unit: CharacterBody3D = null



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
	if event is InputEventMouseButton and event.pressed:
		# LEFT CLICK: Select a unit
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_selection(event.position)

	# RIGHT CLICK: Move the selected unit
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_movement(event.position)



func _handle_selection(mouse_pos: Vector2):
	var result = _get_raycast_result(mouse_pos)
	# Dictionary access: result.collider
	if not result.is_empty() and result.collider is CharacterBody3D:
		var unit_hit = result.collider
		if unit_hit.is_multiplayer_authority():
			selected_unit = unit_hit
			print("Selected my unit: ", selected_unit.name)
		else:
			print("That unit belongs to another player!")
	else:
		selected_unit = null
		print("Deselected")


#
#func _handle_movement(mouse_pos: Vector2):
	#if selected_unit:
		#var result = _get_raycast_result(mouse_pos)
		#if result:
			## We pass the selected_unit's name or ID to the RPC
			## so the server knows which specific unit to move
			#MultiPlayerManager.request_move_command.rpc(selected_unit.get_path(), result.position)

#func _handle_movement(mouse_pos: Vector2):
	#if selected_unit:
		#var result = _get_raycast_result(mouse_pos)
		## Check if the dictionary is not empty
		#if not result.is_empty():
			#var target_pos = result.position
			## The physics process and simulation will be run by every player themselves
			## and the MultiplayerSynchronizer will be sending the updated positions to
			## all the peers connected to the network
			##selected_unit.set_movement_target(target_pos)
			#MultiPlayerManager.request_move_command.rpc(selected_unit.get_path(), target_pos)

func _handle_movement(mouse_pos: Vector2):
	if selected_unit:
		var result = _get_raycast_result(mouse_pos)
		if not result.is_empty():
			# Plan the move for 2 ticks in the future to account for latency
			
			var cmd = {
				"tick": SimulationManager.current_tick + 5,
				"unit_id": str(selected_unit.name), # Send the NAME as a STRING
				"type": "MOVE",
				"target": result.position
			}
			# Send to server
			SimulationManager.server_receive_command.rpc(cmd)

#

#func _unhandled_input(event: InputEvent):

## 2. Unit Command (Right Click to move)

#if event is InputEventMouseButton and event.pressed:

#if event.button_index == MOUSE_BUTTON_RIGHT:

#var target_pos = _get_raycast_result(event.position)

#if target_pos != Vector3.ZERO:

#unit.set_movement_target(target_pos)



# Change the return type from Vector3 to Dictionary (or Variant)
func _get_raycast_result(mouse_pos: Vector2) -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var from = project_ray_origin(mouse_pos)
	var to = from + project_ray_normal(mouse_pos) * 1000.0
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	# Return the whole dict so we can see WHAT we hit, not just WHERE
	if result:
		print("Result: ", result.position, "  Unit: ", selected_unit)
		
		return result
	return {}
