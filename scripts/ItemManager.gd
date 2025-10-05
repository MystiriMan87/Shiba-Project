# ItemManager.gd - Fixed version with proper scaling
extends Node

signal weapon_changed(weapon_data)
signal item_picked_up(item_data)
signal inventory_updated()
signal weapon_equipped(weapon_data)

var weapons_database = {}
var items_database = {}
var player_inventory = []
var equipped_weapon = null
var max_inventory_size = 20

func _ready():
	load_weapons_database()
	load_items_database()
	# Start without an equipped weapon by default

func load_weapons_database():
	weapons_database = {
		"iron_sword": {
			"id": "iron_sword",
			"name": "Iron Sword",
			"type": "weapon",
			"damage": 2.5,
			"attack_speed": 1.0,
			"attack_range": 50,
			"icon_path": "res://textures/items/weapons/iron_sword.png",
			"sprite_path": "res://textures/items/weapons/iron_sword.png",
			"description": "A basic iron sword",
			"rarity": "rare",
			"stackable": false,
			"max_stack": 1,
			"weapon_scale": 2  # NEW: Scale for when used as weapon
		},
		"iron_axe": {
			"id": "iron_axe",
			"name": "Iron Axe",
			"type": "weapon",
			"damage": 2,
			"attack_speed": 0.8,
			"attack_range": 50,
			"icon_path": "res://Assets/oubliette_weapons - free/spr_wep_iron_axe_2.png",
			"sprite_path": "res://Assets/oubliette_weapons - free/spr_wep_iron_axe_2.png",
			"description": "A heavy iron axe",
			"rarity": "uncommon",
			"stackable": false,
			"max_stack": 1,
			"weapon_scale": 2.5  # Larger weapon
		},
		#"wooden_bow": {
			#"id": "wooden_bow",
			#"name": "Wooden Bow",
			#"type": "weapon",
			#"damage": 1,
			#"attack_speed": 1.2,
			#"attack_range": 80,
			#"icon_path": "res://textures/items/weapons/wooden_bow.png",
			#"sprite_path": "res://textures/items/weapons/wooden_bow.png",
			#"description": "A simple wooden bow",
			#"rarity": "common",
			#"stackable": false,
			#"max_stack": 1,
			#"weapon_scale": 1.6
		#},
		"iron_dagger": {
			"id": "iron_dagger",
			"name": "Iron Dagger",
			"type": "weapon",
			"damage": 3,
			"attack_speed": 1.5,
			"attack_range": 35,
			"icon_path": "res://textures/items/weapons/iron_dagger.png",
			"sprite_path": "res://textures/items/weapons/iron_dagger.png",
			"description": "An old, worn dagger. Still sharp enough to be dangerous.",
			"rarity": "common",
			"stackable": false,
			"max_stack": 1,
			"weapon_scale": 1.2  # Smaller weapon
		},
		"stone_sword_huge": {
			"id": "stone_sword_huge",
			"name": "Huge Stone Sword",
			"type": "weapon",
			"damage": 6,
			"attack_speed": 1.5,
			"attack_range": 45,
			"icon_path": "res://textures/items/weapons/stone_sword_huge.png",
			"sprite_path": "res://textures/items/weapons/stone_sword_huge.png",
			"description": "An old, worn dagger. Still sharp enough to be dangerous.",
			"rarity": "common",
			"stackable": false,
			"max_stack": 1,
			"weapon_scale": 4 
		},
		"steel_sword": {
			"id": "steel_sword",
			"name": "Steel Sword",
			"type": "weapon",
			"damage": 5,
			"attack_speed": 1.1,
			"attack_range": 55,
			"icon_path": "res://textures/items/weapons/steel_sword.png",
			"sprite_path": "res://textures/items/weapons/steel_sword.png",
			"description": "A well-crafted steel blade.",
			"rarity": "uncommon",
			"stackable": false,
			"max_stack": 1,
			"weapon_scale": 2.5
		},
		"legendary_sword": {
			"id": "legendary_sword",
			"name": "Legendary Sword",
			"type": "weapon",
			"damage": 15,
			"attack_speed": 1.3,
			"attack_range": 60,
			"icon_path": "res://textures/items/weapons/legendary_sword.png",
			"sprite_path": "res://textures/items/weapons/legendary_sword.png",
			"description": "A blade of legend, humming with ancient power.",
			"rarity": "common",
			"stackable": false,
			"max_stack": 1,
			"weapon_scale": 2.0  # Large legendary weapon
		},
		"legendary_mace": {
			"id": "legendary_mace",
			"name": "Legendary Mace",
			"type": "weapon",
			"damage": 15,
			"attack_speed": 1.3,
			"attack_range": 60,
			"icon_path": "res://textures/items/weapons/legendary_mace.png",
			"sprite_path": "res://textures/items/weapons/legendary_mace.png",
			"description": "A blade of legend, humming with ancient power.",
			"rarity": "common",
			"stackable": false,
			"max_stack": 1,
			"weapon_scale": 2.5  # Large legendary weapon
		},
		"steel_hammer": {
			"id": "steel_hammer",
			"name": "Steel Hammer",
			"type": "weapon",
			"damage": 4,
			"attack_speed": 1.3,
			"attack_range": 60,
			"icon_path": "res://textures/items/weapons/steel_hammer.png",
			"sprite_path": "res://textures/items/weapons/steel_hammer.png",
			"description": "A blade of legend, humming with ancient power.",
			"rarity": "uncommon",
			"stackable": false,
			"max_stack": 1,
			"weapon_scale": 3.0  # Large legendary weapon
		}
	}
	

