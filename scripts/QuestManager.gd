# QuestManager.gd
extends Node

signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)
signal quest_objective_updated(quest_id: String, objective_index: int)
signal quest_updated()

var quests_database = {}
var active_quests = {}
var completed_quests = []
var failed_quests = []

func _ready():
	load_quests_database()

func load_quests_database():
	quests_database = {
		"tutorial_quest": {
			"id": "tutorial_quest",
			"name": "Welcome to the Dungeon",
			"description": "Learn the basics of survival in the dungeon.",
			"objectives": [
				#{
					#"description": "Move around using WASD",
					#"type": "custom",  # Will be manually completed
					#"required": 1,
					#"current": 0,
					#"completed": false
				#},
				{
					"description": "Attack an enemy",
					"type": "kill_enemy",
					"target": "any",
					"required": 1,
					"current": 0,
					"completed": false
				},
				{
					"description": "Open a chest",
					"type": "open_chest",
					"required": 1,
					"current": 0,
					"completed": false
				}
			],
			"rewards": {
				"gold": 50,
				"items": ["health_potion"],
				"experience": 100
			},
			"auto_accept": false
		},
		
		"slay_skeletons": {
			"id": "slay_skeletons",
			"name": "Skeleton Slayer",
			"description": "The dungeon is overrun with skeletons. Defeat them to make it safer.",
			"objectives": [
				{
					"description": "Defeat 3 skeleton enemies",
					"type": "kill_enemy",
					"target": "skeleton_enemy",
					"required": 3,
					"current": 0,
					"completed": false
				}
			],
			"rewards": {
				"gold": 20,
				"items": ["iron_sword"],
				"experience": 250
			},
			"auto_accept": false
		},
		
		#"collect_keys": {
			#"id": "collect_keys",
			#"name": "Key Collector",
			#"description": "Find and collect keys scattered throughout the dungeon.",
			#"objectives": [
				#{
					#"description": "Collect 3 wooden keys",
					#"type": "collect_item",
					#"target": "wooden_key",
					#"required": 3,
					#"current": 0,
					#"completed": false
				#},
				#{
					#"description": "Collect 1 iron key",
					#"type": "collect_item",
					#"target": "iron_key",
					#"required": 1,
					#"current": 0,
					#"completed": false
				#}
			#],
			#"rewards": {
				#"gold": 75,
				#"items": ["golden_key"],
				#"experience": 150
			#},
			#"auto_accept": false
		#},
		
		"treasure_hunter": {
			"id": "treasure_hunter",
			"name": "Treasure Hunter",
			"description": "Open treasure chests to find valuable loot.",
			"objectives": [
				{
					"description": "Open 1 chest(s)",
					"type": "open_chest",
					"required": 1,
					"current": 0,
					"completed": false
				}
			],
			"rewards": {
				"gold": 15,
				"items": ["health_potion"],
				"experience": 200
			},
			"auto_accept": false
		},
		
		#"merchant_delivery": {
			#"id": "merchant_delivery",
			#"name": "Merchant's Request",
			#"description": "The merchant needs materials. Deliver them for a reward.",
			#"objectives": [
				#{
					#"description": "Collect 10 iron ore",
					#"type": "collect_item",
					#"target": "iron_ore",
					#"required": 10,
					#"current": 0,
					#"completed": false
				#},
				#{
					#"description": "Return to the merchant",
					#"type": "talk_to_npc",
					#"target": "merchant",
					#"required": 1,
					#"current": 0,
					#"completed": false
				#}
			#],
			#"rewards": {
				#"gold": 200,
				#"items": ["steel_sword"],
				#"experience": 300
			#},
			#"auto_accept": false
		#}
	}

func start_quest(quest_id: String) -> bool:
	"""Start a new quest"""
	if quest_id in active_quests:
		print("Quest already active: ", quest_id)
		return false
	
	if quest_id in completed_quests:
		print("Quest already completed: ", quest_id)
		return false
	
	if not quests_database.has(quest_id):
		print("Quest not found: ", quest_id)
		return false
	
	# Create a copy of the quest data
	var quest_data = quests_database[quest_id].duplicate(true)
	active_quests[quest_id] = quest_data
	
	print("Quest started: ", quest_data.name)
	quest_started.emit(quest_id)
	quest_updated.emit()
	return true

func complete_quest(quest_id: String) -> bool:
	"""Complete a quest and give rewards"""
	if not quest_id in active_quests:
		print("Quest not active: ", quest_id)
		return false
	
	var quest_data = active_quests[quest_id]
	
	# Check if all objectives are completed
	for objective in quest_data.objectives:
		if not objective.completed:
			print("Cannot complete quest - objective not finished: ", objective.description)
			return false
	
	# Give rewards
	give_quest_rewards(quest_data.rewards)
	
	# Move quest to completed
	completed_quests.append(quest_id)
	active_quests.erase(quest_id)
	
	print("Quest completed: ", quest_data.name)
	quest_completed.emit(quest_id)
	quest_updated.emit()
	return true

