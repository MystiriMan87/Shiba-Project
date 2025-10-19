extends Node
# Dialogue data structure
var dialogues = {
	"npc_greeting": [
		{"speaker": "Crazed Wizard", "text": "Hello traveler! Thank you for defeating those skeletons for me!"},
		{"speaker": "Crazed Wizard", "text": "I don't have any new quests fo now, come back later!"},
		{"speaker": "Crazed Wizard", "text": "Before you go"},
		{"speaker": "Crazed Wizard", "text": "If you meet a merchant on your travels through the dungeons make sure to give him your coins in exhange for valuable.. valuable.. items! (mumbling)"},
	],
	"elf_messenger": [
		{"speaker": "Elf Messenger", "text": "I come with peace. I know you have been ruthlessly fighting our warriors down in the depths of the dungeons."},
		{"speaker": "Elf Messenger", "text": "I have a proposition to make."},
		{"speaker": "Elf Messenger", "text": "If you instead defeat 10 goblins for me I would not only forget our previous conflict but would reward you handsomely."},
		{"speaker": "Elf Messenger", "text": "It should be marked in your quest logd. Do not return until you accomplished the task."},
	],
	"sign-default": [
		{"speaker": "Amazing Sign", "text": "Deep Dark Caverns"},
		{"speaker": "Amazing Sign", "text": ""},
		{"speaker": "Amazing Sign", "text": ""},
		{"speaker": "Amazing Sign", "text": "Still clicking? Go play the game already."},
	],
	"npc_no_pass": [
		{"speaker": "Explorer Dave", "text": "Someone took the ladder from here, there are 2 tunnels to go around but I don't dare head that way."},
		{"speaker": "Explorer Dave", "text": "If you're crazy enough to go there, one holds plenty of swift goblins the other contains hulking brutes."},
		{"speaker": "Explorer Dave", "text": "Before you go, if you are having trouble defeating the ghosts, the goblins have a chance to drop a magic ring to help you! Good luck"},
	],
	"skeleton_quest_start": [
		{"speaker": "Crazed Wizard", "text": "Greetings traveler, are you by chance going to decending into those caverns?"},
		{"speaker": "Crazed Wizard", "text": "Could you help me by defeating 3 skeletons while you are down there?"},
		{"speaker": "Crazed Wizard", "text": "I'll reward you handsomely for your trouble."}
	],
	"skeleton_quest_active": [
		{"speaker": "Crazed Wizard", "text": "Have you dealt with those skeletons yet?"},
		{"speaker": "Crazed Wizard", "text": "Be careful out there, they can be dangerous!"},
		{"speaker": "Crazed Wizard", "text": "Come back when you've defeated 3 of them."}
	],
		
	"skeleton_quest_complete": [
		{"speaker": "Crazed Wizard", "text": "You did it! The dungeon feels safer already."},
		{"speaker": "Crazed Wizard", "text": "Thank you so much for your help!"},
		{"speaker": "Crazed Wizard", "text": "You should've recieved your reward so check your inventory!"}
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
