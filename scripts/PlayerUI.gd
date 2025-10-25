extends Control

@export var slot_size: Vector2 = Vector2(72, 72)
@export var max_inventory_slots: int = 20
@export var weapon_scale_factor: float = 0.6
@export var slot_padding: int = 8
@export var boss_detection_distance: float = 500.0

var inventory_slots: Array = []
var selected_slot_index: int = -1
var inventory_slots_per_row: int = 6
var item_manager: Node = null
var player: CharacterBody2D = null
var active_notifications: Array = []
var notification_spacing: float = 30.0
var game_start_time: float = 0.0
var enemies_killed: int = 0
var connected_bosses: Array = []
var current_boss: Node = null


@onready var inventory_panel: Panel = $InventoryPanel
@onready var inventory_grid: GridContainer = $InventoryPanel/ContentPanel/ScrollContainer/InventoryGrid
@onready var dash_bar: ProgressBar = $DashContainer/DashBar if has_node("DashContainer/DashBar") else null
@onready var dash_label: Label = $DashContainer/DashLabel if has_node("DashContainer/DashLabel") else null
@onready var echo_container: HBoxContainer = $EchoPips if has_node("EchoPips") else null
@onready var boss_bar_container: Control = $BossBarContainer if has_node("BossBarContainer") else null
@onready var boss_bar: ProgressBar = $BossBarContainer/BossInner/BossVBox/BossBar if has_node("BossBarContainer/BossInner/BossVBox/BossBar") else null
@onready var boss_label: Label = $BossBarContainer/BossInner/BossVBox/BossName if has_node("BossBarContainer/BossInner/BossVBox/BossName") else null
@onready var death_screen: Control = $DeathScreen if has_node("DeathScreen") else null

@onready var victory_popup: Control = $VictoryPopup if has_node("VictoryPopup") else null
@onready var victory_text: Label = $VictoryPopup/Banner/MainText if has_node("VictoryPopup/Banner/MainText") else null
@onready var victory_banner: Panel = $VictoryPopup/Banner if has_node("VictoryPopup/Banner") else null

func _ready():
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
		var controller_evt := InputEventJoypadButton.new()
		controller_evt.button_index = JOY_BUTTON_Y
		InputMap.action_add_event("inventory_toggle", controller_evt)
	
	if not echo_container:
		create_echo_pips()
	if not boss_bar_container:
		create_boss_bar()
	if not dash_bar:
		create_dash_bar()
	if not death_screen:
		setup_death_screen()
	
	game_start_time = Time.get_unix_time_from_system()
	
	await get_tree().process_frame
	
	connect_signals()
	setup_inventory_ui()
	update_health_display()
	
	if inventory_panel:
		inventory_panel.visible = false

func connect_signals():
	if item_manager:
		if not item_manager.inventory_updated.is_connected(_on_inventory_updated):
			item_manager.inventory_updated.connect(_on_inventory_updated)
		if not item_manager.item_picked_up.is_connected(_on_item_picked_up):
			item_manager.item_picked_up.connect(_on_item_picked_up)
	
	if player:
		if player.has_signal("health_changed"):
			if not player.health_changed.is_connected(_on_player_health_changed):
				player.health_changed.connect(_on_player_health_changed)
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

	call_deferred("_connect_to_existing_bosses")
	
func _connect_to_existing_bosses():
	var bosses = get_tree().get_nodes_in_group("boss")
	for boss in bosses:
		if boss and is_instance_valid(boss):
			_connect_boss_signals(boss)

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
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	
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
	
	var selection_overlay = Panel.new()
	selection_overlay.name = "SelectionOverlay"
	selection_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	item_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.flat = true
	button.pressed.connect(_on_slot_clicked.bind(index))
	slot.add_child(button)
	
	return slot

func create_echo_pips():
	var container = HBoxContainer.new()
	container.name = "EchoPips"
	container.position = Vector2(600, 148)
	container.add_theme_constant_override("separation", 8)
	add_child(container)
	echo_container = container
	update_echo_pips(0, 3)

