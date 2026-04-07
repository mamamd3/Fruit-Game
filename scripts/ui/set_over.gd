extends Control

@onready var ranking_label:   Label  = $RankingLabel
@onready var continue_button: Button = $Continue
@onready var reset_button:    Button = $Reset

func _ready() -> void:
	var sorted = Global.points.keys()
	sorted.sort_custom(func(a, b): return Global.points[a] > Global.points[b])
	var text = "Wyniki po " + str(Global.round_number) + " rundach:\n\n"
	for i in range(sorted.size()):
		text += str(i + 1) + ". " + sorted[i] + " — " + str(Global.points[sorted[i]]) + " pkt\n"
	ranking_label.text = text

	# W trybie sieciowym tylko serwer steruje
	if Global.is_network_game and not multiplayer.is_server():
		continue_button.disabled = true
		reset_button.disabled    = true
		continue_button.text     = "Czekaj na hosta..."

func _on_continue_pressed() -> void:
	if Global.is_network_game:
		if not multiplayer.is_server():
			return
		MultiplayerManager.server_change_scene("res://scenes/ui/round_ended.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/round_ended.tscn")

func _on_reset_pressed() -> void:
	if Global.is_network_game:
		if not multiplayer.is_server():
			return
		Global.reset_full_game()
		MultiplayerManager._rpc_sync_character_state.rpc("", "", "", "", 1)
		MultiplayerManager.server_change_scene("res://scenes/ui/choose_character.tscn")
	else:
		Global.reset_full_game()
		get_tree().change_scene_to_file("res://scenes/ui/choose_character.tscn")
