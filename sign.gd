extends Node2D

@export var dialogue_id: String = "sign_default"
@export var interaction_range: float = 60.0

var player_in_range: bool = false
var player: Node = null

@onready var interaction_label: Label = null

func _ready():
	add_to_group("signs")
	interaction_label = get_node_or_null("E")
	if interaction_label:
		interaction_label.visible = false

func _physics_process(_delta):
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return
	
	var distance = global_position.distance_to(player.global_position)
	player_in_range = distance <= interaction_range
	
	if interaction_label:
		interaction_label.visible = player_in_range

func _unhandled_input(event):
	if player_in_range and event.is_action_pressed("interact"):
		interact()
		get_viewport().set_input_as_handled()

func interact():
	var dialogue_box = get_tree().current_scene.get_node_or_null("DialogueBox")
	if dialogue_box and dialogue_box.has_method("start_dialogue"):
		dialogue_box.start_dialogue(dialogue_id)
	else:
		print("DialogueBox not found in scene!")	
