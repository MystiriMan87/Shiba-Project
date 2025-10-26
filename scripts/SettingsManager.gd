extends Node

const SETTINGS_FILE = "user://settings.cfg"
var config = ConfigFile.new()

var settings = {
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0
	},
	"video": {
		"fullscreen": false,
		"vsync_mode": 3,  # 0=Disabled, 1=Enabled, 2=30fps, 3=60fps, 4=120fps, 5=144fps
		"resolution": Vector2i(1920, 1080)
	},
	"gameplay": {
		"mouse_sensitivity": 0.5,
		"show_fps": false
	}
}

func _ready():
	load_settings()
	apply_settings()

func load_settings():
	var err = config.load(SETTINGS_FILE)
	
	if err != OK:
		print("No settings file found, using defaults")
		save_settings()
		return
	
	for section in settings.keys():
		for key in settings[section].keys():
			if config.has_section_key(section, key):
				settings[section][key] = config.get_value(section, key)
	
	# Migrate old vsync boolean to vsync_mode
	if config.has_section_key("video", "vsync") and not config.has_section_key("video", "vsync_mode"):
		var old_vsync = config.get_value("video", "vsync")
		settings.video.vsync_mode = 1 if old_vsync else 0
		save_settings()
	
	print("Settings loaded successfully")

func save_settings():
	for section in settings.keys():
		for key in settings[section].keys():
			config.set_value(section, key, settings[section][key])
	
	var err = config.save(SETTINGS_FILE)
	if err == OK:
		print("Settings saved successfully")
	else:
		print("Error saving settings: ", err)

func apply_settings():
	apply_audio_settings()
	apply_video_settings()
	apply_gameplay_settings()

func apply_audio_settings():
	var master_bus = AudioServer.get_bus_index("Master")
	var music_bus = AudioServer.get_bus_index("Music")
	var sfx_bus = AudioServer.get_bus_index("SFX")
	
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(settings.audio.master_volume))
	
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(settings.audio.music_volume))
	
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(settings.audio.sfx_volume))

func apply_video_settings():
	# Apply fullscreen/windowed mode
	if settings.video.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(settings.video.resolution)
	
	# Apply VSync mode with framerate caps
	match settings.video.vsync_mode:
		0:  # Disabled
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			Engine.max_fps = 0  # Unlimited
		1:  # Enabled (adaptive - matches monitor)
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			Engine.max_fps = 0  # No cap, monitor decides
		2:  # 30 FPS
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			Engine.max_fps = 30
		3:  # 60 FPS
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			Engine.max_fps = 60
		4:  # 120 FPS
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			Engine.max_fps = 120
		5:  # 144 FPS
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			Engine.max_fps = 144

func apply_gameplay_settings():
	pass

# Audio setters
func set_master_volume(value: float):
	settings.audio.master_volume = value
	apply_audio_settings()

func set_music_volume(value: float):
	settings.audio.music_volume = value
	apply_audio_settings()

func set_sfx_volume(value: float):
	settings.audio.sfx_volume = value
	apply_audio_settings()

# Video setters
func set_fullscreen(enabled: bool):
	settings.video.fullscreen = enabled
	apply_video_settings()

func set_vsync_mode(mode: int):
	settings.video.vsync_mode = mode
	apply_video_settings()

func set_resolution(resolution: Vector2i):
	settings.video.resolution = resolution
	apply_video_settings()

# Gameplay setters
func set_mouse_sensitivity(value: float):
	settings.gameplay.mouse_sensitivity = value

func set_show_fps(enabled: bool):
	settings.gameplay.show_fps = enabled
