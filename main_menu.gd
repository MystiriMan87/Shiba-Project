extends Control

@export var game_scene: PackedScene
@export var slide_distance: float = 20.0
@export var slide_duration: float = 0.2

var button_original_positions: Dictionary = {}

func _ready():
	setup_button_animations()
	update_ui_text()
	
<<<<<<< HEAD
	
=======
	if has_node("/root/LocalizationManager"):
		LocalizationManager.language_changed.connect(_on_language_changed)
<<<<<<< HEAD
>>>>>>> parent of 9b2cc3f (japanese is awful to translate)
=======
>>>>>>> parent of 9b2cc3f (japanese is awful to translate)

func setup_button_animations():
	var buttons = find_buttons(self)
	
	for child in buttons:
		button_original_positions[child] = child.position
		child.mouse_entered.connect(_on_button_hover.bind(child))
		child.mouse_exited.connect(_on_button_unhover.bind(child))

func find_buttons(node: Node) -> Array:
	var buttons = []
	
	for child in node.get_children():
		if child is Button:
			buttons.append(child)
		buttons += find_buttons(child)
	
	return buttons

func _on_button_hover(button: Button):
	var target_pos = button_original_positions[button] + Vector2(slide_distance, 0)
	animate_button(button, target_pos)

func _on_button_unhover(button: Button):
	var target_pos = button_original_positions[button]
	animate_button(button, target_pos)

func animate_button(button: Button, target_position: Vector2):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "position", target_position, slide_duration)

func _on_play_pressed():
	print("Play button pressed - showing tutorial")
	get_tree().change_scene_to_file("res://scenes/TutorialScreen.tscn")

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://scenes/SettingsMenu.tscn")

func _on_button_quit_pressed():
	get_tree().paused = false
	get_tree().quit()
	

func update_ui_text():
	if has_node("StartButton"):
		$StartButton.text = LocalizationManager.t("start_game")
	if has_node("SettingsButton"):
		$SettingsButton.text = LocalizationManager.t("settings")
	if has_node("QuitButton"):
		$QuitButton.text = LocalizationManager.t("quit")

func _on_language_changed(new_lang: String):
	update_ui_text()
