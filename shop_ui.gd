extends CanvasLayer

signal shop_closed

@onready var panel: Panel = $Panel
@onready var items_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ItemsContainer
@onready var gold_label: Label = $Panel/MarginContainer/VBoxContainer/TopBar/GoldLabel
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/TopBar/CloseButton
@onready var message_label: Label = $Panel/MarginContainer/VBoxContainer/MessageLabel

var player: Node = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("shop_ui")  # Add to group so NPC can find it
	hide()
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func open_shop(player_ref: Node):
	player = player_ref
	print("Opening shop for player...")
	show()
	get_tree().paused = true
	
	# Debug: Check if nodes exist
	if not items_container:
		print("ERROR: items_container is null!")
		return
	
	if not gold_label:
		print("ERROR: gold_label is null!")
	
	if not message_label:
		print("ERROR: message_label is null!")
	
	populate_shop_items()
	update_gold_display()
	
	if message_label:
		message_label.text = ""

func close_shop():
	hide()
	get_tree().paused = false
	shop_closed.emit()

func populate_shop_items():
	# Clear existing items
	for child in items_container.get_children():
		child.queue_free()
	
	# Check if ShopManager exists
	var shop_manager = get_node_or_null("/root/ShopManager")
	if not shop_manager:
		print("ERROR: ShopManager not found! Did you add it as an Autoload?")
		show_message("Shop Error: Manager not found!")
		return
	
	var shop_items = shop_manager.get_shop_items()
	
	if shop_items.is_empty():
		print("WARNING: No shop items found!")
		show_message("Shop is empty!")
		return
	
	print("Loading ", shop_items.size(), " shop items...")
	
	for item_id in shop_items:
		var item_data = shop_items[item_id]
		create_shop_item(item_id, item_data)
	
	print("Shop populated successfully!")

func create_shop_item(item_id: String, item_data: Dictionary):
	var item_panel = PanelContainer.new()
	item_panel.custom_minimum_size = Vector2(0, 60)
	
	var hbox = HBoxContainer.new()
	item_panel.add_child(hbox)
	
	# Item info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var name_label = Label.new()
	name_label.text = item_data.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = item_data.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	info_vbox.add_child(desc_label)
	
	# Price and buy button
	var buy_vbox = VBoxContainer.new()
	hbox.add_child(buy_vbox)
	
	var price_label = Label.new()
	price_label.text = str(item_data.get("price", 0)) + " Gold"
	price_label.add_theme_font_size_override("font_size", 14)
	price_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	buy_vbox.add_child(price_label)
	
	var buy_button = Button.new()
	buy_button.text = "Buy"
	buy_button.custom_minimum_size = Vector2(80, 0)
	buy_button.pressed.connect(_on_buy_pressed.bind(item_id, item_data))
	buy_vbox.add_child(buy_button)
	
	items_container.add_child(item_panel)

func _on_buy_pressed(item_id: String, item_data: Dictionary):
	if not player:
		return
	
	var item_manager = get_node_or_null("/root/ItemManager")
	if not item_manager:
		show_message("Error: ItemManager not found!")
		return
	
	var price = item_data.get("price", 0)
	var player_gold = item_manager.has_item("coin")
	
	if player_gold >= price:
		# Remove gold
		item_manager.remove_item_from_inventory("coin", price)
		
		# Handle different item types
		var item_type = item_data.get("type", "")
		
		match item_type:
			"consumable":
				# Add consumable to inventory
				if item_manager.add_item_to_inventory(item_id, 1):
					show_message("Bought " + item_data.get("name", "Item") + "!")
				else:
					show_message("Inventory full! Refunding...")
					item_manager.add_item_to_inventory("coin", price)
			
			"weapon":
				# Add weapon to inventory
				if item_manager.add_item_to_inventory(item_id, 1):
					show_message("Bought " + item_data.get("name", "Weapon") + "!")
				else:
					show_message("Inventory full! Refunding...")
					item_manager.add_item_to_inventory("coin", price)
			
			"key":
				# Add key to inventory
				if item_manager.add_item_to_inventory(item_id, 1):
					show_message("Bought " + item_data.get("name", "Key") + "!")
				else:
					show_message("Inventory full! Refunding...")
					item_manager.add_item_to_inventory("coin", price)
			
			"upgrade":
				# Permanent upgrades (like max health)
				match item_id:
					"max_health_upgrade":
						if player.has_method("get_max_health"):
							player.max_health += 1
							player.current_health += 1
							if player.has_signal("health_changed"):
								player.health_changed.emit(player.current_health)
							show_message("Bought Heart Container! Max HP +1")
					_:
						show_message("Unknown upgrade type!")
						item_manager.add_item_to_inventory("coin", price)
			
			_:
				show_message("Unknown item type!")
				item_manager.add_item_to_inventory("coin", price)
		
		update_gold_display()
	else:
		show_message("Not enough gold! Need " + str(price - player_gold) + " more.")

func update_gold_display():
	var item_manager = get_node_or_null("/root/ItemManager")
	if item_manager and gold_label:
		var gold = item_manager.has_item("coin") 
		gold_label.text = "Gold: " + str(gold)

func show_message(msg: String):
	if message_label:
		message_label.text = msg
		
		# Clear message after 2 seconds
		await get_tree().create_timer(2.0).timeout
		if is_instance_valid(message_label):
			message_label.text = ""

func _on_close_pressed():
	close_shop()

func _unhandled_input(event):
	if not visible:
		return
	
	if event.is_action_pressed("ui_cancel"):
		close_shop()
		get_viewport().set_input_as_handled()
