extends Control

@export var slot_size: Vector2 = Vector2(72, 72)
@export var max_inventory_slots: int = 20
@export var inventory_position: Vector2 = Vector2(120, 120)
@export var health_bar_position: Vector2 = Vector2(100, 90)
@export var weapon_scale_factor: float = 0.6
@export var slot_padding: int = 8

var inventory_slots: Array = []
var selected_slot_index: int = -1
var inventory_slots_per_row: int = 8 
var inventory_rows: int = 4  
var item_manager: Node = null
var player: CharacterBody2D = null

var active_notifications: Array = []
var notification_spacing: float = 30.0

@onready var inventory_grid: GridContainer = null
@onready var inventory_panel: Control = null
@onready var health_bar: ProgressBar = null
@onready var health_label: Label = null
@onready var death_screen: Control = null
@onready var dash_bar: ProgressBar = null
@onready var dash_label: Label = null
@onready var echo_container: HBoxContainer = null
@onready var boss_bar_container: Control = null
@onready var boss_bar: ProgressBar = null
@onready var boss_label: Label = null

# Death screen variables
var game_start_time: float = 0.0
var enemies_killed: int = 0

func _ready():
	# Ensure this UI is rendered in the same pass as the world (so it warps with fisheye)
	if get_parent() is CanvasLayer:
		var cl := get_parent() as CanvasLayer
		cl.layer = 0
	item_manager = get_node("/root/ItemManager") if has_node("/root/ItemManager") else null
	player = get_tree().get_first_node_in_group("player")
	set_process_input(true)
	if not InputMap.has_action("inventory_toggle"):
		InputMap.add_action("inventory_toggle")
		var evt := InputEventKey.new()
		evt.physical_keycode = KEY_TAB
		InputMap.action_add_event("inventory_toggle", evt)
		# Add controller support for inventory toggle (Triangle/Y button)
		var controller_evt := InputEventJoypadButton.new()
		controller_evt.button_index = JOY_BUTTON_Y
		InputMap.action_add_event("inventory_toggle", controller_evt)
	
	if not item_manager:
		print("Warning: ItemManager not found at /root/ItemManager")
	if not player:
		print("Warning: Player not found in 'player' group")
	
	setup_ui_layout()
	setup_inventory_ui()
	setup_death_screen()
	
	game_start_time = Time.get_unix_time_from_system()
	
	await get_tree().process_frame
	
	connect_signals()
	
	update_health_display()
	
	if inventory_panel:
		inventory_panel.visible = false

func connect_signals():
	# Connect item manager signals
	if item_manager:
		if not item_manager.inventory_updated.is_connected(_on_inventory_updated):
			item_manager.inventory_updated.connect(_on_inventory_updated)
		if not item_manager.item_picked_up.is_connected(_on_item_picked_up):
			item_manager.item_picked_up.connect(_on_item_picked_up)
	
	# Connect player signals
	if player:
		if player.has_signal("health_changed"):
			if not player.health_changed.is_connected(_on_player_health_changed):
				player.health_changed.connect(_on_player_health_changed)
				print("Connected to player health_changed signal")
		else:
			print("Warning: Player doesn't have health_changed signal")
		if player.has_signal("dash_energy_changed"):
			if not player.dash_energy_changed.is_connected(_on_player_dash_changed):
				player.dash_energy_changed.connect(_on_player_dash_changed)
		
		if player.has_signal("player_died"):
			if not player.player_died.is_connected(_on_player_died):
				player.player_died.connect(_on_player_died)
		
		if player.has_signal("enemy_killed"):
			if not player.enemy_killed.is_connected(_on_enemy_killed):
				player.enemy_killed.connect(_on_enemy_killed)
		if player.has_signal("echoes_changed"):
			if not player.echoes_changed.is_connected(_on_echoes_changed):
				player.echoes_changed.connect(_on_echoes_changed)
		if player.has_signal("echo_spawned"):
			if not player.echo_spawned.is_connected(_on_echo_spawned):
				player.echo_spawned.connect(_on_echo_spawned)

	# Connect boss signals from existing big slime in scene (if any)
	var bosses = get_tree().get_nodes_in_group("boss")
	for b in bosses:
		_connect_boss_signals(b)

func setup_ui_layout():
	#create_health_bar()
	create_dash_bar()
	create_inventory_panel()
	create_echo_pips()
	create_boss_bar()

