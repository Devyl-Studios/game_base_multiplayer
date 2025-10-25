extends Node

# MULTIPLAYER

const PORT = 9000
const MAX_PLAYERS = 2
var connected_peers := []
var have_units_spawned := 0




func host_game():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	print("Hosting server on port %s" % PORT)

func join_game(ip: String):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer
	print("Joining server at %s:%s" % [ip, PORT])





func _ready():
	# Connect signals for when peers join/leave
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_init_connected_peers()



func _on_peer_connected(id):
	print("Player connected:", id)
	# Deduplicate
	if not connected_peers.has(id):
		connected_peers.append(id)
	# Server-only spawn (recommended). If you still call spawn for every peer, guard it below.
	
	if multiplayer.is_server():
		print("(SERVER) Connected peers now:", connected_peers)
		
		if len(connected_peers) == MAX_PLAYERS:
			print("All players have connected")
			# we will later add an rpc to see if all players are ready, like in AOE
			# Tell everyone to spawn units
			start_game_and_spawn_units(connected_peers)
			rpc("start_game_and_spawn_units", connected_peers)

	else:
		print("(CLIENT) Connected peers now:", connected_peers)
	


func _on_peer_disconnected(id):
	print("Player disconnected:", id)
	if connected_peers.has(id):
		connected_peers.erase(id)
	print("Connected peers now:", connected_peers)
	# optional: cleanup units / state for this peer here



@rpc("any_peer", "reliable")
func start_game_and_spawn_units(peer_ids: Array):
	print("Spawning units for peers:", peer_ids)
	var spawner = get_node("/root/Main/GameWorld/UnitSpawner")
	for id in peer_ids:
		var pos = Vector3(randi() % 4, 0, 0)  # or use spawn markers
		spawner.spawn_unit(id, pos)


func _spawn_for_peer(id):
	var spawner = get_node("/root/Main/GameWorld/UnitSpawner")
	spawner.spawn_unit(id, Vector3( randi()%4 + 0, 0, 0) ) # offset so they don't overlap
	


# Ensure list contains the local host id (if any) and any peers already known
func _init_connected_peers():
	connected_peers.clear()
	if multiplayer.multiplayer_peer == null:
		return
	# Add host unique id if present (server or host)
	var host_id := multiplayer.get_unique_id()
	if host_id != 0 and not connected_peers.has(host_id):
		connected_peers.append(host_id)
	# Add currently connected peers reported by the API
	for id in multiplayer.get_peers():
		if id != 0 and not connected_peers.has(id):
			connected_peers.append(id)
	print("Connected peers initialized:", connected_peers)





# RPC calls for player synchronising

@rpc("any_peer", "reliable", "call_local")
func request_move_command(target_pos: Vector3):
	# Validate: only allow the sender to move their own unit
	var sender_id = multiplayer.get_remote_sender_id()
	var unit = find_unit_by_owner(sender_id)
	print("Requesting move command, Unit: ", unit, "senderID: ", sender_id)
	
	if unit:
		unit.navigation_agent.set_target_position(target_pos)
		# Broadcast to all clients so they see the move
		print("Unit found sending to apply move command")
		rpc("apply_move_command", sender_id, target_pos)

@rpc("reliable")
func apply_move_command(owner_id: int, target_pos: Vector3):
	var unit = find_unit_by_owner(owner_id)
	print("Applying move command ", owner_id)
	if unit:
		print("moving")
		unit.navigation_agent.set_target_position(target_pos)

func find_unit_by_owner(owner_id: int) -> Node:
	for unit in get_node("/root/Main/GameWorld/Units").get_children():
		if unit.owner_id == owner_id:
			return unit
	return null
