extends Node

# Singleton for managing items and weapons
# Add this as an AutoLoad in Project Settings

signal weapon_changed(weapon_data)
signal item_picked_up(item_data)
signal inventory_updated()

# Item and weapon databases
var weapons_database = {}
var items_database = {}
var player_inventory = []
var equipped_weapon = null
var max_inventory_size = 20

func _ready():
	# Load item databases
	load_weapons_database()
	load_items_database()
	
	# Set default weapon
	equip_weapon("iron_sword")

func load_weapons_database():
	# You can load this from JSON files later
	weapons_database = {
		"iron_sword": {
			"id": "iron_axe",
			"name": "Iron Axe",
			"type": "weapon",
			"damage": 1,
			"attack_speed": 1.0,
			"attack_range": 50,
			"icon_path": "res://Assets/oubliette_weapons - free/spr_wep_iron_axe_2.png",
			"sprite_path": "res://Assets/oubliette_weapons - free/spr_wep_iron_axe_2.png",
			"description": "A sturdy iron axe. Reliable and sharp.",
			"rarity": "common",
			#"durability": 100,
			#"max_durability": 100
		}
		#"magic_sword": {
			#"id": "magic_sword",
			#"name": "Enchanted Blade",
			#"type": "weapon",
			#"damage": 2,
			#"attack_speed": 1.2,
			#"attack_range": 55,
			#"icon_path": "res://Assets/2D Pixel Dungeon Asset Pack/character and tileset/magic_sword_icon.png",
			#"sprite_path": "res://Assets/2D Pixel Dungeon Asset Pack/character and tileset/magic_sword_sprite.png",
			#"description": "A blade infused with mystical energy.",
			#"rarity": "rare",
			#"durability": 150,
			#"max_durability": 150,
			#"special_effects": ["magic_damage", "mana_restore"]
		#},
		#"crystal_sword": {
			#"id": "crystal_sword",
			#"name": "Crystal Sword",
			#"type": "weapon",
			#"damage": 3,
			#"attack_speed": 0.9,
			#"attack_range": 60,
			#"icon_path": "res://Assets/2D Pixel Dungeon Asset Pack/character and tileset/crystal_sword_icon.png",
			#"sprite_path": "res://Assets/2D Pixel Dungeon Asset Pack/character and tileset/crystal_sword_sprite.png",
			#"description": "A sword forged from pure crystal. Extremely sharp.",
			#"rarity": "epic",
			#"durability": 200,
			#"max_durability": 200,
			#"special_effects": ["critical_chance", "ice_damage"]
		#}
	}

func load_items_database():
	items_database = {
		#"health_potion": {
			#"id": "health_potion",
			#"name": "Health Potion",
			#"type": "consumable",
			#"icon_path": "res://Assets/2D Pixel Dungeon Asset Pack/items and trap_animation/health_potion.png",
			#"description": "Restores 3 health points.",
			#"effect": "heal",
			#"effect_value": 3,
			#"rarity": "common",
			#"stackable": true,
			#"max_stack": 10
		#},
		#"mana_potion": {
			#"id": "mana_potion",
			#"name": "Mana Potion",
			#"type": "consumable",
			#"icon_path": "res://Assets/2D Pixel Dungeon Asset Pack/items and trap_animation/mana_potion.png",
			#"description": "Restores mana points.",
			#"effect": "restore_mana",
			#"effect_value": 50,
			#"rarity": "common",
			#"stackable": true,
			#"max_stack": 10
		#},
		#"gold_coin": {
			#"id": "gold_coin",
			#"name": "Gold Coin",
			#"type": "currency",
			#"icon_path": "res://Assets/2D Pixel Dungeon Asset Pack/items and trap_animation/gold_coin.png",
			#"description": "Currency used for trading.",
			#"rarity": "common",
			#"stackable": true,
			#"max_stack": 999
		#}
	}

func get_weapon_data(weapon_id: String) -> Dictionary:
	return weapons_database.get(weapon_id, {})

func get_item_data(item_id: String) -> Dictionary:
	return items_database.get(item_id, {})

func equip_weapon(weapon_id: String) -> bool:
	var weapon_data = get_weapon_data(weapon_id)
	if weapon_data.is_empty():
		print("Weapon not found: ", weapon_id)
		return false
	
	equipped_weapon = weapon_data.duplicate()
	weapon_changed.emit(equipped_weapon)
	
	# Update player stats if player exists
	var player = get_tree().get_first_node_in_group("player")
	if player:
		update_player_weapon_stats(player, equipped_weapon)
	
	print("Equipped weapon: ", equipped_weapon.name)
	return true