#func create_health_bar():
	#var health_container = VBoxContainer.new()
	#health_container.name = "HealthContainer"
	#health_container.position = health_bar_position
	#health_container.size = Vector2(360, 70)
	#add_child(health_container)
	#
	#health_label = Label.new()
	#health_label.name = "HealthLabel"
	#health_label.visible = false
	#health_container.add_child(health_label)
	#
	
	#health_bar = ProgressBar.new()
	#health_bar.visible = false
	#health_container.add_child(health_bar)
	#health_container.visible = false

func create_echo_pips():
	var container = HBoxContainer.new()
	container.name = "EchoPips"
	# Position under the dash bar
	container.position = health_bar_position + Vector2(420 + 80, 28 + 60)
	container.add_theme_constant_override("separation", 8)
	add_child(container)
	echo_container = container
	update_echo_pips(0, 3)

func create_boss_bar():
	var container = Panel.new()
	container.name = "BossBarContainer"
	container.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	container.offset_top = 80
	container.offset_left = 0
	container.offset_right = 0
	container.visible = false
	add_child(container)

	var inner = CenterContainer.new()
	inner.name = "BossInner"
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(inner)

	var vbox = VBoxContainer.new()
	vbox.name = "BossVBox"
	vbox.add_theme_constant_override("separation", 6)
	inner.add_child(vbox)

	boss_label = Label.new()
	boss_label.name = "BossName"
	boss_label.text = "Lord Slime"
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.add_theme_font_size_override("font_size", 20)
	boss_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	vbox.add_child(boss_label)

	boss_bar = ProgressBar.new()
	boss_bar.name = "BossBar"
	boss_bar.min_value = 0
	boss_bar.max_value = 100
	boss_bar.value = 100
	boss_bar.custom_minimum_size = Vector2(620, 24)
	boss_bar.show_percentage = false

	var boss_fill = StyleBoxFlat.new()
	boss_fill.bg_color = Color(0.85, 0.25, 0.25)
	boss_fill.corner_radius_top_left = 6
	boss_fill.corner_radius_top_right = 6
	boss_fill.corner_radius_bottom_left = 6
	boss_fill.corner_radius_bottom_right = 6
	boss_bar.add_theme_stylebox_override("fill", boss_fill)

	var boss_bg = StyleBoxFlat.new()
	boss_bg.bg_color = Color(0.05, 0.03, 0.04, 0.9)
	boss_bg.border_color = Color(0.3, 0.2, 0.25)
	boss_bg.border_width_left = 2
	boss_bg.border_width_right = 2
	boss_bg.border_width_top = 2
	boss_bg.border_width_bottom = 2
	boss_bg.corner_radius_top_left = 6
	boss_bg.corner_radius_top_right = 6
	boss_bg.corner_radius_bottom_left = 6
	boss_bg.corner_radius_bottom_right = 6
	boss_bar.add_theme_stylebox_override("background", boss_bg)

	vbox.add_child(boss_bar)

	boss_bar_container = container

func update_echo_pips(count: int, max_count: int = 3):
	if not echo_container:
		return
	for c in echo_container.get_children():
		c.queue_free()
	for i in range(max_count):
		var pip = ColorRect.new()
		pip.custom_minimum_size = Vector2(12, 12)
		var on_color = Color(0.2, 0.6, 1.0)
		var off_color = Color(0.1, 0.2, 0.35)
		pip.color = on_color if i < count else off_color
		pip.modulate.a = 0.9
		echo_container.add_child(pip)

func create_dash_bar():
	var dash_container = VBoxContainer.new()
	dash_container.name = "DashContainer"
	# Place directly under the health bar position
	dash_container.position = health_bar_position + Vector2(35, 120)
	dash_container.size = Vector2(460, 48)
	add_child(dash_container)

	dash_label = Label.new()
	dash_label.name = "DashLabel"
	dash_label.visible = false
	dash_container.add_child(dash_label)

	dash_bar = ProgressBar.new()
	dash_bar.name = "DashBar"
	dash_bar.min_value = 0
	dash_bar.max_value = 100
	dash_bar.value = 100
	# Make thinner
	dash_bar.custom_minimum_size = Vector2(420, 12)
	dash_bar.show_percentage = false

	var dash_fill = StyleBoxFlat.new()
	dash_fill.bg_color = Color(0.16, 0.55, 1.0)
	dash_fill.corner_radius_top_left = 3
	dash_fill.corner_radius_top_right = 3
	dash_fill.corner_radius_bottom_left = 3
	dash_fill.corner_radius_bottom_right = 3
	dash_bar.add_theme_stylebox_override("fill", dash_fill)

	var dash_bg = StyleBoxFlat.new()
	dash_bg.bg_color = Color(0.06, 0.08, 0.14, 0.9)
	dash_bg.border_color = Color(0.12, 0.16, 0.26)
	dash_bg.border_width_left = 1
	dash_bg.border_width_right = 1
	dash_bg.border_width_top = 1
	dash_bg.border_width_bottom = 1
	dash_bg.corner_radius_top_left = 4
	dash_bg.corner_radius_top_right = 4
	dash_bg.corner_radius_bottom_left = 4
	dash_bg.corner_radius_bottom_right = 4
	dash_bar.add_theme_stylebox_override("background", dash_bg)

	dash_container.add_child(dash_bar)

