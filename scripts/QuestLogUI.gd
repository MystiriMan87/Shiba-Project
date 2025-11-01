# QuestLogUI.gd
extends CanvasLayer

signal quest_log_closed

var quest_manager: Node = null
var active_container: VBoxContainer = null
var completed_container: VBoxContainer = null
var available_container: VBoxContainer = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("quest_log_ui")
	hide()
	
	quest_manager = get_node_or_null("/root/QuestManager")
	if not quest_manager:
		print("ERROR: QuestManager not found!")
	
	find_containers()
	

func find_containers():
	var tabs = get_node_or_null("Panel/MarginContainer/TabContainer")
	if not tabs:
		print("ERROR: TabContainer not found!")
		return
	
	for tab_idx in tabs.get_tab_count():
		var tab_name = tabs.get_tab_title(tab_idx)
		var tab_control = tabs.get_tab_control(tab_idx)
		
		if tab_control:
			var scroll = tab_control.get_node_or_null("ScrollContainer")
			if scroll:
				var vbox = scroll.get_node_or_null("VBoxContainer")
				if vbox:
					match tab_name:
						"Active":
							active_container = vbox
							print("Found Active container")
						"Completed":
							completed_container = vbox
							print("Found Completed container")
						"Available":
							available_container = vbox
							print("Found Available container")

func open_quest_log():
	print("Opening quest log...")
	show()
	get_tree().paused = true
	
	var virtual_cursor = get_node_or_null("/root/VirtualCursor")
	if virtual_cursor:
		print("Unlocking cursor from orbit...")
		virtual_cursor.on_menu_opened()
		virtual_cursor.force_activate()
		print("Cursor orbit_around_player: ", virtual_cursor.orbit_around_player)
	else:
		print("WARNING: VirtualCursor not found!")
	
	refresh_all_tabs()


func close_quest_log():
	print("Closing quest log...")
	hide()
	get_tree().paused = false
	
	var virtual_cursor = get_node_or_null("/root/VirtualCursor")
	if virtual_cursor:
		print("Locking ursor back to orbit... ")
		virtual_cursor.on_menu_closed()
		print("Cursor orbit_around_player: ", virtual_cursor.orbit_around_player)
		

	quest_log_closed.emit()

func refresh_all_tabs():
	if not quest_manager:
		print("Cannot refresh - QuestManager not found")
		return
	
	print("Refreshing all tabs...")
	refresh_active_quests()
	refresh_completed_quests()
	refresh_available_quests()

func refresh_active_quests():
	if not active_container:
		print("Active container not found")
		return
		
	clear_container(active_container)
	
	var active_quests = quest_manager.get_active_quests()
	print("Active quests: ", active_quests.size())
	
	if active_quests.is_empty():
		var label = Label.new()
		label.text = "No active quests"
		label.add_theme_font_size_override("font_size", 16)
		active_container.add_child(label)
		return
	
	for quest_id in active_quests:
		var quest_data = active_quests[quest_id]
		create_detailed_quest_panel(quest_data, active_container, true)

func refresh_completed_quests():
	if not completed_container:
		print("Completed container not found")
		return
		
	clear_container(completed_container)
	
	var completed_quests = quest_manager.completed_quests
	print("Completed quests: ", completed_quests.size())
	
	if completed_quests.is_empty():
		var label = Label.new()
		label.text = "No completed quests yet"
		label.add_theme_font_size_override("font_size", 16)
		completed_container.add_child(label)
		return
	
	for quest_id in completed_quests:
		var quest_data = quest_manager.get_quest_data(quest_id)
		create_simple_quest_panel(quest_data, completed_container, "COMPLETED")

func refresh_available_quests():
	if not available_container:
		print("Available container not found")
		return
		
	clear_container(available_container)
	
	var available_quests = quest_manager.get_all_available_quests()
	print("Available quests: ", available_quests.size())
	
	if available_quests.is_empty():
		var label = Label.new()
		label.text = "No available quests"
		label.add_theme_font_size_override("font_size", 16)
		available_container.add_child(label)
		return
	
	for quest_id in available_quests:
		var quest_data = quest_manager.get_quest_data(quest_id)
		create_quest_with_accept(quest_data, available_container)

