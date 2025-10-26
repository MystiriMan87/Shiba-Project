extends CanvasLayer

signal loading_complete

@export var min_display_time: float = 1.5
@export var fade_in_duration: float = 0.3
@export var fade_out_duration: float = 0.3

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var progress_bar: ProgressBar = $FadeOverlay/Panel/VBoxContainer/ProgressBar
@onready var loading_label: Label = $FadeOverlay/Panel/VBoxContainer/LoadingLabel

var target_scene_path: String = ""
var loading_start_time: float = 0.0
var is_loading: bool = false

func _ready():
	layer = 50
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	set_process_input(false)

func load_scene(scene_path: String):
	if is_loading:
		return
	
	print("LoadingScreen: Starting load for ", scene_path)
	is_loading = true
	target_scene_path = scene_path
	
	show()
	fade_overlay.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, fade_in_duration)
	await tween.finished
	
	print("LoadingScreen: Fade in complete, starting resource load")
	loading_start_time = Time.get_ticks_msec() / 1000.0
	ResourceLoader.load_threaded_request(scene_path)
	set_process(true)

func _process(_delta):
	if not is_loading:
		return
	
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
	
	if progress.size() > 0:
		progress_bar.value = progress[0] * 100
		loading_label.text = "Loading... %d%%" % int(progress[0] * 100)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var elapsed_time = (Time.get_ticks_msec() / 1000.0) - loading_start_time
		
		if elapsed_time >= min_display_time:
			print("LoadingScreen: Load complete, finishing")
			finish_loading()

func finish_loading():
	var packed_scene = ResourceLoader.load_threaded_get(target_scene_path)
	
	if packed_scene:
		var tween = create_tween()
		tween.tween_property(fade_overlay, "modulate:a", 0.0, fade_out_duration)
		await tween.finished
		
		print("LoadingScreen: Changing scene")
		get_tree().change_scene_to_packed(packed_scene)
	
	is_loading = false
	set_process(false)
	set_process_input(false)
	progress_bar.value = 0
	loading_label.text = "Loading... 0%"
	hide()
	
	loading_complete.emit()
