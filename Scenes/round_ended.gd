extends Control

func _ready() -> void:
	if Global.winner == "":
		$Label.text = "REMIS!"
	else:
		$Label.text = "Winner: " + Global.winner

func _on_button_pressed() -> void:
	Global.reset_all()
	get_tree().change_scene_to_file("res://Scenes/main_game.tscn")
