class_name DaleCraftSlot
extends TextureRect

@onready var icon: TextureRect = $Icon
@onready var quantity: Label = $Quantity
var chunk_manager: DaleCraftChunkManager
var hand: DaleCraftSlot

@export var item: String = ""
@export var item_texture: Texture2D


func _ready():
	chunk_manager = get_node("/root/DaleCraft/World/ChunkManager")
	hand = get_node("/root/DaleCraft/World/CanvasLayer/UI/SelectedPanel/VBoxContainer/Hand")
	icon.texture = item_texture


func _get_drag_data(_at_position):
	if get_parent().get_parent().name == "Items":
		return
	var prev = Control.new()
	var picon = TextureRect.new()
	picon.position -= Vector2(32, 32)
	picon.texture = icon.texture
	
	modulate = Color(1, 1, 1, 0.5)
	
	prev.add_child(picon)
	set_drag_preview(prev)
	var data = {}
	data["item"] = item
	data["item_texture"] = item_texture
	data["quantity"] = quantity.text
	
	return data


func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		modulate = Color(1, 1, 1, 1)


func _can_drop_data(_at_position, _data):
	if get_parent().get_parent().name == "Items":
		return
	if name == "Hand":
		return true
	return false


func _drop_data(_at_position, data):
	if get_parent().get_parent().name == "Items":
		return
	item = data["item"]
	item_texture = data["item_texture"]
	icon.texture = item_texture
	quantity.text = data["quantity"]


func _set_amount(value):
	quantity.text = str(value)


func _on_button_button_up():
	if get_parent().get_parent().name == "Items":
		return
	var data = {}
	data["item"] = item
	data["item_texture"] = item_texture
	data["quantity"] = quantity.text
	hand._drop_data(null, data)