func load_items_database():
	items_database = {
		"health_potion": {
			"id": "health_potion",
			"name": "Health Potion",
			"type": "consumable",
			"effect": "heal",
			"effect_value": 1,
			"icon_path": "res://textures/items/consumables/health_potion.png",
			"description": "Restores 2 health points",
			"rarity": "common",
			"stackable": true,
			"max_stack": 5,
			"weapon_scale": 1.5
		},
		"mana_potion": {
			"id": "mana_potion",
			"name": "Mana Potion",
			"type": "consumable",
			"effect": "restore_mana",
			"effect_value": 3,
			"icon_path": "res://textures/items/consumables/mana_potion.png",
			"description": "Restores 3 mana points",
			"rarity": "common",
			"stackable": true,
			"max_stack": 5,
			"weapon_scale": 1.5
		},
		"dash_flask": {
			"id": "dash_flask",
			"name": "Dash Flask",
			"type": "consumable",
			"effect": "restore_dash",
			"effect_value": 40,
			"icon_path": "res://textures/items/consumables/mana_potion.png",
			"description": "Restores dash energy",
			"rarity": "uncommon",
			"stackable": true,
			"max_stack": 5,
			"weapon_scale": 1.5
		},
		"magic_crystal": {
			"id": "magic_crystal",
			"name": "Magic Crystal",
			"type": "material",
			"icon_path": "res://textures/items/materials/magic_crystal.png",
			"description": "A mysterious glowing crystal",
			"rarity": "rare",
			"stackable": true,
			"max_stack": 10,
			"weapon_scale": 1.5
		},
		"coin": {
			"id": "coin",
			"name": "Gold Coin",
			"type": "currency",
			"icon_path": "res://textures/items/currency/coin.png",
			"description": "Standard currency of the realm.",
			"rarity": "common",
			"stackable": true,
			"max_stack": 99,
			"value": 1,
			"weapon_scale": 1.5
		},
		"iron_ore": {
			"id": "iron_ore",
			"name": "Iron Ore",
			"type": "material",
			"icon_path": "res://textures/items/materials/iron_ore.png",
			"description": "Raw iron ore, useful for crafting.",
			"rarity": "common",
			"stackable": true,
			"max_stack": 20,
			"weapon_scale": 1.5
		},
		"dragon_scale": {
			"id": "dragon_scale",
			"name": "Dragon Scale",
			"type": "material",
			"icon_path": "res://textures/items/materials/dragon_scale.png",
			"description": "A scale from an ancient dragon.",
			"rarity": "legendary",
			"stackable": true,
			"max_stack": 5,
			"weapon_scale": 1.5
		},
		"magic_ring": {
			"id": "magic_ring",
			"name": "Magic Ring",
			"type": "accessory",
			"icon_path": "res://textures/items/accessories/magic_ring.png",
			"description": "A ring imbued with magical energy.",
			"rarity": "rare",
			"stackable": false,
			"max_stack": 1,
			"magic_bonus": 10,
			"weapon_scale": 1.5
		},
		"ancient_artifact": {
			"id": "ancient_artifact",
			"name": "Ancient Artifact",
			"type": "artifact",
			"icon_path": "res://textures/items/artifacts/ancient_artifact.png",
			"description": "An artifact of unknown origin and immense power.",
			"rarity": "legendary",
			"stackable": false,
			"max_stack": 1,
			"weapon_scale": 1.5
		},
		"fire_gem": {
			"id": "fire_gem",
			"name": "Fire Gem",
			"type": "gem",
			"icon_path": "res://textures/items/gems/fire_gem.png",
			"description": "A gem that radiates intense heat.",
			"rarity": "epic",
			"stackable": true,
			"max_stack": 10,
			"element": "fire",
			"weapon_scale": 1.5
		},
		"wooden_key": {
			"id": "wooden_key",
			"name": "Wooden Key",
			"type": "key",
			"icon_path": "res://Assets/2D Pixel Dungeon Asset Pack/items/keys/key_wooden.png",
			"description": "A simple wooden key that can unlock basic chests.",
			"rarity": "common",
			"stackable": false,
			"max_stack": 1,
			"key_type": "wooden",
			"weapon_scale": 1.5
		},
		"iron_key": {
			"id": "iron_key",
			"name": "Iron Key",
			"type": "key",
			"icon_path": "res://Assets/2D Pixel Dungeon Asset Pack/items/keys/key_iron.png",
			"description": "A sturdy iron key for more secure locks.",
			"rarity": "uncommon",
			"stackable": false,
			"max_stack": 1,
			"key_type": "iron",
			"weapon_scale": 1.5
		},
		"golden_key": {
			"id": "golden_key",
			"name": "Golden Key",
			"type": "key",
			"icon_path": "res://Assets/2D Pixel Dungeon Asset Pack/items/keys/key_golden.png",
			"description": "A precious golden key that unlocks rare treasures.",
			"rarity": "rare",
			"stackable": false,
			"max_stack": 1,
			"key_type": "golden",
			"weapon_scale": 1.5
		}
	}

