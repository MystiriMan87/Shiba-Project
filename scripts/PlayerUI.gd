extends Control

# UI node references
@onready var health_bar = $HealthContainer/HealthBar
@onready var health_label = $HealthContainer/HealthLabel
@onready var weapon_icon = $WeaponContainer/WeaponIcon
@onready var weapon_name_label = $WeaponContainer/WeaponInfo/WeaponName
@onready var weapon_damage_label = $WeaponContainer/WeaponInfo/WeaponDamage
@onready var attack_cooldown_bar = $WeaponContainer/CooldownBar
@onready var inventory_slots = $InventoryContainer/InventoryGrid

# Container references for toggling visibility
@onready var weapon_container = $WeaponContainer
@onready var inventory_container = $InventoryContainer

# Player reference
var player: CharacterBody2D
var current_weapon_data: Dictionary = {}

# UI state
var is_inventory_open = false

# Weapon database - fallback if ItemManager not available
var weapon_database = {
	"sword": {
		"name": "Iron Sword",
		"icon": "res://Assets/oubliette_weapons - free/spr_wep_iron_sci_0.png",
		"damage": 1,
		"description": "A basic iron sword"
	}
}

# Current inventory (simple array for compatibility)
var inventory_items = []
var max_inventory_slots = 8

func _ready():
	# Find player in scene
	find_player()
	
	# Initialize UI
	setup_ui()
	
	# Hide inventory and weapon containers by default
	hide_inventory_ui()
	
	# Create inventory slots
	create_inventory_slots()
	
	# Connect to ItemManager signals if available
	if has_node("/root/ItemManager") or get_tree().get_nodes_in_group("ItemManager").size() > 0:
		var item_manager = get_node("/root/ItemManager")
		if item_manager:
			item_manager.weapon_changed.connect(_on_weapon_changed)
			item_manager.inventory_updated.connect(_on_inventory_updated)
			print("Connected to ItemManager")
			
			# Get current equipped weapon
			var equipped = item_manager.get_equipped_weapon()
			if not equipped.is_empty():
				current_weapon_data = equipped
				update_weapon_display()
	else:
		# Fallback: Set up initial weapon without ItemManager
		set_current_weapon("sword")
	
	# Update inventory display
	update_inventory_display()

func find_player():
	# Try to find player by group first
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("Found player: ", player.name)
	else:
		# Fallback: search by name
		player = get_tree().get_first_node_in_group("player")
		if not player:
			print("WARNING: Player not found! Make sure player is in 'player' group")

func setup_ui():
	if not player:
		return
	
	# Set up health bar
	if health_bar:
		health_bar.max_value = player.max_health if player.has_method("get") or "max_health" in player else 100
		health_bar.value = player.current_health if player.has_method("get") or "current_health" in player else 100
	
	# Update health label
	update_health_display()

func hide_inventory_ui():
	# Hide both inventory and weapon containers by default
	if inventory_container:
		inventory_container.visible = false
		print("Inventory container hidden")
	else:
		print("Warning: inventory_container not found")
	
	if weapon_container:
		weapon_container.visible = false
		print("Weapon container hidden")
	else:
		print("Warning: weapon_container not found")
	
	is_inventory_open = false

func show_inventory_ui():
	# Show both inventory and weapon containers
	if inventory_container:
		inventory_container.visible = true
		print("Inventory container shown")
	
	if weapon_container:
		weapon_container.visible = true
		print("Weapon container shown")
	
	is_inventory_open = true

func _process(delta):
	if not player:
		return
	
	# Update health display
	update_health_display()
	
	# Update attack cooldown (only if weapon container is visible)
	if weapon_container and weapon_container.visible:
		update_attack_cooldown()
	
	# Update weapon info (in case it changed, only if weapon container is visible)
	if weapon_container and weapon_container.visible:
		update_weapon_display()

