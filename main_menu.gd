extends Control

@export var game_scene: PackedScene

func _ready():
	pass
	#anchor_left = 0
	#anchor_top = 0
	#anchor_right = 1
	#anchor_bottom = 1

func _on_play_pressed():
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)
	else:
		# fallback
		get_tree().change_scene_to_file("res://scenes/Hub.tscn")

func _on_quit_pressed():
	get_tree().quit()
