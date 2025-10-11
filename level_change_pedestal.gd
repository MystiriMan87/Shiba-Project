extends Area2D

@export var target_scene: String = "res://scenes/Hub.tscn"
@export var fade_duration: float = 0.5
@export var prompt_text: String = "Enter the dungeon?"

var can_teleport: bool = true
var player_in_area: bool = false
var dialog_open: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	collision_layer = 0
	collision_mask = 1

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = true
		if can_teleport and not dialog_open:
			show_confirmation_dialog()

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = false

func show_confirmation_dialog():
	dialog_open = true
	
	var canvas = CanvasLayer.new()
	canvas.layer = 99
	canvas.name = "ConfirmDialog"
	get_tree().root.add_child(canvas)
	
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(300, 150)
	panel.position = Vector2(
		get_viewport_rect().size.x / 2 - 150,
		get_viewport_rect().size.y / 2 - 75
	)
	canvas.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.size = Vector2(260, 110)
	panel.add_child(vbox)
	
	var label = Label.new()
	label.text = prompt_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)
	
	var yes_button = Button.new()
	yes_button.text = "Yes"
	yes_button.custom_minimum_size = Vector2(100, 40)
	hbox.add_child(yes_button)
	
	var button_spacer = Control.new()
	button_spacer.custom_minimum_size = Vector2(20, 0)
	hbox.add_child(button_spacer)
	
	var no_button = Button.new()
	no_button.text = "No"
	no_button.custom_minimum_size = Vector2(100, 40)
	hbox.add_child(no_button)
	
	yes_button.pressed.connect(func():
		canvas.queue_free()
		dialog_open = false
		teleport_player()
	)
	
	no_button.pressed.connect(func():
		canvas.queue_free()
		dialog_open = false
		can_teleport = true
	)

func teleport_player():
	can_teleport = false
	
	var transition = SceneTransition.new()
	transition.transition_to_scene(target_scene, fade_duration)

class SceneTransition:
	func transition_to_scene(scene_path: String, duration: float):
		var tree = Engine.get_main_loop() as SceneTree
		if not tree:
			return
		
		var root = tree.root
		var canvas = CanvasLayer.new()
		canvas.layer = 100
		
		var fade = ColorRect.new()
		fade.color = Color.BLACK
		fade.modulate.a = 0.0
		fade.set_anchors_preset(Control.PRESET_FULL_RECT)
		
		canvas.add_child(fade)
		root.add_child(canvas)
		
		var tween = tree.create_tween()
		tween.tween_property(fade, "modulate:a", 1.0, duration)
		tween.tween_callback(func():
			tree.call_deferred("change_scene_to_file", scene_path)
		)
		tween.tween_interval(duration)
		tween.tween_property(fade, "modulate:a", 0.0, duration)
		tween.tween_callback(func():
			canvas.queue_free()
		)