func create_inventory_panel():
	inventory_panel = Panel.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.size = Vector2(500, 390)
	inventory_panel.position = inventory_position
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.06, 0.05, 0.96)
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_color = Color(0.5, 0.4, 0.3)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	inventory_panel.add_theme_stylebox_override("panel", panel_style)
	
	add_child(inventory_panel)
	
	var header = Panel.new()
	header.name = "Header"
	header.position = Vector2(10, 10)
	header.size = Vector2(480, 34)
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.12, 0.1, 0.08, 1.0)
	header_style.border_width_bottom = 2
	header_style.border_color = Color(0.35, 0.28, 0.2)
	header_style.corner_radius_top_left = 6
	header_style.corner_radius_top_right = 6
	header_style.corner_radius_bottom_left = 6
	header_style.corner_radius_bottom_right = 6
	header.add_theme_stylebox_override("panel", header_style)
	inventory_panel.add_child(header)
	
	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Inventory"
	title_label.position = Vector2(12, 6)
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(title_label)
	
	var content = Panel.new()
	content.name = "Content"
	content.position = Vector2(10, 52)
	content.size = Vector2(480, 326)
	var content_style = StyleBoxFlat.new()
	content_style.bg_color = Color(0.09, 0.07, 0.06, 0.9)
	content_style.border_width_top = 2
	content_style.border_width_bottom = 2
	content_style.border_width_left = 2
	content_style.border_width_right = 2
	content_style.border_color = Color(0.28, 0.22, 0.16, 0.8)
	content_style.corner_radius_top_left = 6
	content_style.corner_radius_top_right = 6
	content_style.corner_radius_bottom_left = 6
	content_style.corner_radius_bottom_right = 6
	content.add_theme_stylebox_override("panel", content_style)
	inventory_panel.add_child(content)
	
	var scroll_container = ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.position = Vector2(8, 8)
	scroll_container.size = Vector2(464, 306)
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll_container)
	
	inventory_grid = GridContainer.new()
	inventory_grid.name = "InventoryGrid"
	inventory_grid.columns = 6
	inventory_grid.add_theme_constant_override("h_separation", 6)
	inventory_grid.add_theme_constant_override("v_separation", 6)
	scroll_container.add_child(inventory_grid)

func setup_death_screen():
	death_screen = Control.new()
	death_screen.name = "DeathScreen"
	death_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_screen.visible = false
	death_screen.modulate.a = 0.0
	add_child(death_screen)
	
	var background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0.0, 0.0, 0.0, 0.7)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_screen.add_child(background)
	
	var death_panel = Panel.new()
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
	
	death_screen.add_child(death_panel)
	
	var content_container = VBoxContainer.new()
	content_container.name = "ContentContainer"
	content_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_container.add_theme_constant_override("separation", 20)
	death_panel.add_child(content_container)
	
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 30)
	content_container.add_child(top_spacer)
	
	var death_label = Label.new()
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
	
	var stats_container = VBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.add_theme_constant_override("separation", 10)
	content_container.add_child(stats_container)
	
	var survival_time_label = Label.new()
	survival_time_label.name = "SurvivalTimeLabel"
	survival_time_label.text = "Survival Time: 0:00"
	survival_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	survival_time_label.add_theme_font_size_override("font_size", 16)
	survival_time_label.add_theme_color_override("font_color", Color.WHITE)
	survival_time_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	survival_time_label.add_theme_constant_override("shadow_offset_x", 1)
	survival_time_label.add_theme_constant_override("shadow_offset_y", 1)
	stats_container.add_child(survival_time_label)
	
	var enemies_killed_label = Label.new()
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
	
	var respawn_button = Button.new()
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

func setup_inventory_ui():
	create_inventory_slots()
	refresh_inventory_display()