func update_player_weapon_stats(player: CharacterBody2D, weapon_data: Dictionary):
	# Update player's attack damage and other stats
	if "damage" in weapon_data:
		player.attack_damage = weapon_data.damage
	
	if "attack_range" in weapon_data:
		player.attack_range = weapon_data.attack_range
	
	# Update attack duration based on attack speed
	if "attack_speed" in weapon_data:
		player.attack_duration = 0.4 / weapon_data.attack_speed

func add_item_to_inventory(item_id: String, quantity: int = 1) -> bool:
	var item_data = get_item_data(item_id)
	if item_data.is_empty():
		print("Item not found: ", item_id)
		return false
	
	# Check if item is stackable
	if item_data.get("stackable", false):
		# Try to stack with existing items
		for inventory_item in player_inventory:
			if inventory_item.id == item_id:
				var max_stack = item_data.get("max_stack", 1)
				var can_add = min(quantity, max_stack - inventory_item.quantity)
				inventory_item.quantity += can_add
				quantity -= can_add
				
				if quantity <= 0:
					inventory_updated.emit()
					item_picked_up.emit(item_data)
					return true
	
	# Add as new inventory slots
	while quantity > 0 and player_inventory.size() < max_inventory_size:
		var stack_size = 1
		if item_data.get("stackable", false):
			stack_size = min(quantity, item_data.get("max_stack", 1))
		
		var inventory_item = {
			"id": item_id,
			"data": item_data.duplicate(),
			"quantity": stack_size
		}
		
		player_inventory.append(inventory_item)
		quantity -= stack_size
	
	if quantity > 0:
		print("Inventory full! Could not add ", quantity, " ", item_data.name)
		return false
	
	inventory_updated.emit()
	item_picked_up.emit(item_data)
	return true

func remove_item_from_inventory(item_id: String, quantity: int = 1) -> bool:
	for i in range(player_inventory.size() - 1, -1, -1):
		var inventory_item = player_inventory[i]
		if inventory_item.id == item_id:
			var remove_amount = min(quantity, inventory_item.quantity)
			inventory_item.quantity -= remove_amount
			quantity -= remove_amount
			
			if inventory_item.quantity <= 0:
				player_inventory.remove_at(i)
			
			if quantity <= 0:
				inventory_updated.emit()
				return true
	
	return false

func use_item(item_id: String) -> bool:
	var item_data = get_item_data(item_id)
	if item_data.is_empty() or item_data.type != "consumable":
		return false
	
	# Check if item is in inventory
	var has_item = false
	for inventory_item in player_inventory:
		if inventory_item.id == item_id and inventory_item.quantity > 0:
			has_item = true
			break
	
	if not has_item:
		return false
	
	# Apply item effect
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return false
	
	var effect = item_data.get("effect", "")
	var effect_value = item_data.get("effect_value", 0)
	
	match effect:
		"heal":
			if player.has_method("heal"):
				player.heal(effect_value)
				print("Used ", item_data.name, " - healed ", effect_value, " HP")
		"restore_mana":
			if player.has_method("restore_mana"):
				player.restore_mana(effect_value)
				print("Used ", item_data.name, " - restored ", effect_value, " mana")
		_:
			print("Unknown item effect: ", effect)
			return false
	
	# Remove item from inventory
	remove_item_from_inventory(item_id, 1)
	return true

func get_inventory_items() -> Array:
	return player_inventory.duplicate()

func get_equipped_weapon() -> Dictionary:
	return equipped_weapon if equipped_weapon else {}

func has_item(item_id: String) -> int:
	var total = 0
	for inventory_item in player_inventory:
		if inventory_item.id == item_id:
			total += inventory_item.quantity
	return total

# Save/Load functions (for persistence)
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

# Debug functions
func debug_add_all_weapons():
	for weapon_id in weapons_database:
		add_item_to_inventory(weapon_id, 1)

func debug_add_test_items():
	add_item_to_inventory("health_potion", 5)
	add_item_to_inventory("mana_potion", 3)
	add_item_to_inventory("gold_coin", 100)

# Get all weapons for testing
func get_all_weapon_ids() -> Array:
	return weapons_database.keys()

# Weapon switching function
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