# FIXED: Function to handle weapon switching from inventory
func equip_weapon_from_inventory(item_id: String) -> bool:
	"""Equip weapon from inventory and return old weapon to inventory"""
	print("Attempting to equip weapon from inventory: ", item_id)
	
	var weapon_data = get_weapon_data(item_id)
	if weapon_data.is_empty():
		print("Item is not a weapon or doesn't exist: ", item_id)
		return false
	
	# Check if player has this weapon in inventory
	var has_weapon = false
	for inventory_item in player_inventory:
		if inventory_item.data.id == item_id and inventory_item.quantity > 0:
			has_weapon = true
			break
	
	if not has_weapon:
		print("Player doesn't have weapon in inventory: ", item_id)
		return false
	
	# Store current equipped weapon to return to inventory
	var old_weapon = equipped_weapon
	
	# Remove the new weapon from inventory
	if not remove_item_from_inventory(item_id, 1):
		print("Failed to remove weapon from inventory")
		return false
	
	# Equip the new weapon
	equipped_weapon = weapon_data.duplicate()
	
	# Return old weapon to inventory if there was one
	if old_weapon and not old_weapon.is_empty():
		add_item_to_inventory(old_weapon.id, 1)
		print("Returned old weapon to inventory: ", old_weapon.name)
	
	# Update player stats and notify systems
	var player = get_tree().get_first_node_in_group("player")
	if player:
		update_player_weapon_stats(player, equipped_weapon)
		update_player_weapon_sprite(player, equipped_weapon)
	
	# Emit signals
	weapon_changed.emit(equipped_weapon)
	weapon_equipped.emit(equipped_weapon)
	inventory_updated.emit()
	
	print("Successfully equipped weapon: ", weapon_data.name)
	return true

