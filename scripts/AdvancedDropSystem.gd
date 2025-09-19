extends Node
class_name DropSystem

var loot_tables = {
	
	#Placeholders
	"slime": {
		"guaranteed_drops": [],  
		"possible_drops": [
			{"item_id": "coin", "chance": 0.8, "min_qty": 1, "max_qty": 5},
			{"item_id": "health_potion", "chance": 0.3, "min_qty": 1, "max_qty": 2},
			{"item_id": "dash_flask", "chance": 0.25, "min_qty": 1, "max_qty": 1},
			{"item_id": "iron_dagger", "chance": 0.1, "min_qty": 1, "max_qty": 1},
			{"item_id": "legendary_mace", "chance": 0.1, "min_qty": 1, "max_qty": 1},
			{"item_id": "steel_hammer", "chance": 0.1, "min_qty": 1, "max_qty": 1},
			{"item_id": "stone_sword_huge", "chance": 0.1, "min_qty": 1, "max_qty": 1}
		]
	},
	#"orc": {
		#"guaranteed_drops": [
			#{"item_id": "coin", "min_qty": 3, "max_qty": 8}
		#],
		#"possible_drops": [
			#{"item_id": "steel_sword", "chance": 0.15, "min_qty": 1, "max_qty": 1},
			#{"item_id": "health_potion", "chance": 0.4, "min_qty": 1, "max_qty": 3},
			#{"item_id": "iron_ore", "chance": 0.25, "min_qty": 1, "max_qty": 2}
		#]
	#},
	#"dragon": {
		#"guaranteed_drops": [
			#{"item_id": "coin", "min_qty": 50, "max_qty": 100},
			#{"item_id": "dragon_scale", "min_qty": 1, "max_qty": 3}
		#],
		#"possible_drops": [
			#{"item_id": "legendary_sword", "chance": 0.3, "min_qty": 1, "max_qty": 1},
			#{"item_id": "ancient_artifact", "chance": 0.2, "min_qty": 1, "max_qty": 1},
			#{"item_id": "fire_gem", "chance": 0.5, "min_qty": 1, "max_qty": 2}
		#]
	#}
}

# Static function to generate drops for an enemy
static func generate_drops(enemy_type: String, drop_system: DropSystem = null) -> Array[Dictionary]:
	if not drop_system:
		drop_system = DropSystem.new()
	
	if not drop_system.loot_tables.has(enemy_type):
		print("No loot table found for enemy type: ", enemy_type)
		return []
	
	var loot_table = drop_system.loot_tables[enemy_type]
	var drops: Array[Dictionary] = []
	
	# Process guaranteed drops
	if "guaranteed_drops" in loot_table:
		for drop in loot_table.guaranteed_drops:
			var quantity = randi_range(drop.min_qty, drop.max_qty)
			drops.append({
				"item_id": drop.item_id,
				"quantity": quantity
			})
			print("Guaranteed drop: ", drop.item_id, " x", quantity)
	
	# Process possible drops
	if "possible_drops" in loot_table:
		for drop in loot_table.possible_drops:
			if randf() <= drop.chance:
				var quantity = randi_range(drop.min_qty, drop.max_qty)
				drops.append({
					"item_id": drop.item_id,
					"quantity": quantity
				})
				print("Random drop: ", drop.item_id, " x", quantity, " (", drop.chance * 100, "% chance)")
	
	return drops

# Function to spawn drops in the world
static func spawn_drops(drops: Array[Dictionary], spawn_position: Vector2, scene_tree: SceneTree):
	for i in range(drops.size()):
		var drop = drops[i]
		
		# Calculate spread position so items don't stack
		var angle = (i * TAU) / max(drops.size(), 1)  # Distribute in circle
		var radius = 20 + (i * 10)  # Spiral outward
		var offset = Vector2(cos(angle), sin(angle)) * radius
		var final_position = spawn_position + offset
		
		# Create pickup item
		var pickup_item = PickupItem.create_pickup_item(
			drop.item_id, 
			final_position, 
			drop.quantity
		)
		
		if pickup_item and scene_tree.current_scene:
			scene_tree.current_scene.add_child(pickup_item)
			if pickup_item is Node2D:
				pickup_item.z_as_relative = true
				pickup_item.z_index = 0
				pickup_item.top_level = false
			if pickup_item.has_method("set_pickup_delay"):
				pickup_item.set_pickup_delay(0.6)
			print("Spawned: ", drop.item_id, " x", drop.quantity, " at ", final_position)

static func handle_enemy_death(enemy_type: String, death_position: Vector2, scene_tree: SceneTree):
	var drop_system = DropSystem.new()
	var drops = generate_drops(enemy_type, drop_system)
	if drops.size() > 0:
		spawn_drops(drops, death_position, scene_tree)
	else:
		print("No drops for ", enemy_type)
