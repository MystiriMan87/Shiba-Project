extends Control

var master_slider: HSlider
var master_value: Label
var music_slider: HSlider
var music_value: Label
var sfx_slider: HSlider
var sfx_value: Label

var fullscreen_checkbox: CheckBox
var vsync_option: OptionButton
var resolution_option: OptionButton

var language_option: OptionButton

func _ready():
	find_ui_elements()
	connect_signals()
	load_current_settings()
	update_ui_text()
	
	if has_node("/root/LocalizationManager"):
		LocalizationManager.language_changed.connect(_on_language_changed)

func find_ui_elements():
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
	
	var video_section = find_child("VideoSection")
	if video_section:
		var fullscreen_container = video_section.find_child("Fullscreen")
		if fullscreen_container:
			fullscreen_checkbox = fullscreen_container.find_child("CheckBox")
		
		var vsync_container = video_section.find_child("VSync")
		if vsync_container:
			vsync_option = vsync_container.find_child("OptionButton")
			if not vsync_option:
				vsync_option = vsync_container.find_child("CheckBox")
		
		var resolution_container = video_section.find_child("Resolution")
		if resolution_container:
			resolution_option = resolution_container.find_child("OptionButton")
	
	var gameplay_section = find_child("GameplaySection")
	if gameplay_section:
		var language_container = gameplay_section.find_child("Language")
		if language_container:
			language_option = language_container.find_child("OptionButton")

func connect_signals():
	if master_slider:
		master_slider.value_changed.connect(_on_master_volume_changed)
		master_slider.min_value = 0
		master_slider.max_value = 100
		master_slider.step = 1
		print("Master slider connected")
	
	if music_slider:
		music_slider.value_changed.connect(_on_music_volume_changed)
		music_slider.min_value = 0
		music_slider.max_value = 100
		music_slider.step = 1
		print("Music slider connected")
	
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
		sfx_slider.min_value = 0
		sfx_slider.max_value = 100
		sfx_slider.step = 1
		print("SFX slider connected")
	
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
	
	if resolution_option:
		resolution_option.item_selected.connect(_on_resolution_selected)
		resolution_option.clear()
		resolution_option.add_item("1920x1080")
		resolution_option.add_item("1680x1050")
		resolution_option.add_item("1600x900")
		resolution_option.add_item("1366x768")
		resolution_option.add_item("1280x720")
		print("Resolution dropdown connected")
	
	if language_option:
		language_option.item_selected.connect(_on_language_selected)
		setup_language_options()
		print("Language dropdown connected")

func setup_language_options():
	if not language_option:
		return
	
	language_option.clear()
	
	# Add English option
	language_option.add_item("English", 0)
	language_option.set_item_metadata(0, "en")
	
	# Add Japanese option with proper UTF-8 encoding
	language_option.add_item("日本語", 1)
	language_option.set_item_metadata(1, "ja")
	
	print("Language options added: English, 日本語")

func load_current_settings():
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
	
	if language_option:
		var current_lang = LocalizationManager.get_current_language()
		for i in language_option.item_count:
			if language_option.get_item_metadata(i) == current_lang:
				language_option.selected = i
				break

func update_ui_text():
	var audio_label = find_child("AudioLabel")
	if audio_label:
		audio_label.text = LocalizationManager.t("audio")
	
	var video_label = find_child("VideoLabel")
	if video_label:
		video_label.text = LocalizationManager.t("video")
	
	var gameplay_label = find_child("GameplayLabel")
	if gameplay_label:
		gameplay_label.text = LocalizationManager.t("gameplay")
	
	var master_container = find_child("MasterVolume")
	if master_container:
		for child in master_container.get_children():
			if child is Label and child.name != "Value":
				child.text = LocalizationManager.t("master_volume")
				break
	
	var music_container = find_child("MusicVolume")
	if music_container:
		for child in music_container.get_children():
			if child is Label and child.name != "Value":
				child.text = LocalizationManager.t("music_volume")
				break
	
	var sfx_container = find_child("SFXVolume")
	if sfx_container:
		for child in sfx_container.get_children():
			if child is Label and child.name != "Value":
				child.text = LocalizationManager.t("sfx_volume")
				break
	
	var fullscreen_container = find_child("Fullscreen")
	if fullscreen_container:
		for child in fullscreen_container.get_children():
			if child is Label:
				child.text = LocalizationManager.t("fullscreen")
				break
	
	var vsync_container = find_child("VSync")
	if vsync_container:
		for child in vsync_container.get_children():
			if child is Label:
				child.text = LocalizationManager.t("vsync")
				break
	
	var resolution_container = find_child("Resolution")
	if resolution_container:
		for child in resolution_container.get_children():
			if child is Label:
				child.text = LocalizationManager.t("resolution")
				break
	
	var language_container = find_child("Language")
	if language_container:
		for child in language_container.get_children():
			if child is Label:
				child.text = LocalizationManager.t("language")
				break
	
	var back_button = find_child("BackButton")
	if back_button:
		back_button.text = LocalizationManager.t("back")

func _on_language_changed(new_lang: String):
	update_ui_text()

func _on_master_volume_changed(value: float):
	var normalized_value = value / 100.0
	SettingsManager.set_master_volume(normalized_value)
	if master_value:
		master_value.text = str(int(value)) + "%"

func _on_music_volume_changed(value: float):
	var normalized_value = value / 100.0
	SettingsManager.set_music_volume(normalized_value)
	if music_value:
		music_value.text = str(int(value)) + "%"

func _on_sfx_volume_changed(value: float):
	var normalized_value = value / 100.0
	SettingsManager.set_sfx_volume(normalized_value)
	if sfx_value:
		sfx_value.text = str(int(value)) + "%"

func _on_fullscreen_toggled(button_pressed: bool):
	SettingsManager.set_fullscreen(button_pressed)

func _on_vsync_selected(index: int):
	SettingsManager.set_vsync_mode(index)

func _on_resolution_selected(index: int):
	if resolution_option:
		var res_string = resolution_option.get_item_text(index)
		var parts = res_string.split("x")
		if parts.size() == 2:
			var resolution = Vector2i(int(parts[0]), int(parts[1]))
			SettingsManager.set_resolution(resolution)

func _on_language_selected(index: int):
	if language_option:
		var lang_code = language_option.get_item_metadata(index)
		LocalizationManager.set_language(lang_code)

func _on_back_pressed():
	SettingsManager.save_settings()
	get_tree().change_scene_to_file("res://main_menu.tscn")