# FIXED: Function to update player's weapon sprite with proper scaling
func update_player_weapon_sprite(player: CharacterBody2D, weapon_data: Dictionary):
	"""Update the player's attack sprite to show the new weapon with proper scale"""
	var attack_sprite = null
	
	# Try to find the attack sprite node
	if player.has_node("AttackSprite"):
		attack_sprite = player.get_node("AttackSprite")
	elif player.has_node("WeaponSprite"):
		attack_sprite = player.get_node("WeaponSprite")
	elif player.has_node("Sword"):
		attack_sprite = player.get_node("Sword")
	
	if not attack_sprite:
		print("No attack sprite found on player")
		return
	
	# Load the weapon sprite
	var sprite_path = weapon_data.get("sprite_path", weapon_data.get("icon_path", ""))
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		var weapon_texture = load(sprite_path)
		if weapon_texture:
			attack_sprite.texture = weapon_texture
			print("Updated player weapon sprite to: ", sprite_path)
			
			# FIXED: Use weapon-specific scale for combat
			var weapon_scale = weapon_data.get("weapon_scale", 1.5)
			attack_sprite.scale = Vector2(weapon_scale, weapon_scale)
			print("Set weapon scale to: ", weapon_scale)
		else:
			print("Failed to load weapon texture: ", sprite_path)
	else:
		print("Weapon sprite path not found or doesn't exist: ", sprite_path)

# FIXED: Enhanced texture loading with proper inventory scaling
func get_item_texture(item_id: String) -> Texture2D:
	"""Load and return item texture with fallback support"""
	var item_data = get_item_data(item_id)
	var icon_path = item_data.get("icon_path", "")
	
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var texture = load(icon_path)
		if texture is Texture2D:
			print("Loaded custom texture for ", item_id, ": ", icon_path)
			return texture
		else:
			print("Invalid texture format for: ", icon_path)
	else:
		print("Custom texture not found: ", icon_path, " for item: ", item_id)
	
	# Try fallback texture based on item type/rarity
	var fallback_texture = get_fallback_texture(item_data)
	if fallback_texture:
		return fallback_texture
	
	# Final fallback to Godot's default icon
	var default_path = "res://icon.svg"
	if ResourceLoader.exists(default_path):
		return load(default_path)
	
	return null

func get_fallback_texture(item_data: Dictionary) -> Texture2D:
	"""Generate fallback texture based on item type and rarity"""
	var item_type = item_data.get("type", "unknown")
	var rarity = item_data.get("rarity", "common")
	
	# Try type-specific fallbacks first
	var type_fallbacks = {
		"weapon": "res://textures/fallbacks/weapon_default.png",
		"consumable": "res://textures/fallbacks/potion_default.png",
		"material": "res://textures/fallbacks/material_default.png",
		"currency": "res://textures/fallbacks/coin_default.png"
	}
	
	if type_fallbacks.has(item_type):
		var fallback_path = type_fallbacks[item_type]
		if ResourceLoader.exists(fallback_path):
			return load(fallback_path)
	
	# Generate colored texture based on rarity if no fallback exists
	return create_rarity_texture(rarity)