func create_inventory_slots():
	for slot in inventory_slots:
		if is_instance_valid(slot):
			slot.queue_free()
	inventory_slots.clear()
	
	if inventory_grid:
		for child in inventory_grid.get_children():
			child.queue_free()
	
	for i in range(max_inventory_slots):
		var slot = create_enhanced_inventory_slot(i)
		inventory_slots.append(slot)
		if inventory_grid:
			inventory_grid.add_child(slot)

func create_enhanced_inventory_slot(index: int) -> Control:
	var slot = Control.new()
	slot.custom_minimum_size = slot_size
	slot.name = "InventorySlot" + str(index)
	
	var background = Panel.new()
	background.name = "Background"
	background.anchor_left = 0.0
	background.anchor_top = 0.0
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.12, 0.08, 0.95)
	style_box.border_width_top = 2
	style_box.border_width_bottom = 3
	style_box.border_width_left = 2
	style_box.border_width_right = 3
	style_box.border_color = Color(0.4, 0.3, 0.2, 0.8)
	style_box.corner_radius_top_left = 6
	style_box.corner_radius_top_right = 6
	style_box.corner_radius_bottom_left = 6
	style_box.corner_radius_bottom_right = 6
	
	background.add_theme_stylebox_override("panel", style_box)
	slot.add_child(background)
	
	# Add selection highlight
	var selection_overlay = Panel.new()
	selection_overlay.name = "SelectionOverlay"
	selection_overlay.anchor_left = 0.0
	selection_overlay.anchor_top = 0.0
	selection_overlay.anchor_right = 1.0
	selection_overlay.anchor_bottom = 1.0
	selection_overlay.visible = false
	
	var selection_style = StyleBoxFlat.new()
	selection_style.bg_color = Color(0.2, 0.6, 1.0, 0.3)
	selection_style.border_width_top = 3
	selection_style.border_width_bottom = 3
	selection_style.border_width_left = 3
	selection_style.border_width_right = 3
	selection_style.border_color = Color(0.4, 0.8, 1.0, 0.8)
	selection_style.corner_radius_top_left = 6
	selection_style.corner_radius_top_right = 6
	selection_style.corner_radius_bottom_left = 6
	selection_style.corner_radius_bottom_right = 6
	
	selection_overlay.add_theme_stylebox_override("panel", selection_style)
	slot.add_child(selection_overlay)
	
	var item_icon = TextureRect.new()
	item_icon.name = "ItemIcon"
	item_icon.anchor_left = 0.0
	item_icon.anchor_top = 0.0
	item_icon.anchor_right = 1.0
	item_icon.anchor_bottom = 1.0
	item_icon.offset_left = slot_padding
	item_icon.offset_top = slot_padding
	item_icon.offset_right = -slot_padding
	item_icon.offset_bottom = -slot_padding
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.add_child(item_icon)
	
	var count_label = Label.new()
	count_label.name = "CountLabel"
	count_label.anchor_left = 0.6
	count_label.anchor_top = 0.6
	count_label.anchor_right = 1.0
	count_label.anchor_bottom = 1.0
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	count_label.add_theme_constant_override("shadow_offset_x", 1)
	count_label.add_theme_constant_override("shadow_offset_y", 1)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_label.text = ""
	slot.add_child(count_label)
	
	var button = Button.new()
	button.name = "ClickDetector"
	button.anchor_left = 0.0
	button.anchor_top = 0.0
	button.anchor_right = 1.0
	button.anchor_bottom = 1.0
	button.flat = true
	button.pressed.connect(_on_slot_clicked.bind(index))
	slot.add_child(button)
	
	return slot

# Update health display
func update_health_display():
	if not player or not health_bar or not health_label:
		return
	
	var current_health = 100
	var max_health = 100
	
	if player.has_method("get_health"):
		current_health = player.get_health()
	elif player.has_method("get_current_health"):
		current_health = player.get_current_health()
	elif "health" in player:
		current_health = player.health
	elif "current_health" in player:
		current_health = player.current_health
	
	if player.has_method("get_max_health"):
		max_health = player.get_max_health()
	elif "max_health" in player:
		max_health = player.max_health
	
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = "Health: " + str(current_health) + "/" + str(max_health)
	
	var health_percentage = float(current_health) / float(max_health)
	var health_color: Color
	
	if health_percentage > 0.7:
		health_color = Color(0.2, 0.8, 0.2)
	elif health_percentage > 0.3:
		health_color = Color(0.8, 0.8, 0.2)
	else:
		health_color = Color(0.8, 0.2, 0.2)
	
	var health_bar_style = StyleBoxFlat.new()
	health_bar_style.bg_color = health_color
	health_bar_style.corner_radius_top_left = 4
	health_bar_style.corner_radius_top_right = 4
	health_bar_style.corner_radius_bottom_left = 4
	health_bar_style.corner_radius_bottom_right = 4
	health_bar.add_theme_stylebox_override("fill", health_bar_style)

	update_dash_display()
	if player and player.has_method("get_echo_count"):
		update_echo_pips(player.get_echo_count(), 3)

