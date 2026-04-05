extends Control

@onready var winner_label: Label = $WinnerLabel
@onready var points_label: Label = $PointsLabel

func _ready() -> void:
	if Global.winner == "":
		winner_label.text = "REMIS!"
	else:
		winner_label.text = "Wygrał: " + Global.winner
	var points_text = "Punkty:\n"
	for character in Global.points:
		points_text += character + ": " + str(Global.points[character]) + " pkt\n"
	points_label.text = points_text

func _on_button_pressed() -> void:
	Global.round_number += 1
	Global.modifier_pickers = Global.get_modifier_pickers()  # ← zapisz przed resetem
	Global.reset_all()
	if Global.modifier_pickers.size() > 0:
		get_tree().change_scene_to_file("res://Scenes/modifier_select.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/main_game.tscn")
