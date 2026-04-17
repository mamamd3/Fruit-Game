extends Control

@onready var fullscreen_check = $VBox/FullscreenCheck
@onready var master_slider = $VBox/MasterSlider
@onready var music_slider = $VBox/MusicSlider
@onready var sfx_slider = $VBox/SfxSlider

func _ready() -> void:
	fullscreen_check.button_pressed = SettingsManager.get_setting("video", "fullscreen")
	master_slider.value = SettingsManager.get_setting("audio", "master_volume")
	music_slider.value = SettingsManager.get_setting("audio", "music_volume")
	sfx_slider.value = SettingsManager.get_setting("audio", "sfx_volume")

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	AudioManager.play_ui_click()
	SettingsManager.set_setting("video", "fullscreen", toggled_on)

func _on_master_slider_value_changed(value: float) -> void:
	SettingsManager.set_setting("audio", "master_volume", value)

func _on_music_slider_value_changed(value: float) -> void:
	SettingsManager.set_setting("audio", "music_volume", value)

func _on_sfx_slider_value_changed(value: float) -> void:
	SettingsManager.set_setting("audio", "sfx_volume", value)

func _on_back_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
