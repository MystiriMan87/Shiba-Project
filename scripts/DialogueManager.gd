extends Node

# Dialogue data structure
var dialogues = {
	"npc_greeting": [
		{"speaker": "Villager", "text": "Hello traveler! Welcome to our village."},
		{"speaker": "Villager", "text": "Beware of the enemies lurking in the forest."},
	],
	"merchant_intro": [
		{"speaker": "Merchant", "text": "Looking to buy some potions?"},
		{"speaker": "Player", "text": "What do you have?"},
		{"speaker": "Merchant", "text": "Health and dash potions! Very useful for adventurers."},
	],
	"quest_giver": [
		{"speaker": "Elder", "text": "The forest has become dangerous lately."},
		{"speaker": "Elder", "text": "Could you clear out some of those creatures?"},
		{"speaker": "Player", "text": "I'll see what I can do."},
	]
}

func get_dialogue(dialogue_id: String) -> Array:
	return dialogues.get(dialogue_id, [])

func add_dialogue(dialogue_id: String, dialogue_data: Array):
	dialogues[dialogue_id] = dialogue_data
