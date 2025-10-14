extends Node

# Dialogue data structure
var dialogues = {
	"npc_greeting": [
		{"speaker": "Crazed Wizard", "text": "Hello traveler! Thank you for defeating those skeletons for me!"},
		{"speaker": "Crazed Wizard", "text": "I don't have any new quests fo now, come back later!"},
		{"speaker": "Crazed Wizard", "text": "Before you go"},
		{"speaker": "Crazed Wizard", "text": "If you meet a merchant on your travels through the dungeons make sure to give him your coins in exhange for valuable.. valuable.. items! (mumbling)"},
	],
	"sign-default": [
		{"speaker": "Amazing Sign", "text": "Deep Dark Caverns"},
		{"speaker": "Amazing Sign", "text": ""},
		{"speaker": "Amazing Sign", "text": ""},
		{"speaker": "Amazing Sign", "text": "Still clicking? Go play the game already."},
	],
	"npc_no_pass": [
		{"speaker": "Explorer Dave", "text": "The entrance seems to be collapsed here, there are 2 tunnels to go around but I don't dare head that way."},
		{"speaker": "Explorer Dave", "text": "If you're crazy enough to go there, one holds plenty of swift goblins the other contains hulking brutes."},
		{"speaker": "Explorer Dave", "text": "Good luck"},
	],
	"skeleton_quest_start": [
		 "Greetings traveler, are you by chance going to decending into those caverns?",
		 "Could you help me by defeating 3 skeletons while you are down there?",
		 "I'll reward you handsomely for your trouble."
	],
	"skeleton_quest_active": [
		"Have you dealt with those skeletons yet?",
		"Be careful out there, they can be dangerous!",
  		"Come back when you've defeated 3 of them."
	],
		
	"skeleton_quest_complete": [
		"You did it! The dungeon feels safer already.",
		"Thank you so much for your help!",
		"You should've recieved your reward so check your inventory!"
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
