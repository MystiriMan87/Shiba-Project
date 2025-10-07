# NPC.gd
extends CharacterBody2D

@export var dialogue_id: String = "npc_greeting"
@export var interaction_range: float = 60.0
@export var npc_name: String = "Villager"
@export var npc_id: String = "villager"
@export var dialogue_audio_path: String = "res://audio/old-miser-laugh-63694.mp3"
@export var audio_volume: float = -5.0

@export_group("Quest Settings")
@export var is_quest_giver: bool = false
@export var quest_to_give: String = ""
@export var quest_dialogue_id: String = ""
@export var quest_complete_dialogue_id: String = ""
@export var quest_active_dialogue_id: String = ""

var player_in_range: bool = false
var player: Node = null

@onready var interaction_indicator: Label = null
@onready var npc_audio_player: AudioStreamPlayer2D = null

func _ready():
	add_to_group("npcs")
	create_interaction_indicator()
	setup_audio()

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
	
	if is_quest_giver and quest_to_give != "":
		create_quest_indicator()

func create_quest_indicator():
	var quest_indicator = Label.new()
	quest_indicator.text = "!"
	quest_indicator.add_theme_font_size_override("font_size", 30)
	quest_indicator.add_theme_color_override("font_color", Color.YELLOW)
	quest_indicator.add_theme_color_override("font_outline_color", Color.BLACK)
	quest_indicator.add_theme_constant_override("outline_size", 3)
	quest_indicator.position = Vector2(-8, -80)
	quest_indicator.name = "QuestIndicator"
	add_child(quest_indicator)

func setup_audio():
	npc_audio_player = AudioStreamPlayer2D.new()
	npc_audio_player.name = "NPCAudioPlayer"
	npc_audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(npc_audio_player)
	
	if dialogue_audio_path != "" and ResourceLoader.exists(dialogue_audio_path):
		var audio = load(dialogue_audio_path)
		
		if audio is AudioStream:
			npc_audio_player.stream = audio
			npc_audio_player.volume_db = audio_volume
			npc_audio_player.bus = "Master"
			npc_audio_player.max_distance = 2000
			npc_audio_player.attenuation = 0.5
			
			if audio is AudioStreamMP3:
				audio.loop = true
			elif audio is AudioStreamOggVorbis:
				audio.loop = true
			elif audio is AudioStreamWAV:
				audio.loop_mode = AudioStreamWAV.LOOP_FORWARD

func _physics_process(_delta):
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return
	
	var distance = global_position.distance_to(player.global_position)
	player_in_range = distance <= interaction_range
	
	if interaction_indicator:
		interaction_indicator.visible = player_in_range
	
	update_quest_indicator()

func update_quest_indicator():
	var quest_indicator = get_node_or_null("QuestIndicator")
	if not quest_indicator or not is_quest_giver or quest_to_give == "":
		return
	
	var quest_manager = get_node_or_null("/root/QuestManager")
	if not quest_manager:
		quest_indicator.visible = false
		return
	
	if not quest_manager.is_quest_active(quest_to_give) and not quest_manager.is_quest_completed(quest_to_give):
		quest_indicator.text = "!"
		quest_indicator.add_theme_color_override("font_color", Color.YELLOW)
		quest_indicator.visible = true
	elif quest_manager.is_quest_active(quest_to_give):
		quest_indicator.text = "?"
		quest_indicator.add_theme_color_override("font_color", Color.GRAY)
		quest_indicator.visible = true
	else:
		quest_indicator.visible = false

func interact():
	if not player_in_range:
		return
	
	if npc_audio_player and npc_audio_player.stream:
		npc_audio_player.play()
	
	var current_dialogue = dialogue_id
	var quest_manager = get_node_or_null("/root/QuestManager")
	
	if is_quest_giver and quest_to_give != "" and quest_manager:
		current_dialogue = handle_quest_interaction(quest_manager)
	
	if quest_manager:
		quest_manager.on_npc_talked(npc_id)
	
	var dialogue_box = get_tree().current_scene.get_node_or_null("DialogueBox")
	if dialogue_box and dialogue_box.has_method("start_dialogue"):
		dialogue_box.start_dialogue(current_dialogue)
		
		if not dialogue_box.dialogue_finished.is_connected(_on_dialogue_finished):
			dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	else:
		print("DialogueBox not found in scene!")

func handle_quest_interaction(quest_manager: Node) -> String:
	if not quest_manager.is_quest_active(quest_to_give) and not quest_manager.is_quest_completed(quest_to_give):
		quest_manager.start_quest(quest_to_give)
		print("Quest given: ", quest_to_give)
		
		if quest_dialogue_id != "":
			return quest_dialogue_id
		else:
			var quest_data = quest_manager.get_quest_data(quest_to_give)
			print("New quest available: ", quest_data.name)
			return dialogue_id
	
	elif quest_manager.is_quest_active(quest_to_give):
		var quest_data = quest_manager.get_quest_data(quest_to_give)
		var all_objectives_done = true
		
		for objective in quest_data.objectives:
			if not objective.completed:
				all_objectives_done = false
				break
		
		if all_objectives_done:
			quest_manager.complete_quest(quest_to_give)
			print("Quest completed: ", quest_to_give)
			
			if quest_complete_dialogue_id != "":
				return quest_complete_dialogue_id
			else:
				return dialogue_id
		else:
			if quest_active_dialogue_id != "":
				return quest_active_dialogue_id
			else:
				return dialogue_id
	
	else:
		return dialogue_id

func _on_dialogue_finished():
	if npc_audio_player and npc_audio_player.playing:
		npc_audio_player.stop()