func update_health_display():
	if not player:
		return
	
	var current_hp = 100
	var max_hp = 100
	
	# Get health values safely
	if "current_health" in player:
		current_hp = player.current_health
	if "max_health" in player:
		max_hp = player.max_health
	
	# Update health bar
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
		
		# Change health bar color based on health percentage
		var health_percent = float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
		if health_percent > 0.6:
			health_bar.modulate = Color.GREEN
		elif health_percent > 0.3:
			health_bar.modulate = Color.YELLOW
		else:
			health_bar.modulate = Color.RED
	
	# Update health text
	if health_label:
		health_label.text = str(current_hp) + "/" + str(max_hp)

func update_attack_cooldown():
	if not player or not attack_cooldown_bar:
		return
	
	# Show cooldown progress
	if "cooldown_timer" in player and "attack_cooldown" in player:
		if player.cooldown_timer > 0:
			attack_cooldown_bar.visible = true
			attack_cooldown_bar.value = (player.attack_cooldown - player.cooldown_timer) / player.attack_cooldown
		else:
			attack_cooldown_bar.visible = false
	else:
		attack_cooldown_bar.visible = false

# Signal handlers for ItemManager
func _on_weapon_changed(weapon_data: Dictionary):
	current_weapon_data = weapon_data
	if weapon_container and weapon_container.visible:
		update_weapon_display()
	update_inventory_display()

func _on_inventory_updated():
	if inventory_container and inventory_container.visible:
		update_inventory_display()

func set_current_weapon(weapon_id: String):
	# Try to use ItemManager first
	if has_node("/root/ItemManager"):
		var item_manager = get_node("/root/ItemManager")
		item_manager.equip_weapon(weapon_id)
		return
	
	# Fallback to local weapon database
	if weapon_id in weapon_database:
		current_weapon_data = weapon_database[weapon_id].duplicate()
		if weapon_container and weapon_container.visible:
			update_weapon_display()
		update_inventory_display()
		
		# Update player stats if possible
		if player and "attack_damage" in player:
			player.attack_damage = current_weapon_data.get("damage", 1)
	else:
		print("Weapon not found in database: ", weapon_id)

func update_weapon_display():
	if current_weapon_data.is_empty():
		return
	
	# Update weapon icon
	if weapon_icon:
		var icon_path = current_weapon_data.get("icon", current_weapon_data.get("icon_path", ""))
		if icon_path != "":
			var texture = load(icon_path)
			if texture:
				weapon_icon.texture = texture
			else:
				print("Could not load weapon icon: ", icon_path)
	
	# Update weapon name
	if weapon_name_label:
		weapon_name_label.text = current_weapon_data.get("name", "Unknown Weapon")
	
	# Update weapon damage
	if weapon_damage_label:
		var damage = current_weapon_data.get("damage", 1)
		weapon_damage_label.text = "DMG: " + str(damage)

func create_inventory_slots():
	if not inventory_slots:
		print("Warning: inventory_slots not found")
		return
	
	# Clear existing slots
	for child in inventory_slots.get_children():
		child.queue_free()
	
	# Wait for nodes to be freed
	await get_tree().process_frame
	
	# Create inventory slots
	for i in range(max_inventory_slots):
		var slot = create_inventory_slot(i)
		inventory_slots.add_child(slot)

func create_inventory_slot(index: int) -> Control:
	var slot = Panel.new()
	slot.custom_minimum_size = Vector2(64, 64)  # Made bigger (was 48x48)
	slot.name = "InventorySlot" + str(index)
	
	# Add slot background styling
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_color = Color(0.5, 0.5, 0.5)
	slot.add_theme_stylebox_override("panel", style_box)
	
	# Add item icon
	var item_icon = TextureRect.new()
	item_icon.name = "ItemIcon"
	item_icon.anchor_left = 0.1
	item_icon.anchor_top = 0.1
	item_icon.anchor_right = 0.9
	item_icon.anchor_bottom = 0.9
	item_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	slot.add_child(item_icon)
	
	# Add item count label
	var count_label = Label.new()
	count_label.name = "CountLabel"
	count_label.anchor_left = 0.6
	count_label.anchor_top = 0.6
	count_label.anchor_right = 1.0
	count_label.anchor_bottom = 1.0
	count_label.add_theme_font_size_override("font_size", 14)  # Slightly bigger font
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_label.text = ""
	slot.add_child(count_label)
	
	return slot

