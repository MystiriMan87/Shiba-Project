extends CanvasLayer

signal shop_closed

@onready var panel: Panel = $Panel
@onready var items_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ItemsContainer
@onready var gold_label: Label = $Panel/MarginContainer/VBoxContainer/TopBar/GoldLabel
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/TopBar/CloseButton
@onready var message_label: Label = $Panel/MarginContainer/VBoxContainer/MessageLabel

# New: Mode toggle buttons
@onready var buy_button: Button = null
@onready var sell_button: Button = null

var player: Node = null
var current_mode: String = "buy"  # "buy" or "sell"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("shop_ui")
	hide()
	
	# Create mode toggle buttons
	create_mode_toggle_buttons()
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func create_mode_toggle_buttons():
	# Find the TopBar to add buttons to it
	var top_bar = $Panel/MarginContainer/VBoxContainer/TopBar
	if not top_bar:
		return
	
	# Create Buy button
	buy_button = Button.new()
	buy_button.text = "Buy"
	buy_button.custom_minimum_size = Vector2(80, 30)
	buy_button.pressed.connect(_on_mode_changed.bind("buy"))
	top_bar.add_child(buy_button)
	top_bar.move_child(buy_button, 1)  # Place after gold label
	
	# Create Sell button
	sell_button = Button.new()
	sell_button.text = "Sell"
	sell_button.custom_minimum_size = Vector2(80, 30)
	sell_button.pressed.connect(_on_mode_changed.bind("sell"))
	top_bar.add_child(sell_button)
	top_bar.move_child(sell_button, 2)  # Place after buy button
	
	update_mode_button_styles()

func update_mode_button_styles():
	if not buy_button or not sell_button:
		return
	
	# Style the active button
	var active_style = StyleBoxFlat.new()
	active_style.bg_color = Color(0.3, 0.6, 0.3)
	active_style.border_color = Color(0.5, 0.8, 0.5)
	active_style.border_width_left = 2
	active_style.border_width_right = 2
	active_style.border_width_top = 2
	active_style.border_width_bottom = 2
	
	# Style the inactive button
	var inactive_style = StyleBoxFlat.new()
	inactive_style.bg_color = Color(0.2, 0.2, 0.2)
	inactive_style.border_color = Color(0.4, 0.4, 0.4)
	inactive_style.border_width_left = 2
	inactive_style.border_width_right = 2
	inactive_style.border_width_top = 2
	inactive_style.border_width_bottom = 2
	
	if current_mode == "buy":
		buy_button.add_theme_stylebox_override("normal", active_style)
		sell_button.add_theme_stylebox_override("normal", inactive_style)
	else:
		buy_button.add_theme_stylebox_override("normal", inactive_style)
		sell_button.add_theme_stylebox_override("normal", active_style)

func _on_mode_changed(mode: String):
	current_mode = mode
	update_mode_button_styles()
	
	if mode == "buy":
		populate_shop_items()
	else:
		populate_player_inventory()
	
	if message_label:
		message_label.text = ""

func open_shop(player_ref: Node):
	player = player_ref
	print("Opening shop for player...")
	show()
	get_tree().paused = true
	
	if not items_container:
		print("ERROR: items_container is null!")
		return
	
	current_mode = "buy"
	update_mode_button_styles()
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
	
	var shop_manager = get_node_or_null("/root/ShopManager")
	if not shop_manager:
		print("ERROR: ShopManager not found!")
		show_message("Shop Error: Manager not found!")
		return
	
	var shop_items = shop_manager.get_shop_items()
	
	if shop_items.is_empty():
		print("WARNING: No shop items found!")
		show_message("Shop is empty!")
		return
	
	for item_id in shop_items:
		var item_data = shop_items[item_id]
		create_buy_item(item_id, item_data)

func populate_player_inventory():
	# Clear existing items
	for child in items_container.get_children():
		child.queue_free()
	
	var item_manager = get_node_or_null("/root/ItemManager")
	if not item_manager:
		show_message("Error: ItemManager not found!")
		return
	
	var inventory_items = item_manager.get_inventory_items()
	
	if inventory_items.is_empty():
		show_message("Your inventory is empty!")
		return
	
	for item in inventory_items:
		var item_data = item.get("data", {})
		var item_id = item_data.get("id", "")
		var quantity = item.get("quantity", 1)
		
		# Don't allow selling equipped items
		if item.get("equipped", false):
			continue
		
		# Don't show coins in sell list
		if item_id == "coin":
			continue
		
		create_sell_item(item_id, item_data, quantity)

