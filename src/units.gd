extends CharacterBody3D

const SPEED = 5.0
const GRAVITY = 9.8

@export var owner_id: int

# We use @onready to ensure the node is available before we access it.
# This is syntactic sugar for initializing inside _ready().
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

func _ready():
	# RTS Specific: Connect to the avoidance signal
	# This ensures units don't overlap when swarming a target
	
	# Server-Authoritative
	# The Unit is 'owned' by the player (for selection/input)
	# BUT the Synchronizer must be 'owned' by the Server (to sync physics)
	$MultiplayerSynchronizer.set_multiplayer_authority(1)
	
	if multiplayer.is_server():
		# Optional: ensure the server starts with a clean velocity
		velocity = Vector3.ZERO
	
	# Client-Authoritative
	#navigation_agent.velocity_computed.connect(_on_velocity_computed)
	
	# Server-Authoritative
	navigation_agent.velocity_computed.connect(_on_navigation_agent_3d_velocity_computed)

# Client-Authoritative
#func _physics_process(delta: float) -> void:
	## Only the server (authority) should calculate physics and movement.
	## The clients will just receive the 'position' updates via the Synchronizer.
	#if not is_multiplayer_authority():
		#return
	## 1. Apply Gravity (Standard Kinematics)
	#if not is_on_floor():
		#velocity.y -= GRAVITY * delta
#
	## 2. Check if we have reached the destination
	#if navigation_agent.is_navigation_finished():
		## Decelerate or stop. For crisp RTS movement, stopping is fine.
		## We only set X and Z to zero to preserve falling speed (gravity)
		#velocity.x = move_toward(velocity.x, 0, SPEED)
		#velocity.z = move_toward(velocity.z, 0, SPEED)
		#move_and_slide()
		#return
#
	## 3. Calculate Pathfinding
	#var next_point = navigation_agent.get_next_path_position()
	##print("Next Point", next_point)
	#
	## Vector Math: Destination (next_point) - Origin (global_position)
	#var direction = (next_point - global_position).normalized()
	#direction.y = 0 # Ignore height differences for movement direction
	#direction = direction.normalized()
	##print("Direction", direction)
	#
	## 4. Request Velocity (Do not apply directly yet!)
	#var intended_velocity = direction * SPEED
	#
	## Send this to the agent. The agent will calculate avoidance 
	## and callback _on_velocity_computed with the "safe" velocity.
	#navigation_agent.set_velocity(intended_velocity)


# Server-Authoritative
func _physics_process(delta: float) -> void:
	# Only the Server (ID 1) calculates movement for ALL units.
	# Clients just watch the Synchronizer update the position.
	if not multiplayer.is_server():
		return
	#print("Server is processing physics for: ", name)
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# 2. Check if we have reached the destination
	if navigation_agent.is_navigation_finished():
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		move_and_slide()
		return

	# 3. Calculate Pathfinding
	var next_point = navigation_agent.get_next_path_position()
	var direction = (next_point - global_position).normalized()
	direction.y = 0 
	direction = direction.normalized()
	
	# 4. Request Velocity
	var intended_velocity = direction * SPEED
	
	# If Avoidance is enabled, the agent calculates a safe path.
	# This call triggers the '_on_navigation_agent_3d_velocity_computed' signal.
	navigation_agent.set_velocity(intended_velocity)

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	# Even the callback must check if we are the server
	if not multiplayer.is_server():
		return
		
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z
	move_and_slide()


# The callback for RVO avoidance
func _on_velocity_computed(safe_velocity: Vector3):
	# Apply the safe velocity calculated by the navigation server
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z
	
	#print("Velocity X", velocity.x)
	#print("Velocity Z", velocity.z)
	
	# Move the physics body
	move_and_slide()

# Helper to set target externally (e.g. from your SelectionManager)
func set_movement_target(target_point: Vector3):
	navigation_agent.target_position = target_point
