extends Node

func _ready():
	# Wait for window to initialize
	await get_tree().process_frame
	
	# Force window properties
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	get_tree().root.size = Vector2i(1920, 1080)
	
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	
	# Center window
	await get_tree().process_frame
	var screen_size = DisplayServer.screen_get_size()
	var window_pos = (screen_size - Vector2i(1920, 1080)) / 2
	DisplayServer.window_set_position(window_pos)
	
	print("Window forced to 1920x1080")
