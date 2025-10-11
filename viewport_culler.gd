extends Node2D
class_name ViewportCuller

@export var cull_margin: float = 100.0
@export var check_interval: float = 0.1
@export var auto_track_group: String = "enemies"

var viewport_rect: Rect2
var timer: float = 0.0
var camera: Camera2D
var tracked_nodes: Array[Node2D] = []

func _ready():
	camera = get_viewport().get_camera_2d()
	if not camera:
		push_error("No Camera2D found in viewport!")
		return
	
	if auto_track_group != "":
		get_tree().node_added.connect(_on_node_added)

func _process(delta):
	if not camera:
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
	for node in tracked_nodes:
		if not is_instance_valid(node):
			continue
			
		var is_visible = viewport_rect.has_point(node.global_position)
		
		node.set_process(is_visible)
		node.set_physics_process(is_visible)
		node.visible = is_visible

func _on_node_added(node):
	if node.is_in_group(auto_track_group) and node is Node2D:
		register_node(node)

func register_node(node: Node2D):
	if node not in tracked_nodes:
		tracked_nodes.append(node)

func unregister_node(node: Node2D):
	tracked_nodes.erase(node)

func clear_tracked_nodes():
	tracked_nodes.clear()
