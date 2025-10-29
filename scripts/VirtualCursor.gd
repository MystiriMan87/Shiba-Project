extends Node

@export var cursor_speed: float = 1600.0
@export var cursor_texture: Texture2D = null
@export var cursor_color: Color = Color(1.0, 1.0, 1.0, 0.9)
@export var cursor_size: Vector2 = Vector2(32, 32)
@export var stick_deadzone: float = 0.12
@export var touchpad_sensitivity: float = 2.0

@export var orbit_around_player: bool = true
@export var orbit_min_distance: float = 80.0
@export var orbit_max_distance: float = 200.0
@export var orbit_sensitivity_multiplier: float = 1.8

var cursor_position: Vector2 = Vector2.ZERO
var is_active: bool = false
var canvas_layer: CanvasLayer = null
var sprite: Sprite2D = null
var last_input_was_controller: bool = false

var click_timer: float = 0.0
var click_cooldown: float = 0.2

var controller_connected: bool = false

var player: Node2D = null

var hovered_control: Control = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10000
	canvas_layer.name = "VirtualCursorLayer"
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	
	sprite = Sprite2D.new()
	sprite.z_index = 10000
	sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	
	if cursor_texture:
		sprite.texture = cursor_texture
	else:
		sprite.texture = create_default_cursor()
	
	sprite.modulate = cursor_color
	
	if sprite.texture:
		var tex_size = sprite.texture.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			sprite.scale = cursor_size / tex_size
	
	canvas_layer.add_child(sprite)
	get_tree().root.call_deferred("add_child", canvas_layer)
	
	await get_tree().process_frame
	
	var viewport_size = get_viewport().get_visible_rect().size
	cursor_position = viewport_size / 2
	sprite.position = cursor_position
	sprite.global_position = cursor_position
	
	controller_connected = Input.get_connected_joypads().size() > 0
	
	canvas_layer.visible = false
	sprite.visible = false
	is_active = false
	
	print("Virtual Cursor initialized")
	print("Controller connected: ", controller_connected)
	print("Canvas layer added to tree: ", canvas_layer.is_inside_tree())
	print("Sprite texture set: ", sprite.texture != null)
	
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	
	set_process(true)
	set_process_input(true)
	
	if controller_connected:
		print("Controller detected - virtual cursor ready. Press F1 or move right stick to activate.")

func _on_joy_connection_changed(device: int, connected: bool):
	controller_connected = Input.get_connected_joypads().size() > 0
	print("Controller ", device, " ", "connected" if connected else "disconnected")
	
	if not controller_connected:
		deactivate()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			if is_active:
				print("F1: Deactivating cursor")
				deactivate()
			else:
				print("F1: Activating cursor")
				activate()
			get_viewport().set_input_as_handled()
			return
	
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if event is InputEventMouseButton:
			last_input_was_controller = false
			if is_active:
				print("Mouse input detected - deactivating virtual cursor")
				deactivate()
		return
	
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		last_input_was_controller = true
		
		if not is_active and controller_connected:
			if event is InputEventJoypadMotion:
				if event.axis == JOY_AXIS_RIGHT_X or event.axis == JOY_AXIS_RIGHT_Y:
					if abs(event.axis_value) > stick_deadzone:
						print("Right stick movement detected - activating cursor")
						activate()
			elif event is InputEventJoypadButton and event.pressed:
				if event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
					print("Right shoulder button pressed - activating cursor")
					activate()