func create_boss_bar():
	var container = Panel.new()
	container.name = "BossBarContainer"
	container.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	container.offset_top = -120
	container.offset_bottom = -50
	container.visible = false
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.6)
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.5, 0, 0, 0.8)
	container.add_theme_stylebox_override("panel", bg_style)
	add_child(container)
	
	var inner = CenterContainer.new()
	inner.name = "BossInner"
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(inner)
	
	var vbox = VBoxContainer.new()
	vbox.name = "BossVBox"
	vbox.add_theme_constant_override("separation", 6)
	inner.add_child(vbox)
	
	boss_label = Label.new()
	boss_label.name = "BossName"
	boss_label.text = "Boss"
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.add_theme_font_size_override("font_size", 20)
	boss_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	boss_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	boss_label.add_theme_constant_override("shadow_offset_x", 2)
	boss_label.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(boss_label)
	
	boss_bar = ProgressBar.new()
	boss_bar.name = "BossBar"
	boss_bar.min_value = 0
	boss_bar.max_value = 100
	boss_bar.value = 100
	boss_bar.custom_minimum_size = Vector2(620, 28)
	boss_bar.show_percentage = false
	
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.8, 0, 0, 1)
	bar_style.border_width_top = 2
	bar_style.border_width_bottom = 2
	bar_style.border_width_left = 2
	bar_style.border_width_right = 2
	bar_style.border_color = Color(0.3, 0, 0, 1)
	bar_style.corner_radius_top_left = 4
	bar_style.corner_radius_top_right = 4
	bar_style.corner_radius_bottom_left = 4
	bar_style.corner_radius_bottom_right = 4
	boss_bar.add_theme_stylebox_override("fill", bar_style)
	
	var bg_bar_style = StyleBoxFlat.new()
	bg_bar_style.bg_color = Color(0.2, 0, 0, 0.8)
	bg_bar_style.border_width_top = 2
	bg_bar_style.border_width_bottom = 2
	bg_bar_style.border_width_left = 2
	bg_bar_style.border_width_right = 2
	bg_bar_style.border_color = Color(0.3, 0, 0, 1)
	bg_bar_style.corner_radius_top_left = 4
	bg_bar_style.corner_radius_top_right = 4
	bg_bar_style.corner_radius_bottom_left = 4
	bg_bar_style.corner_radius_bottom_right = 4
	boss_bar.add_theme_stylebox_override("background", bg_bar_style)
	
	vbox.add_child(boss_bar)
	
	boss_bar_container = container

func create_dash_bar():
	var dash_container = VBoxContainer.new()
	dash_container.name = "DashContainer"
	dash_container.position = Vector2(135, 210)
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
	dash_bar.custom_minimum_size = Vector2(420, 12)
	dash_bar.show_percentage = false
	dash_container.add_child(dash_bar)

func setup_death_screen():
	death_screen = Control.new()
	death_screen.name = "DeathScreen"
	death_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_screen.visible = false
	death_screen.modulate.a = 0.0
	add_child(death_screen)
	
	var background = ColorRect.new()
	background.color = Color(0.0, 0.0, 0.0, 0.7)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_screen.add_child(background)
	
	var death_panel = Panel.new()
	death_panel.set_anchors_preset(Control.PRESET_CENTER)
	death_panel.size = Vector2(400, 300)
	death_panel.position = Vector2(-200, -150)
	death_screen.add_child(death_panel)

func toggle_inventory():
	if inventory_panel:
		inventory_panel.visible = !inventory_panel.visible
		if inventory_panel.visible:
			refresh_inventory_display()
			selected_slot_index = 0
			update_inventory_selection()
		else:
			selected_slot_index = -1

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
		quantity = item.get("count", item.get("quantity", 1))
		is_equipped = item.get("equipped", false)
	
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var texture = load(icon_path)
		if texture:
			icon.texture = texture
	
	if is_equipped:
		count_label.text = "E"
		count_label.add_theme_color_override("font_color", Color.GOLD)
	elif quantity > 1:
		count_label.text = str(quantity)
		count_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		count_label.text = ""

