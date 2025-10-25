extends Node3D

@export var unit_scene: PackedScene

func spawn_unit(player_id: int, _position: Vector3):
	if unit_scene == null:
		push_error("UnitSpawner: unit_scene not assigned!")
		return

	var units_node = get_parent().get_node("Units")

	# Check if a unit with this owner_id already exists
	for child in units_node.get_children():
		if child.owner_id == player_id:
			print("Unit for player %s already exists, skipping spawn" % player_id)
			return

	# Otherwise, spawn a new one
	var unit = unit_scene.instantiate()
	unit.owner_id = player_id
	units_node.add_child(unit, true)  # true = replicate to clients
	unit.global_position = _position

	print("Spawned unit for player %s at %s" % [player_id, _position])
