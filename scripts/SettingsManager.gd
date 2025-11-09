extends Node

const SETTINGS_FILE = "user://settings.json"

var settings = {
	"video": {
		"fullscreen": false,
		"vsync_mode": 1,  # Changed from vsync to vsync_mode
		"resolution": Vector2i(1920, 1080)
	},
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.7,
		"sfx_volume": 0.8
	},
	"gameplay": {
		"language": "en"
	}
}

# Extended resolution options including lower resolutions for weak platforms
const AVAILABLE_RESOLUTIONS = [
	Vector2i(7680, 4320),  # 8K
	Vector2i(3840, 2160),  # 4K
	Vector2i(2560, 1440),  # 2K/QHD
	Vector2i(1920, 1080),  # Full HD
	Vector2i(1680, 1050),  # WSXGA+
	Vector2i(1600, 900),   # HD+
	Vector2i(1440, 900),   # WXGA+
	Vector2i(1366, 768),   # HD (Common laptop)
	Vector2i(1280, 720),   # HD Ready
	Vector2i(1024, 768),   # XGA
	Vector2i(960, 540),    # qHD (Quarter HD)
	Vector2i(854, 480),    # FWVGA
	Vector2i(800, 600),    # SVGA (Weak devices)
	Vector2i(640, 480),    # VGA (Very weak devices)
	Vector2i(640, 360),    # nHD (Mobile/Very weak)
	Vector2i(480, 320),    # HVGA (Extremely weak)
]

func _ready():
	load_settings()
	apply_settings()

func load_settings():
	if not FileAccess.file_exists(SETTINGS_FILE):
		print("No settings file found, using defaults")
		save_settings()
		return
	
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if not file:
		print("Failed to open settings file")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result == OK:
		var loaded_data = json.data
		# Merge loaded settings with defaults
		merge_settings(loaded_data)
		print("Settings loaded successfully")
	else:
		print("Failed to parse settings JSON")

func merge_settings(loaded_data):
	for category in loaded_data:
		if category in settings:
			for key in loaded_data[category]:
				# Special handling for resolution (convert Array to Vector2i)
				if key == "resolution" and loaded_data[category][key] is Array:
					var res_array = loaded_data[category][key]
					if res_array.size() == 2:
						var loaded_res = Vector2i(res_array[0], res_array[1])
						# Validate resolution is reasonable (not too small)
						if loaded_res.x >= 480 and loaded_res.y >= 320:
							settings[category][key] = loaded_res
						else:
							print("Invalid resolution in settings: ", loaded_res, " - using default")
							settings[category][key] = Vector2i(1920, 1080)
				else:
					settings[category][key] = loaded_data[category][key]

func save_settings():
	var save_data = settings.duplicate(true)
	
	# Convert Vector2i to Array for JSON serialization
	if save_data.video.resolution is Vector2i:
		save_data.video.resolution = [save_data.video.resolution.x, save_data.video.resolution.y]
	
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if not file:
		print("Failed to save settings file")
		return
	
	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()
	print("Settings saved")

func apply_settings():
	apply_video_settings()
	apply_audio_settings()
	apply_gameplay_settings()

func apply_video_settings():
	var resolution = settings.video.resolution
	
	print("=== Applying Video Settings ===")
	print("Resolution: ", resolution)
	print("Fullscreen: ", settings.video.fullscreen)
	
	# First set the window mode
	if settings.video.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		# In fullscreen, the resolution is handled by the display
		DisplayServer.window_set_size(resolution)
	else:
		# Set to windowed mode first
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
		# IMPORTANT: Set the window size
		DisplayServer.window_set_size(resolution)
		
		# Wait a frame for the window to resize
		await get_tree().process_frame
		
		# Center the window on screen
		var screen_size = DisplayServer.screen_get_size()
		var window_size = DisplayServer.window_get_size()
		var centered_pos = (screen_size - window_size) / 2
		DisplayServer.window_set_position(centered_pos)
		
		print("Window size set to: ", DisplayServer.window_get_size())
	
	# Apply VSync mode
	var vsync_mode = settings.video.get("vsync_mode", 1)
	match vsync_mode:
		0:  # Disabled
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		1:  # Enabled
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		2:  # Adaptive
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
		3:  # Mailbox
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_MAILBOX)
	
	print("Video settings applied successfully")

