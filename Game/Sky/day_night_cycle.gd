class_name DaleCraftDayNightCycle
extends Node3D

@export var sky_top_colour: Gradient
@export var sky_horizon_colour: Gradient
@export var day_length: float = 600.0
@export var start_time: float = 0.3
@export var sun_colour: Gradient
@export var sun_intensity: Curve
@export var moon_colour: Gradient
@export var moon_intensity: Curve

@onready var environment: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $Sun
@onready var moon: DirectionalLight3D = $Moon

var time: float
var time_rate: float

var run_time = false


func _ready():
	time_rate = 1.0 / day_length
	time = start_time


func _process(delta):
	if run_time == false:
		return
	
	time += time_rate * delta
	if time >= 1.0:
		time -= 1.0
	
	environment.environment.sky.sky_material.set("sky_top_color", sky_top_colour.sample(time))
	environment.environment.sky.sky_material.set("sky_horizon_color", sky_horizon_colour.sample(time))
	environment.environment.sky.sky_material.set("ground_bottom_color", sky_horizon_colour.sample(time))
	environment.environment.sky.sky_material.set("ground_horizon_color", sky_horizon_colour.sample(time))
	environment.environment.ambient_light_energy = sun_intensity.sample(time)
	environment.environment.ambient_light_sky_contribution = sun_intensity.sample(time)
	
	sun.rotation_degrees.x = time * 360 + 90
	sun.light_color = sun_colour.sample(time)
	sun.light_energy = sun_intensity.sample(time)
	
	moon.rotation_degrees.x = time * 360 + 270
	moon.light_color = moon_colour.sample(time)
	moon.light_energy = moon_intensity.sample(time)
	
	sun.visible = sun.light_energy > 0
	moon.visible = moon.light_energy > 0