func create_buy_item(item_id: String, item_data: Dictionary):
	var item_panel = PanelContainer.new()
	item_panel.custom_minimum_size = Vector2(0, 60)
	
	var hbox = HBoxContainer.new()
	item_panel.add_child(hbox)
	
	# Item icon (if available)
	var icon_path = item_data.get("icon_path", item_data.get("icon", ""))
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(50, 50)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture = load(icon_path)
		hbox.add_child(icon_rect)
	
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

func create_sell_item(item_id: String, item_data: Dictionary, quantity: int):
	var item_panel = PanelContainer.new()
	item_panel.custom_minimum_size = Vector2(0, 60)
	
	var hbox = HBoxContainer.new()
	item_panel.add_child(hbox)
	
	# Item icon (if available)
	var icon_path = item_data.get("icon_path", item_data.get("icon", ""))
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(50, 50)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture = load(icon_path)
		hbox.add_child(icon_rect)
	
	# Item info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var name_label = Label.new()
	var name_text = item_data.get("name", "Unknown")
	if quantity > 1:
		name_text += " x" + str(quantity)
	name_label.text = name_text
	name_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = item_data.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	info_vbox.add_child(desc_label)
	
	# Sell price and button
	var sell_vbox = VBoxContainer.new()
	hbox.add_child(sell_vbox)
	
	var sell_price = calculate_sell_price(item_data)
	
	var price_label = Label.new()
	price_label.text = str(sell_price) + " Gold"
	price_label.add_theme_font_size_override("font_size", 14)
	price_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	sell_vbox.add_child(price_label)
	
	var sell_button = Button.new()
	sell_button.text = "Sell"
	sell_button.custom_minimum_size = Vector2(80, 0)
	sell_button.pressed.connect(_on_sell_pressed.bind(item_id, item_data, sell_price))
	sell_vbox.add_child(sell_button)
	
	items_container.add_child(item_panel)

func calculate_sell_price(item_data: Dictionary) -> int:
	# Sell for 50% of buy price (or a fixed amount if not in shop)
	var shop_manager = get_node_or_null("/root/ShopManager")
	if shop_manager:
		var item_id = item_data.get("id", "")
		var shop_items = shop_manager.get_shop_items()
		if shop_items.has(item_id):
			return int(shop_items[item_id].get("price", 0) * 0.5)
	
	# Default sell prices based on type
	var item_type = item_data.get("type", "")
	match item_type:
		"weapon":
			return 25
		"consumable":
			return 3
		"key":
			return 10
		"artifact":
			return 30
		_:
			return 5

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
				if item_manager.add_item_to_inventory(item_id, 1):
					show_message("Bought " + item_data.get("name", "Item") + "!")
				else:
					show_message("Inventory full! Refunding...")
					item_manager.add_item_to_inventory("coin", price)
			
			"weapon":
				if item_manager.add_item_to_inventory(item_id, 1):
					show_message("Bought " + item_data.get("name", "Weapon") + "!")
				else:
					show_message("Inventory full! Refunding...")
					item_manager.add_item_to_inventory("coin", price)
			
			"key":
				if item_manager.add_item_to_inventory(item_id, 1):
					show_message("Bought " + item_data.get("name", "Key") + "!")
				else:
					show_message("Inventory full! Refunding...")
					item_manager.add_item_to_inventory("coin", price)
			
			"upgrade":
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

func _on_sell_pressed(item_id: String, item_data: Dictionary, sell_price: int):
	if not player:
		return
	
	var item_manager = get_node_or_null("/root/ItemManager")
	if not item_manager:
		show_message("Error: ItemManager not found!")
		return
	
	# Remove one of the item from inventory
	if item_manager.remove_item_from_inventory(item_id, 1):
		# Add gold
		item_manager.add_item_to_inventory("coin", sell_price)
		show_message("Sold " + item_data.get("name", "Item") + " for " + str(sell_price) + " gold!")
		
		# Refresh the sell list
		populate_player_inventory()
		update_gold_display()
	else:
		show_message("Failed to sell item!")

func update_gold_display():
	var item_manager = get_node_or_null("/root/ItemManager")
	if item_manager and gold_label:
		var gold = item_manager.has_item("coin") 
		gold_label.text = "Gold: " + str(gold)

func show_message(msg: String):
	if message_label:
		message_label.text = msg
		
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
