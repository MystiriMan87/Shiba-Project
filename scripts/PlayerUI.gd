extends Control

# UI Layout settings
@export var slot_size: Vector2 = Vector2(64, 64)
@export var max_inventory_slots: int = 20
@export var inventory_position: Vector2 = Vector2(100, 80)  # Position below health bar
@export var health_bar_position: Vector2 = Vector2(20, 20)  # Top-left for health bar

var inventory_slots: Array = []
var selected_slot_index: int = -1
var item_manager: Node = null
var player: CharacterBody2D = null

# Node references
@onready var inventory_grid: GridContainer = null
@onready var inventory_panel: Control = null
@onready var health_bar: ProgressBar = null
@onready var health_label: Label = null

func _ready():
	# Get references
	item_manager = get_node("/root/ItemManager") if has_node("/root/ItemManager") else null
	player = get_tree().get_first_node_in_group("player")
	
	if not item_manager:
		print("Warning: ItemManager not found at /root/ItemManager")
	if not player:
		print("Warning: Player not found in 'player' group")
	
	setup_ui_layout()
	setup_inventory_ui()
	
	# Connect signals - WAIT FOR PLAYER TO BE READY
	await get_tree().process_frame  # Wait one frame to ensure player is fully initialized
	
	if item_manager:
		if not item_manager.inventory_updated.is_connected(_on_inventory_updated):
			item_manager.inventory_updated.connect(_on_inventory_updated)
		if not item_manager.item_picked_up.is_connected(_on_item_picked_up):
			item_manager.item_picked_up.connect(_on_item_picked_up)
	
	if player:
		# Connect player health changes - the signal should exist now
		if player.has_signal("health_changed"):
			if not player.health_changed.is_connected(_on_player_health_changed):
				player.health_changed.connect(_on_player_health_changed)
				print("Connected to player health_changed signal")
		else:
			print("Warning: Player doesn't have health_changed signal")
	
	# Initial UI updates
	update_health_display()
	
	# Hide inventory initially
	if inventory_panel:
		inventory_panel.visible = false

func setup_ui_layout():
	"""Create the main UI layout with proper positioning"""
	
	# Create health bar at top-left
	create_health_bar()
	
	# Create inventory panel positioned below health bar
	create_inventory_panel()

func create_health_bar():
	"""Create health bar UI at the top"""
	var health_container = VBoxContainer.new()
	health_container.name = "HealthContainer"
	health_container.position = health_bar_position
	health_container.size = Vector2(200, 60)
	add_child(health_container)
	
	# Health label
	health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.text = "Health: 100/100"
	health_label.add_theme_font_size_override("font_size", 14)
	health_label.add_theme_color_override("font_color", Color.WHITE)
	health_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	health_label.add_theme_constant_override("shadow_offset_x", 1)
	health_label.add_theme_constant_override("shadow_offset_y", 1)
	health_container.add_child(health_label)
	
	# Health progress bar
	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.min_value = 0
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.custom_minimum_size = Vector2(180, 20)
	health_bar.show_percentage = false
	
	# Style the health bar
	var health_bar_style = StyleBoxFlat.new()
	health_bar_style.bg_color = Color(0.8, 0.2, 0.2)  # Red background
	health_bar_style.corner_radius_top_left = 4
	health_bar_style.corner_radius_top_right = 4
	health_bar_style.corner_radius_bottom_left = 4
	health_bar_style.corner_radius_bottom_right = 4
	health_bar.add_theme_stylebox_override("fill", health_bar_style)
	
	var health_bg_style = StyleBoxFlat.new()
	health_bg_style.bg_color = Color(0.3, 0.1, 0.1)  # Dark red background
	health_bg_style.corner_radius_top_left = 4
	health_bg_style.corner_radius_top_right = 4
	health_bg_style.corner_radius_bottom_left = 4
	health_bg_style.corner_radius_bottom_right = 4
	health_bar.add_theme_stylebox_override("background", health_bg_style)
	
	health_container.add_child(health_bar)

func create_inventory_panel():
	"""Create inventory panel positioned to not overlap health bar"""
	inventory_panel = Panel.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.size = Vector2(400, 300)
	inventory_panel.position = inventory_position
	
	# Style the inventory panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.08, 0.06, 0.95)
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_color = Color(0.4, 0.3, 0.2)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	inventory_panel.add_theme_stylebox_override("panel", panel_style)
	
	add_child(inventory_panel)
	
	# Add title label
	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Inventory"
	title_label.position = Vector2(10, 5)
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	inventory_panel.add_child(title_label)
	
	# Create scroll container
	var scroll_container = ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.position = Vector2(10, 30)
	scroll_container.size = Vector2(380, 260)
	inventory_panel.add_child(scroll_container)
	
	# Create grid container
	inventory_grid = GridContainer.new()
	inventory_grid.name = "InventoryGrid"
	inventory_grid.columns = 5
	inventory_grid.add_theme_constant_override("h_separation", 4)
	inventory_grid.add_theme_constant_override("v_separation", 4)
	scroll_container.add_child(inventory_grid)

