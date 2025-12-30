# Global/Singleton: SimulationManager.gd
extends Node

var current_tick: int = 0
var tick_rate: float = 0.005 # 10 ticks per second (100ms per turn)
var command_buffer: Dictionary = {} # tick_id -> Array of commands
var units_container: Node3D = null

func register_units_container(node: Node3D):
	units_container = node
	print("SimulationManager: Units container registered successfully!")
	
	
func _ready():
	var timer = Timer.new()
	timer.wait_time = tick_rate
	timer.autostart = true
	timer.timeout.connect(_on_tick)
	add_child(timer)

func _on_tick():
	# 1. Check if we have commands for the current tick from ALL players
	# In a real game, if someone is lagging, we WAIT here (The "Lock")
	execute_tick(current_tick)
	current_tick += 1

func execute_tick(tick_id: int):
	# 1. Dispatch commands for this tick
	var commands = command_buffer.get(tick_id, [])
	for cmd in commands:
		apply_command(cmd)
	
	# 2. Run physics for all units
	# We pass tick_rate as the 'fake' delta to keep movement speed consistent
	get_tree().call_group("units", "deterministic_update", tick_rate)
	
	
func apply_command(cmd: Dictionary):
	# Find the unit by its name inside your units container
	if units_container == null:
		print("Error: Command received but no units_container registered!")
		return
	if units_container:
		var unit = units_container.get_node_or_null(str(cmd.unit_id))
		if unit:
			unit.set_movement_target(cmd.target)
	
	
@rpc("any_peer", "call_local", "reliable")
func server_receive_command(cmd):
	if multiplayer.is_server():
		# The server broadcasts the command to EVERYONE
		# This ensures everyone runs it on the same tick
		broadcast_command.rpc(cmd)

@rpc("call_local", "reliable")
func broadcast_command(cmd):
	var tick = cmd.tick
	if not command_buffer.has(tick):
		command_buffer[tick] = []
	command_buffer[tick].append(cmd)
