extends CharacterBody2D

@export var dialogue_id: String = "npc_greeting"
@export var interaction_range: float = 60.0
@export var npc_name: String = "Villager"

var player_in_range: bool = false
var player: Node = null

@onready var interaction_indicator: Sprite2D = null

func _ready():
	add_to_group("npcs")
	
	create_interaction_indicator()

func create_interaction_indicator():
	# Create a simple label that shows "E" when player is near
	var label = Label.new()
	label.text = "E"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.position = Vector2(-10, -60)  # Above the NPC
	label.visible = false
	label.name = "InteractionLabel"
	add_child(label)
	#interaction_indicator = label

func _physics_process(_delta):
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return
	
	# Check if player is in range
	var distance = global_position.distance_to(player.global_position)
	player_in_range = distance <= interaction_range
	
	# Show/hide indicator
	if interaction_indicator:
		interaction_indicator.visible = player_in_range

func interact():
	if not player_in_range:
		return
		
	# Find the dialogue box in the scene
	var dialogue_box = get_tree().current_scene.get_node_or_null("DialogueBox")
	if dialogue_box and dialogue_box.has_method("start_dialogue"):
		dialogue_box.start_dialogue(dialogue_id)
	else:
		print("DialogueBox not found in scene!")
