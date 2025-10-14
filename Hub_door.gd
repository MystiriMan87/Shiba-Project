extends Area2D

@export var target_scene: String = "res://scenes/world.tscn"
@export var fade_duration: float = 0.5
@export var prompt_text: String = "Press E to enter the dungeon"

var can_teleport: bool = true
var player_in_area: bool = false
var prompt_visible: bool = false
var prompt_label: Label = null
var prompt_canvas: CanvasLayer = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	collision_layer = 0
	collision_mask = 1

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = true
		if can_teleport:
			show_prompt()

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = false
		hide_prompt()

func show_prompt():
	if prompt_visible:
		return
	
	prompt_visible = true
	
	# Create canvas layer for the prompt
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.name = "DoorPrompt"
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(canvas)
	
	prompt_label = Label.new()
	prompt_label.text = prompt_text
	prompt_label.add_theme_font_size_override("font_size", 24)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Position it near the bottom center of screen
	var viewport_size = get_viewport_rect().size
	prompt_label.position = Vector2(
		viewport_size.x / 2 - 150,
		viewport_size.y - 100
	)
	prompt_label.size = Vector2(300, 50)
	
	# Add a semi-transparent background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.position = prompt_label.position
	bg.size = prompt_label.size
	bg.z_index = -1
	
	canvas.add_child(bg)
	canvas.add_child(prompt_label)
	
	# Store reference to canvas for cleanup
	prompt_canvas = canvas

func hide_prompt():
	if not prompt_visible or not prompt_label:
		return
	
	prompt_visible = false
	
	if prompt_canvas and is_instance_valid(prompt_canvas):
		prompt_canvas.queue_free()
	
	prompt_label = null
	prompt_canvas = null

func _process(_delta):
	# Check for E key press while player is in area and prompt is visible
	if player_in_area and prompt_visible and Input.is_action_just_pressed("interact"):
		hide_prompt()
		teleport_player()

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
