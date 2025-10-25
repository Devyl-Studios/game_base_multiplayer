extends Node3D

@onready var camera = $Camera3D

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 1000
		print("from:", from, " -- to: ", to)
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(query)
		print("mouse input")

		if result and result.has("position"):
			var target_pos = result.position
			# Send this to the server
			print("sending input event to server position: ", target_pos)
			# Send to the server (peer_id = 1 is always the server)
			MultiPlayerManager.rpc_id(1, "request_move_command", target_pos)
