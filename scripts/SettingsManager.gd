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
		"vsync": true,
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
	if settings.video.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(settings.video.resolution)
	
	if settings.video.vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func apply_gameplay_settings():
	pass

func set_master_volume(value: float):
	settings.audio.master_volume = value
	apply_audio_settings()

func set_music_volume(value: float):
	settings.audio.music_volume = value
	apply_audio_settings()

func set_sfx_volume(value: float):
	settings.audio.sfx_volume = value
	apply_audio_settings()

func set_fullscreen(enabled: bool):
	settings.video.fullscreen = enabled
	apply_video_settings()

func set_vsync(enabled: bool):
	settings.video.vsync = enabled
	apply_video_settings()

func set_resolution(resolution: Vector2i):
	settings.video.resolution = resolution
	apply_video_settings()

func set_mouse_sensitivity(value: float):
	settings.gameplay.mouse_sensitivity = value

func set_show_fps(enabled: bool):
	settings.gameplay.show_fps = enabled
	
func _on_back_pressed():
		get_tree().change_scene_to_file("res://main_menu.tscn")
