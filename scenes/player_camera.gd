extends Camera2D

@export var follow_speed = 5.0  # How fast camera catches up to player
@export var lookahead_distance = 50.0  # How far ahead of player movement to look
@export var lookahead_smoothing = 3.0  # How smooth the lookahead effect is
@export var dead_zone_size = 20.0  # Player can move this far before camera starts following

# Camera shake variables
@export var shake_intensity = 0.0
@export var shake_duration = 0.0
var shake_timer = 0.0
var shake_offset = Vector2.ZERO

# Target and player references
var player = null
var target_position = Vector2.ZERO
var last_player_position = Vector2.ZERO

func _ready():
	# Find the player node
	player = get_tree().get_first_node_in_group("player")
	if not player:
		# Fallback search
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		else:
			print("Warning: No player found for camera")
			return
	
	# Initialize camera position
	global_position = player.global_position
	last_player_position = player.global_position
	target_position = player.global_position
	
	# Make this camera current
	make_current()

func _process(delta):
	if not player:
		return
	
	# Handle camera shake
	if shake_timer > 0:
		shake_timer -= delta
		shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		shake_offset = Vector2.ZERO
	
	# Calculate player movement direction
	var player_velocity = (player.global_position - last_player_position) / delta
	last_player_position = player.global_position
	
	# Calculate lookahead position
	var lookahead_offset = Vector2.ZERO
	if player_velocity.length() > 10:  # Only add lookahead when player is moving
		lookahead_offset = player_velocity.normalized() * lookahead_distance
		lookahead_offset = lookahead_offset.lerp(Vector2.ZERO, 1.0 / lookahead_smoothing)
	
	# Calculate target position
	target_position = player.global_position + lookahead_offset
	
	# Dead zone check - only move camera if player is far enough from current position
	var distance_to_target = global_position.distance_to(target_position)
	
	if distance_to_target > dead_zone_size:
		# Smooth camera movement
		global_position = global_position.lerp(target_position, follow_speed * delta)
	
	# Apply camera shake
	global_position += shake_offset

# Call this function to shake the camera (useful for hits, explosions, etc.)
func shake_camera(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration

# Instantly snap camera to player (useful for scene transitions)
func snap_to_player():
	if player:
		global_position = player.global_position
		target_position = player.global_position

# Set camera limits (useful for keeping camera within level bounds)
func set_limits(left: int, top: int, right: int, bottom: int):
	limit_left = left
	limit_top = top
	limit_right = right
	limit_bottom = bottom

# Smooth zoom function
func zoom_to(target_zoom: Vector2, duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(self, "zoom", target_zoom, duration)
	tween.tween_callback(func(): print("Zoom complete"))

# Get camera bounds (useful for enemy spawning, etc.)
func get_camera_bounds() -> Rect2:
	var screen_size = get_viewport_rect().size / zoom
	var top_left = global_position - screen_size / 2
	return Rect2(top_left, screen_size)
