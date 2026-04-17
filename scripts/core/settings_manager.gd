extends Node

const SETTINGS_FILE = "user://settings.cfg"

var config = ConfigFile.new()

var default_settings = {
	"audio": {
		"master_volume": 1.0,
		"music_volume": 1.0,
		"sfx_volume": 1.0
	},
	"video": {
		"fullscreen": false
	}
}

func _ready() -> void:
	load_settings()
	apply_settings()

func load_settings() -> void:
	var err = config.load(SETTINGS_FILE)
	if err != OK:
		# Plik nie istnieje lub jest uszkodzony, wczytaj domyślne
		for section in default_settings:
			for key in default_settings[section]:
				config.set_value(section, key, default_settings[section][key])
		save_settings()

func save_settings() -> void:
	config.save(SETTINGS_FILE)

func get_setting(section: String, key: String):
	return config.get_value(section, key, default_settings.get(section, {}).get(key))

func set_setting(section: String, key: String, value) -> void:
	config.set_value(section, key, value)
	save_settings()
	apply_settings()

func apply_settings() -> void:
	# Video
	var is_fullscreen = get_setting("video", "fullscreen")
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# Audio
	var master_vol = get_setting("audio", "master_volume")
	var music_vol = get_setting("audio", "music_volume")
	var sfx_vol = get_setting("audio", "sfx_volume")
	
	# Godot używa AudioServer do głośności
	var master_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(master_vol))
	
	# Jeśli masz bus "Music" i "SFX":
	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_vol))
		
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_vol))
