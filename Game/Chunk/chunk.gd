class_name DaleCraftChunk
extends StaticBody3D

@export var noise: FastNoiseLite
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _chunk_manager: Node
var _default_block: DaleCraftBlock
var _torch_block: DaleCraftBlock
var _torch_block_scene = preload("res://Game/Torch/torch.tscn")

# Chunk definitions
var _dimensions: Vector3
var _ground_level = 24
var _chunk_position: Vector2
var _chunk_global_position: Vector2
var _blocks: Array
var _seed: int

# SurfaceTool and mesh
var _surface_tool: SurfaceTool
var _mesh: Mesh
var _update_collision_shape = false
var _texture_atlas_size

# cube vertice locations
var _vertices: Array = [Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1)]

# vertice arrays for each side of the blocks
var _top: Array = [2, 3, 7, 6]
var _bottom: Array = [0, 4, 5, 1]
var _left: Array = [6, 4, 0, 2]
var _right: Array = [3, 1, 5, 7]
var _back: Array = [7, 5, 4, 6]
var _front: Array = [2, 0, 1, 3]

# Direction index helpers
var _one_up: int
var _one_down: int
var _one_left: int
var _one_right: int
var _one_forward: int
var _one_back: int


func _ready() -> void:
	_blocks.clear()
	_chunk_manager = get_parent()
	_default_block = _chunk_manager._default_block
	_torch_block = _chunk_manager._torch_block
	_texture_atlas_size = _chunk_manager._texture_atlas_size


func _process(_delta):
	if _blocks.size() > 0 and _update_collision_shape:
		if _mesh != null:
			mesh_instance.mesh = _mesh
			collision_shape.shape = _mesh.create_trimesh_shape()
			_update_collision_shape = false


func _setup_chunk(chunk_position, dimensions):
	_surface_tool = SurfaceTool.new()
	
	_chunk_position = chunk_position
	_dimensions = dimensions
	_chunk_global_position = (_chunk_position * Vector2(_dimensions.x, _dimensions.z))
	
	noise.seed = _seed
	
	_one_up = _dimensions.x * _dimensions.z
	_one_down = -_one_up
	_one_right = 1
	_one_left = -_one_right
	_one_back = _dimensions.x
	_one_forward = -_one_back
	
	_initialise_chunk()
	_generate_chunk()
	_add_trees()
	_update_chunk()


func _load_chunk(chunk_position, dimensions, blocks):
	_surface_tool = SurfaceTool.new()
	
	_chunk_position = chunk_position
	_dimensions = dimensions
	_chunk_global_position = (_chunk_position * Vector2(_dimensions.x, _dimensions.z))
	
	noise.seed = _seed
	
	_one_up = _dimensions.x * _dimensions.z
	_one_down = -_one_up
	_one_right = 1
	_one_left = -_one_right
	_one_back = _dimensions.x
	_one_forward = -_one_back
	
	_initialise_chunk()
	_blocks = blocks
	_update_chunk()


func _initialise_chunk():
	var block = _chunk_manager._default_block
	
	_blocks.clear()
	for count in (_dimensions.x * _dimensions.z * _dimensions.y):
		_blocks.append(block)


# standard calculation to take x/y/z vector and translate to flat array index
func _calculate_chunk_index(x, y, z):
	return (y * (_dimensions.x * _dimensions.z)) + (z * _dimensions.x) + x


func set_block(block_position, block):
	if block_position.y >= 60:
		return false
	_blocks[_calculate_chunk_index(block_position.x, block_position.y, block_position.z)] = block
	if block == _torch_block:
		var torch = _torch_block_scene.instantiate()
		add_child(torch)
		torch.global_position = global_position + block_position + Vector3(0.5, 0, 0.5)
	return true


func get_block(block_position):
	return _blocks[_calculate_chunk_index(block_position.x, block_position.y, block_position.z)]


func _generate_chunk():
	var index = 0
	for y in _dimensions.y:
		var did_block = false
		for z in _dimensions.z:
			for x in _dimensions.x:
				var result = _set_best_block(x, y, z, index)
				if result:
					did_block = true
				index += 1
		if did_block == false:
			break


func _add_trees():
	var tree_vector_array = []
	var tree_index_array = []
	for num_tree in 5:
		var tree_loc = Vector2(randi_range(3, (_dimensions.x - 3)), randi_range(3, (_dimensions.z - 3)))
		var loc_height = 0
		var can_grow = true
		var index = _calculate_chunk_index(tree_loc.x, 0, tree_loc.y)
		for y in _dimensions.y:
			if y < (_dimensions.y - 10):
				var check_index = index + (y * _one_up)
				var block = _blocks[check_index]
				if block == _chunk_manager.water or block == _chunk_manager.sand:
					can_grow = false
					break
				if block == _default_block and loc_height == 0 and can_grow:
					loc_height = y
					index = check_index
					y = _dimensions.y
					can_grow = true
					break
		if loc_height == 0 or loc_height <= _ground_level:
			can_grow = false
		if loc_height > 0 and can_grow == true:
			var tree_pos = Vector3(tree_loc.x, loc_height, tree_loc.y)
			for tree in tree_vector_array.size():
				if tree_pos.distance_to(tree_vector_array[tree]) <= 5:
					can_grow = false
		if can_grow:
			tree_vector_array.append(Vector3(tree_loc.x, loc_height, tree_loc.y))
			tree_index_array.append(index)
	for num_tree in tree_index_array.size():
		var trunk_height = randi_range(3, 5)
		var index = tree_index_array[num_tree]
		for trunk in trunk_height:
			_blocks[index + (trunk * _one_up)] = _chunk_manager.oak_log
		var brush_height = randi_range(4, 5)
		for y in brush_height:
			for z in 5:
				for x in 5:
					if x == 2 and z == 2:
						_blocks[index + ((trunk_height + y) * _one_up)] = _chunk_manager.oak_leaves
					elif x >= 1 and x <= 3 and z >= 1 and z <= 3:
						if randi_range(0, 99) < 60:
							_blocks[index + (x - 2) + ((trunk_height + y) * _one_up) + ((z - 2) * _one_forward)] = _chunk_manager.oak_leaves
					elif y < (brush_height - 1):
						if randi_range(0, 99) < 30:
							_blocks[index + (x - 2) + ((trunk_height + y) * _one_up) + ((z - 2) * _one_forward)] = _chunk_manager.oak_leaves


