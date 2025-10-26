# QuestUI.gd
extends CanvasLayer

@onready var quest_container: VBoxContainer = $Panel/MarginContainer/QuestContainer
var quest_manager: Node = null

@export var custom_font_path: String = "res://Fonts/PixeloidSans-nR3g1.ttf"  
@export var title_font_size: int = 24  # Quest title size
@export var objective_font_size: int = 18  # Objective text size
@export var no_quest_font_size: int = 20  # "No quests" message size

var custom_font: Font = null

func _ready():
	# Load custom font
	load_custom_font()
	
	quest_manager = get_node_or_null("/root/QuestManager")
	
	if quest_manager:
		quest_manager.quest_updated.connect(_on_quest_updated)
		quest_manager.quest_started.connect(_on_quest_started)
		quest_manager.quest_completed.connect(_on_quest_completed)
	
	refresh_quests()

func load_custom_font():
	"""Load the custom font from the specified path"""
	if FileAccess.file_exists(custom_font_path):
		custom_font = load(custom_font_path)
		print("Custom font loaded: ", custom_font_path)
	else:
		print("WARNING: Custom font not found at ", custom_font_path, " - using default font")

func apply_font_to_label(label: Label, font_size: int):
	"""Apply custom font and size to a label"""
	if custom_font:
		label.add_theme_font_override("font", custom_font)
	label.add_theme_font_size_override("font_size", font_size)

func _on_quest_updated():
	refresh_quests()

func _on_quest_started(quest_id: String):
	var quest_data = quest_manager.get_quest_data(quest_id)
	show_notification("New Quest: " + quest_data.name)
	refresh_quests()

func _on_quest_completed(quest_id: String):
	var quest_data = quest_manager.get_quest_data(quest_id)
	show_notification("Quest Completed: " + quest_data.name)
	refresh_quests()

func refresh_quests():
	"""Rebuild the quest list display"""
	if not quest_manager or not quest_container:
		return
	
	for child in quest_container.get_children():
		child.queue_free()
	
	var active_quests = quest_manager.get_active_quests()
	
	if active_quests.is_empty():
		var no_quest_label = Label.new()
		no_quest_label.text = "No Active Quests"
		apply_font_to_label(no_quest_label, no_quest_font_size)
		no_quest_label.modulate = Color(0.7, 0.7, 0.7)
		quest_container.add_child(no_quest_label)
		return
	
	# Display each active quest
	for quest_id in active_quests:
		var quest_data = active_quests[quest_id]
		create_quest_display(quest_data)

func create_quest_display(quest_data: Dictionary):
	# Quest title
	var title_label = Label.new()
	title_label.text = quest_data.name
	apply_font_to_label(title_label, title_font_size)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	quest_container.add_child(title_label)
	
	# Objectives
	for objective in quest_data.objectives:
		var objective_hbox = HBoxContainer.new()
		objective_hbox.add_theme_constant_override("separation", 5)
		
		# Checkbox/status icon
		var status_label = Label.new()
		if objective.completed:
			status_label.text = "✓"
			status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
		else:
			status_label.text = "○"
			status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		apply_font_to_label(status_label, objective_font_size)
		objective_hbox.add_child(status_label)
		
		# Objective text with progress
		var obj_label = Label.new()
		var progress_text = ""
		if "required" in objective and objective.required > 1:
			progress_text = " (%d/%d)" % [objective.current, objective.required]
		
		obj_label.text = objective.description + progress_text
		apply_font_to_label(obj_label, objective_font_size)
		
		if objective.completed:
			obj_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		else:
			obj_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		
		objective_hbox.add_child(obj_label)
		quest_container.add_child(objective_hbox)
	
	# Add spacing between quests
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	quest_container.add_child(spacer)

func show_notification(message: String):
	print("QUEST NOTIFICATION: ", message)
