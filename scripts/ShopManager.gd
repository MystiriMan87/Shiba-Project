extends Node

# Define what items are available in shops
var shop_items = {}

func _ready():
	load_shop_items()

func load_shop_items():
	"""Define all items available for purchase in shops"""
	shop_items = {
		"health_potion": {
			"id": "health_potion",
			"name": "Health Potion",
			"description": "Restores 2 health points",
			"price": 10,
			"type": "consumable"
		},
		"dash_potion": {
			"id": "dash_potion",
			"name": "Dash Flask",
			"description": "Restores dash energy",
			"price": 15,
			"type": "consumable"
		},
		"max_health_upgrade": {
			"id": "max_health_upgrade",
			"name": "Heart Container",
			"description": "Permanently increases max HP by 1",
			"price": 20,
			"type": "upgrade"
		},
		#"iron_sword": {
			#"id": "iron_sword",
			#"name": "Iron Sword",
			#"description": "A basic iron sword",
			#"price": 100,
			#"type": "weapon"
		#},
		"iron_axe": {
			"id": "iron_axe",
			"name": "Iron Axe",
			"description": "A heavy iron axe",
			"price": 30,
			"type": "weapon"
		},
		#"steel_sword": {
			#"id": "steel_sword",
			#"name": "Steel Sword",
			#"description": "A well-crafted steel blade",
			#"price": 200,
			#"type": "weapon"
		#},
		#"iron_dagger": {
			#"id": "iron_dagger",
			#"name": "Iron Dagger",
			#"description": "Fast and deadly",
			#"price": 75,
			#"type": "weapon"
		#},
		#"wooden_key": {
			#"id": "wooden_key",
			#"name": "Wooden Key",
			#"description": "Opens wooden chests",
			#"price": 25,
			#"type": "key"
		#},
		#"iron_key": {
			#"id": "iron_key",
			#"name": "Iron Key",
			#"description": "Opens iron chests",
			#"price": 50,
			#"type": "key"
		#}
	}

func get_shop_items() -> Dictionary:
	"""Returns all available shop items"""
	return shop_items

func get_shop_items_by_type(item_type: String) -> Dictionary:
	"""Returns only items of a specific type"""
	var filtered_items = {}
	for item_id in shop_items:
		var item = shop_items[item_id]
		if item.get("type", "") == item_type:
			filtered_items[item_id] = item
	return filtered_items

func add_shop_item(item_id: String, item_data: Dictionary):
	"""Dynamically add a new item to the shop"""
	shop_items[item_id] = item_data

func remove_shop_item(item_id: String):
	"""Remove an item from the shop"""
	shop_items.erase(item_id)

func get_item_price(item_id: String) -> int:
	"""Get the price of a specific item"""
	if shop_items.has(item_id):
		return shop_items[item_id].get("price", 0)
	return 0

func set_item_price(item_id: String, new_price: int):
	"""Change the price of an item"""
	if shop_items.has(item_id):
		shop_items[item_id]["price"] = new_price
