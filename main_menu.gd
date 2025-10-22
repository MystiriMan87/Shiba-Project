extends Control

@export var game_scene: PackedScene

func _ready():
	pass

func _on_play_pressed():
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)
	else:
		# fallback
		get_tree().change_scene_to_file("res://scenes/Hub.tscn")

#func _on_quit_pressed():
	## Make sure the game isn't paused
	#get_tree().paused = false
	#
	## Quit the game
	#get_tree().quit()


func _on_button_quit_pressed():
	get_tree().paused = false
	
	# Quit the game
	get_tree().quit()
