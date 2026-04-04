extends Control

func _on_button_pressed() -> void:
	print("restarted")
	Global.reset_all()
	Global.round_over = false
	get_tree().change_scene_to_file("res://Scenes/main_game.tscn")