func clear_slot(slot: Control):
	if slot.has_node("ItemIcon"):
		slot.get_node("ItemIcon").texture = null
	if slot.has_node("CountLabel"):
		slot.get_node("CountLabel").text = ""

func _on_slot_clicked(slot_index: int):
	selected_slot_index = slot_index
	if item_manager:
		var inventory_items = item_manager.get_inventory_items()
		if slot_index < inventory_items.size():
			var item = inventory_items[slot_index]
			handle_item_interaction(item, slot_index)

func handle_item_interaction(item: Dictionary, slot_index: int):
	var item_data = item.get("data", {})
	var item_type = item_data.get("type", "")
	var item_id = item_data.get("id", "")
	
	if item_type == "consumable":
		if item_manager and item_manager.has_method("use_item"):
			item_manager.use_item(item_id)
	elif item_type == "weapon":
		if item_manager and item_manager.has_method("equip_weapon_from_inventory"):
			item_manager.equip_weapon_from_inventory(item_id)

func update_inventory_selection():
	for i in range(inventory_slots.size()):
		var slot = inventory_slots[i]
		if slot and slot.has_node("SelectionOverlay"):
			slot.get_node("SelectionOverlay").visible = false
	
	if selected_slot_index >= 0 and selected_slot_index < inventory_slots.size():
		var selected_slot = inventory_slots[selected_slot_index]
		if selected_slot and selected_slot.has_node("SelectionOverlay"):
			selected_slot.get_node("SelectionOverlay").visible = true

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("inventory_toggle"):
			toggle_inventory()

func _process(_delta):
	if not player:
		return
	
	# Find closest boss
	var bosses = get_tree().get_nodes_in_group("boss")
	var closest_boss = null
	var closest_distance = boss_detection_distance
	
	for boss in bosses:
		if boss and is_instance_valid(boss) and not boss.is_dead:
			var distance = player.global_position.distance_to(boss.global_position)
			if distance < closest_distance:
				closest_boss = boss
				closest_distance = distance
	
	# Update current boss
	if closest_boss != current_boss:
		if current_boss:
			_disconnect_boss(current_boss)
		current_boss = closest_boss
		if current_boss:
			_connect_to_boss(current_boss)
	
	# Update boss bar visibility and value
	if current_boss and is_instance_valid(current_boss):
		_update_boss_bar_display()
	elif boss_bar_container and boss_bar_container.visible:
		_hide_boss_bar()

func _on_inventory_updated():
	refresh_inventory_display()

func _on_item_picked_up(item_data: Dictionary):
	pass

func _on_player_health_changed(new_health: int):
	update_health_display()

func _on_player_dash_changed(new_energy: int):
	if dash_bar:
		dash_bar.value = new_energy

func _on_player_died():
	if death_screen:
		death_screen.visible = true
		var tween = create_tween()
		tween.tween_property(death_screen, "modulate:a", 1.0, 0.5)

func _on_enemy_killed():
	enemies_killed += 1

func _connect_boss_signals(boss: Node):
	if not boss or not is_instance_valid(boss):
		return
	
	print("Connecting to boss: ", boss.name)  # Debug print
	
	# Connect to boss_engaged signal
	if boss.has_signal("boss_engaged"):
		if not boss.boss_engaged.is_connected(_on_boss_engaged):
			boss.boss_engaged.connect(_on_boss_engaged)
			print("Connected to boss_engaged signal")
	
	# Connect to health_changed signal
	if boss.has_signal("health_changed"):
		if not boss.health_changed.is_connected(_on_boss_health_changed):
			boss.health_changed.connect(_on_boss_health_changed.bind(boss))
			print("Connected to health_changed signal")
	elif boss.has_signal("boss_health_changed"):
		if not boss.boss_health_changed.is_connected(_on_boss_health_changed):
			boss.boss_health_changed.connect(_on_boss_health_changed.bind(boss))
			print("Connected to boss_health_changed signal")
	
	# Connect to boss_disengaged signal
	if boss.has_signal("boss_disengaged"):
		if not boss.boss_disengaged.is_connected(_on_boss_disengaged):
			boss.boss_disengaged.connect(_on_boss_disengaged)
	
	# Set initial boss bar values
	if boss_label:
		var boss_type = "Boss"
		if "enemy_type" in boss:
			boss_type = boss.enemy_type.capitalize()
		boss_label.text = boss_type
	
	if boss_bar:
		var max_hp = 100
		if "max_health" in boss:
			max_hp = boss.max_health
		
		var curr_hp = max_hp
		if "current_health" in boss:
			curr_hp = boss.current_health
		
		boss_bar.max_value = max_hp
		boss_bar.value = curr_hp
		print("Set boss bar - Max: ", max_hp, " Current: ", curr_hp)
	
	if not connected_bosses.has(boss):
		connected_bosses.append(boss)