func update_dash_display():
	if not player or not dash_bar or not dash_label:
		return

	var current_energy = 100
	var max_energy = 100

	if player.has_method("get_dash_energy"):
		current_energy = player.get_dash_energy()
	if player.has_method("get_max_dash_energy"):
		max_energy = player.get_max_dash_energy()

	dash_bar.max_value = max_energy
	dash_bar.value = current_energy
	dash_label.text = "Dash: " + str(current_energy) + "/" + str(max_energy)

	var pct = float(current_energy) / float(max_energy)
	var color: Color = Color(0.16, 0.55, 1.0)
	if pct < 0.25:
		color = Color(0.22, 0.28, 0.5)

	var dash_fill = StyleBoxFlat.new()
	dash_fill.bg_color = color
	dash_fill.corner_radius_top_left = 4
	dash_fill.corner_radius_top_right = 4
	dash_fill.corner_radius_bottom_left = 4
	dash_fill.corner_radius_bottom_right = 4
	dash_bar.add_theme_stylebox_override("fill", dash_fill)

# Signal handlers
func _on_player_health_changed(new_health: int):
	print("Health changed signal received: ", new_health)
	update_health_display()

func _on_player_dash_changed(new_energy: int):
	update_dash_display()

func _on_echoes_changed(count: int):
	update_echo_pips(count, 3)

func _on_echo_spawned(duration: float):
	if not echo_container:
		return
	# brief glow on newest pip
	var idx = min(2, max(0, (player.get_echo_count() - 1))) if player and player.has_method("get_echo_count") else 0
	if idx < echo_container.get_child_count():
		var pip = echo_container.get_child(idx)
		if is_instance_valid(pip):
			var t = create_tween()
			t.tween_property(pip, "modulate", Color(0.5, 0.8, 1.0, 1.0), 0.08)
			t.tween_property(pip, "modulate", Color(0.2, 0.6, 1.0, 0.9), 0.18)

func _on_item_picked_up(item_data: Dictionary):
	var item_name = item_data.get("name", "Unknown Item")
	show_notification("Picked up: " + item_name)

func _on_player_died():
	show_death_screen()

func _on_enemy_killed():
	enemies_killed += 1

func _connect_boss_signals(boss: Node):
	if boss and boss.has_signal("boss_engaged"):
		if not boss.boss_engaged.is_connected(_on_boss_engaged):
			boss.boss_engaged.connect(_on_boss_engaged)
	if boss and boss.has_signal("boss_disengaged"):
		if not boss.boss_disengaged.is_connected(_on_boss_disengaged):
			boss.boss_disengaged.connect(_on_boss_disengaged)
	if boss and boss.has_signal("boss_health_changed"):
		if not boss.boss_health_changed.is_connected(_on_boss_health_changed):
			boss.boss_health_changed.connect(_on_boss_health_changed)

func _on_boss_engaged(name: String, max_hp: int, cur_hp: int):
	if boss_bar_container and boss_bar and boss_label:
		boss_label.text = name
		boss_bar.max_value = max_hp
		boss_bar.value = cur_hp
		boss_bar_container.visible = true

func _on_boss_disengaged():
	if boss_bar_container:
		boss_bar_container.visible = false

func _on_boss_health_changed(cur_hp: int, max_hp: int):
	if boss_bar:
		boss_bar.max_value = max_hp
		boss_bar.value = cur_hp

func _on_slot_clicked(slot_index: int):
	print("Slot clicked: ", slot_index)
	selected_slot_index = slot_index
	
	if item_manager:
		var inventory_items = item_manager.get_inventory_items()
		if slot_index < inventory_items.size():
			var item = inventory_items[slot_index]
			handle_item_interaction(item, slot_index)

func _on_inventory_updated():
	refresh_inventory_display()

func _on_respawn_button_pressed():
	respawn_player()