func _process(delta):
	if not player or not is_instance_valid(player):
		find_player()
	
	if not is_active or not controller_connected:
		return
	
	click_timer = max(0.0, click_timer - delta)
	
	var input_vector = Vector2.ZERO
	
	var right_stick = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	
	if right_stick.length() > stick_deadzone:
		input_vector = right_stick
	
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP):
		input_vector.y -= 1.0
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN):
		input_vector.y += 1.0
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT):
		input_vector.x -= 1.0
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT):
		input_vector.x += 1.0
	
	if input_vector.length() > 0:
		var current_speed = cursor_speed
		if orbit_around_player and player and is_instance_valid(player):
			current_speed *= orbit_sensitivity_multiplier
		
		cursor_position += input_vector.normalized() * current_speed * delta
		
		if orbit_around_player and player and is_instance_valid(player):
			var player_pos = get_player_screen_position()
			var offset_from_player = cursor_position - player_pos
			var distance = offset_from_player.length()
			
			if distance < orbit_min_distance:
				offset_from_player = offset_from_player.normalized() * orbit_min_distance
				cursor_position = player_pos + offset_from_player
			elif distance > orbit_max_distance:
				offset_from_player = offset_from_player.normalized() * orbit_max_distance
				cursor_position = player_pos + offset_from_player
		else:
			var viewport_size = get_viewport().get_visible_rect().size
			cursor_position.x = clamp(cursor_position.x, 0, viewport_size.x)
			cursor_position.y = clamp(cursor_position.y, 0, viewport_size.y)
		
		sprite.position = cursor_position
		
		update_hovered_control()
	
	if Input.is_joy_button_pressed(0, JOY_BUTTON_A) and click_timer <= 0:
		click_at_cursor()
		click_timer = click_cooldown
	
	if Input.is_joy_button_pressed(0, JOY_BUTTON_B) and click_timer <= 0:
		right_click_at_cursor()
		click_timer = click_cooldown

func update_hovered_control():
	var root = get_tree().root
	hovered_control = find_control_at_position(root, cursor_position)

func find_control_at_position(node: Node, pos: Vector2) -> Control:
	if node is Control:
		var control = node as Control
		if control.visible and control.global_position.distance_to(Vector2.ZERO) < 100000:
			var rect = Rect2(control.global_position, control.size)
			if rect.has_point(pos):
				for child in control.get_children():
					var child_result = find_control_at_position(child, pos)
					if child_result:
						return child_result
				return control
	
	for child in node.get_children():
		var result = find_control_at_position(child, pos)
		if result:
			return result
	
	return null

func click_at_cursor():
	if hovered_control and is_instance_valid(hovered_control):
		if hovered_control is Button:
			var button = hovered_control as Button
			if button.disabled:
				return
			print("Clicking button: ", button.name)
			button.emit_signal("pressed")
			flash_cursor()
			return
		elif hovered_control is BaseButton:
			var base_button = hovered_control as BaseButton
			if base_button.disabled:
				return
			print("Clicking base button: ", base_button.name)
			base_button.emit_signal("pressed")
			flash_cursor()
			return
	
	var motion_event = InputEventMouseMotion.new()
	motion_event.position = cursor_position
	motion_event.global_position = cursor_position
	Input.parse_input_event(motion_event)
	
	await get_tree().process_frame
	
	var press_event = InputEventMouseButton.new()
	press_event.button_index = MOUSE_BUTTON_LEFT
	press_event.pressed = true
	press_event.position = cursor_position
	press_event.global_position = cursor_position
	Input.parse_input_event(press_event)
	
	await get_tree().create_timer(0.05).timeout
	
	var release_event = InputEventMouseButton.new()
	release_event.button_index = MOUSE_BUTTON_LEFT
	release_event.pressed = false
	release_event.position = cursor_position
	release_event.global_position = cursor_position
	Input.parse_input_event(release_event)
	
	flash_cursor()

func right_click_at_cursor():
	var motion_event = InputEventMouseMotion.new()
	motion_event.position = cursor_position
	motion_event.global_position = cursor_position
	Input.parse_input_event(motion_event)
	
	await get_tree().process_frame
	
	var press_event = InputEventMouseButton.new()
	press_event.button_index = MOUSE_BUTTON_RIGHT
	press_event.pressed = true
	press_event.position = cursor_position
	press_event.global_position = cursor_position
	Input.parse_input_event(press_event)
	
	await get_tree().create_timer(0.05).timeout
	
	var release_event = InputEventMouseButton.new()
	release_event.button_index = MOUSE_BUTTON_RIGHT
	release_event.pressed = false
	release_event.position = cursor_position
	release_event.global_position = cursor_position
	Input.parse_input_event(release_event)

func flash_cursor():
	if not sprite:
		return
	var original_scale = sprite.scale
	var tween = create_tween()
	tween.tween_property(sprite, "scale", original_scale * 1.3, 0.05)
	tween.tween_property(sprite, "scale", original_scale, 0.05)

