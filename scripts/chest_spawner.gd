extends Node
class_name ChestSpawner

# Quick chest spawning functions
func spawn_chest(chest_type: String, position: Vector2) -> Chest:
	var chest_scene = load("res://scenes/chest.tscn")
	if not chest_scene:
		return null
	
	var chest = chest_scene.instantiate()
	get_tree().current_scene.add_child(chest)
	chest.global_position = position
	
	# Configure based on type
	match chest_type:
		"wooden":
			chest.required_key_type = "wooden"
			chest.loot_table = ["health_potion", "coin", "iron_ore"]
			chest.coin_drop_min = 1
			chest.coin_drop_max = 5
		"iron":
			chest.required_key_type = "iron"
			chest.loot_table = ["health_potion", "mana_potion", "magic_crystal"]
			chest.guaranteed_loot = ["coin"]
			chest.coin_drop_min = 3
			chest.coin_drop_max = 10
		"golden":
			chest.required_key_type = "golden"
			chest.loot_table = ["fire_gem", "magic_ring", "ancient_artifact"]
			chest.guaranteed_loot = ["coin", "coin"]
			chest.coin_drop_min = 5
			chest.coin_drop_max = 20
		"unlocked":
			chest.is_locked = false
			chest.loot_table = ["health_potion", "coin"]
			chest.coin_drop_min = 0
			chest.coin_drop_max = 3
	
	return chest

func spawn_key(key_type: String, position: Vector2):
	var key_id = key_type + "_key"
	var pickup_scene = load("res://scenes/PickupItem.tscn")
	
	if pickup_scene:
		var pickup = pickup_scene.instantiate()
		get_tree().current_scene.add_child(pickup)
		pickup.global_position = position
		pickup.set_item(key_id, 1)

# Quick demo function
func spawn_demo():
	spawn_chest("wooden", Vector2(100, 100))
	spawn_chest("iron", Vector2(200, 100))
	spawn_chest("golden", Vector2(300, 100))
	spawn_chest("unlocked", Vector2(400, 100))
	
	spawn_key("wooden", Vector2(100, 200))
	spawn_key("iron", Vector2(200, 200))
	spawn_key("golden", Vector2(300, 200))
