class_name DaleCraftWorld
extends Node3D

signal world_done

var chunk_manager_scene = preload("res://Game/ChunkManager/chunk_manager.tscn")
var player_scene = preload("res://Game/Player/player.tscn")
var ui_scene = preload("res://Game/UI/ui.tscn")

var player
var chunk_manager
var ui

var is_loading = false
var loading_console_countdown = 0.0

var save_file_path = "user://player_save.sav"


func _process(delta):
	if loading_console_countdown > 0:
		loading_console_countdown -= delta
		if loading_console_countdown <= 0:
			$LoadingConsole.visible = false
			loading_console_countdown = 0
	
	if Input.is_action_just_pressed("F1"):
		$DebugPanel.visible = !$DebugPanel.visible


func _new_game(load_game):
	if load_game:
		is_loading = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 120
	chunk_manager = chunk_manager_scene.instantiate()
	chunk_manager.name = "ChunkManager"
	add_child(chunk_manager)
	ui = ui_scene.instantiate()
	ui.name = "UI"
	$CanvasLayer.add_child(ui)
	player = player_scene.instantiate()
	player.name = "Player"
	add_child(player)
	ui._set_player_chunk_manager()
	$Clouds._seed = chunk_manager._seed
	$Clouds._setup_clouds()
	chunk_manager.setup_complete.connect(_setup_complete)
	chunk_manager._new_game()


func _setup_complete():
	emit_signal("world_done")
	get_node("Player").survival_mode = true
	$DayNightCycle.run_time = true
	if is_loading:
		_load_game()


func _end_game():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_node("Player").queue_free()
	$CanvasLayer.get_node("UI").queue_free()
	get_node("ChunkManager").queue_free()
	get_tree().change_scene_to_file("res://dalecraft.tscn")
	queue_free()


func _save_game():
	var config_file = ConfigFile.new()
	
	config_file.set_value("World", "Is_Chunk", false)
	config_file.set_value("World", "Time", $DayNightCycle.time)
	config_file.set_value("World", "Time_Rate", $DayNightCycle.time_rate)
	
	config_file.set_value("Player", "Is_Chunk", false)
	config_file.set_value("Player", "Global_Position", player.global_position)
	config_file.set_value("Player", "Selected_Block", player._selected_block)
	config_file.set_value("Player", "Inventory", player._inventory)
	config_file.set_value("Player", "Is_In_Game", player.is_in_game)
	config_file.set_value("Player", "Survival_Mode", player.survival_mode)
	config_file.set_value("Player", "New_Height", player.new_height)
	config_file.set_value("Player", "New_Height_Received", player.new_height_received)
	
	config_file.set_value("Chunk_Manager", "Is_Chunk", false)
	config_file.set_value("Chunk_Manager", "Setting_Up", chunk_manager._setting_up)
	config_file.set_value("Chunk_Manager", "Game_Playing", chunk_manager._game_playing)
	config_file.set_value("Chunk_Manager", "Seed", chunk_manager._seed)
	
	var chunk_pos_array: Array = []
	for chunk_index in chunk_manager._chunks:
		var chunk = chunk_manager._chunks[chunk_index]
		chunk_pos_array.append(chunk._chunk_position)
	config_file.set_value("Chunk_Manager", "Chunk_Positions", chunk_pos_array)
	
	for chunk_index in chunk_manager._chunks:
		var chunk = chunk_manager._chunks[chunk_index]
		config_file.set_value(str(chunk._chunk_position), "Is_Chunk", true)
		config_file.set_value(str(chunk._chunk_position), "Chunk_Position", chunk._chunk_position)
		config_file.set_value(str(chunk._chunk_position), "Chunk_Global_Position", chunk._chunk_global_position)
		config_file.set_value(str(chunk._chunk_position), "Global_Position", chunk.global_position)
		var block_array = chunk._blocks
		var save_block_array: Array = []
		for count in block_array.size():
			var block = block_array[count]
			save_block_array.append(block.type)
		config_file.set_value(str(chunk._chunk_position), "Blocks", save_block_array)
		var torch_array: Array = []
		for child in chunk.get_children():
			if child is DaleCraftTorch:
				torch_array.append(child.global_position)
		config_file.set_value(str(chunk._chunk_position), "Torches", torch_array)
		config_file.set_value(str(chunk._chunk_position), "Seed", chunk._seed)
	
	var error = config_file.save(save_file_path)
	if error:
		print("Error saving game: " + str(error))


func _load_game():
	var config_file = ConfigFile.new()
	
	var error = config_file.load(save_file_path)
	if error:
		print("Error loading game: " + str(error))
		return
	
	$LoadingConsole.visible = true
	var text_box = $LoadingConsole/MarginContainer/RichTextLabel
	
	text_box.text += "Loading World...\n"
	$DayNightCycle.time = config_file.get_value("World", "Time")
	$DayNightCycle.time_rate = config_file.get_value("World", "Time_Rate")
	
	text_box.text += "Loading Player...\n"
	player.global_position = config_file.get_value("Player", "Global_Position")
	player._selected_block = config_file.get_value("Player", "Selected_Block")
	player._inventory = config_file.get_value("Player", "Inventory")
	player._update_slots_from_inventory()
	player.is_in_game = config_file.get_value("Player", "Is_In_Game")
	player.survival_mode = config_file.get_value("Player", "Survival_Mode")
	player.new_height = config_file.get_value("Player", "New_Height")
	player.new_height_received = config_file.get_value("Player", "New_Height_Received")
	
	text_box.text += "Loading Chunk Manager...\n"
	chunk_manager._setting_up = config_file.get_value("Chunk_Manager", "Setting_Up")
	chunk_manager._game_playing = config_file.get_value("Chunk_Manager", "Game_Playing")
	chunk_manager._seed = config_file.get_value("Chunk_Manager", "Seed")
	
	for section in config_file.get_sections():
		if config_file.get_value(section, "Is_Chunk") == true:
			chunk_manager._load_chunk(config_file.get_value(section, "Chunk_Position"), config_file.get_value(section, "Chunk_Global_Position"), config_file.get_value(section, "Global_Position"), config_file.get_value(section, "Seed"), config_file.get_value(section, "Blocks"), config_file.get_value(section, "Torches"))
			text_box.text += "Loading Chunk: " + str(config_file.get_value(section, "Chunk_Position")) + "\n"
	
	var chunk = chunk_manager._chunks[Vector2(0, 0)]
	chunk_manager._chunks_to_update_lock.lock()
	chunk_manager._chunks_to_update.append(chunk)
	chunk_manager._chunks_to_update_lock.unlock()
	
	text_box.text += "World loaded"
	loading_console_countdown = 5.0
