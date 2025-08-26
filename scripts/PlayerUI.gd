extends Control

@onready var health_bar = $HealthContainer/HealthBar
@onready var health_label = $HealthContainer/HealthLabel
@onready var weapon_icon = $WeaponContainer/WeaponIcon
@onready var weapon_name_label = $WeaponContainer/WeaponInfo/WeaponName
@onready var weapon_damage_label = $WeaponContainer/WeaponInfo/WeaponDamage
@onready var attack_cooldown_bar = $WeaponContainer/CooldownBar
@onready var inventory_slots = $InventoryContainer/InventoryGrid

@onready var weapon_container = $WeaponContainer
@onready var inventory_container = $InventoryContainer

var player: CharacterBody2D
var current_weapon_data: Dictionary = {}

var is_inventory_open = false

var slot_normal_texture = "res://path/to/slot_normal.png"
var slot_selected_texture = "res://path/to/slot_selected.png"
var slot_equipped_texture = "res://path/to/slot_equipped.png"

var weapon_database = {
	"sword": {
		"id": "sword",
		"name": "Iron Sword",
		"icon": "res://Assets/oubliette_weapons - free/spr_wep_iron_axe_2.png",
		"damage": 1,
		"description": "A basic iron sword"
	},
	"axe": {
		"id": "axe",
		"name": "Iron Axe",
		"icon": "res://Assets/oubliette_weapons - free/spr_wep_iron_axe_2.png",
		"damage": 2,
		"description": "A heavy iron axe"
	},
	"bow": {
		"id": "bow",
		"name": "Wooden Bow",
		"icon": "res://Assets/oubliette_weapons - free/spr_wep_wooden_bow.png",
		"damage": 1,
		"description": "A simple wooden bow"
	}
}

var inventory_items = []
var max_inventory_slots = 9
var selected_slot_index = -1

func _ready():
	find_player()
	setup_ui()
	hide_inventory_ui()
	create_inventory_slots()
	connect_item_manager()
	sync_weapon_from_player()
	update_inventory_display()

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		player = get_tree().get_first_node_in_group("player")

func setup_ui():
	if not player:
		return
	
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
		
		var health_percent = float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
		if health_percent > 0.6:
			health_bar.modulate = Color.GREEN
		elif health_percent > 0.3:
			health_bar.modulate = Color.YELLOW
		else:
			health_bar.modulate = Color.RED
	
	if health_label:
		health_label.text = str(current_hp) + "/" + str(max_hp)

func update_attack_cooldown():
	if not player or not attack_cooldown_bar:
		return
	
	if "cooldown_timer" in player and "attack_cooldown" in player:
		if player.cooldown_timer > 0:
			attack_cooldown_bar.visible = true
			attack_cooldown_bar.value = (player.attack_cooldown - player.cooldown_timer) / player.attack_cooldown
		else:
			attack_cooldown_bar.visible = false
	else:
		attack_cooldown_bar.visible = false

func _on_weapon_changed(weapon_data: Dictionary):
	current_weapon_data = weapon_data
	if weapon_container and weapon_container.visible:
		update_weapon_display()
	update_inventory_display()

func _on_inventory_updated():
	if inventory_container and inventory_container.visible:
		update_inventory_display()

func set_current_weapon(weapon_id: String):
	if has_node("/root/ItemManager"):
		var item_manager = get_node("/root/ItemManager")
		item_manager.equip_weapon(weapon_id)
		return
	
	if weapon_id in weapon_database:
		current_weapon_data = weapon_database[weapon_id].duplicate()
		if weapon_container and weapon_container.visible:
			update_weapon_display()
		update_inventory_display()
		
		if player and "attack_damage" in player:
			player.attack_damage = current_weapon_data.get("damage", 1)

func update_weapon_display():
	if current_weapon_data.is_empty():
		return
	
	if weapon_icon:
		var icon_path = current_weapon_data.get("icon", current_weapon_data.get("icon_path", ""))
		if icon_path != "":
			var texture = load(icon_path)
			if texture:
				weapon_icon.texture = texture
	
	if weapon_name_label:
		weapon_name_label.text = current_weapon_data.get("name", "Unknown Weapon")
	
	if weapon_damage_label:
		weapon_damage_label.text = "DMG: " + str(current_weapon_data.get("damage", 1))

