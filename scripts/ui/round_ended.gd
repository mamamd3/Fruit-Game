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

	# Przy remisoie nikt nie wybiera modyfikatorów — gnicie = wszyscy remisują,
	# więc nikt nie "wygrał" rundy i nie ma kogo nagradzać modem.
	# Bez tego warunku get_modifier_pickers() nadpisałoby puste [] ustawione
	# przez _end_round() i gracze niepotrzebnie wybieraliby mody po remisoie.
	if Global.winner == "":
		Global.modifier_pickers = []
	else:
		Global.modifier_pickers = Global.get_modifier_pickers()

	if Global.modifier_pickers.size() > 0:
		get_tree().change_scene_to_file("res://Scenes/ui/modifier_select.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/main_game.tscn")
