extends CharacterBody3D

const SPEED = 5.0
const GRAVITY = 9.8

@export var owner_id: int

# We use @onready to ensure the node is available before we access it.
# This is syntactic sugar for initializing inside _ready().
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
var target_position: Vector3
var grid_speed: float = 0.5 # Discrete distance per tick
var speed = 5.0

@onready var nav_agent = $NavigationAgent3D
func _ready():
	# Add unit to the "units" group so SimulationManager can call deterministic_update on it
	add_to_group("units")
	# Wait for the navigation map to be ready before using the navigation agent
	call_deferred("_setup_navigation_agent")

func _setup_navigation_agent():
	# Wait for the navigation map to be ready
	await get_tree().physics_frame
	# NavigationAgent3D needs to be aware of the unit's position
	nav_agent.set_velocity(Vector3.ZERO)

func deterministic_update(tick_delta: float):
	# Update navigation agent's velocity so it knows the unit's current movement
	# This helps NavigationAgent3D calculate avoidance properly
	navigation_agent.set_velocity(velocity)
	
	# 1. CALCULATE HORIZONTAL VELOCITY (X and Z)
	var move_velocity = Vector3.ZERO
	if not navigation_agent.is_navigation_finished():
		var next_p = navigation_agent.get_next_path_position()
		# .direction_to is cleaner than (b-a).normalized()
		var dir = global_position.direction_to(next_p)
		move_velocity = Vector3(dir.x, 0, dir.z) * SPEED
		
		# Optional: Use your handle_rotation here
		handle_rotation(tick_delta)

	# 2. CALCULATE VERTICAL VELOCITY (Y)
	if not is_on_floor():
		velocity.y -= GRAVITY * tick_delta
	else:
		# Small downward force to keep the 'is_on_floor' check stable in Jolt
		velocity.y = -0.1 

	# 3. MERGE THEM
	velocity.x = move_velocity.x
	velocity.z = move_velocity.z

	# 4. EXECUTE
	# Note: Jolt requires move_and_slide to be called to update 'is_on_floor()'
	move_and_slide()

func set_movement_target(target: Vector3):
	nav_agent.target_position = target


# Add this inside your _physics_process or call it from there
func handle_rotation(delta: float):
	# We only want to rotate if the unit is actually moving
	# and we only care about horizontal movement (X and Z)
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	
	if horizontal_velocity.length() > 0.1:
		# Calculate the target look-at direction
		var target_dir = horizontal_velocity.normalized()
		var target_basis = Basis.looking_at(target_dir)
		
		# Smoothly interpolate the rotation so it doesn't "snap" instantly
		# 10.0 is the rotation speed; higher = faster turning
		basis = basis.slerp(target_basis, 10.0 * delta).orthonormalized()


func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	# Even the callback must check if we are the server
	if not multiplayer.is_server():
		return
		
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z
	move_and_slide()
