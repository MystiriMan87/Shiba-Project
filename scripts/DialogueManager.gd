extends Node

# Dialogue data structure
var dialogues = {
	"npc_greeting": [
		{"speaker": "Crazed Wizard", "text": "Hello traveler! What brings you to these forsaken caverns?."},
		{"speaker": "Player", "text": "I came here for some loot to salvage."},
		{"speaker": "Crazed Wizard", "text": "Looking for treasure hehe... (crazed mumbling) I wouldn't reccomend you go that way... that place is infested with vampires. How about this, go kill some enemies and find the chest somewhere that way, I will reward you handsomely."},
		{"speaker": "Crazed Wizard", "text": "If you meet a merchant on your travels make sure to give him your coins in exhange for valuable.. valuable.. items! (mumbling)"},
	],
	"merchant_intro": [
		{"speaker": "Merchant", "text": "Looking to buy some potions?"},
		{"speaker": "Player", "text": "What do you have?"},
		{"speaker": "Merchant", "text": "Health, dash potions, and more! Very useful for adventurers. If you bring me upgrades I will be able to sell you more items. Take a look at my supplies here, if anything catches your eye"},
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
