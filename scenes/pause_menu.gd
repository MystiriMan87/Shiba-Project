extends CanvasLayer

@onready var pause_panel: Panel = null
@onready var resume_button: Button = null
@onready var main_menu_button: Button = null
@onready var quit_button: Button = null

var is_paused: bool = false

func _ready():
	print("=== PAUSE MENU READY ===")
	
	# CRITICAL: Make sure THIS node processes when paused, but nothing else does
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Get nodes
	pause_panel = get_node_or_null("PausePanel")
	print("PausePanel found: ", pause_panel != null)
	
	if pause_panel:
		# Make sure the panel also processes when paused (so it stays visible)
		pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
		
		var vbox = pause_panel.get_node_or_null("VBoxContainer")
		print("VBoxContainer found: ", vbox != null)
		
		if vbox:
			# Make VBox and buttons work when paused
			vbox.process_mode = Node.PROCESS_MODE_ALWAYS
			
			resume_button = vbox.get_node_or_null("ResumeButton")
			main_menu_button = vbox.get_node_or_null("MainMenuButton")
			quit_button = vbox.get_node_or_null("QuitButton")
			
			print("ResumeButton found: ", resume_button != null)
			print("MainMenuButton found: ", main_menu_button != null)
			print("QuitButton found: ", quit_button != null)
			
			# Set buttons to work when paused
			if resume_button:
				resume_button.process_mode = Node.PROCESS_MODE_ALWAYS
				resume_button.pressed.connect(_on_resume_pressed)
			if main_menu_button:
				main_menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
				main_menu_button.pressed.connect(_on_main_menu_pressed)
			if quit_button:
				quit_button.process_mode = Node.PROCESS_MODE_ALWAYS
				quit_button.pressed.connect(_on_quit_pressed)
	
	# Hide initially
	hide_pause_menu()
	
	# Add escape key if not already mapped
	if not InputMap.has_action("pause"):
		print("Creating 'pause' action")
		InputMap.add_action("pause")
		var escape_key = InputEventKey.new()
		escape_key.physical_keycode = KEY_ESCAPE
		InputMap.action_add_event("pause", escape_key)
	else:
		print("'pause' action already exists")
	
	print("=== PAUSE MENU SETUP COMPLETE ===")

func _input(event):
	if event.is_action_pressed("pause"):
		print("PAUSE KEY PRESSED!")
		toggle_pause()
		# Important: consume the input so it doesn't propagate to game
		get_viewport().set_input_as_handled()

func toggle_pause():
	print("Toggle pause called. Current state: ", is_paused)
	is_paused = !is_paused
	
	if is_paused:
		print("Showing pause menu")
		show_pause_menu()
	else:
		print("Hiding pause menu")
		hide_pause_menu()

func show_pause_menu():
	print("show_pause_menu() called")
	
	# FIRST: Show the menu
	if pause_panel:
		pause_panel.visible = true
		print("Panel set to visible")
	else:
		print("ERROR: pause_panel is null!")
	
	# THEN: Pause the game
	get_tree().paused = true
	is_paused = true
	print("Game paused: ", get_tree().paused)
	
	# Make sure all game nodes are actually paused
	verify_pause_mode()

func hide_pause_menu():
	print("hide_pause_menu() called")
	
	# FIRST: Unpause the game
	get_tree().paused = false
	is_paused = false
	
	# THEN: Hide the menu
	if pause_panel:
		pause_panel.visible = false

func verify_pause_mode():
	# Check if any nodes have incorrect process modes
	var scene_root = get_tree().current_scene
	if scene_root:
		print("Checking scene root process mode: ", scene_root.process_mode)
		if scene_root.process_mode == Node.PROCESS_MODE_ALWAYS:
			print("WARNING: Scene root is set to ALWAYS process! This prevents pausing.")

func _on_resume_pressed():
	print("Resume pressed")
	hide_pause_menu()

func _on_main_menu_pressed():
	print("Main menu pressed")
	# Unpause before changing scenes
	get_tree().paused = false
	is_paused = false
	
	# Change to main menu
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_quit_pressed():
	print("Quit pressed")
	get_tree().paused = false
	get_tree().quit()