func create_detailed_quest_panel(quest_data: Dictionary, container: VBoxContainer, show_objectives: bool):
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 0)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 5)
	margin.add_child(content_vbox)
	
	var title = Label.new()
	title.text = quest_data.name
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	content_vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = quest_data.description
	desc.add_theme_font_size_override("font_size", 14)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	content_vbox.add_child(desc)
	
	if show_objectives:
		var obj_header = Label.new()
		obj_header.text = "\nObjectives:"
		obj_header.add_theme_font_size_override("font_size", 16)
		content_vbox.add_child(obj_header)
		
		for objective in quest_data.objectives:
			var obj_hbox = HBoxContainer.new()
			
			var status = Label.new()
			status.text = "✓ " if objective.completed else "○ "
			status.add_theme_font_size_override("font_size", 14)
			status.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2) if objective.completed else Color(0.8, 0.8, 0.8))
			obj_hbox.add_child(status)
			
			var obj_text = Label.new()
			var progress = ""
			if "required" in objective and objective.required > 1:
				progress = " (%d/%d)" % [objective.current, objective.required]
			obj_text.text = objective.description + progress
			obj_text.add_theme_font_size_override("font_size", 14)
			obj_hbox.add_child(obj_text)
			
			content_vbox.add_child(obj_hbox)
	
	if "rewards" in quest_data:
		var rewards_label = Label.new()
		rewards_label.text = "\nRewards:"
		rewards_label.add_theme_font_size_override("font_size", 16)
		content_vbox.add_child(rewards_label)
		
		var rewards = quest_data.rewards
		if "gold" in rewards:
			var gold_label = Label.new()
			gold_label.text = "  • %d Gold" % rewards.gold
			gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
			content_vbox.add_child(gold_label)
		
		if "items" in rewards:
			for item_id in rewards.items:
				var item_label = Label.new()
				item_label.text = "  • " + item_id.capitalize()
				content_vbox.add_child(item_label)
		
		if "experience" in rewards:
			var xp_label = Label.new()
			xp_label.text = "  • %d XP" % rewards.experience
			content_vbox.add_child(xp_label)
	
	container.add_child(panel)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	container.add_child(spacer)

func create_simple_quest_panel(quest_data: Dictionary, container: VBoxContainer, status_text: String):
	var hbox = HBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = quest_data.name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)
	
	var status_label = Label.new()
	status_label.text = status_text
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	hbox.add_child(status_label)
	
	container.add_child(hbox)

func create_quest_with_accept(quest_data: Dictionary, container: VBoxContainer):
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 0)
	
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	hbox.add_child(margin)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(content_vbox)
	
	var title = Label.new()
	title.text = quest_data.name
	title.add_theme_font_size_override("font_size", 18)
	content_vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = quest_data.description
	desc.add_theme_font_size_override("font_size", 14)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	content_vbox.add_child(desc)
	
	var accept_button = Button.new()
	accept_button.text = "Accept Quest"
	accept_button.custom_minimum_size = Vector2(120, 40)
	accept_button.pressed.connect(_on_accept_quest.bind(quest_data.id))
	hbox.add_child(accept_button)
	
	container.add_child(panel)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	container.add_child(spacer)

func _on_accept_quest(quest_id: String):
	if quest_manager:
		quest_manager.start_quest(quest_id)
		refresh_all_tabs()

func clear_container(container: VBoxContainer):
	if not container:
		return
	for child in container.get_children():
		child.queue_free()

func _on_close_pressed():
	close_quest_log()

func _input(event):
	if not visible:
		return
		
	if event.is_action_pressed("ui_cancel"):
		close_quest_log()
		get_viewport().set_input_as_handled()
		
	if event.is_action_pressed("open_quest_log"):
		close_quest_log()
		get_viewport().set_input_as_handled()
