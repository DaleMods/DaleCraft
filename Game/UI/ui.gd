class_name DaleCraftUI
extends Control

@onready var inventory: PanelContainer = $Inventory
@onready var craft_table: PanelContainer = $CraftTable

var world
var player
var chunk_manager

var _oak_log_to_plank_cost = 1
var _oak_plank_from_log = 2
var _oak_log_to_torch_cost = 1
var _torch_from_log = 5


func _set_player_chunk_manager():
	world = get_node("/root/DaleCraft/World")
	player = get_node("/root/DaleCraft/World/Player")
	chunk_manager = get_node("/root/DaleCraft/World/ChunkManager")


func change_visibility():
	if inventory.visible == false:
		inventory.show()
		craft_table.show()
		_update_craft_table()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		inventory.hide()
		craft_table.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _update_craft_table():
	$CraftTable/Items/Item1/OakLogs._set_amount(_oak_log_to_plank_cost)
	$CraftTable/Items/Item1/OakPlanks._set_amount(_oak_plank_from_log)
	$CraftTable/Items/Item2/OakLogs._set_amount(_oak_log_to_torch_cost)
	$CraftTable/Items/Item2/Torchs._set_amount(_torch_from_log)
	
	if player._get_inventory(chunk_manager.oak_log.type) < _oak_log_to_plank_cost:
		$CraftTable/Items/Item1/CraftOakPlanks.disabled = true
		$CraftTable/Items/Item2/CraftTorch.disabled = true
	else:
		$CraftTable/Items/Item1/CraftOakPlanks.disabled = false
		$CraftTable/Items/Item2/CraftTorch.disabled = false


func _show_menu():
	if $Menu.visible == false:
		$Menu.visible = true
	else:
		$Menu.visible = false


func _on_craft_oak_planks_pressed():
	player._change_inventory(chunk_manager.oak_log.type, -_oak_log_to_plank_cost)
	player._change_inventory(chunk_manager.oak_planks.type, _oak_plank_from_log)
	
	_update_craft_table()


func _on_craft_torch_pressed() -> void:
	player._change_inventory(chunk_manager.oak_log.type, -_oak_log_to_torch_cost)
	player._change_inventory(chunk_manager.torch.type, _torch_from_log)
	
	_update_craft_table()


func _on_save_pressed() -> void:
	world._save_game()


func _on_exit_pressed() -> void:
	world._end_game()
