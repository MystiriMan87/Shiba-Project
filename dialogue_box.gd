# DialogueBox.gd
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

@onready var panel: Panel = $Panel
@onready var speaker_label: Label = $Panel/MarginContainer/VBoxContainer/SpeakerLabel
@onready var text_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/TextLabel
@onready var continue_indicator: Label = $Panel/ContinueIndicator
@onready var type_timer: Timer = $TypeTimer

func _ready():
	hide()
	type_timer.timeout.connect(_on_type_timer_timeout)
	continue_indicator.text = "▼"
	continue_indicator.visible = false

func start_dialogue(dialogue_id: String):
	current_dialogue = DialogueManager.get_dialogue(dialogue_id)
	if current_dialogue.is_empty():
		push_warning("Dialogue not found: " + dialogue_id)
		return
	
	current_index = 0
	show()
	get_tree().paused = true
	display_current_line()

func display_current_line():
	if current_index >= current_dialogue.size():
		end_dialogue()
		return
	
	var line = current_dialogue[current_index]
	speaker_label.text = line.get("speaker", "")
	current_text = line.get("text", "")
	
	text_label.text = ""
	char_index = 0
	is_typing = true
	continue_indicator.visible = false
	
	type_timer.start(text_speed)

func _on_type_timer_timeout():
	if char_index < current_text.length():
		text_label.text += current_text[char_index]
		char_index += 1
		type_timer.start(text_speed) 
	else:
		type_timer.stop()
		is_typing = false
		continue_indicator.visible = true

func _input(event):
	if not visible:
		return
	
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()  # Consume the input
		
		if is_typing:
			# Skip typing animation
			type_timer.stop()
			text_label.text = current_text
			is_typing = false
			continue_indicator.visible = true
		else:
			# Advance to next line
			current_index += 1
			dialogue_advanced.emit()
			display_current_line()

func end_dialogue():
	hide()
	get_tree().paused = false
	dialogue_finished.emit()
	current_dialogue.clear()
	current_index = 0

func _exit_tree():
	if get_tree():
		get_tree().paused = false