func create_inventory_slots():
	if not inventory_slots:
		return
	
	for child in inventory_slots.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	if inventory_slots is GridContainer:
		inventory_slots.columns = 3
	
	for i in range(max_inventory_slots):
		var slot = create_enhanced_inventory_slot(i)
		inventory_slots.add_child(slot)

func create_enhanced_inventory_slot(index: int) -> Control:
	var slot = Control.new()
	slot.custom_minimum_size = Vector2(64, 64)
	slot.name = "InventorySlot" + str(index)
	
	var background = NinePatchRect.new()
	background.name = "Background"
	background.anchor_left = 0.0
	background.anchor_top = 0.0
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	
	if ResourceLoader.exists(slot_normal_texture):
		background.texture = load(slot_normal_texture)
	else:
		var panel = Panel.new()
		panel.name = "Panel"
		panel.anchor_left = 0.0
		panel.anchor_top = 0.0
		panel.anchor_right = 1.0
		panel.anchor_bottom = 1.0
		
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.3, 0.2, 0.1, 0.9)
		style_box.border_width_top = 2
		style_box.border_width_bottom = 2
		style_box.border_width_left = 2
		style_box.border_width_right = 2
		style_box.border_color = Color(0.6, 0.4, 0.2)
		style_box.corner_radius_top_left = 4
		style_box.corner_radius_top_right = 4
		style_box.corner_radius_bottom_left = 4
		style_box.corner_radius_bottom_right = 4
		panel.add_theme_stylebox_override("panel", style_box)
		slot.add_child(panel)
	
	if background.texture:
		slot.add_child(background)
	
	var item_icon = TextureRect.new()
	item_icon.name = "ItemIcon"
	item_icon.anchor_left = 0.1
	item_icon.anchor_top = 0.1
	item_icon.anchor_right = 0.9
	item_icon.anchor_bottom = 0.9
	item_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	slot.add_child(item_icon)
	
	var count_label = Label.new()
	count_label.name = "CountLabel"
	count_label.anchor_left = 0.6
	count_label.anchor_top = 0.6
	count_label.anchor_right = 1.0
	count_label.anchor_bottom = 1.0
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	count_label.add_theme_constant_override("shadow_offset_x", 1)
	count_label.add_theme_constant_override("shadow_offset_y", 1)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_label.text = ""
	slot.add_child(count_label)
	
	var selection_highlight = NinePatchRect.new()
	selection_highlight.name = "SelectionHighlight"
	selection_highlight.anchor_left = 0.0
	selection_highlight.anchor_top = 0.0
	selection_highlight.anchor_right = 1.0
	selection_highlight.anchor_bottom = 1.0
	selection_highlight.modulate = Color.YELLOW
	selection_highlight.visible = false
	
	if ResourceLoader.exists(slot_selected_texture):
		selection_highlight.texture = load(slot_selected_texture)
	else:
		var highlight_style = StyleBoxFlat.new()
		highlight_style.bg_color = Color.TRANSPARENT
		highlight_style.border_width_top = 3
		highlight_style.border_width_bottom = 3
		highlight_style.border_width_left = 3
		highlight_style.border_width_right = 3
		highlight_style.border_color = Color.YELLOW
		var highlight_panel = Panel.new()
		highlight_panel.name = "SelectionHighlight"
		highlight_panel.anchor_left = 0.0
		highlight_panel.anchor_top = 0.0
		highlight_panel.anchor_right = 1.0
		highlight_panel.anchor_bottom = 1.0
		highlight_panel.add_theme_stylebox_override("panel", highlight_style)
		highlight_panel.visible = false
		slot.add_child(highlight_panel)
		selection_highlight = highlight_panel
	
	if selection_highlight.get_parent() == null:
		slot.add_child(selection_highlight)
	
	var button = Button.new()
	button.name = "ClickDetector"
	button.anchor_left = 0.0
	button.anchor_top = 0.0
	button.anchor_right = 1.0
	button.anchor_bottom = 1.0
	button.flat = true
	button.pressed.connect(_on_slot_clicked.bind(index))
	slot.add_child(button)
	
	return slot

func _on_slot_clicked(slot_index: int):
	select_inventory_slot(slot_index)

