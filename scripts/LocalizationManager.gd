extends Node

signal language_changed(new_language: String)

const LANGUAGES = {
	"en": "English",
	"ja": "日本語"
}

var current_language: String = "en"

var translations: Dictionary = {
	"en": {},
	"ja": {}
}

func _ready():
	load_translations()
	
	var saved_language = SettingsManager.settings.gameplay.get("language", "en") if has_node("/root/SettingsManager") else "en"
	set_language(saved_language)

func load_translations():
	translations["en"] = {
		# UI
		"start_game": "Start Game",
		"settings": "Settings",
		"quit": "Quit",
		"back": "Back",
		"resume": "Resume",
		"main_menu": "Main Menu",
		"inventory": "Inventory",
		"quest_log": "Quest Log",
		"yes": "Yes",
		"no": "No",
		
		"quest_tab_active": "Active",
		"quest_tab_completed": "Completed", 
		"quest_tab_available": "Available",
		"gold": "Gold",
		"accept_quest": "Accept Quest",
		"no_active_quests": "No active quests",
		"no_completed_quests": "No completed quests yet",
		"no_available_quests": "No available quests",
		
		# Settings
		"audio": "Audio",
		"video": "Video",
		"gameplay": "Gameplay",
		"language": "Language",
		"master_volume": "Master Volume",
		"music_volume": "Music Volume",
		"sfx_volume": "SFX Volume",
		"fullscreen": "Fullscreen",
		"vsync": "VSync",
		"resolution": "Resolution",
		
		"tutorial_quest_name": "Welcome to the Dungeon",
		"tutorial_quest_desc": "Learn the basics of survival in the dungeon.",
		"tutorial_quest_obj_0": "Attack an enemy",
		"tutorial_quest_obj_1": "Open a chest",

		"retrieve_firegem_name": "Sacred Fire Gem",
		"retrieve_firegem_desc": "The dungeon contains a sacred relic called the firegem. The old wizard asks you to retrieve it. He hasn't mentioned its use...",
		"retrieve_firegem_obj_0": "Collect the Fire Gem",

		"slay_goblins_name": "Goblin Slayer",
		"slay_goblins_desc": "The Dark Elf messenger asked you to clear out the dungeon from goblins",
		"slay_goblins_obj_0": "Defeat 10 goblin enemies",

		"treasure_hunter_name": "Treasure Hunter",
		"treasure_hunter_desc": "Open treasure chests to find valuable loot.",
		"treasure_hunter_obj_0": "Open 1 chest(s)",
		
		# Gameplay
		"health": "Health",
		"damage": "Damage",
		"attack_range": "Range",
		"attack_speed": "Speed",
		"level": "Level",
		"experience": "Experience",
		
		# Items
		"health_potion": "Health Potion",
		"health_potion_desc": "Restores 2 HP",
		"dash_potion": "Dash Potion",
		"dash_potion_desc": "Restores dash energy",
		"wooden_key": "Wooden Key",
		"wooden_key_desc": "Opens wooden chests",
		"iron_key": "Iron Key",
		"iron_key_desc": "Opens iron chests",
		"magic_ring": "Magic Ring",
		"magic_ring_desc": "Deals 2x damage to ghosts",
		
		# Weapons
		"sword": "Sword",
		"axe": "Axe",
		"spear": "Spear",
		"equipped": "Equipped",
		"weapon_damage": "Damage: {0}",
		"weapon_range": "Range: {0}",
		"weapon_speed": "Speed: {0}",
		
		# Enemies
		"slime": "Slime",
		"skeleton": "Skeleton",
		"goblin": "Goblin",
		"ghost": "Ghost",
		"boss": "Boss",
		
		# Quests
		"quest_active": "Active Quest",
		"quest_completed": "Quest Completed!",
		"quest_failed": "Quest Failed",
		"objectives": "Objectives:",
		"rewards": "Rewards:",

		
		# Notifications
		"item_picked_up": "Picked up: {0}",
		"quest_started": "New Quest: {0}",
		"quest_updated": "Quest Updated: {0}",
		"enemy_defeated": "Enemy Defeated!",
		"boss_defeated": "Boss Defeated!",
		
		# Death Screen
		"you_died": "You Died",
		"respawn": "Respawn",
		"enemies_killed": "Enemies Killed: {0}",
		"time_survived": "Time Survived: {0}",
		
		# Tutorial
		"move_tutorial": "Use WASD or Left Stick to move",
		"attack_tutorial": "Left Click or RT to attack",
		"dash_tutorial": "Shift or LB to dash",
		"interact_tutorial": "E or A to interact",
		
		# Dialogue
		"continue_dialogue": "Press [E] to continue",
		"skip_dialogue": "Press [ESC] to skip",
		
		 # Quest: Welcome to the Dungeon
		"quest_tutorial_title": "Welcome to the Dungeon",
		"quest_tutorial_desc": "Learn the basics of survival in the dungeon.",
		"quest_tutorial_obj1": "Attack an enemy",
		"quest_tutorial_obj2": "Open a chest"
	}
	
	translations["ja"] = {
		# UI
		"start_game": "ゲーム開始",
		"settings": "設定",
		"quit": "終了",
		"back": "戻る",
		"resume": "再開",
		"main_menu": "メインメニュー",
		"inventory": "インベントリ",
		"quest_log": "クエストログ",
		"yes": "はい",
		"no": "いいえ",
		
		# Settings
		"audio": "オーディオ",
		"video": "ビデオ",
		"gameplay": "ゲームプレイ",
		"language": "言語",
		"master_volume": "マスター音量",
		"music_volume": "音楽音量",
		"sfx_volume": "効果音音量",
		"fullscreen": "フルスクリーン",
		"vsync": "垂直同期",
		"resolution": "解像度",
		
		"quest_tab_active": "進行中",
		"quest_tab_completed": "完了",
		"quest_tab_available": "利用可能",
		"gold": "ゴールド",
		"accept_quest": "クエストを受ける",
		"no_active_quests": "進行中のクエストはありません",
		"no_completed_quests": "完了したクエストはまだありません",
		"no_available_quests": "利用可能なクエストはありません",
		
		"tutorial_quest_name": "ダンジョンへようこそ",
		"tutorial_quest_desc": "ダンジョンでの生存の基本を学ぶ。",
		"tutorial_quest_obj_0": "敵を攻撃する",
		"tutorial_quest_obj_1": "宝箱を開ける",

		"retrieve_firegem_name": "聖なる炎の宝石",
		"retrieve_firegem_desc": "ダンジョンには炎の宝石と呼ばれる聖なる遺物がある。老魔法使いはあなたにそれを回収するよう頼んでいる。彼はその用途について言及していない...",
		"retrieve_firegem_obj_0": "炎の宝石を集める",

		"slay_goblins_name": "ゴブリンスレイヤー",
		"slay_goblins_desc": "ダークエルフの使者はあなたにダンジョンからゴブリンを一掃するよう頼んだ",
		"slay_goblins_obj_0": "ゴブリンの敵を10体倒す",

		"treasure_hunter_name": "トレジャーハンター",
		"treasure_hunter_desc": "宝箱を開けて貴重な戦利品を見つける。",
		"treasure_hunter_obj_0": "宝箱を1個開ける",
		
		# Gameplay
		"health": "体力",
		"damage": "ダメージ",
		"attack_range": "射程",
		"attack_speed": "攻撃速度",
		"level": "レベル",
		"experience": "経験値",
		
		# Items
		"health_potion": "体力ポーション",
		"health_potion_desc": "体力を2回復する",
		"dash_potion": "ダッシュポーション",
		"dash_potion_desc": "ダッシュエネルギーを回復する",
		"wooden_key": "木の鍵",
		"wooden_key_desc": "木製の箱を開ける",
		"iron_key": "鉄の鍵",
		"iron_key_desc": "鉄製の箱を開ける",
		"magic_ring": "魔法の指輪",
		"magic_ring_desc": "幽霊に2倍のダメージを与える",
		
		# Weapons
		"sword": "剣",
		"axe": "斧",
		"spear": "槍",
		"equipped": "装備中",
		"weapon_damage": "ダメージ: {0}",
		"weapon_range": "射程: {0}",
		"weapon_speed": "速度: {0}",
		
		# Enemies
		"slime": "スライム",
		"skeleton": "スケルトン",
		"goblin": "ゴブリン",
		"ghost": "ゴースト",
		"boss": "ボス",
		
		# Quests
		"quest_active": "進行中のクエスト",
		"quest_completed": "クエスト完了！",
		"quest_failed": "クエスト失敗",
		"objectives": "目標:",
		"rewards": "報酬:",
		
		# Notifications
		"item_picked_up": "入手: {0}",
		"quest_started": "新しいクエスト: {0}",
		"quest_updated": "クエスト更新: {0}",
		"enemy_defeated": "敵を倒した！",
		"boss_defeated": "ボスを倒した！",
		
		# Death Screen
		"you_died": "死亡",
		"respawn": "復活",
		"enemies_killed": "倒した敵: {0}",
		"time_survived": "生存時間: {0}",
		
		# Tutorial
		"move_tutorial": "WASDまたは左スティックで移動",
		"attack_tutorial": "左クリックまたはRTで攻撃",
		"dash_tutorial": "シフトまたはLBでダッシュ",
		"interact_tutorial": "EまたはAで対話",
		
		# Dialogue
		"continue_dialogue": "[E]を押して続ける",
		"skip_dialogue": "[ESC]を押してスキップ",
		
		 "quest_tutorial_title": "ダンジョンへようこそ",
		"quest_tutorial_desc": "ダンジョンでの生存の基本を学ぶ。",
		"quest_tutorial_obj1": "敵を攻撃する",
		"quest_tutorial_obj2": "宝箱を開ける"
	}



