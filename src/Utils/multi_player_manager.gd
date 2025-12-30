extends Node

const PORT = 9000
const MAX_PLAYERS = 2

# Reference to your spawner (Assumes you use a MultiplayerSpawner node)
#@onready var unit_spawner = get_node("MultiplayerSpawner")
# Using a variable that we will assign later
var unit_spawner: MultiplayerSpawner = null

# TODO: Use Dictionary for faster lookup
#var player_units: Dictionary = {} # {peer_id: unit_node}
#func _on_unit_spawned(unit_node, peer_id):
	#player_units[peer_id] = unit_node

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	# Use 'call_deferred' to wait until the current frame is over 
	# and the Main scene is fully loaded into the tree.
	if "--server" in OS.get_cmdline_args():
		call_deferred("host_game")
	elif "--client" in OS.get_cmdline_args():
		call_deferred("join_game", "127.0.0.1")



func _spawn_player_unit(p_id):
	# Ensure we fetch the spawner if we don't have it yet
	if unit_spawner == null:
		unit_spawner = get_tree().root.find_child("UnitSpawner", true, false)
	
	if unit_spawner:
		var spawn_data = {"peer_id": p_id, "position": Vector3.ZERO}
		unit_spawner.spawn(spawn_data)
	else:
		printerr("CRITICAL: UnitSpawner not found in scene tree!")

func _unhandled_input(_event) -> void:
	if Input.is_key_pressed(KEY_F1):
		host_game()
	if Input.is_key_pressed(KEY_F2):
		join_game("127.0.0.1") # Connect to yourself


#func host_game():
	#var peer = ENetMultiplayerPeer.new()
	#peer.create_server(PORT, MAX_PLAYERS)
	#multiplayer.multiplayer_peer = peer
	## The server also counts as a player (ID 1)
	#_spawn_player_unit(1)

func host_game():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	print("Server Started")
	
	# Even here, give the scene one frame to settle so find_child works
	await get_tree().process_frame 
	_spawn_player_unit(1) 


func join_game(ip: String):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer

#func _on_peer_connected(id):
	#if multiplayer.is_server():
		## Only the server should dictate spawning
		#_spawn_player_unit(id)

#func _on_peer_connected(id):
	#if multiplayer.is_server():
		## Create a data packet for the spawn_function
		#var spawn_data = {
			#"peer_id": id,
			#"position": Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		#}
		## This triggers the _custom_spawn function on Server AND Clients
		#unit_spawner.spawn(spawn_data)

func _on_peer_connected(id):
	if multiplayer.is_server():
		# Safety check: make sure the world is loaded and spawner is found
		if unit_spawner == null:
			# Find it in the current scene tree
			unit_spawner = get_tree().root.find_child("MultiplayerSpawner", true, false)
		
		if unit_spawner:
			var spawn_data = {
				"peer_id": id,
				"position": Vector3(randf_range(-2, 2), 2.0, randf_range(-2, 2))
			}
			
			print(spawn_data)
			unit_spawner.spawn(spawn_data)

#func _spawn_player_unit(p_id):
	#var spawn_pos = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
	## Use the custom spawn function of the MultiplayerSpawner
	#unit_spawner.spawn({"id": p_id, "pos": spawn_pos})

# --- MOVEMENT LOGIC ---

#@rpc("any_peer", "call_local", "reliable")
#func request_move(target_pos: Vector3):
	## Security: Get the ID of the person who sent this RPC
	#var sender_id = multiplayer.get_remote_sender_id()
	#
	## Only the server processes the movement logic
	#if multiplayer.is_server():
		#var unit = find_unit_by_owner(sender_id)
		#if unit:
			#unit.set_movement_target(target_pos)
			## No need to RPC back to clients! 
			## MultiplayerSynchronizer on the unit will sync the transform.
			

# RPC call for requesting a move incase we move to server authoritative model (highly likely)
# ServeR-Authoritative
@rpc("any_peer", "call_local", "reliable")
func request_move_command(unit_path: NodePath, target_pos: Vector3):
	var sender_id = multiplayer.get_remote_sender_id()
	var unit = get_node_or_null(unit_path)
	
	# Server validates: Does this sender own this unit?
	if multiplayer.is_server() and unit:
		if unit.get_multiplayer_authority() == sender_id:
			# Set the target on the server's instance of the unit
			print("Server-Authoritative target_pos:", target_pos)
			unit.navigation_agent.target_position = target_pos



func find_unit_by_owner(owner_id: int) -> Node:
	# Optimization: Consider using a Dictionary {owner_id: node_path} 
	# instead of looping every time (O(1) vs O(N))
	for unit in get_node("/root/MultiPlayerManager").get_children():
		if unit.get_multiplayer_authority() == owner_id:
			return unit
	return null

func _on_peer_disconnected(id: int):
	print("Player disconnected: ", id)
	# Logic for handling a player leaving (e.g., deleting their units)
	var unit = find_unit_by_owner(id)
	if unit:
		unit.queue_free()