func activate():
	print("=== ACTIVATING CURSOR ===")
	
	if not controller_connected:
		print("Cannot activate cursor - no controller connected")
		return
	
	is_active = true
	
	if not canvas_layer or not is_instance_valid(canvas_layer):
		print("ERROR: canvas_layer is null or invalid!")
		return
	
	if not sprite or not is_instance_valid(sprite):
		print("ERROR: sprite is null or invalid!")
		return
	
	canvas_layer.visible = true
	sprite.visible = true
	
	print("Canvas layer visible: ", canvas_layer.visible)
	print("Sprite visible: ", sprite.visible)
	print("Sprite texture: ", sprite.texture)
	print("Sprite position: ", sprite.position)
	print("Sprite global_position: ", sprite.global_position)
	print("Sprite scale: ", sprite.scale)
	print("Sprite modulate: ", sprite.modulate)
	print("Canvas layer: ", canvas_layer.layer)
	print("Sprite z_index: ", sprite.z_index)
	
	find_player()
	
	if orbit_around_player and player and is_instance_valid(player):
		var player_pos = get_player_screen_position()
		cursor_position = player_pos + Vector2(orbit_min_distance + 50, 0)
		print("Starting cursor near player at: ", cursor_position)
	else:
		var viewport_size = get_viewport().get_visible_rect().size
		cursor_position = viewport_size / 2
		print("Starting cursor at screen center: ", cursor_position)
	
	sprite.position = cursor_position
	
	print("Virtual cursor activated")
	print("===========================")

func deactivate():
	is_active = false
	if canvas_layer:
		canvas_layer.visible = false
	if sprite:
		sprite.visible = false
	
	hovered_control = null
	
	print("Virtual cursor deactivated")

func create_default_cursor() -> ImageTexture:
	var size = 32
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center = size / 2
	var arm_length = 12
	var thickness = 3
	
	for i in range(size):
		if abs(i - center) < arm_length:
			for t in range(thickness):
				var offset = t - thickness / 2
				if center + offset >= 0 and center + offset < size:
					image.set_pixel(i, center + offset, Color.WHITE)
		
		if abs(i - center) < arm_length:
			for t in range(thickness):
				var offset = t - thickness / 2
				if center + offset >= 0 and center + offset < size:
					image.set_pixel(center + offset, i, Color.WHITE)
	
	for x in range(center - 3, center + 4):
		for y in range(center - 3, center + 4):
			if x >= 0 and x < size and y >= 0 and y < size:
				if (x - center) * (x - center) + (y - center) * (y - center) <= 9:
					image.set_pixel(x, y, Color.RED)
	
	var texture = ImageTexture.create_from_image(image)
	print("Default cursor texture created: ", texture.get_size())
	return texture

func set_cursor_texture(texture: Texture2D):
	print("Setting cursor texture: ", texture)
	if sprite:
		sprite.texture = texture
		sprite.visible = true
		
		if texture:
			var tex_size = texture.get_size()
			print("Texture size: ", tex_size)
			if tex_size.x > 0 and tex_size.y > 0:
				sprite.scale = cursor_size / tex_size
				print("Sprite scale: ", sprite.scale)

func set_cursor_color(color: Color):
	cursor_color = color
	if sprite:
		sprite.modulate = color

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

func force_activate():
	activate()

func force_deactivate():
	deactivate()

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func get_player_screen_position() -> Vector2:
	if not player or not is_instance_valid(player):
		return get_viewport().get_visible_rect().size / 2
	
	var camera = get_viewport().get_camera_2d()
	if camera:
		var player_global = player.global_position
		var screen_pos = player_global - camera.global_position + get_viewport().get_visible_rect().size / 2
		return screen_pos
	else:
		return player.global_position

func set_orbit_enabled(enabled: bool):
	orbit_around_player = enabled
	print(">>> Virtual Cursor: Orbit mode ", "ENABLED" if enabled else "DISABLED", " <<<")

func set_orbit_distance(min_dist: float, max_dist: float):
	orbit_min_distance = min_dist
	orbit_max_distance = max_dist

func on_menu_opened():
	set_orbit_enabled(false)
	print("Menu opened - cursor unlocked")

func on_menu_closed():
	set_orbit_enabled(true)
	print("Menu closed - cursor locked to orbit")

func set_cursor_sensitivity(sensitivity: float):
	cursor_speed = sensitivity