func create_rarity_texture(rarity: String) -> ImageTexture:
	"""Create a simple colored texture based on rarity"""
	var colors = {
		"common": Color.LIGHT_GRAY,
		"uncommon": Color.GREEN,
		"rare": Color.BLUE,
		"epic": Color.PURPLE,
		"legendary": Color.ORANGE
	}
	
	var color = colors.get(rarity, Color.WHITE)
	var size = Vector2i(24, 24)  # FIXED: Smaller default size for inventory
	
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	
	# Fill with transparent background
	image.fill(Color.TRANSPARENT)
	
	# Create border
	var border_width = 1  # FIXED: Thinner border
	for x in range(size.x):
		for y in range(size.y):
			if x < border_width or x >= size.x - border_width or y < border_width or y >= size.y - border_width:
				image.set_pixel(x, y, Color.BLACK)
			elif x < border_width + 1 or x >= size.x - border_width - 1 or y < border_width + 1 or y >= size.y - border_width - 1:
				image.set_pixel(x, y, color.darkened(0.3))
			else:
				image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

# FIXED: Function to create properly scaled sprites for inventory items
func create_item_sprite(item_id: String, target_size: Vector2 = Vector2(28, 28)) -> Sprite2D:
	"""Create a properly configured Sprite2D for an item in inventory"""
	var sprite = Sprite2D.new()
	var texture = get_item_texture(item_id)
	
	if texture:
		sprite.texture = texture
		
		# FIXED: Better scaling calculation for inventory slots
		var texture_size = texture.get_size()
		if texture_size.x > 0 and texture_size.y > 0:
			# Calculate scale to fit within target size with some padding
			var padding = 4  # Leave some space around the edges
			var available_size = target_size - Vector2(padding, padding)
			
			var scale_x = available_size.x / texture_size.x
			var scale_y = available_size.y / texture_size.y
			var scale_factor = min(scale_x, scale_y)
			
			# Clamp the scale to reasonable bounds
			scale_factor = clamp(scale_factor, 0.1, 2.0)
			
			sprite.scale = Vector2(scale_factor, scale_factor)
			print("Created inventory sprite for ", item_id, " with scale: ", scale_factor)
	
	return sprite

# NEW: Function specifically for creating inventory item sprites
func create_inventory_item_sprite(item_id: String, slot_size: Vector2 = Vector2(32, 32)) -> Sprite2D:
	"""Create a sprite specifically sized for inventory slots"""
	var sprite = Sprite2D.new()
	var texture = get_item_texture(item_id)
	
	if texture:
		sprite.texture = texture
		
		var texture_size = texture.get_size()
		if texture_size.x > 0 and texture_size.y > 0:
			# For inventory, we want items to fit nicely in slots
			var max_size = slot_size * 0.8  # Use 80% of slot size
			
			var scale_x = max_size.x / texture_size.x
			var scale_y = max_size.y / texture_size.y
			var scale_factor = min(scale_x, scale_y)
			
			# Ensure minimum visibility
			scale_factor = max(scale_factor, 0.3)
			
			sprite.scale = Vector2(scale_factor, scale_factor)
	
	return sprite

# Function to validate all texture paths
func validate_all_textures():
	"""Debug function to check which textures are missing"""
	print("=== TEXTURE VALIDATION ===")
	
	var all_items = {}
	all_items.merge(weapons_database)
	all_items.merge(items_database)
	
	var missing_count = 0
	var found_count = 0
	
	for item_id in all_items.keys():
		var item_data = all_items[item_id]
		var icon_path = item_data.get("icon_path", "")
		
		if icon_path == "":
			print("❌ ", item_id, " - No icon_path specified")
			missing_count += 1
		elif ResourceLoader.exists(icon_path):
			print("✅ ", item_id, " - Found: ", icon_path)
			found_count += 1
		else:
			print("❌ ", item_id, " - Missing: ", icon_path)
			missing_count += 1
	
	print("Found: ", found_count, " | Missing: ", missing_count)
	print("==========================")