# Death screen functions
func show_death_screen():
	if not death_screen:
		return
		
	death_screen.visible = true
	
	calculate_survival_time()
	update_death_stats_display()
	
	get_tree().paused = true
	death_screen.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(death_screen, "modulate:a", 1.0, 0.5)

func hide_death_screen():
	if not death_screen:
		return
		
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(death_screen, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		death_screen.visible = false
		get_tree().paused = false
	)

func calculate_survival_time():
	var current_time = Time.get_unix_time_from_system()
	return current_time - game_start_time

func update_death_stats_display():
	if not death_screen:
		return
		
	var survival_time = calculate_survival_time()
	var minutes = int(survival_time) / 60
	var seconds = int(survival_time) % 60
	
	var survival_label = death_screen.find_child("SurvivalTimeLabel", true, false)
	var enemies_label = death_screen.find_child("EnemiesKilledLabel", true, false)
	
	if survival_label:
		survival_label.text = "Survival Time: %d:%02d" % [minutes, seconds]
	
	if enemies_label:
		enemies_label.text = "Enemies Defeated: %d" % enemies_killed

func respawn_player():
	if not player:
		print("Error: No player reference for respawn")
		return
	
	hide_death_screen()
	
	await get_tree().create_timer(0.3).timeout
	
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
	
	update_health_display()
	
	print("Player respawned!")

func reset_game_stats():
	game_start_time = Time.get_unix_time_from_system()
	enemies_killed = 0

# Inventory functions
func refresh_inventory_display():
	if not item_manager:
		return
	
	var inventory_items = item_manager.get_inventory_items()
	
	for slot in inventory_slots:
		clear_slot(slot)
	
	for i in range(min(inventory_items.size(), inventory_slots.size())):
		var item = inventory_items[i]
		var slot = inventory_slots[i]
		display_item_in_slot(slot, item, i)

func display_item_in_slot(slot: Control, item: Dictionary, slot_index: int):
	if not slot.has_node("ItemIcon") or not slot.has_node("CountLabel"):
		print("Slot missing ItemIcon or CountLabel: ", slot.name)
		return
	
	var icon = slot.get_node("ItemIcon")
	var count_label = slot.get_node("CountLabel")
	
	var icon_path = ""
	var quantity = 1
	var is_equipped = false
	var item_data = {}
	
	if "data" in item:  
		item_data = item.data
		icon_path = item.data.get("icon_path", item.data.get("icon", ""))
		quantity = item.get("quantity", 1)
		is_equipped = item.get("equipped", false)
	else: 
		item_data = item
		if "icon" in item:
			icon_path = item.icon
		elif "id" in item and item_manager:
			var weapon_data = item_manager.get_weapon_data(item.id)
			if not weapon_data.is_empty():
				icon_path = weapon_data.get("icon_path", "")
		
		quantity = item.get("count", item.get("quantity", 1))
		is_equipped = item.get("equipped", false)
	
	if icon_path != "":
		if ResourceLoader.exists(icon_path):
			var texture = load(icon_path)
			if texture:
				icon.texture = texture
				var item_type = item_data.get("type", "")
				if item_type == "weapon":
					fit_weapon_sprite_to_slot(icon, texture, slot_size)
				else:
					fit_sprite_to_slot(icon, texture, slot_size)
			else:
				print("Failed to load texture: ", icon_path)
		else:
			print("Texture file doesn't exist: ", icon_path)
			var fallback_path = "res://icon.svg"   
			if ResourceLoader.exists(fallback_path):
				var texture = load(fallback_path)
				icon.texture = texture
				fit_sprite_to_slot(icon, texture, slot_size)
	
	if is_equipped:
		count_label.text = "E"
		count_label.add_theme_color_override("font_color", Color.GOLD)
	elif quantity > 1:
		count_label.text = str(quantity)
		count_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		count_label.text = ""
	
	var rarity = item_data.get("rarity", "common")
	var rarity_color = get_rarity_color(rarity)
	apply_rarity_effects(slot, rarity_color, is_equipped)

func clear_slot(slot: Control):
	if slot.has_node("ItemIcon"):
		slot.get_node("ItemIcon").texture = null
	if slot.has_node("CountLabel"):
		slot.get_node("CountLabel").text = ""