func _connect_to_boss(boss: Node):
	if not boss or not is_instance_valid(boss):
		return
	
	print("=== Connecting to boss: ", boss.name, " ===")
	
	# Connect signals
	if boss.has_signal("boss_engaged"):
		if not boss.boss_engaged.is_connected(_on_boss_engaged):
			boss.boss_engaged.connect(_on_boss_engaged)
			print("✓ Connected boss_engaged")
	
	if boss.has_signal("health_changed"):
		if not boss.health_changed.is_connected(_on_boss_health_changed):
			boss.health_changed.connect(_on_boss_health_changed)
			print("✓ Connected health_changed")
	
	if boss.has_signal("boss_disengaged"):
		if not boss.boss_disengaged.is_connected(_on_boss_disengaged):
			boss.boss_disengaged.connect(_on_boss_disengaged)
			print("✓ Connected boss_disengaged")
	
	# Initialize boss bar
	_show_boss_bar(boss)
	
	
func _show_boss_bar(boss: Node):
	if not boss_bar or not boss_bar_container:
		return
	
	# Get boss name
	var boss_name = "Boss"
	if "enemy_type" in boss:
		boss_name = boss.enemy_type.capitalize() + " Champion"
	
	# Get health values
	var max_hp = 100
	var curr_hp = 100
	
	if "max_health" in boss:
		max_hp = boss.max_health
	if "current_health" in boss:
		curr_hp = boss.current_health
	
	print("Showing boss bar - Name: ", boss_name, " HP: ", curr_hp, "/", max_hp)
	
	# Set values
	if boss_label:
		boss_label.text = boss_name
	
	boss_bar.max_value = max_hp
	boss_bar.value = curr_hp
	
	# Show with fade in
	if not boss_bar_container.visible:
		boss_bar_container.visible = true
		boss_bar_container.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(boss_bar_container, "modulate:a", 1.0, 0.3)
		
func _update_boss_bar_display():
	if not current_boss or not boss_bar:
		return
	
	if "current_health" in current_boss:
		# Direct update without tween for immediate feedback
		boss_bar.value = current_boss.current_health

# Hide boss bar
func _hide_boss_bar():
	if not boss_bar_container:
		return
	
	var tween = create_tween()
	tween.tween_property(boss_bar_container, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): 
		boss_bar_container.visible = false
		current_boss = null
	)
	
func _on_boss_engaged(boss_name: String, max_hp: int, current_hp: int):
	print(">>> Boss Engaged Signal Received! <<<")
	print("Name: ", boss_name, " Max HP: ", max_hp, " Current HP: ", current_hp)
	
	if boss_label:
		boss_label.text = boss_name
	
	if boss_bar:
		boss_bar.max_value = max_hp
		boss_bar.value = current_hp

func _on_boss_health_changed(current_hp: int, max_hp: int):
	print(">>> Boss Health Changed! HP: ", current_hp, "/", max_hp, " <<<")
	
	if boss_bar:
		boss_bar.max_value = max_hp
		var tween = create_tween()
		tween.tween_property(boss_bar, "value", current_hp, 0.2)
		
func _on_boss_disengaged():
	print(">>> Boss Disengaged! <<<")
	_hide_boss_bar()
	
	await get_tree().create_timer(0.5).timeout
	show_victory_popup("DARK ELF CHAMPION")

	
