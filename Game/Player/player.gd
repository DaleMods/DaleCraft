class_name DaleCraftPlayer
extends CharacterBody3D

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray_cast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var block_highlight: MeshInstance3D = $BlockHighlight
@onready var player_ui: Control = $"../CanvasLayer/UI"

# Inventory slots
@onready var slot_0: DaleCraftSlot = $"../CanvasLayer/UI/Inventory/GridContainer/Slot0"
@onready var slot_1: DaleCraftSlot = $"../CanvasLayer/UI/Inventory/GridContainer/Slot1"
@onready var slot_2: DaleCraftSlot = $"../CanvasLayer/UI/Inventory/GridContainer/Slot2"
@onready var slot_3: DaleCraftSlot = $"../CanvasLayer/UI/Inventory/GridContainer/Slot3"
@onready var slot_4: DaleCraftSlot = $"../CanvasLayer/UI/Inventory/GridContainer/Slot4"
@onready var slot_5: DaleCraftSlot = $"../CanvasLayer/UI/Inventory/GridContainer/Slot5"
@onready var slot_6: DaleCraftSlot = $"../CanvasLayer/UI/Inventory/GridContainer/Slot6"
@onready var slot_7: DaleCraftSlot = $"../CanvasLayer/UI/Inventory/GridContainer/Slot7"
@onready var hand: DaleCraftSlot = $"../CanvasLayer/UI/SelectedPanel/VBoxContainer/Hand"

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# inventory stuff
var _inventory = {}
var _selected_block
var _slots = []

# ref to Managers
var _chunk_manager

# character move variables
var _mouse_sensitivity: float = 0.3
var _movement_speed: float = 10.0
var _jump_velocity: float = 7.0

# track camera up/down rotation
var _camera_x_rotation: float = 0.0

var is_in_game = true
var survival_mode = false
var is_in_inventory = false
var new_height = 0
var new_height_received = false


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_chunk_manager = get_parent().get_node("ChunkManager")
	_selected_block = _chunk_manager._initial_block
	_slots = [slot_0, slot_1, slot_2, slot_3, slot_4, slot_5, slot_6, slot_7]


func _input(event: InputEvent):
	if event is InputEventMouseMotion and is_in_inventory == false:
		var mouse_motion = event as InputEventMouseMotion
		var deltax = mouse_motion.relative.y * _mouse_sensitivity
		var deltay = -mouse_motion.relative.x * _mouse_sensitivity
		
		head.rotate_y(deg_to_rad(deltay))
		if _camera_x_rotation + deltax > -90 and _camera_x_rotation + deltax < 90:
			camera.rotate_x(deg_to_rad(-deltax))
			_camera_x_rotation += deltax


func _process(_delta: float):
	if Input.is_action_just_pressed("Escape"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		is_in_inventory = !is_in_inventory
		_chunk_manager._shutdown()
		player_ui._show_menu()
	
	if Input.is_action_just_pressed("I"):
		is_in_inventory = !is_in_inventory
		player_ui.change_visibility()
	
	if is_in_inventory:
		return
	
	block_highlight.visible = false
	if ray_cast.is_colliding() and ray_cast.get_collider() is DaleCraftChunk:
		block_highlight.visible = true
		
		var block_position = ray_cast.get_collision_point() - 0.5 * ray_cast.get_collision_normal()
		var int_block_position = Vector3(floori(block_position.x), floori(block_position.y), floori(block_position.z))
		block_highlight.global_position = int_block_position + Vector3(0.5, 0.5, 0.5)
		
		var amount = 0
		var block
		if Input.is_action_just_pressed("LMB"):
			block = _chunk_manager.get_block_at_position(int_block_position)
			if _chunk_manager.set_block((int_block_position), _chunk_manager._default_block):
				amount = 1
		
		if Input.is_action_just_pressed("RMB"):
			_selected_block = _chunk_manager._get_block_by_type(hand.item)
			block = _selected_block.type
			if _inventory.has(block):
				if _inventory[block] > 0:
					if _chunk_manager.set_block((int_block_position + ray_cast.get_collision_normal()), _selected_block):
						amount = -1
		
		if amount != 0:
			_change_inventory(block, amount)


func _update_slots_from_inventory():
	for count in _slots.size():
		if _inventory.has(_slots[count].item):
			_slots[count]._set_amount(_inventory[_slots[count].item])
		if _slots[count].item == _selected_block.type:
			hand.item = _selected_block.type
			hand.item_texture = _slots[count].item_texture
			hand.icon.texture = _slots[count].item_texture
			if _inventory.has(_selected_block.type):
				hand._set_amount(_inventory[_selected_block.type])
			else:
				hand._set_amount(0)


func _change_inventory(block, amount):
	if !_inventory.has(block):
		_inventory[block] = 0
	_inventory[block] += amount
	
	for count in _slots.size():
		if _slots[count].item == block:
			_slots[count]._set_amount(_inventory[block])
	
	if hand.item == block:
		hand._set_amount(_inventory[block])


func _get_inventory(block):
	if !_inventory.has(block):
		return 0
	return _inventory[block]


func _physics_process(delta: float):
	if is_in_game and !is_in_inventory:
		if new_height_received == true:
			new_height_received = false
			global_position.y = new_height
		
		if !is_on_floor() and survival_mode:
			velocity.y -= _gravity * delta
		
		if Input.is_action_pressed("Space") and is_on_floor():
			velocity.y = _jump_velocity
		
		if Input.is_action_just_pressed("Z"):
			survival_mode = !survival_mode
		
		var updown_direction = Input.get_axis("E", "Q")
		var input_direction = Input.get_vector("A", "D", "S", "W").normalized()
		var direction = Vector3.ZERO
		direction += input_direction.x * head.global_basis.x
		direction += input_direction.y * -head.global_basis.z
		if !survival_mode:
			direction += updown_direction * head.global_basis.y
		
		velocity.x = direction.x * _movement_speed
		velocity.z = direction.z * _movement_speed
		if !survival_mode:
			velocity.y = direction.y * _movement_speed
		
		move_and_slide()


func _set_height(height):
	new_height = height + 3
	new_height_received = true
