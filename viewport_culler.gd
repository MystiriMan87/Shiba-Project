extends Node2D

@export var cull_margin: float = 200.0
@export var check_interval: float = 0.15
@export var auto_track_group: String = "enemies"
@export var debug_mode: bool = false

var viewport_rect: Rect2
var timer: float = 0.0
var camera: Camera2D
var tracked_nodes: Array[Node2D] = []

func _ready():
	print("ViewportCuller: Starting...")
	set_process(true)
	
	await get_tree().process_frame
	
	camera = get_viewport().get_camera_2d()
	if not camera:
		print("ViewportCuller ERROR: No Camera2D found!")
		return
	
	print("ViewportCuller: Camera found - ", camera.name)
	
	if auto_track_group != "":
		get_tree().node_added.connect(_on_node_added)
		
		for node in get_tree().get_nodes_in_group(auto_track_group):
			if node is Node2D:
				register_node(node)
		
		print("ViewportCuller: Tracking ", tracked_nodes.size(), " nodes in group '", auto_track_group, "'")

func _process(delta):
	if not camera or not is_instance_valid(camera):
		return
	
	timer += delta
	if timer >= check_interval:
		timer = 0.0
		update_viewport_rect()
		cull_objects()

func update_viewport_rect():
	var viewport_size = get_viewport_rect().size
	var cam_pos = camera.get_screen_center_position()
	
	viewport_rect = Rect2(
		cam_pos - viewport_size / 2 - Vector2(cull_margin, cull_margin),
		viewport_size + Vector2(cull_margin * 2, cull_margin * 2)
	)

func cull_objects():
	var visible_count = 0
	var culled_count = 0
	
	for node in tracked_nodes:
		if not is_instance_valid(node):
			continue
		
		var is_visible = viewport_rect.has_point(node.global_position)
		
		if node.visible != is_visible:
			node.visible = is_visible
		
		if node.is_processing() != is_visible:
			node.set_process(is_visible)
		
		if node.is_physics_processing() != is_visible:
			node.set_physics_process(is_visible)
		
		if is_visible:
			visible_count += 1
		else:
			culled_count += 1
	
	if debug_mode and Engine.get_frames_per_second() > 0:
		if int(Time.get_ticks_msec() / 1000) % 2 == 0:
			print("ViewportCuller: Visible: ", visible_count, " | Culled: ", culled_count)

func _on_node_added(node):
	if node.is_in_group(auto_track_group) and node is Node2D:
		register_node(node)
		if debug_mode:
			print("ViewportCuller: Registered new node - ", node.name)

func register_node(node: Node2D):
	if node not in tracked_nodes:
		tracked_nodes.append(node)

func unregister_node(node: Node2D):
	tracked_nodes.erase(node)

func clear_tracked_nodes():
	tracked_nodes.clear()

func get_tracked_count() -> int:
	return tracked_nodes.size()