func handle_item_interaction(item: Dictionary, slot_index: int):
	var item_data = item.get("data", {})
	var item_type = item_data.get("type", "")
	var item_id = item_data.get("id", "")
	
	if item_type == "consumable":
		if item_manager and item_manager.has_method("use_item"):
			var success = item_manager.use_item(item_id)
			if success:
				var item_name = item_data.get("name", "Item")
				var effect = item_data.get("effect", "")
				var effect_value = item_data.get("effect_value", 0)
				
				match effect:
					"heal":
						show_notification("Used " + item_name + " (+%d HP)" % effect_value, Color.GREEN)
						await get_tree().process_frame
						update_health_display()
					"restore_mana":
						show_notification("Used " + item_name + " (+%d MP)" % effect_value, Color.BLUE)
					_:
						show_notification("Used " + item_name)
			else:
				show_notification("Cannot use " + item_data.get("name", "item"), Color.RED)
	
	elif item_type == "weapon":
		if item_manager and item_manager.has_method("equip_weapon_from_inventory"):
			var success = item_manager.equip_weapon_from_inventory(item_id)
			if success:
				show_notification("Equipped: " + item_data.get("name", "weapon"), Color.YELLOW)
			else:
				show_notification("Cannot equip weapon", Color.RED)

# Utility functions
func fit_weapon_sprite_to_slot(icon: TextureRect, texture: Texture2D, target_slot_size: Vector2):
	if not texture:
		return
	
	var texture_size = texture.get_size()
	if texture_size.x <= 0 or texture_size.y <= 0:
		return
	
	var padding = slot_padding + 6
	var available_size = target_slot_size - Vector2(padding * 2, padding * 2)
	available_size.x = max(1.0, available_size.x)
	available_size.y = max(1.0, available_size.y)
	
	var scale_x = available_size.x / texture_size.x
	var scale_y = available_size.y / texture_size.y
	var scale_factor = min(scale_x, scale_y) * weapon_scale_factor
	
	scale_factor = clamp(scale_factor, 0.05, 1.5)
	
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var final_size = texture_size * scale_factor
	if final_size.x > available_size.x or final_size.y > available_size.y:
		scale_factor = min(available_size.x / texture_size.x, available_size.y / texture_size.y)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func fit_sprite_to_slot(icon: TextureRect, texture: Texture2D, target_slot_size: Vector2):
	if not texture:
		return
	
	var texture_size = texture.get_size()
	if texture_size.x <= 0 or texture_size.y <= 0:
		return
	
	var padding = slot_padding
	var available_size = target_slot_size - Vector2(padding * 2, padding * 2)
	available_size.x = max(1.0, available_size.x)
	available_size.y = max(1.0, available_size.y)
	
	var scale_x = available_size.x / texture_size.x
	var scale_y = available_size.y / texture_size.y
	var scale_factor = min(scale_x, scale_y)
	
	scale_factor = clamp(scale_factor, 0.1, 2.0)
	
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var final_size = texture_size * scale_factor
	if final_size.x > available_size.x or final_size.y > available_size.y:
		scale_factor = min(available_size.x / texture_size.x, available_size.y / texture_size.y)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common":
			return Color(0.7, 0.7, 0.7)
		"uncommon":
			return Color(0.3, 0.8, 0.3)
		"rare":
			return Color(0.3, 0.3, 1.0)
		"epic":
			return Color(0.8, 0.3, 0.8)
		"legendary":
			return Color(1.0, 0.6, 0.0)
		_:
			return Color(0.7, 0.7, 0.7)

func apply_rarity_effects(slot: Control, rarity_color: Color, is_equipped: bool):
	if not slot.has_node("Background"):
		return
		
	var background = slot.get_node("Background")
	var style_box = background.get_theme_stylebox("panel")
	
	if style_box is StyleBoxFlat:
		var new_style = style_box.duplicate()
		
		if is_equipped:
			new_style.border_color = Color.GOLD
			new_style.border_width_top = 3
			new_style.border_width_bottom = 3
			new_style.border_width_left = 3
			new_style.border_width_right = 3
		else:
			new_style.border_color = rarity_color
			new_style.border_width_top = 2
			new_style.border_width_bottom = 2
			new_style.border_width_left = 2
			new_style.border_width_right = 2
		
		background.add_theme_stylebox_override("panel", new_style)

