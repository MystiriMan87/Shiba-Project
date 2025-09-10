extends Node

@export var respawn_delay = 3.0
@export var max_respawns = -1

var respawn_data = []

func _ready():
	add_to_group("respawn_manager")

func _process(delta):
	for i in range(respawn_data.size() - 1, -1, -1):
		var respawn_info = respawn_data[i]
		respawn_info.respawn_timer -= delta
		
		if respawn_info.respawn_timer <= 0:
			respawn_enemy(respawn_info)
			respawn_data.remove_at(i)

func register_enemy_death(enemy: Node):
	if max_respawns >= 0:
		var current_respawns = get_enemy_respawn_count(enemy)
		if current_respawns >= max_respawns:
			return
	
	var enemy_scene_path = get_enemy_scene_path(enemy)
	if enemy_scene_path == "":
		return
	
	var respawn_info = {
		"scene_path": enemy_scene_path,
		"position": enemy.global_position,
		"parent_node": enemy.get_parent(),
		"respawn_timer": respawn_delay,
		"respawn_count": get_enemy_respawn_count(enemy) + 1,
		"original_name": enemy.name
	}
	
	respawn_data.append(respawn_info)

func get_enemy_scene_path(enemy: Node) -> String:
	if "scene_path" in enemy:
		return enemy.scene_path
	
	# Check enemy_type property first (more reliable)
	if "enemy_type" in enemy:
		var enemy_type = enemy.enemy_type
		print("Respawn Manager: Enemy has enemy_type: ", enemy_type)
		var enemy_scene_map = {
			"slime": "res://scenes/slime_enemy.tscn",
			"skeleton": "res://scenes/skeleton_enemy.tscn",
		}
		if enemy_type in enemy_scene_map:
			print("Respawn Manager: Found scene path for enemy_type: ", enemy_scene_map[enemy_type])
			return enemy_scene_map[enemy_type]
	
	# Fallback: check enemy name
	var enemy_name = enemy.name.to_lower()
	print("Respawn Manager: Checking enemy name: ", enemy_name)
	
	var enemy_scene_map = {
		"slime": "res://scenes/slime_enemy.tscn",
		"skeleton": "res://scenes/skeleton_enemy.tscn",
	}
	
	for enemy_type in enemy_scene_map:
		if enemy_type in enemy_name:
			print("Respawn Manager: Found scene path for enemy name: ", enemy_scene_map[enemy_type])
			return enemy_scene_map[enemy_type]
	
	# Default fallback for any other enemies
	print("Respawn Manager: Using default fallback scene path")
	return "res://scenes/slime_enemy.tscn"

func get_enemy_respawn_count(enemy: Node) -> int:
	if enemy.has_meta("respawn_count"):
		return enemy.get_meta("respawn_count")
	return 0

func respawn_enemy(respawn_info: Dictionary):
	if not is_instance_valid(respawn_info.parent_node):
		return
	
	var enemy_scene = load(respawn_info.scene_path)
	if not enemy_scene:
		return
	
	var new_enemy = enemy_scene.instantiate()
	if not new_enemy:
		return
	
	new_enemy.global_position = respawn_info.position
	new_enemy.set_meta("respawn_count", respawn_info.respawn_count)
	
	if "original_name" in respawn_info:
		new_enemy.name = respawn_info.original_name
	
	add_respawn_effect(respawn_info.position)
	respawn_info.parent_node.call_deferred("add_child", new_enemy)

func add_respawn_effect(position: Vector2):
	pass

func get_pending_respawns() -> int:
	return respawn_data.size()

func clear_respawn_queue():
	respawn_data.clear()

func set_respawn_delay(new_delay: float):
	respawn_delay = new_delay

var respawning_enabled = true

func enable_respawning():
	respawning_enabled = true

func disable_respawning():
	respawning_enabled = false
	clear_respawn_queue()

func _register_enemy_death_checked(enemy: Node):
	if respawning_enabled:
		register_enemy_death(enemy)
