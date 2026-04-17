extends Node

var sounds = {
	"shoot": preload("res://assets/audio/shoot.wav"),
	"hit": preload("res://assets/audio/hit.wav"),
	"jump": preload("res://assets/audio/jump.wav"),
	"death": preload("res://assets/audio/death.wav"),
	"ui_click": preload("res://assets/audio/ui_click.wav"),
	"melee": preload("res://assets/audio/melee.wav"),
	"bgm": preload("res://assets/audio/bgm.wav")
}

var bgm_player: AudioStreamPlayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Create BGM player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = sounds["bgm"]
	bgm_player.volume_db = -10.0 # Make BGM a bit quieter
	add_child(bgm_player)
	
	# Start BGM
	# Uncomment to auto-play
	# bgm_player.play()

func play_sound(sound_name: String, pitch_scale: float = 1.0, volume_db: float = 0.0):
	if sounds.has(sound_name):
		var player = AudioStreamPlayer.new()
		player.stream = sounds[sound_name]
		player.pitch_scale = pitch_scale
		player.volume_db = volume_db
		add_child(player)
		player.play()
		player.finished.connect(func(): player.queue_free())
	else:
		print("Sound not found: ", sound_name)

func play_bgm():
	if not bgm_player.playing:
		bgm_player.play()

func stop_bgm():
	if bgm_player.playing:
		bgm_player.stop()

func play_ui_click():
	play_sound("ui_click")
