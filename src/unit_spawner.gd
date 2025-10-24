extends Node3D

@export var unit_scene: PackedScene


func spawn_unit(player_id: int, _position: Vector3):
	var unit = unit_scene.instantiate()
	if unit.has_variable("owner_id"):
		unit.owner_id = player_id
	unit.global_position = _position
	var units_node = get_parent().get_node("Units")
	units_node.add_child(unit)
	print("Spawned unit for player %s at %s" % [player_id, _position])
