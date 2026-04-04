# w round_ended.gd
extends Control

func _on_button_pressed() -> void:
	print("restarted")
	Global.strawberry_health = 100  # reset!
	Global.grape_health = 70        # reset!
	Global.game_over = false
	get_tree().change_scene_to_file("res://Scenes/main_game.tscn")