func update_inventory_display():
	if not inventory_slots:
		return
	
	var slots = inventory_slots.get_children()
	if slots.is_empty():
		return
	
	for i in range(slots.size()):
		var slot = slots[i]
		clear_slot(slot)
		update_slot_selection(slot, i == selected_slot_index)
	
	var current_slot_index = 0
	
	if not current_weapon_data.is_empty() and current_slot_index < slots.size():
		var equipped_weapon_item = {
			"data": current_weapon_data,
			"quantity": 1,
			"equipped": true
		}
		display_item_in_slot(slots[current_slot_index], equipped_weapon_item, current_slot_index)
		current_slot_index += 1
	
	var items_to_show = []
	if has_node("/root/ItemManager"):
		var item_manager = get_node("/root/ItemManager")
		items_to_show = item_manager.get_inventory_items()
	else:
		items_to_show = inventory_items
	
	for item in items_to_show:
		if current_slot_index >= slots.size():
			break
		
		var item_id = ""
		if "data" in item:
			item_id = item.data.get("id", "")
		else:
			item_id = item.get("id", "")
		
		var equipped_weapon_id = current_weapon_data.get("id", "")
		if item_id == equipped_weapon_id and item.get("equipped", false):
			continue
		
		display_item_in_slot(slots[current_slot_index], item, current_slot_index)
		current_slot_index += 1

func clear_slot(slot: Control):
	if slot.has_node("ItemIcon"):
		slot.get_node("ItemIcon").texture = null
	if slot.has_node("CountLabel"):
		slot.get_node("CountLabel").text = ""

func update_slot_selection(slot: Control, is_selected: bool):
	var highlight = slot.get_node("SelectionHighlight") if slot.has_node("SelectionHighlight") else null
	if highlight:
		highlight.visible = is_selected

func display_item_in_slot(slot: Control, item: Dictionary, slot_index: int):
	if not slot.has_node("ItemIcon") or not slot.has_node("CountLabel"):
		return
	
	var icon = slot.get_node("ItemIcon")
	var count_label = slot.get_node("CountLabel")
	
	var icon_path = ""
	var quantity = 1
	var is_equipped = false
	
	if "data" in item:
		icon_path = item.data.get("icon_path", item.data.get("icon", ""))
		quantity = item.get("quantity", 1)
		is_equipped = item.get("equipped", false)
	else:
		if "icon" in item:
			icon_path = item.icon
		elif "id" in item and item.id in weapon_database:
			icon_path = weapon_database[item.id].get("icon", "")
		
		quantity = item.get("count", item.get("quantity", 1))
		is_equipped = item.get("equipped", false)
	
	if icon_path != "":
		if ResourceLoader.exists(icon_path):
			var texture = load(icon_path)
			if texture:
				icon.texture = texture
		else:
			var fallback_path = "res://icon.svg"
			if ResourceLoader.exists(fallback_path):
				icon.texture = load(fallback_path)
	
	if is_equipped:
		count_label.text = "E"
		count_label.add_theme_color_override("font_color", Color.GOLD)
	elif quantity > 1:
		count_label.text = str(quantity)
		count_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		count_label.text = ""
	
	if is_equipped:
		if slot.has_node("Panel"):
			var panel = slot.get_node("Panel")
			var style_box = panel.get_theme_stylebox("panel")
			if style_box is StyleBoxFlat:
				var new_style = style_box.duplicate()
				new_style.border_color = Color.GOLD
				panel.add_theme_stylebox_override("panel", new_style)

func _input(event):
	if event.is_action_pressed("ui_select"):
		toggle_inventory()

func toggle_inventory():
	if is_inventory_open:
		hide_inventory_ui()
		selected_slot_index = -1
	else:
		show_inventory_ui()
		update_inventory_display()
		update_weapon_display()

