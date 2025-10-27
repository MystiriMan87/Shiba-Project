extends Control

@export var fade_in_duration: float = 0.5
@export var fade_out_duration: float = 0.3
@export var respawn_delay: float = 5.0
@export var respawn_scene: String = "res://scenes/Hub.tscn"

var player: CharacterBody2D = null
var main_ui: Control = null
var is_showing: bool = false

var game_start_time: float = 0.0
var enemies_killed: int = 0
var survival_time: float = 0.0

@onready var background: ColorRect = null
@onready var death_panel: Panel = null
@onready var death_label: Label = null
@onready var respawn_button: Button = null
@onready var stats_container: VBoxContainer = null
@onready var survival_time_label: Label = null
@onready var enemies_killed_label: Label = null

func _ready():
	# Make sure this node processes when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	player = get_tree().get_first_node_in_group("player")
	main_ui = get_parent() if get_parent().name == "UI" else null
	
	if not player:
		print("⚠ Warning: Player not found in 'player' group for DeathScreen")
	else:
		print("✓ DeathScreen found player")
	
	game_start_time = Time.get_unix_time_from_system()
	
	setup_death_screen_ui()
	
	# Connect to player signals
	if player:
		if player.has_signal("player_died"):
			if not player.player_died.is_connected(_on_player_died):
				player.player_died.connect(_on_player_died)
				print("✓ DeathScreen connected to player_died signal")
		
		if player.has_signal("enemy_killed"):
			if not player.enemy_killed.is_connected(_on_enemy_killed):
				player.enemy_killed.connect(_on_enemy_killed)
				print("✓ DeathScreen connected to enemy_killed signal")
	
	# Start hidden
	visible = false
	modulate.a = 0.0

func setup_death_screen_ui():
	# Set to full screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Semi-transparent background
	background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0.0, 0.0, 0.0, 0.8)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	
	# Main death panel
	death_panel = Panel.new()
	death_panel.name = "DeathPanel"
	death_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	death_panel.size = Vector2(500, 400)
	death_panel.position = Vector2(-250, -200)
	
	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.05, 0.05, 0.95)
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_color = Color(0.7, 0.2, 0.2, 1.0)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	death_panel.add_theme_stylebox_override("panel", panel_style)
	
	add_child(death_panel)
	
	# Content container
	var content_container = VBoxContainer.new()
	content_container.name = "ContentContainer"
	content_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_container.offset_left = 20
	content_container.offset_top = 20
	content_container.offset_right = -20
	content_container.offset_bottom = -20
	content_container.add_theme_constant_override("separation", 20)
	death_panel.add_child(content_container)
	
	# Top spacer
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 30)
	content_container.add_child(top_spacer)
	
	# "YOU DIED" label
	death_label = Label.new()
	death_label.name = "DeathLabel"
	death_label.text = "YOU DIED"
	death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	death_label.add_theme_font_size_override("font_size", 48)
	death_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	death_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	death_label.add_theme_constant_override("shadow_offset_x", 4)
	death_label.add_theme_constant_override("shadow_offset_y", 4)
	content_container.add_child(death_label)
	
	# Middle spacer
	var middle_spacer = Control.new()
	middle_spacer.custom_minimum_size = Vector2(0, 20)
	content_container.add_child(middle_spacer)
	
	# Stats container
	stats_container = VBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.add_theme_constant_override("separation", 15)
	content_container.add_child(stats_container)
	
	# Survival time label
	survival_time_label = Label.new()
	survival_time_label.name = "SurvivalTimeLabel"
	survival_time_label.text = "Survival Time: 0:00"
	survival_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	survival_time_label.add_theme_font_size_override("font_size", 20)
	survival_time_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	survival_time_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	survival_time_label.add_theme_constant_override("shadow_offset_x", 2)
	survival_time_label.add_theme_constant_override("shadow_offset_y", 2)
	stats_container.add_child(survival_time_label)
	
	# Enemies killed label
	enemies_killed_label = Label.new()
	enemies_killed_label.name = "EnemiesKilledLabel"
	enemies_killed_label.text = "Enemies Defeated: 0"
	enemies_killed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemies_killed_label.add_theme_font_size_override("font_size", 20)
	enemies_killed_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	enemies_killed_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	enemies_killed_label.add_theme_constant_override("shadow_offset_x", 2)
	enemies_killed_label.add_theme_constant_override("shadow_offset_y", 2)
	stats_container.add_child(enemies_killed_label)
	
	# Bottom spacer (expands to push button down)
	var expand_spacer = Control.new()
	expand_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.add_child(expand_spacer)
	
	# Button container
	var button_container = CenterContainer.new()
	content_container.add_child(button_container)
	
	# Respawn button
	respawn_button = Button.new()
	respawn_button.name = "RespawnButton"
	respawn_button.text = "RESPAWN"
	respawn_button.custom_minimum_size = Vector2(250, 60)
	respawn_button.add_theme_font_size_override("font_size", 24)
	
	# Button normal style
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	button_style.border_width_top = 3
	button_style.border_width_bottom = 3
	button_style.border_width_left = 3
	button_style.border_width_right = 3
	button_style.border_color = Color(0.8, 0.3, 0.3, 1.0)
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_left = 8
	button_style.corner_radius_bottom_right = 8
	respawn_button.add_theme_stylebox_override("normal", button_style)
	
	# Button hover style
	var button_hover_style = button_style.duplicate()
	button_hover_style.bg_color = Color(0.8, 0.3, 0.3, 1.0)
	button_hover_style.border_color = Color(1.0, 0.5, 0.5, 1.0)
	respawn_button.add_theme_stylebox_override("hover", button_hover_style)
	
	# Button pressed style
	var button_pressed_style = button_style.duplicate()
	button_pressed_style.bg_color = Color(0.5, 0.15, 0.15, 1.0)
	respawn_button.add_theme_stylebox_override("pressed", button_pressed_style)
	
	# Button font colors
	respawn_button.add_theme_color_override("font_color", Color.WHITE)
	respawn_button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	respawn_button.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9, 1.0))
	respawn_button.add_theme_color_override("font_shadow_color", Color.BLACK)
	respawn_button.add_theme_constant_override("shadow_offset_x", 2)
	respawn_button.add_theme_constant_override("shadow_offset_y", 2)
	
	button_container.add_child(respawn_button)
	
	# Connect button
	respawn_button.pressed.connect(_on_respawn_button_pressed)
	
	# Bottom padding
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 20)
	content_container.add_child(bottom_spacer)

