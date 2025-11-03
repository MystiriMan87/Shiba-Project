extends Control
@export var slides: Array[Dictionary] = []
@export var next_scene: String = "res://scenes/Hub.tscn"
var current_slide: int = 0 

@onready var title_label = $Panel/TitleLabel
@onready var description_label = $Panel/DescriptionLabel
@onready var image_rect = $Panel/ImageRect
@onready var next_button = $Panel/NextButton
@onready var skip_button = $Panel/SkipButton
@onready var progress_label = $Panel/ProgressLabel

func _ready():
	slides = [
		{
			"title": "Welcome to Finders Keepers - いらっしゃいませ!",
			"description": "Use WASD to move your character around the world. Right stick to move on controller. \n \n WASD を使用して、キャラクターを世界中で移動させます。右スティックでコントローラーを移動します。",
			"image": "res://Screenshot 2025-11-02 at 9.31.45 AM.png"
		},
		{
			"title": "Controls - コントロール",
			"description":"Left click (RT) - Attack. \n Tab (Triangle/Y) - Inventory. \n J - Quest Log. \n E (Square/X) - Interact. \n \n 左クリック(RT) - 攻撃。\n タブ (三角形/Y) - インベントリ。\n J - クエストログ。\n E (スクエア/X) - インタラクト。",
			"image": "res://Screenshot 2025-11-02 at 9.36.41 AM.png"
		},
		{
			"title": "Ready to Start! - 始める準備完了!",
			"description": "You're all set! Click Next to begin your adventure. \n \n 準備は完了です! 「次へ」をクリックして冒険を始めます。",
			"image": "res://Screenshot 2025-11-02 at 9.40.41 AM.png"
		}
	]
	
	next_button.pressed.connect(_on_next_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	
	show_slide(0)
	
func show_slide(index: int):
	if index >= slides.size():
		go_to_next_scene()
		return
	
	current_slide = index
	var slide = slides[index]
	
	title_label.text = slide.get("title", "")
	description_label.text = slide.get("description", "")
	
	var image_path = slide.get("image", "")
	if image_path != "" and ResourceLoader.exists(image_path):
		image_rect.texture = load(image_path)
		image_rect.visible = true
	else:
		image_rect.visible = false
	
	progress_label.text = str(index + 1) + " / " + str(slides.size())
	
	if index == slides.size() - 1:
		next_button.text = "Start Game!"
	else:
		next_button.text = "Next"
		
func _on_next_pressed():
	show_slide(current_slide + 1)
	
func _on_skip_pressed():
	go_to_next_scene()
	
func go_to_next_scene():
	print("Tutorial completed, loading: ", next_scene)
	
	if has_node("/root/LoadingScreen"):
		LoadingScreen.load_scene(next_scene)
	else:
		get_tree().change_scene_to_file(next_scene)
		
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_skip_pressed()
