# ItemManager.gd - Fixed version
extends Node

signal weapon_changed(weapon_data)
signal item_picked_up(item_data)
signal inventory_updated()

var weapons_database = {}
var items_database = {}
var player_inventory = []
var equipped_weapon = null
var max_inventory_size = 20

func _ready():
	load_weapons_database()
	load_items_database()
	equip_weapon("iron_axe")  # Start with iron axe since iron_sword is commented out

func load_weapons_database():
	weapons_database = {
		"iron_sword": {  # FIXED: Uncommented iron_sword
			"id": "iron_sword",
			"name": "Iron Sword",
			"type": "weapon",
			"damage": 1,
			"attack_speed": 1.0,
			"attack_range": 50,
			"icon_path": "res://icon.svg",  # Using fallback since original path may not exist
			"sprite_path": "res://icon.svg",
			"description": "A basic iron sword",
			"rarity": "common",
			"stackable": false,
			"max_stack": 1
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
			"max_stack": 1
		},
		"wooden_bow": {  # FIXED: Uncommented wooden_bow
			"id": "wooden_bow",
			"name": "Wooden Bow",
			"type": "weapon",
			"damage": 1,
			"attack_speed": 1.2,
			"attack_range": 80,
			"icon_path": "res://icon.svg",  # Using fallback
			"sprite_path": "res://icon.svg",
			"description": "A simple wooden bow",
			"rarity": "common",
			"stackable": false,
			"max_stack": 1
		}
	}

func load_items_database():
	items_database = {
		"health_potion": {
			"id": "health_potion",
			"name": "Health Potion",
			"type": "consumable",
			"effect": "heal",
			"effect_value": 2,
			"icon_path": "res://icon.svg",
			"description": "Restores 2 health points",
			"rarity": "common",
			"stackable": true,
			"max_stack": 5
		},
		"magic_crystal": {
			"id": "magic_crystal",
			"name": "Magic Crystal",
			"type": "material",
			"icon_path": "res://icon.svg",
			"description": "A mysterious glowing crystal",
			"rarity": "rare",
			"stackable": true,
			"max_stack": 10
		}
	}

func get_weapon_data(weapon_id: String) -> Dictionary:
	return weapons_database.get(weapon_id, {})

func get_item_data(item_id: String) -> Dictionary:
	# Check both weapons and items databases
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
	
	print("Equipped weapon: ", weapon_data.name)
	return true

func update_player_weapon_stats(player: CharacterBody2D, weapon_data: Dictionary):
	if "damage" in weapon_data:
		player.attack_damage = weapon_data.damage
	
	if "attack_range" in weapon_data:
		player.attack_range = weapon_data.attack_range
	
	if "attack_speed" in weapon_data:
		player.attack_duration = 0.4 / weapon_data.attack_speed

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

# Rest of the methods remain the same...
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
		_:
			print("Unknown item effect: ", effect)
			return false
	
	# Remove the used item
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

# Debug functions
func debug_print_inventory():
	print("=== INVENTORY DEBUG ===")
	print("Total items in inventory: ", player_inventory.size())
	for i in range(player_inventory.size()):
		var item = player_inventory[i]
		print("Slot ", i, ": ", item.data.name, " x", item.quantity, " (", item.data.id, ")")
	print("Equipped weapon: ", equipped_weapon.get("name", "None") if equipped_weapon else "None")
	print("=======================")
