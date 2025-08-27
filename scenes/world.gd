# Main.gd - Fixed main scene script
extends Node2D

func _ready():
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Spawn some test items around the world
	spawn_pickup_item("iron_sword", Vector2(200, 300))
	spawn_pickup_item("health_potion", Vector2(300, 300), 3)
	spawn_pickup_item("iron_axe", Vector2(400, 300))
	spawn_pickup_item("magic_crystal", Vector2(500, 300), 2)
	spawn_pickup_item("wooden_bow", Vector2(600, 300))
	
	print("Spawned test pickup items")
	
		# Test texture loading
	ItemManager.validate_all_textures()
	
	# Add some items to inventory
	ItemManager.debug_add_test_items()
	
	# Test individual texture loading
	var texture = ItemManager.get_item_texture("health_potion")
	if texture:
		print("Successfully loaded health potion texture!")
	
	# Create a sprite for testing
	var test_sprite = ItemManager.create_item_sprite("coin", Vector2(64, 64))
	add_child(test_sprite)
	test_sprite.position = Vector2(100, 100)

func spawn_pickup_item(item_id: String, position: Vector2, quantity: int = 1):
	# FIXED: Use the static create function instead of trying to load a .tscn file
	var pickup = PickupItem.create_pickup_item(item_id, position, quantity)
	add_child(pickup)
	print("Spawned ", item_id, " x", quantity, " at ", position)

func _on_enemy_died(enemy_position: Vector2):
	# Random chance to drop an item
	if randf() < 0.3:  # 30% drop rate
		var possible_items = ["health_potion", "magic_crystal", "iron_sword"]
		var random_item = possible_items[randi() % possible_items.size()]
		var random_quantity = 1
		
		# Sometimes drop more consumables
		if random_item in ["health_potion", "magic_crystal"]:
			random_quantity = randi_range(1, 3)
		
		spawn_pickup_item(random_item, enemy_position, random_quantity)

# Test function - call this to debug pickup system
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				# Spawn item at mouse position
				var mouse_pos = get_global_mouse_position()
				spawn_pickup_item("health_potion", mouse_pos)
			KEY_2:
				# Spawn weapon at mouse position
				var mouse_pos = get_global_mouse_position()
				spawn_pickup_item("iron_sword", mouse_pos)
			KEY_3:
				# Debug print inventory
				var item_manager = get_node("/root/ItemManager")
				if item_manager:
					item_manager.debug_print_inventory()

# Function to test if pickup system is working
func test_pickup_system():
	print("=== PICKUP SYSTEM TEST ===")
	
	# Check if ItemManager exists
	var item_manager = get_node("/root/ItemManager")
	if item_manager:
		print("✓ ItemManager found")
		print("Available items: ", item_manager.get_all_item_ids())
	else:
		print("✗ ItemManager not found")
	
	# Check if player exists and has pickup system
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("✓ Player found")
		if player.has_node("PickupArea"):
			print("✓ Player has PickupArea")
			var pickup_area = player.get_node("PickupArea")
			print("  - Pickup area collision_mask: ", pickup_area.collision_mask)
			print("  - Pickup area collision_layer: ", pickup_area.collision_layer)
		else:
			print("✗ Player missing PickupArea")
	else:
		print("✗ Player not found")
	
	print("==========================")
