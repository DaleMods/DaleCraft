class_name DaleCraftChunkManager
extends Node

signal setup_complete

# block types
@export var air: DaleCraftBlock
@export var stone: DaleCraftBlock
@export var dirt: DaleCraftBlock
@export var grass: DaleCraftBlock
@export var water: DaleCraftBlock
@export var sand: DaleCraftBlock
@export var oak_log: DaleCraftBlock
@export var oak_leaves: DaleCraftBlock
@export var oak_planks: DaleCraftBlock
@export var torch: DaleCraftBlock

var _textures = [
	preload("res://Game/BlockTextures/stone.png"),			# 0
	preload("res://Game/BlockTextures/dirt.png"),			# 1
	preload("res://Game/BlockTextures/grass.png"),			# 2
	preload("res://Game/BlockTextures/grass_side.png"),		# 3
	preload("res://Game/BlockTextures/water.png"),			# 4
	preload("res://Game/BlockTextures/sand.png"),			# 5
	preload("res://Game/BlockTextures/oak_log.png"),		# 6
	preload("res://Game/BlockTextures/oak_log_top.png"),	# 7
	preload("res://Game/BlockTextures/oak_leaves.png"),		# 8
	preload("res://Game/BlockTextures/oak_planks.png"),		# 9
	preload("res://Game/BlockTextures/torch.png"),			# 10
	]

var _block_types: Array
var _default_block
var _initial_block
var _torch_block
var _setting_up = false
var _game_playing = false
var _seed: int

# Chunk dictionary and definitions
var _chunks = {}
var _chunk_scene = preload("res://Game/Chunk/chunk.tscn")
var _chunk_dimensions = Vector3(32, 64, 32)

# Player definitions
var _player
var _player_position = Vector2(0, 0)
var _player_chunk_radius = 2

# Thread stuff
var _thread_chunk_check: Thread
var _is_thread_needed = true
var _chunks_to_setup: Array
var _chunks_to_setup_lock: Mutex
var _chunks_to_update: Array
var _chunks_to_update_lock: Mutex
var _chunk_threads: Array

# texture dictionary and stuff
var _atlas_lookup = {}
var _grid_width = 4
var _grid_height
var _block_texture_size := Vector2(16, 16)
var _texture_atlas_size: Vector2

# create chunk material
var _chunk_material: StandardMaterial3D


func _ready():
	randomize()
	_seed = randi_range(0, 10000)
	
	_load_textures()
	
	_block_types = [ air, stone, dirt, grass, water, sand, oak_log, oak_leaves, oak_planks, torch ]
	
	_default_block = air
	_initial_block = grass
	_torch_block = torch
	
	_chunk_threads.clear()
	_chunks_to_setup.clear()
	_chunks_to_setup_lock = Mutex.new()
	_chunks_to_update.clear()
	_chunks_to_update_lock = Mutex.new()
	_thread_chunk_check = Thread.new()
	_thread_chunk_check.start(_thread_check_chunks)


func _new_game():
	_player = $"../Player"
	_check_for_new_chunks(_player_chunk_radius, false)
	_setting_up = true


func _process(_delta):
	if _setting_up == true:
		if _game_playing:
			_setting_up = false
	else:
		var player_global_position = _player.global_position
		_player_position = Vector2(floori(player_global_position.x / _chunk_dimensions.x), floori(player_global_position.z / _chunk_dimensions.z))
		_check_for_new_chunks(_player_chunk_radius, true)
		_thread_management()


func _thread_management():
	for thread in _chunk_threads:
		if !thread.is_alive() and thread.is_started():
			thread.wait_to_finish()
			_chunk_threads.erase(thread)
			return


func _check_for_new_chunks(radius, single):
	for x in ((radius * 2) + 1):
		for y in ((radius * 2) + 1):
			var check = Vector2(_player_position.x - radius + x, _player_position.y - radius + y)
			if !_chunks.has(check):
				var chunk = _chunk_scene.instantiate()
				chunk._chunk_position = check
				chunk._seed = _seed
				add_child(chunk)
				chunk.global_position = Vector3(check.x * _chunk_dimensions.x, 0, check.y * _chunk_dimensions.z)
				_chunks[check] = chunk
				_chunks_to_setup_lock.lock()
				_chunks_to_setup.append(chunk)
				_chunks_to_setup_lock.unlock()
				if single:
					return


func _shutdown():
	_is_thread_needed = false
	_thread_chunk_check.wait_to_finish()


