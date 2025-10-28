extends Node

# Virtual cursor for controller/touchpad navigation

@export var cursor_speed: float = 800.0
@export var cursor_texture: Texture2D = null
@export var cursor_color: Color = Color(1.0, 1.0, 1.0, 0.9)
@export var cursor_size: Vector2 = Vector2(32, 32)
@export var stick_deadzone: float = 0.15
@export var touchpad_sensitivity: float = 2.0

# Player orbit settings
@export var orbit_around_player: bool = true
@export var orbit_min_distance: float = 80.0   # Minimum distance from player
@export var orbit_max_distance: float = 200.0  # Maximum distance from player

var cursor_position: Vector2 = Vector2.ZERO
var is_active: bool = false
var canvas_layer: CanvasLayer = null
var sprite: Sprite2D = null
var last_input_was_controller: bool = false

# For click detection
var click_timer: float = 0.0
var click_cooldown: float = 0.2

# Track if we've detected any controller
var controller_connected: bool = false

# Player reference
var player: Node2D = null

func _ready():
	# CRITICAL: Make sure cursor works even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Create a CanvasLayer to hold the cursor
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # On top of everything
	canvas_layer.name = "VirtualCursorLayer"
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS  # Also works when paused
	
	# Create cursor sprite
	sprite = Sprite2D.new()
	sprite.z_index = 1000  # Always on top
	sprite.process_mode = Node.PROCESS_MODE_ALWAYS  # Also works when paused
	
	if cursor_texture:
		sprite.texture = cursor_texture
	else:
		# Create a simple default cursor
		sprite.texture = create_default_cursor()
	
	sprite.modulate = cursor_color
	
	# Scale the sprite to desired size
	if sprite.texture:
		var tex_size = sprite.texture.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			sprite.scale = cursor_size / tex_size
	
	# Add sprite to canvas layer
	canvas_layer.add_child(sprite)
	
	# Add canvas layer to scene tree
	get_tree().root.add_child(canvas_layer)
	
	# Start at center of screen
	var viewport_size = get_viewport().get_visible_rect().size
	cursor_position = viewport_size / 2
	sprite.position = cursor_position
	
	# Check if controller is connected
	controller_connected = Input.get_connected_joypads().size() > 0
	
	# Hide initially - will activate on controller input
	canvas_layer.visible = false
	is_active = false
	
	print("Virtual Cursor initialized")
	print("Controller connected: ", controller_connected)
	print("Cursor sprite texture: ", sprite.texture)
	print("Cursor size: ", cursor_size)
	
	# Connect to joypad connection signals
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	
	# Enable processing
	set_process(true)
	set_process_input(true)

func _on_joy_connection_changed(device: int, connected: bool):
	controller_connected = Input.get_connected_joypads().size() > 0
	print("Controller ", device, " ", "connected" if connected else "disconnected")
	print("Total controllers: ", Input.get_connected_joypads().size())
	
	if not controller_connected:
		deactivate()

func _input(event):
	# Detect if using mouse - but ignore programmatic mouse events
	if event is InputEventMouse and not event is InputEventMouseMotion:
		# Only deactivate on actual mouse clicks, not our simulated motion
		last_input_was_controller = false
		if is_active:
			deactivate()
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		last_input_was_controller = true
		
		# Activate on any stick movement or button press
		if not is_active:
			# Check if there's meaningful input
			if event is InputEventJoypadMotion:
				if abs(event.axis_value) > stick_deadzone:
					activate()
			elif event is InputEventJoypadButton and event.pressed:
				activate()