func show_death_screen():
	if is_showing:
		return
	
	print("=== SHOWING DEATH SCREEN ===")
	is_showing = true
	visible = true
	
	calculate_survival_time()
	update_stats_display()
	
	# Pause the game
	get_tree().paused = true
	
	# Fade in animation
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)
	
	play_death_sound()
	print("Death screen shown - Survival: ", int(survival_time), "s, Kills: ", enemies_killed)

func hide_death_screen():
	if not is_showing:
		return
	
	print("=== HIDING DEATH SCREEN ===")
	is_showing = false
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 0.0, fade_out_duration)
	tween.tween_callback(func():
		visible = false
		get_tree().paused = false
		print("Death screen hidden, game unpaused")
	)

func calculate_survival_time():
	var current_time = Time.get_unix_time_from_system()
	survival_time = current_time - game_start_time

func update_stats_display():
	if survival_time_label:
		var minutes = int(survival_time) / 60
		var seconds = int(survival_time) % 60
		survival_time_label.text = "Survival Time: %d:%02d" % [minutes, seconds]
	
	if enemies_killed_label:
		enemies_killed_label.text = "Enemies Defeated: %d" % enemies_killed

func _on_player_died():
	print(">>> DeathScreen received player_died signal! <<<")
	show_death_screen()

func _on_enemy_killed():
	enemies_killed += 1

func _on_respawn_button_pressed():
	print("Respawn button pressed")
	respawn_player()

func respawn_player():
	if not player:
		print("Error: No player reference for respawn")
		return
	
	print("Respawning player...")
	hide_death_screen()
	
	# Wait for fade out (use timer that works when paused)
	await get_tree().create_timer(fade_out_duration, true, false, true).timeout
	
	# Unpause the game before changing scenes
	get_tree().paused = false
	
	# Reset game stats
	reset_game_stats()
	
	# Change to the respawn scene (Hub)
	if respawn_scene != "" and ResourceLoader.exists(respawn_scene):
		print("Loading respawn scene: ", respawn_scene)
		get_tree().change_scene_to_file(respawn_scene)
	else:
		print("⚠ Warning: Respawn scene not found or not set: ", respawn_scene)
		# Fallback: just reset player in current scene
		reset_player_state()

func reset_player_state():
	if not player:
		return
	
	print("Resetting player state in current scene")
	
	# Restore full health
	player.current_health = player.max_health
	if player.has_signal("health_changed"):
		player.health_changed.emit(player.current_health)
	
	# Clear damage/knockback states
	player.damage_immunity_timer = 0.0
	player.player_knockback_velocity = Vector2.ZERO
	player.is_taking_damage = false
	
	# Reset sprite appearance
	if player.sprite:
		player.sprite.modulate = Color.WHITE
	
	# Restore dash energy
	if "dash_energy" in player and "max_dash_energy" in player:
		player.dash_energy = player.max_dash_energy
		if player.has_signal("dash_energy_changed"):
			player.dash_energy_changed.emit(player.dash_energy)
	
	# Move to spawn point
	var spawn_point = get_tree().get_first_node_in_group("player_spawn")
	if spawn_point:
		player.global_position = spawn_point.global_position
		print("Respawned at spawn point: ", spawn_point.global_position)
	else:
		player.global_position = Vector2(0, 0)
		print("Respawned at origin (no spawn point found)")
	
	# Update UI
	if main_ui and main_ui.has_method("update_health_display"):
		main_ui.update_health_display()
	
	print("✓ Player respawned successfully!")

func reset_game_stats():
	game_start_time = Time.get_unix_time_from_system()
	enemies_killed = 0
	survival_time = 0.0
	print("✓ Game stats reset")

func play_death_sound():
	# Add  death sound here 
	# if death_audio_player:
	#     death_audio_player.play()
	pass

func _input(event):
	# Allow respawn with Enter/Space key
	if is_showing and event.is_action_pressed("ui_accept"):
		_on_respawn_button_pressed()

# Getters for external access
func get_survival_time() -> float:
	return survival_time

func get_enemies_killed() -> int:
	return enemies_killed

func is_death_screen_showing() -> bool:
	return is_showing
