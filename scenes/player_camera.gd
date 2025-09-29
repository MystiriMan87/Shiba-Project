extends Camera2D

@export var follow_speed = 5.0 
@export var lookahead_distance = 50.0 
@export var lookahead_smoothing = 3.0 
@export var dead_zone_size = 20.0 

@export var shake_intensity = 0.0
@export var shake_duration = 0.0
var shake_timer = 0.0
var shake_offset = Vector2.ZERO

var player = null
var target_position = Vector2.ZERO
var last_player_position = Vector2.ZERO

func _ready():
	player = get_tree().get_first_node_in_group("player")
	if not player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		else:
			print("Warning: No player found for camera")
			return
	
	global_position = player.global_position
	last_player_position = player.global_position
	target_position = player.global_position
	
	make_current()

	# Attach CRT overlay if not already present
	if not has_node("CRT"):
		var crt = preload("res://addons/crt/crt.gd").new()
		crt.name = "CRT"
		add_child(crt)
		# Tasteful defaults: mild warp and vignette, subtle scanlines
		if crt.has_variable("warp_amount"):
			crt.warp_amount = 0.15
		if crt.has_variable("vignette_amount"):
			crt.vignette_amount = 0.8
		if crt.has_variable("vignette_intensity"):
			crt.vignette_intensity = 0.5
		if crt.has_variable("scan_line_amount"):
			crt.scan_line_amount = 0.6
		if crt.has_variable("interference_amount"):
			crt.interference_amount = 0.05
		if crt.has_variable("grille_amount"):
			crt.grille_amount = 0.1
		if crt.has_variable("aberation_amount"):
			crt.aberation_amount = 0.2

func _process(delta):
	if not player:
		return
	
	if shake_timer > 0:
		shake_timer -= delta
		shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		shake_offset = Vector2.ZERO
	
	var player_velocity = (player.global_position - last_player_position) / delta
	last_player_position = player.global_position
	
	var lookahead_offset = Vector2.ZERO
	if player_velocity.length() > 10: 
		lookahead_offset = player_velocity.normalized() * lookahead_distance
		lookahead_offset = lookahead_offset.lerp(Vector2.ZERO, 1.0 / lookahead_smoothing)
	
	target_position = player.global_position + lookahead_offset
	
	var distance_to_target = global_position.distance_to(target_position)
	
	if distance_to_target > dead_zone_size:
		global_position = global_position.lerp(target_position, follow_speed * delta)
	
	global_position += shake_offset

func shake_camera(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration

func snap_to_player():
	if player:
		global_position = player.global_position
		target_position = player.global_position

func set_limits(left: int, top: int, right: int, bottom: int):
	limit_left = left
	limit_top = top
	limit_right = right
	limit_bottom = bottom

func zoom_to(target_zoom: Vector2, duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(self, "zoom", target_zoom, duration)
	tween.tween_callback(func(): print("Zoom complete"))

func get_camera_bounds() -> Rect2:
	var screen_size = get_viewport_rect().size / zoom
	var top_left = global_position - screen_size / 2
	return Rect2(top_left, screen_size)
