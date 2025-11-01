@tool
extends Label

@export var translation_key: String = ""
@export var auto_detect_key: bool = true

func _ready():
	if Engine.is_editor_hint():
		return
	
	if auto_detect_key and translation_key == "":
		translation_key = name.to_snake_case()
	
	update_translation()
	
	if has_node("/root/LocalizationManager"):
		LocalizationManager.language_changed.connect(_on_language_changed)

func update_translation():
	if translation_key != "" and has_node("/root/LocalizationManager"):
		text = LocalizationManager.t(translation_key)

func _on_language_changed(_lang: String):
	update_translation()
