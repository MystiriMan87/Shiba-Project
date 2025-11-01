extends CanvasLayer

signal loading_complete

@export var min_display_time: float = 1.5
@export var fade_in_duration: float = 0.3
@export var scene_fade_in_duration: float = 0.5

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var progress_bar: ProgressBar = $FadeOverlay/Panel/VBoxContainer/ProgressBar
@onready var loading_label: Label = $FadeOverlay/Panel/VBoxContainer/LoadingLabel

var target_scene_path: String = ""
var loading_start_time: float = 0.0
var is_loading: bool = false
var transition_overlay: ColorRect = null

func _ready():
	layer = 1000
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	set_process_input(false)
	
	#if has_node("/root/LocalizationManager"):

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
	
	if not packed_scene:
		print("LoadingScreen: ERROR - packed_scene is null")
		is_loading = false
		hide()
		return
	
	progress_bar.visible = false
	loading_label.visible = false
	
	create_persistent_overlay()
	
	print("LoadingScreen: Changing scene")
	get_tree().change_scene_to_packed(packed_scene)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("LoadingScreen: Scene loaded, fading in")
	fade_in_new_scene()
	
	is_loading = false
	set_process(false)
	progress_bar.value = 0
	progress_bar.visible = true
	loading_label.text = "Loading... 0%"
	loading_label.visible = true
	hide()
	
	loading_complete.emit()

func create_persistent_overlay():
	var root = get_tree().root
	var canvas = CanvasLayer.new()
	canvas.layer = 10000
	canvas.name = "TransitionOverlay"
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color.BLACK
	transition_overlay.modulate.a = 1.0
	transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	canvas.add_child(transition_overlay)
	root.add_child(canvas)
	
	print("LoadingScreen: Created persistent overlay")

func fade_in_new_scene():
	if not transition_overlay:
		print("LoadingScreen: ERROR - transition_overlay is null")
		return
	
	print("LoadingScreen: Starting fade in animation")
	var tween = get_tree().create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 0.0, scene_fade_in_duration)
	tween.tween_callback(func():
		print("LoadingScreen: Fade complete, cleaning up overlay")
		if transition_overlay and transition_overlay.get_parent():
			transition_overlay.get_parent().queue_free()
		transition_overlay = null
	)
