extends CanvasLayer

signal dialogue_finished
signal dialogue_advanced

@export var text_speed: float = 0.05
@export var auto_advance_delay: float = 0.5

var current_dialogue: Array = []
var current_index: int = 0
var is_typing: bool = false
var current_text: String = ""
var char_index: int = 0

var character_portraits: Dictionary = {
	"Merchant": "res://portaits/portrait_human_3.png",
	"Elf Messenger": "res://portaits/portrait_dark_elf_4.png",
	"Crazed Wizard": "res://portaits/portrait_human_20.png",
	"Explorer Dave": "res://portaits/portrait_human_20.png",
	"???": "res://portaits/portrait_human_12.png",
	"Cowardly Skeleton": "res://portaits/portrait_skeleton.png"
}

@onready var panel: Panel = $Panel
@onready var speaker_label: Label = $Panel/MarginContainer/VBoxContainer/SpeakerLabel
@onready var text_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/TextLabel
@onready var continue_indicator: Label = $Panel/ContinueIndicator
@onready var type_timer: Timer = $TypeTimer
@onready var portrait_rect: TextureRect = $Panel/HBoxContainer/PortaitRect

func _ready():
	print("=== DialogueBox _ready() CALLED ===")
	
	# Wait one frame for all nodes to be ready
	await get_tree().process_frame
	
	print("Panel: ", panel)
	print("speaker_label: ", speaker_label)
	print("text_label: ", text_label)
	print("continue_indicator: ", continue_indicator)
	print("type_timer: ", type_timer)
	print("portrait_rect: ", portrait_rect)
	
	hide()
	
	if type_timer:
		type_timer.timeout.connect(_on_type_timer_timeout)
	
	if continue_indicator:
		continue_indicator.text = "▼"
		continue_indicator.visible = false
	
	if portrait_rect:
		portrait_rect.visible = false
<<<<<<< HEAD
	
	# Apply font for current language
	apply_dialogue_font()

func apply_dialogue_font():
	"""Apply the current language font to dialogue elements"""
	#if has_node("/root/LocalizationManager"):
		# Apply font to specific text elements only, not the portrait
		#if speaker_label:
			##LocalizationManager.apply_font_to_ui(speaker_label)
		#if text_label:
			#LocalizationManager.apply_font_to_ui(text_label)
		#if continue_indicator:
			#LocalizationManager.apply_font_to_ui(continue_indicator)
=======
>>>>>>> parent of 9b2cc3f (japanese is awful to translate)

func start_dialogue(dialogue_id: String):
	print("=== START DIALOGUE ===")
	print("dialogue_id: ", dialogue_id)
	
	current_dialogue = DialogueManager.get_dialogue(dialogue_id)
	print("current_dialogue size: ", current_dialogue.size())
	
	if current_dialogue.is_empty():
		push_warning("Dialogue not found: " + dialogue_id)
		return
	
	current_index = 0
	show()
	
	# Make sure panel is visible
	if panel:
		panel.visible = true
		panel.modulate = Color.WHITE
	
	get_tree().paused = false
	display_current_line()

func display_current_line():
	print("=== DISPLAY CURRENT LINE ===")
	
	if current_index >= current_dialogue.size():
		end_dialogue()
		return
	
	var line = current_dialogue[current_index]
	print("line: ", line)
	
	var speaker_name = ""
	
	if typeof(line) == TYPE_STRING:
		if speaker_label:
			speaker_label.text = ""
		current_text = line
		speaker_name = ""
	else:
		speaker_name = line.get("speaker", "")
		if speaker_label:
			speaker_label.text = speaker_name
		current_text = line.get("text", "")
	
	print("speaker_name: '", speaker_name, "'")
	print("current_text: '", current_text, "'")
	
	update_portrait(speaker_name)
	
	if text_label:
		text_label.text = ""
		text_label.visible = true
		text_label.modulate = Color.WHITE
		print("Text label ready for typing")
	
	char_index = 0
	is_typing = true
	
	if continue_indicator:
		continue_indicator.visible = false
	
	if type_timer:
		type_timer.start(text_speed)

func update_portrait(speaker_name: String):
	print("=== UPDATE PORTRAIT ===")
	print("Speaker: '", speaker_name, "'")
	print("PortraitRect exists: ", portrait_rect != null)
	
	if not portrait_rect:
		print("ERROR: No portrait_rect!")
		return
	
	if speaker_name == "":
		portrait_rect.visible = false
		portrait_rect.texture = null
		return
	
	if not character_portraits.has(speaker_name):
		print("Speaker not in dictionary")
		portrait_rect.visible = false
		return
	
	var portrait_path = character_portraits[speaker_name]
	print("Loading portrait: ", portrait_path)
	
	if ResourceLoader.exists(portrait_path):
		var texture = load(portrait_path)
		if texture:
			portrait_rect.texture = texture
			portrait_rect.visible = true
			portrait_rect.modulate = Color.WHITE
			print("Portrait loaded!")
		else:
			portrait_rect.visible = false
	else:
		print("Portrait file not found")
		portrait_rect.visible = false

func _on_type_timer_timeout():
	if char_index < current_text.length():
		if text_label:
			text_label.text += current_text[char_index]
		char_index += 1
		type_timer.start(text_speed) 
	else:
		type_timer.stop()
		is_typing = false
		if continue_indicator:
			continue_indicator.visible = true

func _input(event):
	if not visible:
		return
	
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		
		if is_typing:
			type_timer.stop()
			if text_label:
				text_label.text = current_text
			is_typing = false
			if continue_indicator:
				continue_indicator.visible = true
		else:
			current_index += 1
			dialogue_advanced.emit()
			display_current_line()

func end_dialogue():
	hide()
	get_tree().paused = false
	dialogue_finished.emit()
	current_dialogue.clear()
	current_index = 0
	
	if portrait_rect:
		portrait_rect.visible = false
		portrait_rect.texture = null

func _exit_tree():
	if get_tree():
		get_tree().paused = false

func add_portrait(character_name: String, portrait_path: String):
	character_portraits[character_name] = portrait_path

func remove_portrait(character_name: String):
	character_portraits.erase(character_name)
