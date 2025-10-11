extends Node2D

@export var background_music_path: String = "res://audio/village-theme-68229.mp3"
@export var background_music_volume: float = 0.0
@export var music_autoplay: bool = true
@onready var music_player: AudioStreamPlayer = null

func _ready():
	await get_tree().process_frame
	setup_background_music()

	
	var camera = get_node_or_null("PlayerCamera")
	if camera:
		camera.follow_speed = 5.0
		print("Camera follow speed set to 0 on hub load")
	else:
		print("PlayerCamera not found as child of hub!")

func setup_background_music():
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)
	
	if background_music_path != "" and ResourceLoader.exists(background_music_path):
		var music = load(background_music_path)
		if music is AudioStream:
			music_player.stream = music
			music_player.volume_db = background_music_volume
			music_player.bus = "Master"
			music_player.autoplay = music_autoplay
			
			if music_autoplay:
				music_player.play()

func play_background_music():
	if music_player and music_player.stream and not music_player.playing:
		music_player.play()

func stop_background_music():
	if music_player and music_player.playing:
		music_player.stop()

func set_music_volume(volume_db: float):
	if music_player:
		music_player.volume_db = volume_db
