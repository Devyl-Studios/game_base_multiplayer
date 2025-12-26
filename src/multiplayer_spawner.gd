extends MultiplayerSpawner

func _init():
	# We assign a custom callable to handle initialization
	spawn_function = _custom_spawn

#func _custom_spawn(data):
	## data is whatever you pass into the .spawn() method (e.g., a Dictionary)
	#var unit_scene = preload("res://src/Unit.tscn")
	#var unit = unit_scene.instantiate()
	#
	## 1. Set the network owner (The most important step!)
	#unit.set_multiplayer_authority(data.peer_id)
	#
	## 2. Set starting properties
	#unit.global_position = data.position
	#unit.owner_id = data.peer_id
	#
	## 3. Return the node; Godot adds it to the "Spawn Path" automatically
	#return unit

func _custom_spawn(data):
	var unit_scene = preload("res://src/Unit.tscn")
	var unit = unit_scene.instantiate()
	
	# 1. Set Authority first
	unit.set_multiplayer_authority(data.peer_id)
	
	# 2. Use 'position' instead of 'global_position'
	# This sets the coordinates relative to the "Units" container
	unit.position = data.position 
	
	# 3. Assign your custom owner variable
	unit.owner_id = data.peer_id
	
	return unit