func update_inventory_display():
	if not inventory_slots:
		return
	
	var slots = inventory_slots.get_children()
	if slots.is_empty():
		return
	
	# Clear all slots first
	for slot in slots:
		if not slot.has_node("ItemIcon") or not slot.has_node("CountLabel"):
			continue
		
		var icon = slot.get_node("ItemIcon")
		var count_label = slot.get_node("CountLabel")
		icon.texture = null
		count_label.text = ""
		
		# Reset slot styling
		var style_box = slot.get_theme_stylebox("panel")
		if style_box is StyleBoxFlat:
			style_box.border_color = Color(0.5, 0.5, 0.5)
	
	var current_slot = 0
	
	# First slot: Show equipped weapon
	if not current_weapon_data.is_empty() and current_slot < slots.size():
		var slot = slots[current_slot]
		if slot.has_node("ItemIcon") and slot.has_node("CountLabel"):
			var icon = slot.get_node("ItemIcon")
			var count_label = slot.get_node("CountLabel")
			
			# Load weapon icon
			var icon_path = current_weapon_data.get("icon", current_weapon_data.get("icon_path", ""))
			if icon_path != "":
				var texture = load(icon_path)
				if texture:
					icon.texture = texture
			
			# Highlight equipped weapon slot
			var style_box = slot.get_theme_stylebox("panel")
			if style_box is StyleBoxFlat:
				style_box.border_color = Color.GOLD  # Golden border for equipped weapon
			
			# Add "E" indicator for equipped
			count_label.text = "E"
			count_label.add_theme_color_override("font_color", Color.GOLD)
			
			current_slot += 1
	
	# Fill remaining slots with inventory items
	var items_to_show = []
	
	# Check if using ItemManager
	if has_node("/root/ItemManager"):
		var item_manager = get_node("/root/ItemManager")
		items_to_show = item_manager.get_inventory_items()
	else:
		# Use local inventory
		items_to_show = inventory_items
	
	# Display items
	for i in range(items_to_show.size()):
		if current_slot >= slots.size():
			break
		
		var slot = slots[current_slot]
		if not slot.has_node("ItemIcon") or not slot.has_node("CountLabel"):
			current_slot += 1
			continue
		
		var item = items_to_show[i]
		var icon = slot.get_node("ItemIcon")
		var count_label = slot.get_node("CountLabel")
		
		# Handle ItemManager format vs local format
		var icon_path = ""
		var quantity = 1
		
		if "data" in item:  # ItemManager format
			icon_path = item.data.get("icon_path", "")
			quantity = item.get("quantity", 1)
		else:  # Local format
			icon_path = "res://Assets/2D Pixel Dungeon Asset Pack/character and tileset/demonstration.png"
			quantity = item.get("count", 1)
		
		# Set item icon
		if icon_path != "":
			var texture = load(icon_path)
			if texture:
				icon.texture = texture
		
		# Set count
		if quantity > 1:
			count_label.text = str(quantity)
		
		current_slot += 1

# Compatibility functions for local inventory system
func add_item_to_inventory(item_id: String, count: int = 1) -> bool:
	# Try ItemManager first
	if has_node("/root/ItemManager"):
		var item_manager = get_node("/root/ItemManager")
		return item_manager.add_item_to_inventory(item_id, count)
	
	# Fallback to local system
	var item_data = {
		"id": item_id,
		"count": count
	}
	
	# Try to stack with existing item
	for i in range(inventory_items.size()):
		if inventory_items[i].id == item_id:
			inventory_items[i].count += count
			if inventory_container and inventory_container.visible:
				update_inventory_display()
			return true
	
	# Add as new item if we have space
	if inventory_items.size() < max_inventory_slots - 1:  # -1 to account for equipped weapon slot
		inventory_items.append(item_data)
		if inventory_container and inventory_container.visible:
			update_inventory_display()
		return true
	
	print("Inventory full!")
	return false