func apply_audio_settings():
	# Master Volume
	var master_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(settings.audio.master_volume))
	AudioServer.set_bus_mute(master_bus, settings.audio.master_volume <= 0.0)
	
	# Music Volume
	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(settings.audio.music_volume))
		AudioServer.set_bus_mute(music_bus, settings.audio.music_volume <= 0.0)
	
	# SFX Volume
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(settings.audio.sfx_volume))
		AudioServer.set_bus_mute(sfx_bus, settings.audio.sfx_volume <= 0.0)

func apply_gameplay_settings():
	# Language
	if has_node("/root/LocalizationManager"):
		LocalizationManager.set_language(settings.gameplay.language)

func set_fullscreen(enabled: bool):
	settings.video.fullscreen = enabled
	apply_video_settings()
	save_settings()

func set_vsync_mode(mode: int):
	settings.video.vsync_mode = mode
	apply_video_settings()
	save_settings()

func set_vsync(enabled: bool):
	# Legacy function for backward compatibility
	settings.video.vsync_mode = 1 if enabled else 0
	apply_video_settings()
	save_settings()

func set_resolution(resolution: Vector2i):
	print("=== Setting Resolution ===")
	print("Requested: ", resolution)
	
	# Validate resolution is in available list
	if resolution in AVAILABLE_RESOLUTIONS:
		settings.video.resolution = resolution
		print("Resolution accepted")
	else:
		print("Warning: Resolution not in available list, but applying anyway: ", resolution)
		settings.video.resolution = resolution
	
	apply_video_settings()
	save_settings()

func set_master_volume(volume: float):
	settings.audio.master_volume = clamp(volume, 0.0, 1.0)
	apply_audio_settings()

func set_music_volume(volume: float):
	settings.audio.music_volume = clamp(volume, 0.0, 1.0)
	apply_audio_settings()

func set_sfx_volume(volume: float):
	settings.audio.sfx_volume = clamp(volume, 0.0, 1.0)
	apply_audio_settings()

func set_language(language_code: String):
	settings.gameplay.language = language_code
	apply_gameplay_settings()

func get_available_resolutions() -> Array:
	return AVAILABLE_RESOLUTIONS

func get_resolution_string(resolution: Vector2i) -> String:
	var aspect_ratio = float(resolution.x) / float(resolution.y)
	var ratio_string = ""
	
	# Determine aspect ratio
	if abs(aspect_ratio - 16.0/9.0) < 0.01:
		ratio_string = " (16:9)"
	elif abs(aspect_ratio - 16.0/10.0) < 0.01:
		ratio_string = " (16:10)"
	elif abs(aspect_ratio - 4.0/3.0) < 0.01:
		ratio_string = " (4:3)"
	elif abs(aspect_ratio - 3.0/2.0) < 0.01:
		ratio_string = " (3:2)"
	
	# Add quality descriptor
	var quality = ""
	if resolution.x >= 3840:
		quality = " [4K+]"
	elif resolution.x >= 2560:
		quality = " [2K]"
	elif resolution.x >= 1920:
		quality = " [Full HD]"
	elif resolution.x >= 1280:
		quality = " [HD]"
	elif resolution.x >= 800:
		quality = " [SD]"
	else:
		quality = " [Low]"
	
	return str(resolution.x) + "x" + str(resolution.y) + ratio_string + quality

func reset_to_defaults():
	settings = {
		"video": {
			"fullscreen": false,
			"vsync_mode": 1,
			"resolution": get_viewport().set_size(Vector2i(640, 480))
		},
		"audio": {
			"master_volume": 1.0,
			"music_volume": 0.7,
			"sfx_volume": 0.8
		},
		"gameplay": {
			"language": "en"
		}
	}
	apply_settings()
	save_settings()
