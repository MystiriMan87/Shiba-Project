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
			"title": "Welcome to Finders Keepers",
			"description": "Use WASD to move your character around the world. Right stick to move on controller.",
			"image": ""
		},
		{
			"title": "Controls",
			"description":"Left click or press F to attack enemies. Right trigger on controller. Tab (Triangle or Y on controller) to open inventory, J (Right bumper) to open Quest Log. E (Square or X) to interact.",
			"image": ""
		},
		{
			"title": "Ready to Start!",
			"description": "You're all set! Click Next to begin your adventure.",
			"image": ""
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