func _disconnect_boss(boss: Node):
	if not boss or not is_instance_valid(boss):
		return
	
	if boss.has_signal("boss_engaged") and boss.boss_engaged.is_connected(_on_boss_engaged):
		boss.boss_engaged.disconnect(_on_boss_engaged)
	
	if boss.has_signal("health_changed") and boss.health_changed.is_connected(_on_boss_health_changed):
		boss.health_changed.disconnect(_on_boss_health_changed)
	
	if boss.has_signal("boss_disengaged") and boss.boss_disengaged.is_connected(_on_boss_disengaged):
		boss.boss_disengaged.disconnect(_on_boss_disengaged)

#func _on_boss_health_changed(new_health: int, boss: Node = null):
	#print("Boss health changed to: ", new_health)  # Debug print
	#
	#if not boss_bar:
		#print("No boss bar found!")
		#return
	#
	#var tween = create_tween()
	#tween.tween_property(boss_bar, "value", new_health, 0.3)

func _on_boss_died(boss: Node = null):
	if boss and connected_bosses.has(boss):
		connected_bosses.erase(boss)
	
	if boss_bar_container and boss_bar_container.visible:
		var tween = create_tween()
		tween.tween_property(boss_bar_container, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func(): boss_bar_container.visible = false)
		
#func _on_boss_engaged(boss_name: String, max_hp: int, current_hp: int):
	#print("Boss engaged callback! Name: ", boss_name, " Max HP: ", max_hp, " Current HP: ", current_hp)
	#
	#if boss_label:
		#boss_label.text = boss_name
	#
	#if boss_bar:
		#boss_bar.max_value = max_hp
		#boss_bar.value = current_hp
	#
	#if boss_bar_container:
		#boss_bar_container.visible = true
		#boss_bar_container.modulate.a = 0.0
		#var tween = create_tween()
		#tween.tween_property(boss_bar_container, "modulate:a", 1.0, 0.3)

#func _on_boss_disengaged():
	#print("Boss disengaged!")
	#if boss_bar_container and boss_bar_container.visible:
		#var tween = create_tween()
		#tween.tween_property(boss_bar_container, "modulate:a", 0.0, 0.3)
		#tween.tween_callback(func(): boss_bar_container.visible = false)

func update_health_display():
	pass

func update_echo_pips(count: int, max_count: int = 3):
	if not echo_container:
		return
	for c in echo_container.get_children():
		c.queue_free()
	for i in range(max_count):
		var pip = ColorRect.new()
		pip.custom_minimum_size = Vector2(12, 12)
		pip.color = Color(0.2, 0.6, 1.0) if i < count else Color(0.1, 0.2, 0.35)
		echo_container.add_child(pip)

func _on_echoes_changed(count: int):
	update_echo_pips(count, 3)

func _on_echo_spawned(duration: float):
	if not echo_container:
		return
	var idx = min(2, max(0, (player.get_echo_count() - 1))) if player and player.has_method("get_echo_count") else 0
	if idx < echo_container.get_child_count():
		var pip = echo_container.get_child(idx)
		if is_instance_valid(pip):
			var t = create_tween()
			t.tween_property(pip, "modulate", Color(0.5, 0.8, 1.0, 1.0), 0.08)
			t.tween_property(pip, "modulate", Color(0.2, 0.6, 1.0, 0.9), 0.18)
			
func show_notification(message: String, color: Color = Color.WHITE, duration: float = 2.0):
	pass
	
func show_victory_popup(boss_name: String = "ENEMY"):
	if not victory_popup:
		return
	
	if victory_text:
		victory_text.text = "ENEMY FELLED"
	
	victory_popup.visible = true
	victory_popup.modulate.a = 0.0
	if victory_banner:
		victory_banner.scale = Vector2(1.2, 1.2)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(victory_popup, "modulate:a", 1.0, 0.4)
	
	if victory_banner:
		tween.tween_property(victory_banner, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(victory_banner, "modulate:a", 1.0, 0.5)
	
	await get_tree().create_timer(3.0).timeout
	hide_victory_popup()

func hide_victory_popup():
	if not victory_popup:
		return
	
	var tween = create_tween()
	tween.tween_property(victory_popup, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func(): victory_popup.visible = false)