func setup_inventory_ui():
	"""Setup inventory slots"""
	create_inventory_slots()
	refresh_inventory_display()

func update_health_display():
	"""Update health bar and label"""
	if not player or not health_bar or not health_label:
		return
	
	var current_health = 100
	var max_health = 100
	
	# Get health from player using the proper methods
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
	
	# Update UI elements
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = "Health: " + str(current_health) + "/" + str(max_health)
	
	print("UI Health updated: ", current_health, "/", max_health)
	
	# Change color based on health percentage
	var health_percentage = float(current_health) / float(max_health)
	var health_color: Color
	
	if health_percentage > 0.7:
		health_color = Color(0.2, 0.8, 0.2)  # Green
	elif health_percentage > 0.3:
		health_color = Color(0.8, 0.8, 0.2)  # Yellow
	else:
		health_color = Color(0.8, 0.2, 0.2)  # Red
	
	var health_bar_style = StyleBoxFlat.new()
	health_bar_style.bg_color = health_color
	health_bar_style.corner_radius_top_left = 4
	health_bar_style.corner_radius_top_right = 4
	health_bar_style.corner_radius_bottom_left = 4
	health_bar_style.corner_radius_bottom_right = 4
	health_bar.add_theme_stylebox_override("fill", health_bar_style)

func _on_player_health_changed(new_health: int):
	"""Called when player health changes"""
	print("Health changed signal received: ", new_health)
	update_health_display()

func _on_item_picked_up(item_data: Dictionary):
	"""Show notification when item is picked up"""
	var item_name = item_data.get("name", "Unknown Item")
	show_notification("Picked up: " + item_name)

func handle_item_interaction(item: Dictionary, slot_index: int):
	"""Handle item usage with proper consumable effects"""
	var item_data = item.get("data", {})
	var item_type = item_data.get("type", "")
	var item_id = item_data.get("id", "")
	
	if item_type == "consumable":
		# Use consumable item
		if item_manager and item_manager.has_method("use_item"):
			var success = item_manager.use_item(item_id)
			if success:
				var item_name = item_data.get("name", "Item")
				var effect = item_data.get("effect", "")
				var effect_value = item_data.get("effect_value", 0)
				
				# Show feedback
				match effect:
					"heal":
						show_notification("Used " + item_name + " (+%d HP)" % effect_value, Color.GREEN)
						# Force update health display after a small delay
						await get_tree().process_frame  # Wait one frame for ItemManager to process
						update_health_display()
					"restore_mana":
						show_notification("Used " + item_name + " (+%d MP)" % effect_value, Color.BLUE)
					_:
						show_notification("Used " + item_name)
			else:
				show_notification("Cannot use " + item_data.get("name", "item"), Color.RED)
	
	elif item_type == "weapon":
		# Equip/unequip weapon
		if item_manager and item_manager.has_method("equip_weapon_from_inventory"):
			var success = item_manager.equip_weapon_from_inventory(item_id)
			if success:
				show_notification("Equipped: " + item_data.get("name", "weapon"), Color.YELLOW)
			else:
				show_notification("Cannot equip weapon", Color.RED)

func show_notification(message: String, color: Color = Color.WHITE, duration: float = 2.0):
	"""Show a temporary notification message"""
	print("Notification: ", message)
	
	# Create notification label
	var notification = Label.new()
	notification.text = message
	notification.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 100, 50)
	notification.add_theme_font_size_override("font_size", 16)
	notification.add_theme_color_override("font_color", color)
	notification.add_theme_color_override("font_shadow_color", Color.BLACK)
	notification.add_theme_constant_override("shadow_offset_x", 2)
	notification.add_theme_constant_override("shadow_offset_y", 2)
	notification.z_index = 100
	
	add_child(notification)
	
	# Animate and remove
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 0.0, duration)
	tween.tween_callback(notification.queue_free)

# Input handling
func _input(event):
	if event.is_action_pressed("toggle_inventory"):  # You'll need to define this action
		toggle_inventory()
	elif event.is_action_pressed("ui_cancel") and inventory_panel and inventory_panel.visible:
		inventory_panel.visible = false

func toggle_inventory():
	"""Toggle inventory visibility"""
	if inventory_panel:
		inventory_panel.visible = !inventory_panel.visible
		if inventory_panel.visible:
			refresh_inventory_display()

# Keep all your existing inventory slot creation and display functions
func create_inventory_slots():
	# Clear existing slots
	for slot in inventory_slots:
		if is_instance_valid(slot):
			slot.queue_free()
	inventory_slots.clear()
	
	# Clear grid children
	if inventory_grid:
		for child in inventory_grid.get_children():
			child.queue_free()
	
	# Create new slots
	for i in range(max_inventory_slots):
		var slot = create_enhanced_inventory_slot(i)
		inventory_slots.append(slot)
		if inventory_grid:
			inventory_grid.add_child(slot)

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
	
	# Load and set icon with better fitting
	if icon_path != "":
		if ResourceLoader.exists(icon_path):
			var texture = load(icon_path)
			if texture:
				icon.texture = texture
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
	
	# Set quantity/equipped label
	if is_equipped:
		count_label.text = "E"
		count_label.add_theme_color_override("font_color", Color.GOLD)
	elif quantity > 1:
		count_label.text = str(quantity)
		count_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		count_label.text = ""
	
	# Apply rarity-based styling
	var rarity = item_data.get("rarity", "common")
	var rarity_color = get_rarity_color(rarity)
	apply_rarity_effects(slot, rarity_color, is_equipped)