# Existing functions remain unchanged
func get_weapon_data(weapon_id: String) -> Dictionary:
	return weapons_database.get(weapon_id, {})

func get_item_data(item_id: String) -> Dictionary:
	var data = weapons_database.get(item_id, {})
	if data.is_empty():
		data = items_database.get(item_id, {})
	return data

func equip_weapon(weapon_id: String) -> bool:
	var weapon_data = get_weapon_data(weapon_id)
	if weapon_data.is_empty():
		print("Weapon not found: ", weapon_id)
		return false
	
	equipped_weapon = weapon_data.duplicate()
	weapon_changed.emit(equipped_weapon)
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		update_player_weapon_stats(player, equipped_weapon)
		update_player_weapon_sprite(player, equipped_weapon)
	
	print("Equipped weapon: ", weapon_data.name)
	return true

func update_player_weapon_stats(player: CharacterBody2D, weapon_data: Dictionary):
	if "damage" in weapon_data:
		player.attack_damage = weapon_data.damage
	
	if "attack_range" in weapon_data:
		player.attack_range = weapon_data.attack_range
	
	if "attack_speed" in weapon_data:
		player.attack_duration = 0.4 / weapon_data.attack_speed

# All other existing functions remain the same...
func add_item_to_inventory(item_id: String, quantity: int = 1) -> bool:
	var item_data = get_item_data(item_id)
	if item_data.is_empty():
		print("Item not found in database: ", item_id)
		return false
	
	print("Adding item to inventory: ", item_id, " x", quantity)
	
	# Handle stackable items
	if item_data.get("stackable", false):
		for inventory_item in player_inventory:
			if inventory_item.data.id == item_id:
				var max_stack = item_data.get("max_stack", 1)
				var current_quantity = inventory_item.quantity
				var can_add = min(quantity, max_stack - current_quantity)
				
				if can_add > 0:
					inventory_item.quantity += can_add
					quantity -= can_add
					print("Stacked ", can_add, " items. Remaining: ", quantity)
					
					if quantity <= 0:
						inventory_updated.emit()
						item_picked_up.emit(item_data)
						return true
	
	# Create new inventory slots for remaining items
	while quantity > 0 and player_inventory.size() < max_inventory_size:
		var stack_size = 1
		if item_data.get("stackable", false):
			stack_size = min(quantity, item_data.get("max_stack", 1))
		
		var inventory_item = {
			"id": item_id,
			"data": item_data.duplicate(),
			"quantity": stack_size,
			"equipped": false
		}
		
		player_inventory.append(inventory_item)
		quantity -= stack_size
		print("Created new stack with ", stack_size, " items. Remaining: ", quantity)
	
	if quantity > 0:
		print("Could not add all items - inventory full! Remaining: ", quantity)
		inventory_updated.emit()
		item_picked_up.emit(item_data)
		return false
	
	inventory_updated.emit()
	item_picked_up.emit(item_data)
	print("Successfully added all items to inventory")
	return true

func remove_item_from_inventory(item_id: String, quantity: int = 1) -> bool:
	print("Removing from inventory: ", item_id, " x", quantity)
	
	for i in range(player_inventory.size() - 1, -1, -1):
		var inventory_item = player_inventory[i]
		if inventory_item.data.id == item_id:
			var remove_amount = min(quantity, inventory_item.quantity)
			inventory_item.quantity -= remove_amount
			quantity -= remove_amount
			
			print("Removed ", remove_amount, " from slot ", i, ". New quantity: ", inventory_item.quantity)
			
			if inventory_item.quantity <= 0:
				player_inventory.remove_at(i)
				print("Removed empty slot")
			
			if quantity <= 0:
				inventory_updated.emit()
				return true
	
	print("Could not remove all requested items. Remaining: ", quantity)
	inventory_updated.emit()
	return quantity == 0

