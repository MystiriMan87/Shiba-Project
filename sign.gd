extends Area2D

@export var sign_text: String = "This is a sign"
@export var interaction_range: float = 50.0
@export var show_prompt_distance: float = 60.0

var player: Node = null
var player_in_range: bool = false

@onready var collision_shape = $CollisionShape2D

func _ready():
	add_to_group("signs")
	
	# Setup collision for detection
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		add_child(collision_shape)
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = show_prompt_distance
		collision_shape.shape = circle_shape
	
	collision_layer = 0
	collision_mask = 1
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	find_player()

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _process(delta):
	if not player:
		find_player()
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= interaction_range and Input.is_action_just_pressed("interact"):
		show_sign_text()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		player = body

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false

func show_sign_text():
	# Display sign text in UI
	var ui = get_node_or_null("/root/UI") or get_tree().current_scene.get_node_or_null("UI")
	
	if ui and ui.has_method("show_notification"):
		ui.show_notification(sign_text, 3.0)
	else:
		# Fallback: print to console
		print("Sign: ", sign_text)

func interact():
	show_sign_text()