func _update_chunk():
	_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material = get_parent()._chunk_material
	_surface_tool.set_material(material)
	
	var index = 0
	for y in _dimensions.y:
		var did_block = false
		for z in _dimensions.z:
			for x in _dimensions.x:
				var result = _create_block_mesh(Vector3(x, y, z), index)
				if result:
					did_block = true
				index += 1
		if did_block == false:
			break
	
	_mesh = _surface_tool.commit()
	_update_collision_shape = true


func _create_block_mesh(block_position, index):
	var block_index = index
	var block = _blocks[block_index]
	if block == _default_block or block == _torch_block:
		return false
	
	if block_position.y == (_dimensions.y - 1) or _blocks[block_index + _one_up] == _default_block or _blocks[block_index + _one_up] == _torch_block:
		_create_face_mesh(_top, block_position, block.top_index)
	
	if block_position.y == 0 or _blocks[block_index + _one_down] == _default_block or _blocks[block_index + _one_down] == _torch_block:
		_create_face_mesh(_bottom, block_position, block.bottom_index)
	
	if block_position.x == 0 or _blocks[block_index + _one_left] == _default_block or _blocks[block_index + _one_left] == _torch_block:
		_create_face_mesh(_left, block_position, block.left_index)
	
	if block_position.x == (_dimensions.x - 1) or _blocks[block_index + _one_right] == _default_block or _blocks[block_index + _one_right] == _torch_block:
		_create_face_mesh(_right, block_position, block.right_index)
	
	if block_position.z == 0 or _blocks[block_index + _one_forward] == _default_block or _blocks[block_index + _one_forward] == _torch_block:
		_create_face_mesh(_front, block_position, block.front_index)
	
	if block_position.z == (_dimensions.z - 1) or _blocks[block_index + _one_back] == _default_block or _blocks[block_index + _one_back] == _torch_block:
		_create_face_mesh(_back, block_position, block.back_index)
	
	return true


func _create_face_mesh(face, block_position, texture_index):
	var texture_position = get_parent().get_texture_atlas_position(texture_index)
	
	var uv_offset = texture_position / _texture_atlas_size
	var uv_width = 1.0 / _texture_atlas_size.x
	var uv_height = 1.0 / _texture_atlas_size.y
	
	var uv_a = uv_offset + Vector2(0, 0)
	var uv_b = uv_offset + Vector2(0, uv_height)
	var uv_c = uv_offset + Vector2(uv_width, uv_height)
	var uv_d = uv_offset + Vector2(uv_width, 0)
	
	var a = _vertices[face[0]] + block_position
	var b = _vertices[face[1]] + block_position
	var c = _vertices[face[2]] + block_position
	var d = _vertices[face[3]] + block_position
	
	var uv_triangle1 = [uv_a, uv_b, uv_c]
	var uv_triangle2 = [uv_a, uv_c, uv_d]
	
	var triangle1 = [a, b, c]
	var triangle2 = [a, c, d]
	
	var normal = (c - a).cross(b - a).normalized()
	var normals = [normal, normal, normal]
	
	_surface_tool.add_triangle_fan(triangle1, uv_triangle1, [], [], normals)
	_surface_tool.add_triangle_fan(triangle2, uv_triangle2, [], [], normals)


func _set_best_block(x, y, z, index):
	var block = _default_block
	
	var global_block_position = _chunk_global_position + Vector2(x, z)
	var ground_height = int(_dimensions.y * ((noise.get_noise_2d(global_block_position.x, global_block_position.y) + 1.0) / 2.0))
	
	if global_block_position == Vector2(0, 0):
		_chunk_manager._set_player_start_height(ground_height)
	
	block = _check_height(y, ground_height)
	
	_blocks[index] = block
	if block == _default_block:
		return false
	return true


func _check_height(y, ground_height):
	if y <= _ground_level and y > ground_height:
		return _chunk_manager.water
	elif y == _ground_level and y == ground_height:
		return _chunk_manager.sand
	elif y > _ground_level and y == ground_height:
		return _chunk_manager.grass
	elif y < ground_height and y > ground_height - 5:
		return _chunk_manager.dirt
	elif y <= ground_height - 5:
		return _chunk_manager.stone
	return _default_block
