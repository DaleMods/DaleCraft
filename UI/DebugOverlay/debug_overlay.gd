class_name DaleCraftDebugOverlay
extends Control

@onready var fps_count: Label = $PanelContainer/MarginContainer/VBoxContainer/Line1/FPSCount
@onready var mem_min: Label = $PanelContainer/MarginContainer/VBoxContainer/Line2/MemMin
@onready var mem_max: Label = $PanelContainer/MarginContainer/VBoxContainer/Line2/MemMax
@onready var vid_mem: Label = $PanelContainer/MarginContainer/VBoxContainer/Line3/VidMem
@onready var nodes_count: Label = $PanelContainer/MarginContainer/VBoxContainer/Line4/NodesCount
@onready var orphans_count: Label = $PanelContainer/MarginContainer/VBoxContainer/Line5/OrphansCount

const BYTES_IN_MEGABYTE = 1048576


func _process(_delta: float) -> void:
	if visible:
		render_performance_metrics()


func render_performance_metrics():
	fps_count.text = str(Engine.get_frames_per_second())
	
	var minRam = Performance.get_monitor(Performance.MEMORY_STATIC) / BYTES_IN_MEGABYTE
	var maxRam = Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / BYTES_IN_MEGABYTE
	mem_min.text = '%.2f' % minRam
	mem_max.text = '%.2f' % maxRam
	
	var vidRam = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / BYTES_IN_MEGABYTE
	vid_mem.text = '%.2f' % vidRam
	
	nodes_count.text = str(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	
	orphans_count.text = str(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
