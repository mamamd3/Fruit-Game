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
		if multiplayer.is_server():
			Global.reset_selection()
			MultiplayerManager._rpc_sync_character_state.rpc(
				Global.player1_character,
				Global.player2_character,
				Global.player3_character,
				Global.player4_character,
				Global.current_picking_player
			)
		MultiplayerManager.pick_synced.connect(_on_pick_synced)
	else:
		Global.reset_selection()
	update_ui()
	# Jeśli bieżący slot to bot — auto-pick po krótkim opóźnieniu
	_try_bot_auto_pick()


func _on_pick_synced() -> void:
	update_ui()


func update_ui():
	var slot = Global.current_picking_player
	var slot_type = Global.slot_types.get(slot, "player")

	# Przeskocz sloty "off"
	while slot <= 4 and Global.slot_types.get(slot, "off") == "off":
		Global.pick_character("")  # pusty pick — slot wyłączony
		slot = Global.current_picking_player
		if Global.all_picked():
			_start_game()
			return

	if slot_type == "bot":
		picking_label.text = "Slot %d (Bot) wybiera..." % slot
		for character in buttons:
			buttons[character].disabled = true
	else:
		picking_label.text = "Gracz %d wybiera!" % slot
		var my_turn = _is_my_turn()
		for character in buttons:
			buttons[character].disabled = not Global.available_characters.has(character) or not my_turn


func _is_my_turn() -> bool:
	if not Global.is_network_game:
		return true
	return Global.current_picking_player == Global.local_player_slot


func _try_bot_auto_pick() -> void:
	# Pomiń sloty "off"
	while Global.current_picking_player <= Global.total_players + _count_off_slots():
		var slot = Global.current_picking_player
		if slot > 4:
			break
		var slot_type = Global.slot_types.get(slot, "player")
		if slot_type == "off":
			Global.pick_character("")
			if Global.all_picked():
				_start_game()
				return
			continue
		elif slot_type == "bot":
			# Bot losuje z dostępnych postaci
			await get_tree().create_timer(0.3).timeout
			if Global.available_characters.size() > 0:
				var choices = Global.available_characters.duplicate()
				choices.shuffle()
				pick(choices[0])
			return
		else:
			# Gracz — czekaj na kliknięcie
			return

func _count_off_slots() -> int:
	var count = 0
	for i in range(1, 5):
		if Global.slot_types.get(i, "player") == "off":
			count += 1
	return count


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
		MultiplayerManager.request_pick.rpc_id(1, character_name)
	else:
		Global.pick_character(character_name)
		if Global.all_picked():
			_start_game()
		else:
			update_ui()
			_try_bot_auto_pick()


func _start_game() -> void:
	Global.reset_all()
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")