func _process(delta):
	# Always try to find player if we don't have one
	if not player or not is_instance_valid(player):
		find_player()
	
	if not is_active or not controller_connected:
		return
	
	click_timer = max(0.0, click_timer - delta)
	
	# Get controller input - ONLY RIGHT STICK
	var input_vector = Vector2.ZERO
	
	# RIGHT STICK ONLY for cursor movement
	var right_stick = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	
	if right_stick.length() > stick_deadzone:
		input_vector = right_stick
	
	# D-pad support (optional alternative)
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP):
		input_vector.y -= 1.0
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN):
		input_vector.y += 1.0
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT):
		input_vector.x -= 1.0
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT):
		input_vector.x += 1.0
	
	# Move cursor
	if input_vector.length() > 0:
		cursor_position += input_vector.normalized() * cursor_speed * delta
		
		# Apply orbit constraint around player
		if orbit_around_player and player and is_instance_valid(player):
			var player_pos = get_player_screen_position()
			var offset_from_player = cursor_position - player_pos
			var distance = offset_from_player.length()
			
			# Clamp distance to orbit range
			if distance < orbit_min_distance:
				offset_from_player = offset_from_player.normalized() * orbit_min_distance
				cursor_position = player_pos + offset_from_player
			elif distance > orbit_max_distance:
				offset_from_player = offset_from_player.normalized() * orbit_max_distance
				cursor_position = player_pos + offset_from_player
		else:
			# Clamp to viewport if no player orbit
			var viewport_size = get_viewport().get_visible_rect().size
			cursor_position.x = clamp(cursor_position.x, 0, viewport_size.x)
			cursor_position.y = clamp(cursor_position.y, 0, viewport_size.y)
		
		sprite.position = cursor_position
		
		# Warp the real mouse cursor to match our virtual cursor position
		Input.warp_mouse(cursor_position)
	
	# Handle clicks
	if Input.is_joy_button_pressed(0, JOY_BUTTON_A) and click_timer <= 0:
		simulate_mouse_click(MOUSE_BUTTON_LEFT)
		click_timer = click_cooldown
	
	if Input.is_joy_button_pressed(0, JOY_BUTTON_B) and click_timer <= 0:
		simulate_mouse_click(MOUSE_BUTTON_RIGHT)
		click_timer = click_cooldown

func activate():
	if not controller_connected:
		print("Cannot activate cursor - no controller connected")
		return
	
	is_active = true
	if canvas_layer:
		canvas_layer.visible = true
	
	# Try to find player
	find_player()
	
	# Start position based on player or screen center
	if orbit_around_player and player and is_instance_valid(player):
		var player_pos = get_player_screen_position()
		# Start at a comfortable distance to the right of player
		cursor_position = player_pos + Vector2(orbit_min_distance + 50, 0)
	else:
		var viewport_size = get_viewport().get_visible_rect().size
		cursor_position = viewport_size / 2
	
	sprite.position = cursor_position
	
	# Warp the actual mouse cursor to match our virtual cursor
	Input.warp_mouse(cursor_position)
	
	# Hide the real mouse cursor (optional - makes it cleaner)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	print("Virtual cursor activated at: ", cursor_position)

func deactivate():
	is_active = false
	if canvas_layer:
		canvas_layer.visible = false
	
	# Show the real mouse cursor again
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	print("Virtual cursor deactivated")

# Remove the simulate_mouse_motion function - we don't need it anymore
# We use Input.warp_mouse() instead

func simulate_mouse_click(button_index: int):
	print("Simulating click at: ", cursor_position)
	
	# Press
	var press_event = InputEventMouseButton.new()
	press_event.button_index = button_index
	press_event.pressed = true
	press_event.position = cursor_position
	press_event.global_position = cursor_position
	Input.parse_input_event(press_event)
	
	# Small delay
	await get_tree().create_timer(0.05).timeout
	
	# Release
	var release_event = InputEventMouseButton.new()
	release_event.button_index = button_index
	release_event.pressed = false
	release_event.position = cursor_position
	release_event.global_position = cursor_position
	Input.parse_input_event(release_event)

