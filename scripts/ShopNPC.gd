extends CharacterBody2D

@export var dialogue_id: String = "merchant_intro"
@export var interaction_range: float = 60.0
@export var npc_name: String = "Merchant"

var player_in_range: bool = false
var player: Node = null

@onready var interaction_indicator: Label = null

func _ready():
	add_to_group("npcs")
	create_interaction_indicator()

func create_interaction_indicator():
	var label = Label.new()
	label.text = "E"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.position = Vector2(-10, -60)
	label.visible = false
	label.name = "InteractionLabel"
	add_child(label)
	interaction_indicator = label

func _physics_process(_delta):
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return
	
	var distance = global_position.distance_to(player.global_position)
	player_in_range = distance <= interaction_range
	
	if interaction_indicator:
		interaction_indicator.visible = player_in_range

func _input(event):
	# Handle interaction when player presses E
	if event.is_action_pressed("interact") and player_in_range:
		interact()

func interact():
	if not player_in_range or not player:
		return
	
	# Try multiple ways to find ShopUI
	var shop_ui = null
	
	# Method 1: Check in current scene
	shop_ui = get_tree().current_scene.get_node_or_null("ShopUI")
	
	# Method 2: Check as autoload
	if not shop_ui:
		shop_ui = get_node_or_null("/root/ShopUI")
	
	# Method 3: Search in tree
	if not shop_ui:
		var nodes = get_tree().get_nodes_in_group("shop_ui")
		if nodes.size() > 0:
			shop_ui = nodes[0]
	
	if shop_ui and shop_ui.has_method("open_shop"):
		print("Opening shop for player")
		shop_ui.open_shop(player)
	else:
		print("ERROR: ShopUI not found! Make sure ShopUI is:")
		print("  1. Added to your scene as a CanvasLayer node, OR")
		print("  2. Added as an Autoload singleton")
		print("  3. Has 'shop_ui' in its groups")
