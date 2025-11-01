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
<<<<<<< HEAD
<<<<<<< HEAD
=======
=======
>>>>>>> parent of 9b2cc3f (japanese is awful to translate)

func load_fonts():
	# Try Regular weight instead of Black
	if ResourceLoader.exists("res://Fonts/Noto_Sans_JP/static/NotoSansJP-Regular.ttf"):
		japanese_font = load("res://Fonts/Noto_Sans_JP/static/NotoSansJP-Regular.ttf")
		print("Japanese font loaded successfully")
	elif ResourceLoader.exists("res://Fonts/Noto_Sans_JP/static/NotoSansJP-Bold.ttf"):
		japanese_font = load("res://Fonts/Noto_Sans_JP/static/NotoSansJP-Bold.ttf")
		print("Japanese font (Bold) loaded successfully")
	else:
		push_warning("Japanese font not found")
	
	if ResourceLoader.exists("res://Fonts/PixeloidSans-nR3g1.ttf"):
		default_font = load("res://Fonts/PixeloidSans-nR3g1.ttf")
		print("Default font loaded successfully")
>>>>>>> parent of 9b2cc3f (japanese is awful to translate)

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
		"skip_dialogue": "Press [ESC] to skip"
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
		"skip_dialogue": "[ESC]を押してスキップ"
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

<<<<<<< HEAD
=======
func apply_font_for_language(lang_code: String):
	var root = get_tree().root
	if lang_code == "ja":
		if japanese_font:
			apply_font_recursively(root, japanese_font)
			print("Applied Japanese font to all UI elements")
		else:
			push_warning("Japanese font not loaded, cannot apply")
	else:
		# Optional: revert to default font
		if default_font:
			apply_font_recursively(root, default_font)
			print("Applied default font to all UI elements")
		else:
			# Remove font overrides to use Godot's default
			remove_font_overrides_recursively(root)
			print("Removed font overrides, using Godot default")

func apply_font_recursively(node: Node, font: Font):
	# Apply font to all Control nodes that support text
	if node is Label:
		node.add_theme_font_override("font", font)
	elif node is Button:
		node.add_theme_font_override("font", font)
	elif node is LineEdit:
		node.add_theme_font_override("font", font)
	elif node is TextEdit:
		node.add_theme_font_override("font", font)
	elif node is RichTextLabel:
		node.add_theme_font_override("normal_font", font)
	elif node is OptionButton:
		node.add_theme_font_override("font", font)
	elif node is CheckBox:
		node.add_theme_font_override("font", font)
	elif node is CheckButton:
		node.add_theme_font_override("font", font)
	
	# Recursively apply to all children
	for child in node.get_children():
		apply_font_recursively(child, font)

func remove_font_overrides_recursively(node: Node):
	# Remove font overrides to revert to default theme
	if node is Label:
		node.remove_theme_font_override("font")
	elif node is Button:
		node.remove_theme_font_override("font")
	elif node is LineEdit:
		node.remove_theme_font_override("font")
	elif node is TextEdit:
		node.remove_theme_font_override("font")
	elif node is RichTextLabel:
		node.remove_theme_font_override("normal_font")
	elif node is OptionButton:
		node.remove_theme_font_override("font")
	elif node is CheckBox:
		node.remove_theme_font_override("font")
	elif node is CheckButton:
		node.remove_theme_font_override("font")
	
	# Recursively remove from all children
	for child in node.get_children():
		remove_font_overrides_recursively(child)

>>>>>>> parent of 9b2cc3f (japanese is awful to translate)
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
