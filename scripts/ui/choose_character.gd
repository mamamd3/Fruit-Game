extends Control

@onready var picking_label: Label = $PickingLabel
@onready var buttons = {
	"Strawberry": $Strawberry2,
	"Orange":     $Orange2,
	"Pineapple":  $Pineapple2,
	"Grape":      $Grape2
}

func _ready():
	if Global.is_network_game:
		# Serwer resetuje wybór i synchronizuje stan do klientów
		if multiplayer.is_server():
			Global.reset_selection()
			MultiplayerManager._rpc_sync_character_state.rpc(
				Global.player1_character,
				Global.player2_character,
				Global.player3_character,
				Global.player4_character,
				Global.current_picking_player
			)
		# Wszyscy nasłuchują na aktualizacje stanu wyboru
		MultiplayerManager.pick_synced.connect(_on_pick_synced)
	else:
		Global.reset_selection()
	update_ui()


func _on_pick_synced() -> void:
	update_ui()


func update_ui():
	picking_label.text = "Gracz " + str(Global.current_picking_player) + " wybiera!"
	var my_turn = _is_my_turn()
	for character in buttons:
		buttons[character].disabled = not Global.available_characters.has(character) or not my_turn


func _is_my_turn() -> bool:
	if not Global.is_network_game:
		return true
	return Global.current_picking_player == Global.local_player_slot


func _on_strawberry_2_pressed():
	pick("Strawberry")

func _on_grape_2_pressed():
	pick("Grape")

func _on_orange_2_pressed():
	pick("Orange")

func _on_pineapple_2_pressed():
	pick("Pineapple")

func pick(character_name: String):
	if Global.is_network_game:
		# Wyślij żądanie wyboru do serwera
		MultiplayerManager.request_pick.rpc_id(1, character_name)
	else:
		Global.pick_character(character_name)
		if Global.all_picked():
			Global.reset_all()
			get_tree().change_scene_to_file("res://Scenes/main_game.tscn")
		else:
			update_ui()
