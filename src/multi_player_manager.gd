extends Node

# MULTIPLAYER

const PORT = 9000
const MAX_PLAYERS = 8

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

func _on_peer_connected(id):
	print("Player connected:", id)
	# Spawn a unit for the new player
	var spawner = get_node("/root/Main/GameWorld/UnitSpawner")
	spawner.spawn_unit(id, Vector3(id * 5, 0, 0)) # offset so they don't overlap

func _on_peer_disconnected(id):
	print("Player disconnected:", id)


# RPC calls for player synchronising

@rpc("any_peer", "reliable")
func request_move_command(target_pos: Vector3):
	# Validate: only allow the sender to move their own unit
	var sender_id = multiplayer.get_remote_sender_id()
	var unit = find_unit_by_owner(sender_id)
	if unit:
		unit.navigation_agent.set_target_position(target_pos)
		# Broadcast to all clients so they see the move
		rpc("apply_move_command", sender_id, target_pos)

@rpc("reliable")
func apply_move_command(owner_id: int, target_pos: Vector3):
	var unit = find_unit_by_owner(owner_id)
	if unit:
		unit.navigation_agent.set_target_position(target_pos)

func find_unit_by_owner(owner_id: int) -> Node:
	var units = get_node("/root/Main/GameWorld/Units").get_children()
	for u in units:
		if u.owner_id == owner_id:
			return u
	return null
