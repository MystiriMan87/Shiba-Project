extends Control

# Audio sliders
var master_slider: HSlider
var master_value: Label
var music_slider: HSlider
var music_value: Label
var sfx_slider: HSlider
var sfx_value: Label

# Video controls
var fullscreen_checkbox: CheckBox
var vsync_option: OptionButton
var resolution_option: OptionButton

func _ready():
	# Find all UI elements
	find_ui_elements()
	
	# Connect signals
	connect_signals()
	
	# Load current settings
	load_current_settings()

func find_ui_elements():
	# Find audio controls
	var audio_section = find_child("AudioSelection")
	if audio_section:
		var master_volume = audio_section.find_child("MasterVolume")
		if master_volume:
			master_slider = master_volume.find_child("HSlider")
			master_value = master_volume.find_child("Value")
		
		var music_volume = audio_section.find_child("MusicVolume")
		if music_volume:
			music_slider = music_volume.find_child("HSlider")
			music_value = music_volume.find_child("Value")
		
		var sfx_volume = audio_section.find_child("SFXVolume")
		if sfx_volume:
			sfx_slider = sfx_volume.find_child("HSlider")
			sfx_value = sfx_volume.find_child("Value")
	
	# Find video controls
	var video_section = find_child("VideoSection")
	if video_section:
		var fullscreen_container = video_section.find_child("Fullscreen")
		if fullscreen_container:
			fullscreen_checkbox = fullscreen_container.find_child("CheckBox")
		
		var vsync_container = video_section.find_child("VSync")
		if vsync_container:
			# Try to find OptionButton first, fallback to CheckBox if not converted yet
			vsync_option = vsync_container.find_child("OptionButton")
			if not vsync_option:
				vsync_option = vsync_container.find_child("CheckBox")
		
		var resolution_container = video_section.find_child("Resolution")
		if resolution_container:
			resolution_option = resolution_container.find_child("OptionButton")

func connect_signals():
	# Connect audio sliders
	if master_slider:
		master_slider.value_changed.connect(_on_master_volume_changed)
		master_slider.min_value = 0
		master_slider.max_value = 100
		master_slider.step = 1
		print("Master slider connected")
	else:
		print("ERROR: Master slider not found!")
	
	if music_slider:
		music_slider.value_changed.connect(_on_music_volume_changed)
		music_slider.min_value = 0
		music_slider.max_value = 100
		music_slider.step = 1
		print("Music slider connected")
	else:
		print("ERROR: Music slider not found!")
	
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
		sfx_slider.min_value = 0
		sfx_slider.max_value = 100
		sfx_slider.step = 1
		print("SFX slider connected")
	else:
		print("ERROR: SFX slider not found!")
	
	# Connect video controls
	if fullscreen_checkbox:
		fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
		print("Fullscreen checkbox connected")
	
	if vsync_option:
		vsync_option.item_selected.connect(_on_vsync_selected)
		vsync_option.clear()
		vsync_option.add_item("Disabled")
		vsync_option.add_item("Enabled")
		vsync_option.add_item("30 FPS")
		vsync_option.add_item("60 FPS")
		vsync_option.add_item("120 FPS")
		vsync_option.add_item("144 FPS")
		print("VSync option button connected")
	else:
		print("ERROR: VSync control not found!")
	
	if resolution_option:
		resolution_option.item_selected.connect(_on_resolution_selected)
		# Add resolution options
		resolution_option.clear()
		resolution_option.add_item("1920x1080")
		resolution_option.add_item("1680x1050")
		resolution_option.add_item("1600x900")
		resolution_option.add_item("1366x768")
		resolution_option.add_item("1280x720")
		print("Resolution dropdown connected")

func load_current_settings():
	# Load audio settings
	if master_slider:
		master_slider.value = SettingsManager.settings.audio.master_volume * 100
		if master_value:
			master_value.text = str(int(master_slider.value)) + "%"
	
	if music_slider:
		music_slider.value = SettingsManager.settings.audio.music_volume * 100
		if music_value:
			music_value.text = str(int(music_slider.value)) + "%"
	
	if sfx_slider:
		sfx_slider.value = SettingsManager.settings.audio.sfx_volume * 100
		if sfx_value:
			sfx_value.text = str(int(sfx_slider.value)) + "%"
	
	# Load video settings
	if fullscreen_checkbox:
		fullscreen_checkbox.button_pressed = SettingsManager.settings.video.fullscreen
	
	if vsync_option and vsync_option is OptionButton:
		var vsync_mode = SettingsManager.settings.video.get("vsync_mode", 1)
		vsync_option.selected = vsync_mode
	
	if resolution_option:
		var current_res = SettingsManager.settings.video.resolution
		var res_string = str(current_res.x) + "x" + str(current_res.y)
		for i in resolution_option.item_count:
			if resolution_option.get_item_text(i) == res_string:
				resolution_option.selected = i
				break

# Audio callbacks
func _on_master_volume_changed(value: float):
	var normalized_value = value / 100.0
	SettingsManager.set_master_volume(normalized_value)
	if master_value:
		master_value.text = str(int(value)) + "%"
	print("Master volume changed to: ", normalized_value)

func _on_music_volume_changed(value: float):
	var normalized_value = value / 100.0
	SettingsManager.set_music_volume(normalized_value)
	if music_value:
		music_value.text = str(int(value)) + "%"
	print("Music volume changed to: ", normalized_value)

func _on_sfx_volume_changed(value: float):
	var normalized_value = value / 100.0
	SettingsManager.set_sfx_volume(normalized_value)
	if sfx_value:
		sfx_value.text = str(int(value)) + "%"
	print("SFX volume changed to: ", normalized_value)

# Video callbacks
func _on_fullscreen_toggled(button_pressed: bool):
	SettingsManager.set_fullscreen(button_pressed)
	print("Fullscreen toggled: ", button_pressed)

func _on_vsync_selected(index: int):
	SettingsManager.set_vsync_mode(index)
	print("VSync mode changed to: ", index)

# Fallback for if CheckBox hasn't been converted yet
func _on_vsync_checkbox_fallback(button_pressed: bool):
	SettingsManager.set_vsync_mode(1 if button_pressed else 0)
	print("VSync toggled (fallback): ", button_pressed)

func _on_resolution_selected(index: int):
	if resolution_option:
		var res_string = resolution_option.get_item_text(index)
		var parts = res_string.split("x")
		if parts.size() == 2:
			var resolution = Vector2i(int(parts[0]), int(parts[1]))
			SettingsManager.set_resolution(resolution)
			print("Resolution changed to: ", resolution)

# Back button (connect this in the editor or find it here)
func _on_back_pressed():
	SettingsManager.save_settings()
	get_tree().change_scene_to_file("res://main_menu.tscn")