func show_notification(message: String, color: Color = Color.WHITE, duration: float = 2.0):
	print("Notification: ", message)
	
	var notification = Label.new()
	notification.text = message
	notification.add_theme_font_size_override("font_size", 16)
	notification.add_theme_color_override("font_color", color)
	notification.add_theme_color_override("font_shadow_color", Color.BLACK)
	notification.add_theme_constant_override("shadow_offset_x", 2)
	notification.add_theme_constant_override("shadow_offset_y", 2)
	notification.z_index = 100
	
	var notification_y = 50.0 + (active_notifications.size() * notification_spacing)
	notification.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 100, notification_y)
	
	active_notifications.append(notification)
	add_child(notification)
	
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 0.0, duration)
	tween.tween_callback(func():
		if notification in active_notifications:
			active_notifications.erase(notification)
			update_notification_positions()
		notification.queue_free()
	)

func update_notification_positions():
	for i in range(active_notifications.size()):
		var notification = active_notifications[i]
		if is_instance_valid(notification):
			var target_y = 50.0 + (i * notification_spacing)
			var tween = create_tween()
			tween.tween_property(notification, "position:y", target_y, 0.2)

func toggle_inventory():
	if inventory_panel:
		inventory_panel.visible = !inventory_panel.visible
		if inventory_panel.visible:
			refresh_inventory_display()
			# Select first slot when opening inventory
			selected_slot_index = 0
			update_inventory_selection()
		else:
			# Clear selection when closing inventory
			selected_slot_index = -1

func add_item_to_inventory(item_id: String, quantity: int = 1) -> bool:
	if item_manager:
		return item_manager.add_item_to_inventory(item_id, quantity)
	return false

# Controller navigation functions
func navigate_inventory(direction: int):
	if inventory_slots.size() == 0:
		return
	
	# Initialize selection if none
	if selected_slot_index == -1:
		selected_slot_index = 0
	else:
		# Move up/down by slots_per_row
		selected_slot_index += direction * inventory_slots_per_row
	
	# Clamp to valid range
	selected_slot_index = clamp(selected_slot_index, 0, inventory_slots.size() - 1)
	
	# Update visual selection
	update_inventory_selection()

func navigate_inventory_horizontal(direction: int):
	if inventory_slots.size() == 0:
		return
	
	# Initialize selection if none
	if selected_slot_index == -1:
		selected_slot_index = 0
	else:
		# Move left/right by 1
		selected_slot_index += direction
	
	# Clamp to valid range
	selected_slot_index = clamp(selected_slot_index, 0, inventory_slots.size() - 1)
	
	# Update visual selection
	update_inventory_selection()

func select_inventory_item():
	if selected_slot_index >= 0 and selected_slot_index < inventory_slots.size():
		_on_slot_clicked(selected_slot_index)

func update_inventory_selection():
	# Clear all selections first
	for i in range(inventory_slots.size()):
		var slot = inventory_slots[i]
		if slot and slot.has_node("SelectionOverlay"):
			slot.get_node("SelectionOverlay").visible = false
	
	# Highlight selected slot
	if selected_slot_index >= 0 and selected_slot_index < inventory_slots.size():
		var selected_slot = inventory_slots[selected_slot_index]
		if selected_slot and selected_slot.has_node("SelectionOverlay"):
			selected_slot.get_node("SelectionOverlay").visible = true

func _input(event):
	# Handle keyboard input
	if event is InputEventKey and event.pressed and not event.echo:
		# First check for death screen input
		if death_screen and death_screen.visible:
			if event.is_action_pressed("ui_accept"):
				_on_respawn_button_pressed()
		# Otherwise allow inventory toggle
		elif event.is_action_pressed("inventory_toggle"):
			toggle_inventory()
	
	# Handle controller button input
	if event is InputEventJoypadButton and event.pressed:
		# First check for death screen input
		if death_screen and death_screen.visible:
			if event.is_action_pressed("ui_accept"):
				_on_respawn_button_pressed()
		# Otherwise allow inventory toggle
		elif event.is_action_pressed("inventory_toggle"):
			toggle_inventory()
	
	# Handle controller D-pad navigation when inventory is open
	if inventory_panel and inventory_panel.visible:
		if event is InputEventJoypadButton and event.pressed:
			match event.button_index:
				JOY_BUTTON_DPAD_UP:
					navigate_inventory(-1)  # Move up
				JOY_BUTTON_DPAD_DOWN:
					navigate_inventory(1)   # Move down
				JOY_BUTTON_DPAD_LEFT:
					navigate_inventory_horizontal(-1)  # Move left
				JOY_BUTTON_DPAD_RIGHT:
					navigate_inventory_horizontal(1)   # Move right
				JOY_BUTTON_A:
					select_inventory_item()  # Select/use item
				JOY_BUTTON_B:
					select_inventory_item()  # Select/use item (Circle button)
