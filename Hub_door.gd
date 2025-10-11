extends Area2D

@export var target_scene: String = "res://scenes/world.tscn"
@export var fade_duration: float = 0.5

var can_teleport: bool = true

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	collision_layer = 0
	collision_mask = 1

func _on_body_entered(body: Node2D):
	if body.is_in_group("player") and can_teleport:
		teleport_player()

func _on_body_exited(body: Node2D):
	pass

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