func fit_sprite_to_slot(icon: TextureRect, texture: Texture2D, target_slot_size: Vector2):
	"""Fit sprite to inventory slot with proper scaling and centering"""
	if not texture:
		return
	
	var texture_size = texture.get_size()
	if texture_size.x <= 0 or texture_size.y <= 0:
		return
	
	# Calculate the available area (leaving some padding)
	var padding = 8  # 4 pixels padding on each side
	var available_size = target_slot_size - Vector2(padding, padding)
	
	# Calculate scale to fit within available area while maintaining aspect ratio
	var scale_x = available_size.x / texture_size.x
	var scale_y = available_size.y / texture_size.y
	var scale_factor = min(scale_x, scale_y)  # Use smaller scale to maintain aspect ratio
	
	# Clamp scale factor to reasonable limits
	scale_factor = clamp(scale_factor, 0.1, 2.0)
	
	# Set the texture rect properties for proper fitting
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Apply custom scaling if needed
	var final_size = texture_size * scale_factor
	if final_size.x > available_size.x or final_size.y > available_size.y:
		# If still too big, force it to fit
		icon.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func get_rarity_color(rarity: String) -> Color:
	"""Get color based on item rarity"""
	match rarity:
		"common":
			return Color(0.7, 0.7, 0.7)  # Gray
		"uncommon":
			return Color(0.3, 0.8, 0.3)  # Green
		"rare":
			return Color(0.3, 0.3, 1.0)  # Blue
		"epic":
			return Color(0.8, 0.3, 0.8)  # Purple
		"legendary":
			return Color(1.0, 0.6, 0.0)  # Orange
		_:
			return Color(0.7, 0.7, 0.7)  # Default gray

func apply_rarity_effects(slot: Control, rarity_color: Color, is_equipped: bool):
	"""Apply visual effects based on item rarity"""
	if not slot.has_node("Background"):
		return
		
	var background = slot.get_node("Background")
	var style_box = background.get_theme_stylebox("panel")
	
	if style_box is StyleBoxFlat:
		var new_style = style_box.duplicate()
		
		if is_equipped:
			# Equipped items get gold border
			new_style.border_color = Color.GOLD
			new_style.border_width_top = 3
			new_style.border_width_bottom = 3
			new_style.border_width_left = 3
			new_style.border_width_right = 3
		else:
			# Non-equipped items get rarity-colored border
			new_style.border_color = rarity_color
			new_style.border_width_top = 2
			new_style.border_width_bottom = 2
			new_style.border_width_left = 2
			new_style.border_width_right = 2
		
		background.add_theme_stylebox_override("panel", new_style)

# Keep all your existing slot creation functions...
func create_enhanced_inventory_slot(index: int) -> Control:
	var slot = Control.new()
	slot.custom_minimum_size = slot_size
	slot.name = "InventorySlot" + str(index)
	
	# Enhanced background
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
	
	# Item icon
	var item_icon = TextureRect.new()
	item_icon.name = "ItemIcon"
	item_icon.anchor_left = 0.1
	item_icon.anchor_top = 0.1
	item_icon.anchor_right = 0.9
	item_icon.anchor_bottom = 0.9
	item_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.add_child(item_icon)
	
	# Quantity label
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
	
	# Interactive button
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

func _on_slot_clicked(slot_index: int):
	print("Slot clicked: ", slot_index)
	selected_slot_index = slot_index
	
	# Handle item interactions
	if item_manager:
		var inventory_items = item_manager.get_inventory_items()
		if slot_index < inventory_items.size():
			var item = inventory_items[slot_index]
			handle_item_interaction(item, slot_index)

func refresh_inventory_display():
	if not item_manager:
		return
	
	var inventory_items = item_manager.get_inventory_items()
	
	# Clear all slots first
	for slot in inventory_slots:
		clear_slot(slot)
	
	# Display items in slots
	for i in range(min(inventory_items.size(), inventory_slots.size())):
		var item = inventory_items[i]
		var slot = inventory_slots[i]
		display_item_in_slot(slot, item, i)

func clear_slot(slot: Control):
	if slot.has_node("ItemIcon"):
		slot.get_node("ItemIcon").texture = null
	if slot.has_node("CountLabel"):
		slot.get_node("CountLabel").text = ""

func _on_inventory_updated():
	refresh_inventory_display()
	# Don't automatically update health here - it should only update from player signals

# Public API
func add_item_to_inventory(item_id: String, quantity: int = 1) -> bool:
	if item_manager:
		return item_manager.add_item_to_inventory(item_id, quantity)
	return false
