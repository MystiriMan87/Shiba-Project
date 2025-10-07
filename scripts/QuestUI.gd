# QuestUI.gd
extends CanvasLayer

@onready var quest_container: VBoxContainer = $Panel/MarginContainer/QuestContainer

var quest_manager: Node = null

func _ready():
	quest_manager = get_node_or_null("/root/QuestManager")
	
	if quest_manager:
		quest_manager.quest_updated.connect(_on_quest_updated)
		quest_manager.quest_started.connect(_on_quest_started)
		quest_manager.quest_completed.connect(_on_quest_completed)
	
	refresh_quests()

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
		no_quest_label.add_theme_font_size_override("font_size", 14)
		no_quest_label.modulate = Color(0.7, 0.7, 0.7)
		quest_container.add_child(no_quest_label)
		return
	
	# Display each active quest
	for quest_id in active_quests:
		var quest_data = active_quests[quest_id]
		create_quest_display(quest_data)

func create_quest_display(quest_data: Dictionary):
	"""Create UI elements for a single quest"""
	
	# Quest title
	var title_label = Label.new()
	title_label.text = quest_data.name
	title_label.add_theme_font_size_override("font_size", 16)
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
		status_label.add_theme_font_size_override("font_size", 14)
		objective_hbox.add_child(status_label)
		
		# Objective text with progress
		var obj_label = Label.new()
		var progress_text = ""
		if "required" in objective and objective.required > 1:
			progress_text = " (%d/%d)" % [objective.current, objective.required]
		
		obj_label.text = objective.description + progress_text
		obj_label.add_theme_font_size_override("font_size", 12)
		
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
