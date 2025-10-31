extends Label


func _ready():
	update_text()
	LocalizationManager.language_changed.connect(_on_language_changed)

func update_text():
	text = LocalizationManager.t("Settings")
	

func _on_language_changed(_lang: String):
	update_text()
