extends Control
@onready var winner_label: Label = $WinnerLabel
@onready var points_label: Label = $PointsLabel
@onready var continue_button: Button = $Continue

func _ready() -> void:
	if Global.winner == "":
		winner_label.text = "REMIS!"
	else:
		winner_label.text = "Wygrał: " + Global.winner

	var points_text = "Punkty:\n"
	for character in Global.points:
		points_text += character + ": " + str(Global.points[character]) + " pkt\n"
	points_label.text = points_text

	# W trybie sieciowym tylko serwer może kontynuować
	if Global.is_network_game and not multiplayer.is_server():
		continue_button.disabled = true
		continue_button.text = "Czekaj na hosta..."

func _on_button_pressed() -> void:
	Global.round_number += 1

	if Global.winner == "":
		Global.modifier_pickers = []
	else:
		Global.modifier_pickers = Global.get_modifier_pickers()

	if Global.is_network_game:
		if not multiplayer.is_server():
			return
		MultiplayerManager.rpc_sync_round_number.rpc(Global.round_number)
		await get_tree().create_timer(0.05).timeout
		if Global.modifier_pickers.size() > 0:
			MultiplayerManager.server_change_scene("res://Scenes/ui/modifier_select.tscn")
		else:
			MultiplayerManager.server_change_scene("res://Scenes/main_game.tscn")
	else:
		if Global.modifier_pickers.size() > 0:
			get_tree().change_scene_to_file("res://Scenes/ui/modifier_select.tscn")
		else:
			get_tree().change_scene_to_file("res://Scenes/main_game.tscn")
