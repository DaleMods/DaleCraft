class_name DaleCraftClouds
extends Node3D

@export var noise: FastNoiseLite

var cloud_block_scene = preload("res://Game/Sky/cloud_block.tscn")

var _seed: int

func _setup_clouds():
	noise.seed = _seed
	for z in 200:
		for x in 200:
			var cloud_height = noise.get_noise_2d(x, z)
			if cloud_height > 0.5:
				var cloud_block = cloud_block_scene.instantiate()
				add_child(cloud_block)
				cloud_block.global_position = Vector3((x * 10) - 1000, 100, (z * 10) - 1000)