func select_inventory_slot(index: int):
	if not is_inventory_open or index >= max_inventory_slots:
		return
	
	selected_slot_index = index
	update_inventory_display()
	
	if index == 0:
		if not current_weapon_data.is_empty():
			var weapon_name = current_weapon_data.get("name", "Unknown Weapon")
			show_notification("Equipped: " + weapon_name, 2.0)
		return
	
	var items_to_show = []
	if has_node("/root/ItemManager"):
		var item_manager = get_node("/root/ItemManager")
		items_to_show = item_manager.get_inventory_items()
	else:
		items_to_show = inventory_items
	
	var inventory_index = index - 1
	
	if inventory_index >= 0 and inventory_index < items_to_show.size():
		var item = items_to_show[inventory_index]
		var item_name = ""
		
		if "data" in item:
			item_name = item.data.get("name", "Unknown Item")
		elif "id" in item and item.id in weapon_database:
			item_name = weapon_database[item.id].get("name", item.id)
		else:
			item_name = item.get("name", item.get("id", "Unknown"))
		
		show_notification("Selected: " + item_name, 2.0)

func show_notification(text: String, duration: float = 3.0):
	var notification_label = Label.new()
	notification_label.text = text
	notification_label.add_theme_font_size_override("font_size", 16)
	notification_label.add_theme_color_override("font_color", Color.WHITE)
	notification_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	notification_label.add_theme_constant_override("shadow_offset_x", 1)
	notification_label.add_theme_constant_override("shadow_offset_y", 1)
	notification_label.position = Vector2(50, 100)
	add_child(notification_label)
	
	var tween = create_tween()
	tween.tween_delay(duration - 1.0)
	tween.tween_property(notification_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(notification_label.queue_free) player.max_health if player.has_method("get") or "max_health" in player else 100
		health_bar.value = player.current_health if player.has_method("get") or "current_health" in player else 100
	
	update_health_display()

func connect_item_manager():
	if has_node("/root/ItemManager") or get_tree().get_nodes_in_group("ItemManager").size() > 0:
		var item_manager = get_node("/root/ItemManager")
		if item_manager:
			item_manager.weapon_changed.connect(_on_weapon_changed)
			item_manager.inventory_updated.connect(_on_inventory_updated)
			
			var equipped = item_manager.get_equipped_weapon()
			if not equipped.is_empty():
				current_weapon_data = equipped
				update_weapon_display()
	else:
		set_current_weapon("sword")

func sync_weapon_from_player():
	if not player:
		return
	
	if "attack_damage" in player:
		var weapon_id = "sword"
		
		if "current_weapon_id" in player:
			weapon_id = player.current_weapon_id
		
		if weapon_id in weapon_database:
			current_weapon_data = weapon_database[weapon_id].duplicate()
			current_weapon_data["damage"] = player.attack_damage
			current_weapon_data["id"] = weapon_id
		else:
			current_weapon_data = {
				"id": weapon_id,
				"name": "Current Weapon",
				"icon": "res://Assets/oubliette_weapons - free/spr_wep_iron_axe_2.png",
				"damage": player.attack_damage,
				"description": "Player's equipped weapon"
			}
	else:
		current_weapon_data = {
			"id": "sword",
			"name": "Default Sword",
			"icon": "res://Assets/oubliette_weapons - free/spr_wep_iron_axe_2.png",
			"damage": 1,
			"description": "Basic starting weapon"
		}

func on_player_weapon_changed(new_weapon_id: String):
	if new_weapon_id in weapon_database:
		current_weapon_data = weapon_database[new_weapon_id].duplicate()
		current_weapon_data["id"] = new_weapon_id
		
		if player and "attack_damage" in player:
			player.attack_damage = current_weapon_data["damage"]
			if "current_weapon_id" in player:
				player.current_weapon_id = new_weapon_id
		
		if is_inventory_open:
			update_inventory_display()
			update_weapon_display()

func hide_inventory_ui():
	if inventory_container:
		inventory_container.visible = false
	if weapon_container:
		weapon_container.visible = false
	is_inventory_open = false

func show_inventory_ui():
	if inventory_container:
		inventory_container.visible = true
	if weapon_container:
		weapon_container.visible = true
	is_inventory_open = true

func _process(delta):
	if not player:
		return
	
	update_health_display()
	
	if weapon_container and weapon_container.visible:
		update_attack_cooldown()
		update_weapon_display()

func update_health_display():
	if not player:
		return
	
	var current_hp = 100
	var max_hp = 100
	
	if "current_health" in player:
		current_hp = player.current_health
	if "max_health" in player:
		max_hp = player.max_health
	
	if health_bar:
		health_bar.max_value =
