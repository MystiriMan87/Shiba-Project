extends Node

# Autoload singleton to manage Godot TranslationServer

signal translations_loaded()

var loaded_translation: Translation = null

func _ready():
	# Attempt to load default language from SettingsManager if available
	var lang = "en"
	if has_node("/root/SettingsManager"):
		lang = SettingsManager.settings.gameplay.get("language", "en")
	set_locale(lang)

func set_locale(lang_code: String):
	# Remove existing translation
	if loaded_translation:
		TranslationServer.remove_translation(loaded_translation)
		loaded_translation = null

	# Load .po file from locale folder
	var path = "res://locale/%s.po" % lang_code
	if ResourceLoader.exists(path):
		var tr = Translation.new()
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			if tr.parse_po(file.get_as_text()):
				loaded_translation = tr
				TranslationServer.add_translation(tr)
				print("Loaded translation: " , path)
				emit_signal("translations_loaded")
			else:
				push_warning("Failed to parse .po file: %s" % path)
			file.close()
		else:
			push_warning("Could not open translation file: %s" % path)
	else:
		print("Translation file not found: ", path)

	# Also notify LocalizationManager if present to update runtime text via its signal
	if has_node("/root/LocalizationManager"):
		LocalizationManager.set_language(lang_code)

func get_current_locale() -> String:
	return LocalizationManager.get_current_language() if has_node("/root/LocalizationManager") else "en"
