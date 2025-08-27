# PlayerUI.gd - Fixed complete script
extends Control

# FIXED: Added missing variables
@export var slot_size: Vector2 = Vector2(64, 64)
@export var max_inventory_slots: int = 20

var inventory_slots: Array = []
var selected_slot_index: int = -1
var item_manager: Node = null

# Node references - adjust these paths to match your scene structure
@onready var inventory_grid: GridContainer = $InventoryPanel/ScrollContainer/InventoryGrid if has_node("InventoryPanel/ScrollContainer/InventoryGrid") else null
@onready var inventory_panel: Control = $InventoryPanel if has_node("InventoryPanel") else null

func _ready():
	# Get ItemManager reference
	item_manager = get_node("/root/ItemManager") if has_node("/root/ItemManager") else null
	if not item_manager:
		print("Warning: ItemManager not found at /root/ItemManager")
	
	setup_inventory_ui()
	
	# Connect to ItemManager signals if available
	if item_manager:
		if not item_manager.inventory_updated.is_connected(_on_inventory_updated):
			item_manager.inventory_updated.connect(_on_inventory_updated)

func setup_inventory_ui():
	# Create inventory grid if it doesn't exist
	if not inventory_grid:
		create_inventory_ui()
	
	# Create initial inventory slots
	create_inventory_slots()
	refresh_inventory_display()

func create_inventory_ui():
	# Create basic UI structure if nodes don't exist
	if not inventory_panel:
		inventory_panel = Panel.new()
		inventory_panel.name = "InventoryPanel"
		inventory_panel.size = Vector2(400, 300)
		inventory_panel.position = Vector2(50, 50)
		add_child(inventory_panel)
	
	if not inventory_grid:
		var scroll_container = ScrollContainer.new()
		scroll_container.name = "ScrollContainer"
		scroll_container.anchor_left = 0.0
		scroll_container.anchor_top = 0.0
		scroll_container.anchor_right = 1.0
		scroll_container.anchor_bottom = 1.0
		inventory_panel.add_child(scroll_container)
		
		inventory_grid = GridContainer.new()
		inventory_grid.name = "InventoryGrid"
		inventory_grid.columns = 5
		scroll_container.add_child(inventory_grid)

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

# FIXED: Updated display_item_in_slot function with all missing references
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
		print("ItemManager format - icon_path: ", icon_path, ", equipped: ", is_equipped)
	else: 
		item_data = item
		if "icon" in item:
			icon_path = item.icon
		elif "id" in item and item_manager:
			# FIXED: Use item_manager instead of undefined weapon_database
			var weapon_data = item_manager.get_weapon_data(item.id)
			if not weapon_data.is_empty():
				icon_path = weapon_data.get("icon_path", "")
		
		quantity = item.get("count", item.get("quantity", 1))
		is_equipped = item.get("equipped", false)
		print("Local format - icon_path: ", icon_path, ", equipped: ", is_equipped)
	
	# Load and set icon with better fitting
	if icon_path != "":
		print("Attempting to load texture: ", icon_path)
		if ResourceLoader.exists(icon_path):
			var texture = load(icon_path)
			if texture:
				icon.texture = texture
				
				# Enhanced sprite fitting to slot
				fit_sprite_to_slot(icon, texture, slot_size)
				
				print("Successfully loaded and fitted texture for slot ", slot_index)
			else:
				print("Failed to load texture: ", icon_path)
		else:
			print("Texture file doesn't exist: ", icon_path)
			var fallback_path = "res://icon.svg"   
			if ResourceLoader.exists(fallback_path):
				var texture = load(fallback_path)
				icon.texture = texture
				fit_sprite_to_slot(icon, texture, slot_size)
				print("Using fallback icon")
	else:
		print("No icon path provided for slot ", slot_index)
	
	# Set quantity/equipped label
	if is_equipped:
		count_label.text = "E"
		count_label.add_theme_color_override("font_color", Color.GOLD)
		print("Marked slot ", slot_index, " as equipped")
	elif quantity > 1:
		count_label.text = str(quantity)
		count_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		count_label.text = ""
	
	# Apply rarity-based styling
	var rarity = item_data.get("rarity", "common")
	var rarity_color = get_rarity_color(rarity)
	
	# Apply visual effects based on rarity
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
	
	print("Fitted sprite - Original: ", texture_size, " Scale: ", scale_factor, " Final: ", final_size)

