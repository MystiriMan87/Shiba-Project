extends Label

# Timer variables
var elapsed_time: float = 0.0
var is_running: bool = true

func _ready():
	# Position at top center
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_top = 10
	offset_bottom = 50
	
	# Style the label
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_TOP
	add_theme_font_size_override("font_size", 24)
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_color_override("font_shadow_color", Color.BLACK)
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)
	
	text = "Time: 0:00.00"
	z_index = 100  # Make sure it's on top
	
	# Listen for level changes
	get_tree().node_added.connect(_on_node_added)

func _process(delta):
	if is_running:
		elapsed_time += delta
		update_display()

func update_display():
	var minutes = int(elapsed_time) / 60
	var seconds = int(elapsed_time) % 60
	var milliseconds = int((elapsed_time - int(elapsed_time)) * 100)
	text = "Time: %d:%02d.%02d" % [minutes, seconds, milliseconds]

func start_timer():
	elapsed_time = 0.0
	is_running = true

func stop_timer():
	is_running = false
	print("Timer stopped at: ", text)

func resume_timer():
	is_running = true

func reset_timer():
	elapsed_time = 0.0
	is_running = false
	update_display()

func get_elapsed_time() -> float:
	return elapsed_time

func get_formatted_time() -> String:
	var minutes = int(elapsed_time) / 60
	var seconds = int(elapsed_time) % 60
	var milliseconds = int((elapsed_time - int(elapsed_time)) * 100)
	return "%d:%02d.%02d" % [minutes, seconds, milliseconds]

# Detect level changes - customize this based on your game
func _on_node_added(node):
	# Stop timer when a new level/world scene is loaded
	if node.scene_file_path != "" and ("level" in node.scene_file_path.to_lower() or "world" in node.scene_file_path.to_lower()):
		if node != get_tree().current_scene:  # Don't stop on initial load
			stop_timer()
