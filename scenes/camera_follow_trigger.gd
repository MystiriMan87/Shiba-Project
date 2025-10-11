extends Area2D

@export var target_follow_speed: float = 5.0
@export var one_time_trigger: bool = true
@export var camera_node_name: String = "PlayerCamera"


var triggered: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	var camera = get_viewport().get_camera_2d()
	collision_layer = 0
	collision_mask = 1
	
	monitoring = true

func _on_body_entered(body: Node2D):
	if body.is_in_group("player") and (not triggered or not one_time_trigger):
		triggered = true
		
		var camera = null
		
		var world = get_tree().current_scene
		if world:
			camera = world.get_node_or_null(camera_node_name)
		
		if not camera or not camera is Camera2D:
			camera = get_viewport().get_camera_2d()
		
		if camera and camera is Camera2D:
			if camera.has_meta("follow_speed") or "follow_speed" in camera:
				camera.follow_speed = target_follow_speed
			print("Camera follow speed set to: ", target_follow_speed)
			print("Camera type: ", camera.get_class())
		else:
			print("Camera not found or wrong type!")
		
		camera.follow_speed = target_follow_speed
		print("Camera follow speed set to: ", camera.follow_speed)
		print("Camera script: ", camera.get_script())

		if one_time_trigger:
			queue_free()
