extends Control

var player_choosing = {Player1 = true, Player2 = false}


func _on_grape_pressed() -> void:
	Global.player2_character = "Grape"


func _on_strawberry_pressed() -> void:
	Global.player2_character = "Strawberry"



func _on_strawberry_2_pressed() -> void:
	Global.player1_character = "Strawberry"



func _on_grape_2_pressed() -> void:
	Global.player1_character = "Grape"


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_game.tscn")
