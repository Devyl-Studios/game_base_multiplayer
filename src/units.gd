extends CharacterBody3D

const SPEED = 5.0

@export var owner_id: int
var navigation_agent: NavigationAgent3D

func _ready():
	navigation_agent = $NavigationAgent3D

func _physics_process(_delta: float) -> void:
	#print("Target:", navigation_agent.get_target_position(),
	  #" Next:", navigation_agent.get_next_path_position(),
	  #" Finished:", navigation_agent.is_navigation_finished())
	#
	if navigation_agent.is_navigation_finished():
		velocity = Vector3.ZERO
	else:
		var next_point = navigation_agent.get_next_path_position()
		var direction = (next_point - global_position).normalized()
		velocity = direction * SPEED
		move_and_slide()
