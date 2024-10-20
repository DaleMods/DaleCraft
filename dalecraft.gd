class_name DaleCraft
extends Node

var in_world = false


func _process(_delta):
	if in_world:
		$LoadingScreen.hide()
		$TextureRect.hide()
	
	var save_file_path = "user://player_save.sav"
	if FileAccess.file_exists(save_file_path):
		$UI/VBoxContainer/Load.disabled = false
	else:
		$UI/VBoxContainer/Load.disabled = true
	
	if $AudioStreamPlayer.playing == false:
		$AudioStreamPlayer.play()


func _on_new_pressed() -> void:
	_new_game(false)


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_load_pressed() -> void:
	_new_game(true)


func _new_game(loading):
	$UI.hide()
	$Instructions.hide()
	$LoadingScreen.show()
	await get_tree().create_timer(0.1).timeout
	
	var world_scene = preload("res://Game/world.tscn")
	var world = world_scene.instantiate()
	world.name = "World"
	add_child(world)
	world.world_done.connect(_world_done)
	world._new_game(loading)


func _world_done():
	in_world = true
