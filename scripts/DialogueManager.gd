extends Node

var dialogues = {
	"npc_greeting": {
		"en": [
			{"speaker": "Crazed Wizard", "text": "Hello traveler! Thank you for bringing me that fire gem!"},
			{"speaker": "Crazed Wizard", "text": "I don't have any new quests for now, come back later!"},
			{"speaker": "Crazed Wizard", "text": "Before you go"},
			{"speaker": "Crazed Wizard", "text": "If you meet a merchant on your travels make sure to give him your coins in exhange for valuable.. valuable.. items! (mumbling)"},
		],
		"ja": [
			{"speaker": "狂気の魔法使い", "text": "こんにちは旅人！火の宝石を持ってきてくれてありがとう！"},
			{"speaker": "狂気の魔法使い", "text": "今は新しいクエストはありません。また後で来てください！"},
			{"speaker": "狂気の魔法使い", "text": "行く前に"},
			{"speaker": "狂気の魔法使い", "text": "旅で商人に会ったら、貴重な...貴重な...アイテムと引き換えにコインを渡してください！（ブツブツ）"},
		]
	},
	"elf_messenger": {
		"en": [
			{"speaker": "Elf Messenger", "text": "I come with peace. I know you have been ruthlessly fighting our warriors down in the depths of the dungeons."},
			{"speaker": "Elf Messenger", "text": "I have a proposition to make."},
			{"speaker": "Elf Messenger", "text": "If you instead defeat 10 goblins for me I would not only forget our previous conflict but would reward you handsomely."},
			{"speaker": "Elf Messenger", "text": "It should be marked in your quest log. Do not return until you accomplished the task."},
		],
		"ja": [
			{"speaker": "エルフの使者", "text": "平和的に来ました。あなたがダンジョンの深部で我々の戦士と無慈悲に戦っていることは知っています。"},
			{"speaker": "エルフの使者", "text": "提案があります。"},
			{"speaker": "エルフの使者", "text": "代わりに10体のゴブリンを倒してくれれば、以前の争いを忘れるだけでなく、豪華な報酬を差し上げます。"},
			{"speaker": "エルフの使者", "text": "クエストログに記録されています。任務を達成するまで戻らないでください。"},
		]
	},
	"sign-default": {
		"en": [
			{"speaker": "Amazing Sign", "text": "Deep Dark Caverns"},
			{"speaker": "Amazing Sign", "text": ""},
			{"speaker": "Amazing Sign", "text": ""},
			{"speaker": "Amazing Sign", "text": "Still clicking? Go play the game already."},
		],
		"ja": [
			{"speaker": "素晴らしい看板", "text": "深く暗い洞窟"},
			{"speaker": "素晴らしい看板", "text": ""},
			{"speaker": "素晴らしい看板", "text": ""},
			{"speaker": "素晴らしい看板", "text": "まだクリックしてる？もうゲームをプレイしてください。"},
		]
	},
	"npc_no_pass": {
		"en": [
			{"speaker": "Explorer Dave", "text": "Someone took the ladder from here, there are 2 tunnels to go around but I don't dare head that way."},
			{"speaker": "Explorer Dave", "text": "If you're crazy enough to go there, one holds plenty of swift goblins the other contains hulking brutes."},
			{"speaker": "Explorer Dave", "text": "Before you go, if you are having trouble defeating the ghosts, the goblins have a chance to drop a magic ring to help you! Good luck"},
		],
		"ja": [
			{"speaker": "探検家デイブ", "text": "誰かがここから梯子を取っていきました。迂回する2つのトンネルがありますが、私はそっちに行く勇気がありません。"},
			{"speaker": "探検家デイブ", "text": "もしあなたが十分に勇敢なら、一方には素早いゴブリンがたくさんいて、もう一方には巨大な野蛮人がいます。"},
			{"speaker": "探検家デイブ", "text": "行く前に、幽霊を倒すのに苦労しているなら、ゴブリンが魔法の指輪をドロップする可能性があります！幸運を！"},
		]
	},
	"mysterious_npc": {
		"en": [
			{"speaker": "???", "text": "I'm surprised you lasted this long"},
			{"speaker": "???", "text": "We'll see soon enough"},
			{"speaker": "???", "text": ". . . . . . . ."},
		],
		"ja": [
			{"speaker": "???", "text": "ここまで生き延びるとは驚きだ"},
			{"speaker": "???", "text": "すぐに分かるだろう"},
			{"speaker": "???", "text": ". . . . . . . ."},
		]
	},
	"coward_skeleton": {
		"en": [
			{"speaker": "Cowardly Skeleton", "text": "No! Please! Don't hurt me!"},
			{"speaker": "Cowardly Skeleton", "text": "Please, I don't want to fight! I was sent away by my friends because I was too cowardly.. Now I sit here all day long."},
			{"speaker": "Cowardly Skeleton", "text": ". . . . . . . . . . ."},
		],
		"ja": [
			{"speaker": "臆病なスケルトン", "text": "やめて！お願い！傷つけないで！"},
			{"speaker": "臆病なスケルトン", "text": "お願い、戦いたくない！臆病すぎて友達に追い出されました...今は一日中ここに座っています。"},
			{"speaker": "臆病なスケルトン", "text": ". . . . . . . . . . ."},
		]
	},
	"firegem_quest_start": {
		"en": [
			{"speaker": "Crazed Wizard", "text": "Greetings traveler, are you by chance going to descending into those caverns?"},
			{"speaker": "Crazed Wizard", "text": "They say an ancient relic has been spotted down in the depths. I challenge you to retrieve it from the 4th level of the dungeon"},
			{"speaker": "Crazed Wizard", "text": "I'll reward you handsomely for your trouble."}
		],
		"ja": [
			{"speaker": "狂気の魔法使い", "text": "ご挨拶、旅人。もしかして、あの洞窟に降りるつもりですか？"},
			{"speaker": "狂気の魔法使い", "text": "古代の遺物が深部で目撃されたそうです。ダンジョンの4階からそれを取り戻すことに挑戦してください"},
			{"speaker": "狂気の魔法使い", "text": "あなたの苦労に対して豪華な報酬を差し上げます。"}
		]
	},
	"firegem_quest_active": {
		"en": [
			{"speaker": "Crazed Wizard", "text": "Have you gotten the Fire Gem yet?"},
			{"speaker": "Crazed Wizard", "text": "Be careful out there, it is guarded by a Dark Elf Champion"},
			{"speaker": "Crazed Wizard", "text": "Come back when you've collected it."}
		],
		"ja": [
			{"speaker": "狂気の魔法使い", "text": "火の宝石はもう手に入れましたか？"},
			{"speaker": "狂気の魔法使い", "text": "気をつけてください。ダークエルフチャンピオンが守っています"},
			{"speaker": "狂気の魔法使い", "text": "集めたら戻ってきてください。"}
		]
	},
	"firegem_quest_complete": {
		"en": [
			{"speaker": "Crazed Wizard", "text": "You did it! The dungeon feels safer already."},
			{"speaker": "Crazed Wizard", "text": "Come back later and I will show you how it works"},
			{"speaker": "Crazed Wizard", "text": "You should've received your reward so check your inventory!"}
		],
		"ja": [
			{"speaker": "狂気の魔法使い", "text": "やりましたね！ダンジョンがもう安全な感じがします。"},
			{"speaker": "狂気の魔法使い", "text": "後で戻ってきてください。使い方を教えます"},
			{"speaker": "狂気の魔法使い", "text": "報酬を受け取ったはずなので、インベントリを確認してください！"}
		]
	},
	"merchant_intro": {
		"en": [
			{"speaker": "Merchant", "text": "Looking to buy some potions?"},
			{"speaker": "Merchant", "text": "Health, dash potions, and more! Very useful for adventurers. Take a look at my supplies here, if anything catches your eye"},
		],
		"ja": [
			{"speaker": "商人", "text": "ポーションを買いたいですか？"},
			{"speaker": "商人", "text": "体力、ダッシュポーションなど！冒険者にとても便利です。私の品物を見てください。何か気に入るものがあれば"},
		]
	}
}

func get_dialogue(dialogue_id: String) -> Array:
	if not dialogues.has(dialogue_id):
		push_warning("Dialogue not found: " + dialogue_id)
		return []
	
	var lang = "en"
	if has_node("/root/LocalizationManager"):
		lang = LocalizationManager.get_current_language()
	
	var dialogue_data = dialogues[dialogue_id]
	
	if typeof(dialogue_data) == TYPE_DICTIONARY:
		if dialogue_data.has(lang):
			return dialogue_data[lang]
		else:
			return dialogue_data.get("en", [])
	else:
		return dialogue_data

func add_dialogue(dialogue_id: String, dialogue_data: Array):
	dialogues[dialogue_id] = dialogue_data