func _load_textures():
	for i in _textures.size():
		_atlas_lookup[i] = Vector2(i % _grid_width, floori(i / _grid_width))
	
	_grid_height = (_textures.size() / _grid_width) + 1
	
	var image = Image.create(_grid_width * _block_texture_size.x, _grid_height * _block_texture_size.y, false, Image.FORMAT_RGB8)
	
	for x in _grid_width:
		for y in _grid_height:
			var img_index = x + (y * _grid_width)
			if img_index >= _textures.size():
				continue
			var current_image = _textures[img_index].get_image()
			current_image.convert(Image.FORMAT_RGB8)
			image.blit_rect(current_image, Rect2(Vector2.ZERO, _block_texture_size), Vector2(x, y) * _block_texture_size)
	
	var texture_atlas = ImageTexture.create_from_image(image)
	_chunk_material = StandardMaterial3D.new()
	_chunk_material.albedo_texture = texture_atlas
	_chunk_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_chunk_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	
	_texture_atlas_size = Vector2(_grid_width, _grid_height)
	print("Done loading " + str(_textures.size()) + " images to make " + str(_grid_width) + " x " + str(_grid_height) + " atlas with size " + str(_texture_atlas_size))


func get_texture_atlas_position(index):
	return _atlas_lookup[index]


func _thread_check_chunks():
	while _is_thread_needed:
		_chunks_to_setup_lock.lock()
		if _chunks_to_setup.size() > 0:
			_new_chunk(_chunks_to_setup[0])
			_chunks_to_setup.remove_at(0)
		
		_chunks_to_setup_lock.unlock()
		
		_chunks_to_update_lock.lock()
		if _chunks_to_update.size() > 0:
			_chunks_to_update[0]._update_chunk()
			_chunks_to_update.remove_at(0)
		_chunks_to_update_lock.unlock()


func _new_chunk(chunk):
	var chunk_thread = Thread.new()
	chunk_thread.start(chunk._setup_chunk.bind(chunk._chunk_position, _chunk_dimensions))
	_chunk_threads.append(chunk_thread)
	if chunk._chunk_position == Vector2(0, 0):
		chunk_thread.wait_to_finish()
		_game_playing = true
		call_deferred("emit_signal", "setup_complete")


func set_block(the_global_position, block):
	var chunk_tile_position = Vector2(floori(the_global_position.x / _chunk_dimensions.x), floori(the_global_position.z / _chunk_dimensions.z))
	
	if _chunks[chunk_tile_position] != null:
		var chunk = _chunks[chunk_tile_position]
		var result = chunk.set_block((the_global_position - chunk.global_position), block)
		_chunks_to_update_lock.lock()
		_chunks_to_update.append(chunk)
		_chunks_to_update_lock.unlock()
		return result


func get_block_at_position(the_global_position):
	var chunk_tile_position = Vector2(floori(the_global_position.x / _chunk_dimensions.x), floori(the_global_position.z / _chunk_dimensions.z))
	
	if _chunks[chunk_tile_position] != null:
		var chunk = _chunks[chunk_tile_position]
		return chunk.get_block(the_global_position - chunk.global_position).mine_type


func _get_block_by_type(item):
	for index in _block_types.size():
		if item == _block_types[index].type:
			return _block_types[index]
	return _default_block


func _set_player_start_height(height):
	_player._set_height(height)


func _exit_tree():
	for thread in _chunk_threads:
		if thread.is_alive():
			thread.wait_to_finish()


func _load_chunk(chunk_position, chunk_global_position, move_global_position, chunk_seed, blocks, torches):
	if _chunks.has(chunk_position):
		var chunk = _chunks[chunk_position]
		chunk._chunk_position = chunk_position
		chunk._chunk_global_position = chunk_global_position
		chunk.global_position = move_global_position
		chunk._seed = chunk_seed
		chunk.noise.seed = chunk_seed
		for count in blocks.size():
			chunk._blocks[count] = _get_block_by_type(blocks[count])
		for count in torches.size():
			var new_torch = chunk._torch_block_scene.instantiate()
			chunk.add_child(new_torch)
			new_torch.global_position = torches[count]
		_chunks_to_update_lock.lock()
		_chunks_to_update.append(chunk)
		_chunks_to_update_lock.unlock()
	else:
		var chunk = _chunk_scene.instantiate()
		chunk._chunk_position = chunk_position
		chunk._seed = chunk_seed
		chunk.noise.seed = chunk_seed
		add_child(chunk)
		chunk.global_position = move_global_position
		var block_array: Array = []
		for count in blocks.size():
			block_array.append(_get_block_by_type(blocks[count]))
		for count in torches.size():
			var new_torch = chunk._torch_block_scene.instantiate()
			chunk.add_child(new_torch)
			new_torch.global_position = torches[count]
		var chunk_thread = Thread.new()
		chunk_thread.start(chunk._load_chunk.bind(chunk._chunk_position, _chunk_dimensions, block_array))
		_chunk_threads.append(chunk_thread)
		_chunks[chunk_position] = chunk