func set_language(lang_code: String):
	if not LANGUAGES.has(lang_code):
		push_warning("Language not supported: " + lang_code)
		return
	
	current_language = lang_code
	print("Language changed to: ", LANGUAGES[lang_code])
	
	if has_node("/root/SettingsManager"):
		SettingsManager.settings.gameplay["language"] = lang_code
		SettingsManager.save_settings()
	
	language_changed.emit(lang_code)

func get_text(key: String, args: Array = []) -> String:
	if not translations.has(current_language):
		return key
	
	var lang_dict = translations[current_language]
	if not lang_dict.has(key):
		push_warning("Translation key not found: " + key)
		return key
	
	var text = lang_dict[key]
	
	for i in range(args.size()):
		text = text.replace("{" + str(i) + "}", str(args[i]))
	
	return text

func t(key: String, args: Array = []) -> String:
	return get_text(key, args)

func get_current_language() -> String:
	return current_language

func get_available_languages() -> Dictionary:
	return LANGUAGES

func add_translation(key: String, en_text: String, ja_text: String):
	translations["en"][key] = en_text
	translations["ja"][key] = ja_text

func load_from_csv(file_path: String):
	if not FileAccess.file_exists(file_path):
		push_warning("Translation CSV not found: " + file_path)
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return
	
	var header = file.get_csv_line()
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() >= 3:
			var key = line[0]
			var en_text = line[1]
			var ja_text = line[2]
			add_translation(key, en_text, ja_text)
	
	file.close()
	print("Translations loaded from CSV: ", file_path)
