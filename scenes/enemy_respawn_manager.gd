# EnemyRespawnManager.gd
# Attach this script to a Node in your main scene (create a new Node called "EnemyRespawnManager")

extends Node

# Respawn settings
@export var respawn_delay = 5.0  # Time in seconds before respawning
@export var max_respawns = -1    # -1 for infinite, or set a number limit

# Internal tracking
var respawn_data = []  # Array to store respawn information

# Structure for respawn data:
# {
#   "scene_path": String,     # Path to the enemy scene file
#   "position": Vector2,      # Original spawn position
#   "parent_node": Node,      # Parent node to add the enemy to
#   "respawn_timer": float,   # Time remaining until respawn
#   "respawn_count": int      # How many times this enemy has respawned
# }

func _ready():
	# Add to a group so enemies can easily find this manager
	add_to_group("respawn_manager")
	print("Enemy Respawn Manager initialized")

func _process(delta):
	# Process respawn timers
	for i in range(respawn_data.size() - 1, -1, -1):  # Iterate backwards to safely remove items
		var respawn_info = respawn_data[i]
		respawn_info.respawn_timer -= delta
		
		if respawn_info.respawn_timer <= 0:
			# Time to respawn!
			respawn_enemy(respawn_info)
			respawn_data.remove_at(i)

# Call this function when an enemy dies
func register_enemy_death(enemy: Node):
	# Check if we should respawn this enemy
	if max_respawns >= 0:
		var current_respawns = get_enemy_respawn_count(enemy)
		if current_respawns >= max_respawns:
			print("Enemy ", enemy.name, " has reached max respawns (", max_respawns, ")")
			return
	
	# Get enemy information for respawning
	var enemy_scene_path = get_enemy_scene_path(enemy)
	if enemy_scene_path == "":
		print("Could not determine scene path for enemy: ", enemy.name)
		return
	
	# Store respawn information
	var respawn_info = {
		"scene_path": enemy_scene_path,
		"position": enemy.global_position,
		"parent_node": enemy.get_parent(),
		"respawn_timer": respawn_delay,
		"respawn_count": get_enemy_respawn_count(enemy) + 1,
		"original_name": enemy.name
	}
	
	respawn_data.append(respawn_info)
	print("Registered enemy '", enemy.name, "' for respawn in ", respawn_delay, " seconds")

# Try to determine the scene path of an enemy
func get_enemy_scene_path(enemy: Node) -> String:
	# Method 1: Check if enemy has a custom property for its scene path
	if "scene_path" in enemy:
		return enemy.scene_path
	
	# Method 2: Try to guess based on the node name/type
	var enemy_name = enemy.name.to_lower()
	
	# Add your enemy scene paths here based on enemy names
	var enemy_scene_map = {
		#"skeleton": "res://scenes/enemies/Skeleton.tscn",
		#"goblin": "res://scenes/enemies/Goblin.tscn", 
		#"orc": "res://scenes/enemies/Orc.tscn",
		"slime": "/Users/alimapekov/shiba-project-game/scenes/enemy.tscn",
		#"enemy": "res://scenes/enemies/Enemy.tscn",  # Generic fallback
		# Add more enemy types as needed
	}
	
	# Check if enemy name contains any of the known types
	for enemy_type in enemy_scene_map:
		if enemy_type in enemy_name:
			return enemy_scene_map[enemy_type]
	
	# Method 3: Default fallback
	print("Warning: Unknown enemy type '", enemy.name, "' - using default scene")
	return "res://scenes/enemies/Enemy.tscn"  # Change this to your default enemy scene path

# Get how many times an enemy has been respawned (using metadata)
func get_enemy_respawn_count(enemy: Node) -> int:
	if enemy.has_meta("respawn_count"):
		return enemy.get_meta("respawn_count")
	return 0

# Respawn an enemy
func respawn_enemy(respawn_info: Dictionary):
	if not is_instance_valid(respawn_info.parent_node):
		print("Parent node no longer exists, cannot respawn enemy")
		return
	
	# Load the enemy scene
	var enemy_scene = load(respawn_info.scene_path)
	if not enemy_scene:
		print("Failed to load enemy scene: ", respawn_info.scene_path)
		return
	
	# Create new enemy instance
	var new_enemy = enemy_scene.instantiate()
	if not new_enemy:
		print("Failed to instantiate enemy from scene: ", respawn_info.scene_path)
		return
	
	# Set up the new enemy
	new_enemy.global_position = respawn_info.position
	new_enemy.set_meta("respawn_count", respawn_info.respawn_count)
	
	# Restore original name if available
	if "original_name" in respawn_info:
		new_enemy.name = respawn_info.original_name
	
	# Add visual respawn effect (optional)
	add_respawn_effect(respawn_info.position)
	
	# Add the enemy back to the scene
	respawn_info.parent_node.call_deferred("add_child", new_enemy)
	
	print("Respawned enemy '", new_enemy.name, "' at position ", respawn_info.position)

# Add a visual effect when enemy respawns (optional)
func add_respawn_effect(position: Vector2):
	# Simple particle effect or animation
	# You can expand this to add actual particles, sounds, etc.
	
	# For now, just print to console
	print("*Respawn effect at position: ", position, "*")
	
	# Example: Create a simple fade-in effect node (optional)
	# You could create a ColorRect or Sprite2D here with a tween animation

# Public functions for external use

# Get current respawn queue size
func get_pending_respawns() -> int:
	return respawn_data.size()

# Clear all pending respawns (useful for scene transitions)
func clear_respawn_queue():
	respawn_data.clear()
	print("Respawn queue cleared")

# Change respawn delay dynamically
func set_respawn_delay(new_delay: float):
	respawn_delay = new_delay
	print("Respawn delay changed to: ", new_delay, " seconds")

# Enable/disable respawning
var respawning_enabled = true

func enable_respawning():
	respawning_enabled = true
	print("Enemy respawning enabled")

func disable_respawning():
	respawning_enabled = false
	clear_respawn_queue()
	print("Enemy respawning disabled")

# Override register_enemy_death to check if respawning is enabled
func _register_enemy_death_checked(enemy: Node):
	if respawning_enabled:
		register_enemy_death(enemy)
	else:
		print("Respawning disabled - enemy will not respawn: ", enemy.name)