func create_default_cursor() -> ImageTexture:
	"""Create a simple default cursor texture"""
	var size = 32
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw a simple crosshair cursor
	var center = size / 2
	var arm_length = 12
	var thickness = 3
	
	# Draw crosshair
	for i in range(size):
		# Horizontal line
		if abs(i - center) < arm_length:
			for t in range(thickness):
				var offset = t - thickness / 2
				if center + offset >= 0 and center + offset < size:
					image.set_pixel(i, center + offset, Color.WHITE)
					if center + offset + 1 < size:
						image.set_pixel(i, center + offset + 1, Color.BLACK)  # Outline
					if center + offset - 1 >= 0:
						image.set_pixel(i, center + offset - 1, Color.BLACK)  # Outline
		
		# Vertical line
		if abs(i - center) < arm_length:
			for t in range(thickness):
				var offset = t - thickness / 2
				if center + offset >= 0 and center + offset < size:
					image.set_pixel(center + offset, i, Color.WHITE)
					if center + offset + 1 < size:
						image.set_pixel(center + offset + 1, i, Color.BLACK)  # Outline
					if center + offset - 1 >= 0:
						image.set_pixel(center + offset - 1, i, Color.BLACK)  # Outline
	
	# Draw center dot
	for x in range(center - 2, center + 3):
		for y in range(center - 2, center + 3):
			if x >= 0 and x < size and y >= 0 and y < size:
				if (x - center) * (x - center) + (y - center) * (y - center) <= 4:
					image.set_pixel(x, y, Color.RED)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

func set_cursor_texture(texture: Texture2D):
	if sprite:
		sprite.texture = texture
		
		# Recalculate scale
		if texture:
			var tex_size = texture.get_size()
			if tex_size.x > 0 and tex_size.y > 0:
				sprite.scale = cursor_size / tex_size

func set_cursor_color(color: Color):
	cursor_color = color
	if sprite:
		sprite.modulate = color

# Utility functions
func get_cursor_position() -> Vector2:
	return cursor_position

func set_cursor_position(pos: Vector2):
	var viewport_size = get_viewport().get_visible_rect().size
	cursor_position = Vector2(
		clamp(pos.x, 0, viewport_size.x),
		clamp(pos.y, 0, viewport_size.y)
	)
	if sprite:
		sprite.position = cursor_position

func is_cursor_active() -> bool:
	return is_active

# Manual activation/deactivation methods for testing
func force_activate():
	activate()

func force_deactivate():
	deactivate()

# Player tracking functions
func find_player():
	"""Find the player node in the scene"""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("Virtual cursor found player: ", player.name)
	else:
		player = null

func get_player_screen_position() -> Vector2:
	"""Get player's position in screen coordinates"""
	if not player or not is_instance_valid(player):
		return get_viewport().get_visible_rect().size / 2
	
	# Get the camera
	var camera = get_viewport().get_camera_2d()
	if camera:
		# Convert world position to screen position
		var player_global = player.global_position
		var camera_offset = camera.get_screen_center_position() - camera.global_position
		var screen_pos = player_global - camera.global_position + get_viewport().get_visible_rect().size / 2
		return screen_pos
	else:
		# No camera, use direct position
		return player.global_position

func set_orbit_enabled(enabled: bool):
	"""Enable or disable player orbit mode"""
	orbit_around_player = enabled
	print("Player orbit mode: ", "enabled" if enabled else "disabled")
	
	# If disabling orbit, reposition cursor to screen center
	if not enabled and is_active:
		var viewport_size = get_viewport().get_visible_rect().size
		cursor_position = viewport_size / 2
		sprite.position = cursor_position
		Input.warp_mouse(cursor_position)

func set_orbit_distance(min_dist: float, max_dist: float):
	"""Set the orbit distance range"""
	orbit_min_distance = min_dist
	orbit_max_distance = max_dist
	print("Orbit distance set to: ", min_dist, " - ", max_dist)

# Helper function to call when entering/exiting menus
func on_menu_opened():
	"""Call this when a menu opens - disables player orbit"""
	set_orbit_enabled(false)

func on_menu_closed():
	"""Call this when a menu closes - enables player orbit"""
	set_orbit_enabled(true)