func use_item(item_id: String) -> bool:
	var item_data = get_item_data(item_id)
	if item_data.is_empty() or item_data.get("type", "") != "consumable":
		print("Cannot use item: ", item_id, " (not consumable or not found)")
		return false
	
	var has_item = false
	for inventory_item in player_inventory:
		if inventory_item.data.id == item_id and inventory_item.quantity > 0:
			has_item = true
			break
	
	if not has_item:
		print("Item not in inventory: ", item_id)
		return false
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Player not found")
		return false
	
	var effect = item_data.get("effect", "")
	var effect_value = item_data.get("effect_value", 0)
	
	match effect:
		"heal":
			if player.has_method("heal"):
				player.heal(effect_value)
				print("Healed player for ", effect_value, " HP")
		"restore_mana":
			if player.has_method("restore_mana"):
				player.restore_mana(effect_value)
				print("Restored ", effect_value, " mana")
		"restore_dash":
			if player.has_method("restore_dash"):
				player.restore_dash(effect_value)
				print("Restored ", effect_value, " dash energy")
		_:
			print("Unknown item effect: ", effect)
			return false
	
	remove_item_from_inventory(item_id, 1)
	return true

func get_inventory_items() -> Array:
	return player_inventory.duplicate()

func get_equipped_weapon() -> Dictionary:
	return equipped_weapon if equipped_weapon else {}

func has_item(item_id: String) -> int:
	var total = 0
	for inventory_item in player_inventory:
		if inventory_item.data.id == item_id:
			total += inventory_item.quantity
	return total

func save_inventory() -> Dictionary:
	return {
		"inventory": player_inventory,
		"equipped_weapon": equipped_weapon
	}

func load_inventory(save_data: Dictionary):
	if "inventory" in save_data:
		player_inventory = save_data.inventory
	
	if "equipped_weapon" in save_data and save_data.equipped_weapon:
		equipped_weapon = save_data.equipped_weapon
		weapon_changed.emit(equipped_weapon)
	
	inventory_updated.emit()

func get_all_weapon_ids() -> Array:
	return weapons_database.keys()

func get_all_item_ids() -> Array:
	var all_ids = weapons_database.keys()
	all_ids.append_array(items_database.keys())
	return all_ids

func switch_to_next_weapon():
	var weapon_ids = get_all_weapon_ids()
	if weapon_ids.is_empty():
		return
	
	var current_index = -1
	if equipped_weapon and "id" in equipped_weapon:
		current_index = weapon_ids.find(equipped_weapon.id)
	
	var next_index = (current_index + 1) % weapon_ids.size()
	equip_weapon(weapon_ids[next_index])

func switch_to_previous_weapon():
	var weapon_ids = get_all_weapon_ids()
	if weapon_ids.is_empty():
		return
	
	var current_index = -1
	if equipped_weapon and "id" in equipped_weapon:
		current_index = weapon_ids.find(equipped_weapon.id)
	
	var prev_index = (current_index - 1) % weapon_ids.size()
	if prev_index < 0:
		prev_index = weapon_ids.size() - 1
	
	equip_weapon(weapon_ids[prev_index])

func debug_print_inventory():
	print("=== INVENTORY DEBUG ===")
	print("Total items in inventory: ", player_inventory.size())
	for i in range(player_inventory.size()):
		var item = player_inventory[i]
		print("Slot ", i, ": ", item.data.name, " x", item.quantity, " (", item.data.id, ")")
	print("Equipped weapon: ", equipped_weapon.get("name", "None") if equipped_weapon else "None")
	print("=======================")

func debug_add_test_items():
	"""Add various items for testing purposes"""
	print("Adding test items...")
	add_item_to_inventory("health_potion", 3)
	add_item_to_inventory("coin", 15)
	add_item_to_inventory("iron_ore", 5)
	add_item_to_inventory("fire_gem", 2)
	add_item_to_inventory("rusty_dagger", 1)
	add_item_to_inventory("steel_sword", 1)
	add_item_to_inventory("wooden_bow", 1)
	print("Test items added!")