func remove_item_from_inventory(item_id: String, count: int = 1) -> bool:
	# Try ItemManager first
	if has_node("/root/ItemManager"):
		var item_manager = get_node("/root/ItemManager")
		return item_manager.remove_item_from_inventory(item_id, count)
	
	# Fallback to local system
	for i in range(inventory_items.size()):
		if inventory_items[i].id == item_id:
			inventory_items[i].count -= count
			if inventory_items[i].count <= 0:
				inventory_items.remove_at(i)
			if inventory_container and inventory_container.visible:
				update_inventory_display()
			return true
	return false

# Input handling for inventory/UI
func _input(event):
	# Toggle inventory with Tab key
	if event.is_action_pressed("ui_select"):  # Tab key
		toggle_inventory()
	
	# Number keys for quick weapon/item selection
	for i in range(1, 9):
		if event.is_action_pressed("slot_" + str(i)):
			select_inventory_slot(i - 1)

func toggle_inventory():
	print("Toggling inventory")
	
	if is_inventory_open:
		hide_inventory_ui()
		print("Inventory and weapon UI hidden")
	else:
		show_inventory_ui()
		print("Inventory and weapon UI shown")
		# Update displays when opening
		update_inventory_display()
		update_weapon_display()

func select_inventory_slot(index: int):
	# Only allow selection if inventory is open
	if not is_inventory_open:
		return
	
	# Handle equipped weapon in first slot
	if index == 0:
		var weapon_name = current_weapon_data.get("name", "Unknown")
		print("Equipped weapon selected: ", weapon_name)
		return
	
	# Adjust index for inventory items (since equipped weapon takes first slot)
	var inventory_index = index - 1
	
	# Check ItemManager first
	if has_node("/root/ItemManager"):
		var item_manager = get_node("/root/ItemManager")
		var items = item_manager.get_inventory_items()
		if inventory_index < items.size():
			var item = items[inventory_index]
			print("Selected item: ", item.data.name if "data" in item else item.id)
			# Handle equip weapons, use items, etc. here
		return
	
	# Local inventory fallback
	if inventory_index < inventory_items.size():
		var item = inventory_items[inventory_index]
		print("Selected item: ", item.id)
		# Handle equip weapons, use items, etc. here

# Public functions for other scripts to call
func show_damage_number(damage: int, position: Vector2):
	# Create floating damage number
	var damage_label = Label.new()
	damage_label.text = str(damage)
	damage_label.add_theme_font_size_override("font_size", 24)
	damage_label.add_theme_color_override("font_color", Color.RED)
	damage_label.position = position
	add_child(damage_label)
	
	# Animate the damage number
	var tween = create_tween()
	tween.parallel().tween_property(damage_label, "position:y", position.y - 50, 1.0)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(damage_label.queue_free)

func show_notification(text: String, duration: float = 3.0):
	# Simple notification system
	print("Notification: ", text)
	
	# You can expand this to show actual UI notifications
	var notification_label = Label.new()
	notification_label.text = text
	notification_label.add_theme_font_size_override("font_size", 18)
	notification_label.add_theme_color_override("font_color", Color.WHITE)
	notification_label.position = Vector2(50, 50)
	add_child(notification_label)
	
	# Fade out after duration
	var tween = create_tween()
	tween.tween_delay(duration - 1.0)
	tween.tween_property(notification_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(notification_label.queue_free)

# Public function to check if inventory is open (useful for other scripts)
func is_inventory_ui_open() -> bool:
	return is_inventory_open

# Public function to get weapon container visibility (useful for other scripts)  
func is_weapon_ui_visible() -> bool:
	return weapon_container.visible if weapon_container else false