# FIXED: Added missing get_rarity_color function
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
			
			# Add equipped glow effect
			if slot.has_node("InnerGlow"):
				var inner_glow = slot.get_node("InnerGlow")
				var glow_style = inner_glow.get_theme_stylebox("panel")
				if glow_style is StyleBoxFlat:
					var new_glow = glow_style.duplicate()
					new_glow.bg_color = Color.GOLD * 0.3
					inner_glow.add_theme_stylebox_override("panel", new_glow)
		else:
			# Non-equipped items get rarity-colored border
			new_style.border_color = rarity_color
			new_style.border_width_top = 2
			new_style.border_width_bottom = 2
			new_style.border_width_left = 2
			new_style.border_width_right = 2
			
			# Add subtle rarity glow for rare+ items
			var rarity_name = get_rarity_name(rarity_color)
			if rarity_name in ["rare", "epic", "legendary"] and slot.has_node("InnerGlow"):
				var inner_glow = slot.get_node("InnerGlow")
				var glow_style = inner_glow.get_theme_stylebox("panel")
				if glow_style is StyleBoxFlat:
					var new_glow = glow_style.duplicate()
					new_glow.bg_color = rarity_color * 0.2
					inner_glow.add_theme_stylebox_override("panel", new_glow)
		
		background.add_theme_stylebox_override("panel", new_style)

func get_rarity_name(rarity_color: Color) -> String:
	"""Get rarity name from color for effect application"""
	if rarity_color.is_equal_approx(Color(0.7, 0.7, 0.7)):
		return "common"
	elif rarity_color.is_equal_approx(Color(0.3, 0.8, 0.3)):
		return "uncommon" 
	elif rarity_color.is_equal_approx(Color(0.3, 0.3, 1.0)):
		return "rare"
	elif rarity_color.is_equal_approx(Color(0.8, 0.3, 0.8)):
		return "epic"
	elif rarity_color.is_equal_approx(Color(1.0, 0.6, 0.0)):
		return "legendary"
	else:
		return "common"

# Enhanced version of the create_enhanced_inventory_slot function with better icon handling
func create_enhanced_inventory_slot(index: int) -> Control:
	var slot = Control.new()
	slot.custom_minimum_size = slot_size
	slot.name = "InventorySlot" + str(index)
	
	# Enhanced background with gradient effect
	var background = Panel.new()
	background.name = "Background"
	background.anchor_left = 0.0
	background.anchor_top = 0.0
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	
	# Create stylish background with gradient
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.12, 0.08, 0.95)  # Rich dark brown
	style_box.border_width_top = 2
	style_box.border_width_bottom = 3
	style_box.border_width_left = 2
	style_box.border_width_right = 3
	style_box.border_color = Color(0.4, 0.3, 0.2, 0.8)  # Bronze border
	style_box.corner_radius_top_left = 6
	style_box.corner_radius_top_right = 6
	style_box.corner_radius_bottom_left = 6
	style_box.corner_radius_bottom_right = 6
	
	# Add subtle shadow effect
	style_box.shadow_color = Color(0, 0, 0, 0.3)
	style_box.shadow_size = 2
	style_box.shadow_offset = Vector2(2, 2)
	
	background.add_theme_stylebox_override("panel", style_box)
	slot.add_child(background)
	
	# Inner glow effect
	var inner_glow = Panel.new()
	inner_glow.name = "InnerGlow"
	inner_glow.anchor_left = 0.05
	inner_glow.anchor_top = 0.05
	inner_glow.anchor_right = 0.95
	inner_glow.anchor_bottom = 0.95
	
	var glow_style = StyleBoxFlat.new()
	glow_style.bg_color = Color(0.25, 0.2, 0.15, 0.3)
	glow_style.corner_radius_top_left = 4
	glow_style.corner_radius_top_right = 4
	glow_style.corner_radius_bottom_left = 4
	glow_style.corner_radius_bottom_right = 4
	inner_glow.add_theme_stylebox_override("panel", glow_style)
	slot.add_child(inner_glow)
	
	# Item icon with better scaling and positioning
	var item_icon = TextureRect.new()
	item_icon.name = "ItemIcon"
	item_icon.anchor_left = 0.1
	item_icon.anchor_top = 0.1
	item_icon.anchor_right = 0.9
	item_icon.anchor_bottom = 0.9
	item_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.add_child(item_icon)
	
	# Quantity label with better styling
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
	
	# Enhanced selection highlight with animation
	var selection_highlight = Panel.new()
	selection_highlight.name = "SelectionHighlight"
	selection_highlight.anchor_left = 0.0
	selection_highlight.anchor_top = 0.0
	selection_highlight.anchor_right = 1.0
	selection_highlight.anchor_bottom = 1.0
	selection_highlight.visible = false
	
	var highlight_style = StyleBoxFlat.new()
	highlight_style.bg_color = Color.TRANSPARENT
	highlight_style.border_width_top = 3
	highlight_style.border_width_bottom = 3
	highlight_style.border_width_left = 3
	highlight_style.border_width_right = 3
	highlight_style.border_color = Color(1.0, 0.8, 0.0, 0.9)  # Golden highlight
	highlight_style.corner_radius_top_left = 6
	highlight_style.corner_radius_top_right = 6
	highlight_style.corner_radius_bottom_left = 6
	highlight_style.corner_radius_bottom_right = 6
	selection_highlight.add_theme_stylebox_override("panel", highlight_style)
	slot.add_child(selection_highlight)
	
	# Hover effect panel
	var hover_highlight = Panel.new()
	hover_highlight.name = "HoverHighlight"
	hover_highlight.anchor_left = 0.0
	hover_highlight.anchor_top = 0.0
	hover_highlight.anchor_right = 1.0
	hover_highlight.anchor_bottom = 1.0
	hover_highlight.visible = false
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.3, 0.25, 0.2, 0.4)
	hover_style.border_width_top = 2
	hover_style.border_width_bottom = 2
	hover_style.border_width_left = 2
	hover_style.border_width_right = 2
	hover_style.border_color = Color(0.6, 0.5, 0.4, 0.7)
	hover_style.corner_radius_top_left = 6
	hover_style.corner_radius_top_right = 6
	hover_style.corner_radius_bottom_left = 6
	hover_style.corner_radius_bottom_right = 6
	hover_highlight.add_theme_stylebox_override("panel", hover_style)
	slot.add_child(hover_highlight)
	
	# Interactive button
	var button = Button.new()
	button.name = "ClickDetector"
	button.anchor_left = 0.0
	button.anchor_top = 0.0
	button.anchor_right = 1.0
	button.anchor_bottom = 1.0
	button.flat = true
	# FIXED: Connect to proper callback functions
	button.pressed.connect(_on_slot_clicked.bind(index))
	button.mouse_entered.connect(_on_slot_hover_start.bind(index))
	button.mouse_exited.connect(_on_slot_hover_end.bind(index))
	slot.add_child(button)
	
	return slot