func fail_quest(quest_id: String):
	"""Fail a quest"""
	if not quest_id in active_quests:
		return
	
	failed_quests.append(quest_id)
	active_quests.erase(quest_id)
	
	quest_failed.emit(quest_id)
	quest_updated.emit()

func update_objective(quest_id: String, objective_index: int, progress: int = 1):
	"""Update progress on a specific objective"""
	if not quest_id in active_quests:
		return
	
	var quest_data = active_quests[quest_id]
	if objective_index >= quest_data.objectives.size():
		return
	
	var objective = quest_data.objectives[objective_index]
	
	if objective.completed:
		return
	
	objective.current = min(objective.current + progress, objective.required)
	
	if objective.current >= objective.required:
		objective.completed = true
		print("Objective completed: ", objective.description)
	
	quest_objective_updated.emit(quest_id, objective_index)
	quest_updated.emit()
	
	# Check if quest is complete
	check_quest_completion(quest_id)

func check_quest_completion(quest_id: String):
	"""Check if all objectives are done and auto-complete if so"""
	if not quest_id in active_quests:
		return
	
	var quest_data = active_quests[quest_id]
	var all_complete = true
	
	for objective in quest_data.objectives:
		if not objective.completed:
			all_complete = false
			break
	
	if all_complete:
		complete_quest(quest_id)

# Event handlers for automatic quest progress tracking
func on_enemy_killed(enemy_type: String):
	"""Call this when player kills an enemy"""
	for quest_id in active_quests:
		var quest_data = active_quests[quest_id]
		for i in range(quest_data.objectives.size()):
			var objective = quest_data.objectives[i]
			if objective.type == "kill_enemy" and not objective.completed:
				if objective.target == "any" or objective.target == enemy_type:
					update_objective(quest_id, i, 1)

func on_item_collected(item_id: String, amount: int = 1):
	"""Call this when player collects an item"""
	for quest_id in active_quests:
		var quest_data = active_quests[quest_id]
		for i in range(quest_data.objectives.size()):
			var objective = quest_data.objectives[i]
			if objective.type == "collect_item" and not objective.completed:
				if objective.target == item_id:
					update_objective(quest_id, i, amount)

func on_chest_opened():
	"""Call this when player opens a chest"""
	for quest_id in active_quests:
		var quest_data = active_quests[quest_id]
		for i in range(quest_data.objectives.size()):
			var objective = quest_data.objectives[i]
			if objective.type == "open_chest" and not objective.completed:
				update_objective(quest_id, i, 1)

func on_npc_talked(npc_id: String):
	"""Call this when player talks to an NPC"""
	for quest_id in active_quests:
		var quest_data = active_quests[quest_id]
		for i in range(quest_data.objectives.size()):
			var objective = quest_data.objectives[i]
			if objective.type == "talk_to_npc" and not objective.completed:
				if objective.target == npc_id:
					update_objective(quest_id, i, 1)

func complete_custom_objective(quest_id: String, objective_index: int):
	"""Manually complete a custom objective"""
	update_objective(quest_id, objective_index, 999)

func give_quest_rewards(rewards: Dictionary):
	"""Give rewards to player"""
	var item_manager = get_node_or_null("/root/ItemManager")
	if not item_manager:
		print("ItemManager not found!")
		return
	
	# Give gold
	if "gold" in rewards:
		item_manager.add_item_to_inventory("coin", rewards.gold)
		print("Rewarded ", rewards.gold, " gold")
	
	# Give items
	if "items" in rewards:
		for item_id in rewards.items:
			item_manager.add_item_to_inventory(item_id, 1)
			print("Rewarded item: ", item_id)
	
	# Give experience (you can hook this up to your XP system)
	if "experience" in rewards:
		print("Rewarded ", rewards.experience, " experience")

func get_active_quests() -> Dictionary:
	return active_quests

func get_quest_data(quest_id: String) -> Dictionary:
	if quest_id in active_quests:
		return active_quests[quest_id]
	elif quests_database.has(quest_id):
		return quests_database[quest_id]
	return {}

func is_quest_active(quest_id: String) -> bool:
	return quest_id in active_quests

func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quests

func get_all_available_quests() -> Array:
	"""Get quests that can be started (not active or completed)"""
	var available = []
	for quest_id in quests_database:
		if not is_quest_active(quest_id) and not is_quest_completed(quest_id):
			available.append(quest_id)
	return available

func save_quests() -> Dictionary:
	return {
		"active_quests": active_quests,
		"completed_quests": completed_quests,
		"failed_quests": failed_quests
	}

func load_quests(save_data: Dictionary):
	if "active_quests" in save_data:
		active_quests = save_data.active_quests
	if "completed_quests" in save_data:
		completed_quests = save_data.completed_quests
	if "failed_quests" in save_data:
		failed_quests = save_data.failed_quests
	
	quest_updated.emit()
