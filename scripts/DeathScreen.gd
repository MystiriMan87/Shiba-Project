extends Control

@export var fade_in_duration: float = 0.5
@export var fade_out_duration: float = 0.3
@export var respawn_delay: float = 1.0

var player: CharacterBody2D = null
var main_ui: Control = null
var is_showing: bool = false

@onready var background: ColorRect = null
@onready var death_panel: Panel = null
@onready var death_label: Label = null
@onready var respawn_button: Button = null
@onready var stats_container: VBoxContainer = null
@onready var survival_time_label: Label = null
@onready var enemies_killed_label: Label = null

@export var respawn_scene: String = "res://scenes/Hub.tscn"


var game_start_time: float = 0.0
var enemies_killed: int = 0
var survival_time: float = 0.0

func _ready():
	player = get_tree().get_first_node_in_group("player")
	main_ui = get_parent() if get_parent().name == "UI" else null
	
	if not player:
		print("Warning: Player not found in 'player' group for DeathScreen")
	
	game_start_time = Time.get_time_dict_from_system()["unix"]
	
	setup_death_screen_ui()
	
	if player:
		if player.has_signal("player_died"):
			if not player.player_died.is_connected(_on_player_died):
				player.player_died.connect(_on_player_died)
	
	visible = false
	modulate.a = 0.0

func setup_death_screen_ui():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0.0, 0.0, 0.0, 0.7)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	
	death_panel = Panel.new()
	death_panel.name = "DeathPanel"
	death_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	death_panel.size = Vector2(400, 300)
	death_panel.position = Vector2(-200, -150)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.05, 0.05, 0.95)
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_color = Color(0.6, 0.2, 0.2)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	death_panel.add_theme_stylebox_override("panel", panel_style)
	
	add_child(death_panel)
	
	var content_container = VBoxContainer.new()
	content_container.name = "ContentContainer"
	content_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_container.add_theme_constant_override("separation", 20)
	death_panel.add_child(content_container)
	
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 30)
	content_container.add_child(top_spacer)
	
	death_label = Label.new()
	death_label.name = "DeathLabel"
	death_label.text = "YOU DIED"
	death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	death_label.add_theme_font_size_override("font_size", 32)
	death_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	death_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	death_label.add_theme_constant_override("shadow_offset_x", 3)
	death_label.add_theme_constant_override("shadow_offset_y", 3)
	content_container.add_child(death_label)
	
	stats_container = VBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.add_theme_constant_override("separation", 10)
	content_container.add_child(stats_container)
	
	survival_time_label = Label.new()
	survival_time_label.name = "SurvivalTimeLabel"
	survival_time_label.text = "Survival Time: 0:00"
	survival_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	survival_time_label.add_theme_font_size_override("font_size", 16)
	survival_time_label.add_theme_color_override("font_color", Color.WHITE)
	survival_time_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	survival_time_label.add_theme_constant_override("shadow_offset_x", 1)
	survival_time_label.add_theme_constant_override("shadow_offset_y", 1)
	stats_container.add_child(survival_time_label)
	
	enemies_killed_label = Label.new()
	enemies_killed_label.name = "EnemiesKilledLabel"
	enemies_killed_label.text = "Enemies Defeated: 0"
	enemies_killed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemies_killed_label.add_theme_font_size_override("font_size", 16)
	enemies_killed_label.add_theme_color_override("font_color", Color.WHITE)
	enemies_killed_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	enemies_killed_label.add_theme_constant_override("shadow_offset_x", 1)
	enemies_killed_label.add_theme_constant_override("shadow_offset_y", 1)
	stats_container.add_child(enemies_killed_label)
	
	var button_spacer = Control.new()
	button_spacer.custom_minimum_size = Vector2(0, 20)
	content_container.add_child(button_spacer)
	
	respawn_button = Button.new()
	respawn_button.name = "RespawnButton"
	respawn_button.text = "RESPAWN"
	respawn_button.custom_minimum_size = Vector2(200, 50)
	respawn_button.add_theme_font_size_override("font_size", 18)
	
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.6, 0.2, 0.2)
	button_style.border_width_top = 2
	button_style.border_width_bottom = 2
	button_style.border_width_left = 2
	button_style.border_width_right = 2
	button_style.border_color = Color(0.8, 0.3, 0.3)
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_left = 8
	button_style.corner_radius_bottom_right = 8
	respawn_button.add_theme_stylebox_override("normal", button_style)
	
	var button_hover_style = button_style.duplicate()
	button_hover_style.bg_color = Color(0.7, 0.3, 0.3)
	respawn_button.add_theme_stylebox_override("hover", button_hover_style)
	
	var button_pressed_style = button_style.duplicate()
	button_pressed_style.bg_color = Color(0.5, 0.15, 0.15)
	respawn_button.add_theme_stylebox_override("pressed", button_pressed_style)
	
	respawn_button.add_theme_color_override("font_color", Color.WHITE)
	respawn_button.add_theme_color_override("font_shadow_color", Color.BLACK)
	respawn_button.add_theme_constant_override("shadow_offset_x", 2)
	respawn_button.add_theme_constant_override("shadow_offset_y", 2)
	
	var button_container = CenterContainer.new()
	button_container.add_child(respawn_button)
	content_container.add_child(button_container)
	
	respawn_button.pressed.connect(_on_respawn_button_pressed)

func show_death_screen():
	if is_showing:
		return
	
	is_showing = true
	visible = true
	
	calculate_survival_time()
	update_stats_display()
	
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)
	
	play_death_sound()

func hide_death_screen():
	if not is_showing:
		return
	
	is_showing = false
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 0.0, fade_out_duration)
	tween.tween_callback(func():
		visible = false
		get_tree().paused = false
	)

func calculate_survival_time():
	var current_time = Time.get_time_dict_from_system()["unix"]
	survival_time = current_time - game_start_time

func update_stats_display():
	if survival_time_label:
		var minutes = int(survival_time) / 60
		var seconds = int(survival_time) % 60
		survival_time_label.text = "Survival Time: %d:%02d" % [minutes, seconds]
	
	if enemies_killed_label:
		enemies_killed_label.text = "Enemies Defeated: %d" % enemies_killed

func _on_player_died():
	show_death_screen()

func _on_respawn_button_pressed():
	respawn_player()

func respawn_player():
	if not player:
		print("Error: No player reference for respawn")
		return
	
	hide_death_screen()
	
	await get_tree().create_timer(fade_out_duration).timeout
	
	reset_player_state()
	reset_game_stats()

func reset_player_state():
	if not player:
		return
	
	player.current_health = player.max_health
	player.health_changed.emit(player.current_health)
	
	player.damage_immunity_timer = 0.0
	player.player_knockback_velocity = Vector2.ZERO
	
	if player.sprite:
		player.sprite.modulate = Color.WHITE
	
	player.global_position = Vector2(0, 0)
	
	if main_ui and main_ui.has_method("update_health_display"):
		main_ui.update_health_display()
	
	print("Player respawned!")

func reset_game_stats():
	game_start_time = Time.get_time_dict_from_system()["unix"]
	enemies_killed = 0
	survival_time = 0.0

func increment_enemy_kill_count():
	enemies_killed += 1

func play_death_sound():
	pass

func on_enemy_killed():
	increment_enemy_kill_count()

func get_survival_time() -> float:
	return survival_time

func get_enemies_killed() -> int:
	return enemies_killed

func is_death_screen_showing() -> bool:
	return is_showing

func _input(event):
	if is_showing and event.is_action_pressed("ui_accept"):
		_on_respawn_button_pressed()