# FIXED: Added missing callback functions
func _on_slot_clicked(slot_index: int):
	print("Slot clicked: ", slot_index)
	selected_slot_index = slot_index
	update_slot_selection()
	
	# Handle item interactions
	if item_manager:
		var inventory_items = item_manager.get_inventory_items()
		if slot_index < inventory_items.size():
			var item = inventory_items[slot_index]
			handle_item_interaction(item, slot_index)

func _on_slot_hover_start(slot_index: int):
	if slot_index >= 0 and slot_index < inventory_slots.size():
		var slot = inventory_slots[slot_index]
		if slot.has_node("HoverHighlight"):
			slot.get_node("HoverHighlight").visible = true

func _on_slot_hover_end(slot_index: int):
	if slot_index >= 0 and slot_index < inventory_slots.size():
		var slot = inventory_slots[slot_index]
		if slot.has_node("HoverHighlight"):
			slot.get_node("HoverHighlight").visible = false

func handle_item_interaction(item: Dictionary, slot_index: int):
	# Right-click or double-click logic for using items
	var item_type = item.get("data", {}).get("type", "")
	
	if item_type == "consumable":
		# Use consumable item
		if item_manager:
			item_manager.use_item(item.get("id", ""))
	elif item_type == "weapon":
		# Equip/unequip weapon
		if item_manager:
			item_manager.equip_weapon(item.get("id", ""))

func update_slot_selection():
	for i in range(inventory_slots.size()):
		var slot = inventory_slots[i]
		if slot.has_node("SelectionHighlight"):
			slot.get_node("SelectionHighlight").visible = (i == selected_slot_index)

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

# Function to spawn test pickup items for debugging
func debug_spawn_pickup_items():
	if not item_manager:
		print("ItemManager not found for spawning test items")
		return
	
	var item_ids = item_manager.get_all_item_ids()
	var spawn_positions = [
		Vector2(100, 100),
		Vector2(150, 100), 
		Vector2(200, 100),
		Vector2(100, 150),
		Vector2(150, 150)
	]
	
	for i in range(min(item_ids.size(), spawn_positions.size())):
		var pickup_item = PickupItem.create_pickup_item(item_ids[i], spawn_positions[i])
		get_tree().current_scene.add_child(pickup_item)
		print("Spawned pickup item: ", item_ids[i], " at ", spawn_positions[i])

# Public API functions for external interaction
func add_item_to_inventory(item_id: String, quantity: int = 1) -> bool:
	if item_manager:
		return item_manager.add_item_to_inventory(item_id, quantity)
	return false

func toggle_inventory():
	if inventory_panel:
		inventory_panel.visible = !inventory_panel.visible

func show_notification(message: String, duration: float = 2.0):
	print("Notification: ", message)
	# You can implement a proper notification system here
