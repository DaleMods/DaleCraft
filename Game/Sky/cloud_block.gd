class_name DaleCraftCloudBlock
extends StaticBody3D


func _process(delta: float) -> void:
	global_position.x += delta
	if global_position.x > 1000:
		global_position.x -= 2000
		global_position.z += 200
		if global_position.z > 1000:
			global_position.z -= 2000
