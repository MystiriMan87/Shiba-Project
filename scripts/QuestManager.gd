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

var is_processing_kill: bool = false


func _ready():
	load_quests_database()

func load_quests_database():
	quests_database = {
		"tutorial_quest": {
			"id": "tutorial_quest",
			"name": "Welcome to the Dungeon",
			"name_key": "tutorial_quest_name",
			"description": "Learn the basics of survival in the dungeon.",
			"desc_key": "tutorial_quest_desc",
			"objectives": [
				{
					"description": "Attack an enemy",
					"desc_key": "tutorial_quest_obj_0",
					"type": "kill_enemy",
					"target": "any",
					"required": 1,
					"current": 0,
					"completed": false
				},
				{
					"description": "Open a chest",
					"desc_key": "tutorial_quest_obj_1",
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
		
		"retrieve_firegem": {
			"id": "retrieve_firegem",
			"name": "Sacred Fire Gem",
			"name_key": "retrieve_firegem_name",
			"description": "The dungeon contains a sacred relic called the firegem. The old wizard asks you to retrieve it. He hasn't mentioned its use...",
			"desc_key": "retrieve_firegem_desc",
			"objectives": [
				{
					"description": "Collect the Fire Gem",
					"desc_key": "retrieve_firegem_obj_0",
					"type": "collect_item",
					"target": "fire_gem",
					"required": 1,
					"current": 0,
					"completed": false
				}
			],
			"rewards": {
				"gold": 30,
				"items": ["steel_hammer"],
				"experience": 250
			},
			"auto_accept": false
		},
		
		"slay_goblins": {
			"id": "slay_goblins",
			"name": "Goblin Slayer",
			"name_key": "slay_goblins_name",
			"description": "The Dark Elf messenger asked you to clear out the dungeon from goblins",
			"desc_key": "slay_goblins_desc",
			"objectives": [
				{
					"description": "Defeat 10 goblin enemies",
					"desc_key": "slay_goblins_obj_0",
					"type": "kill_enemy",
					"target": "goblin_enemy",
					"required": 10,
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
		
		"treasure_hunter": {
			"id": "treasure_hunter",
			"name": "Treasure Hunter",
			"name_key": "treasure_hunter_name",
			"description": "Open treasure chests to find valuable loot.",
			"desc_key": "treasure_hunter_desc",
			"objectives": [
				{
					"description": "Open 1 chest(s)",
					"desc_key": "treasure_hunter_obj_0",
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
		}
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
	
	# Create a copy of the quest data with translations
	var quest_data = get_localized_quest_data(quest_id)
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
	
	if "experience" in rewards:
		print("Rewarded ", rewards.experience, " experience")

func get_active_quests() -> Dictionary:
	"""Returns active quests with current language translations"""
	var translated_quests = {}
	for quest_id in active_quests:
		translated_quests[quest_id] = get_localized_quest_data(quest_id)
	return translated_quests

func get_quest_data(quest_id: String) -> Dictionary:
	"""Returns quest data with translations for current language"""
	return get_localized_quest_data(quest_id)

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
	
func get_localized_quest_data(quest_id: String) -> Dictionary:
	"""Returns a quest with translated name, description, and objectives"""
	var quest = quests_database.get(quest_id, {})
	if quest.is_empty():
		return {}
	
	var localized = quest.duplicate(true)
	
	# Only translate if LocalizationManager exists
	if not has_node("/root/LocalizationManager"):
		return localized
	
	# Translate quest name
	if "name_key" in quest:
		var translated_name = LocalizationManager.t(quest.name_key)
		if translated_name != quest.name_key:
			localized.name = translated_name
	
	# Translate quest description
	if "desc_key" in quest:
		var translated_desc = LocalizationManager.t(quest.desc_key)
		if translated_desc != quest.desc_key:
			localized.description = translated_desc
	
	# Translate objectives
	if "objectives" in localized:
		for i in range(localized.objectives.size()):
			if "desc_key" in quest.objectives[i]:
				var translated_obj = LocalizationManager.t(quest.objectives[i].desc_key)
				if translated_obj != quest.objectives[i].desc_key:
					localized.objectives[i].description = translated_obj
	
	return localized


func on_enemy_killed(enemy_type: String):
	"""Call this when player kills an enemy"""
	if is_processing_kill:
		return  # Prevent recursive calls
	
	is_processing_kill = true
	
	for quest_id in active_quests:
		var quest_data = active_quests[quest_id]
		for i in range(quest_data.objectives.size()):
			var objective = quest_data.objectives[i]
			if objective.type == "kill_enemy" and not objective.completed:
				if objective.target == "any" or objective.target == enemy_type:
					update_objective(quest_id, i, 1)
	
	is_processing_kill = false
