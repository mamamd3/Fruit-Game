extends Control

@onready var picking_label: Label  = $PickingLabel
@onready var card1: Button         = $HBoxContainer/Card1
@onready var card2: Button         = $HBoxContainer/Card2
@onready var card3: Button         = $HBoxContainer/Card3

var pickers:              Array = []
var current_picker_index: int   = 0
var current_cards:        Array = []


func _ready() -> void:
	pickers              = Global.modifier_pickers
	current_picker_index = 0
	if Global.is_network_game:
		MultiplayerManager.modifier_applied.connect(_on_modifier_applied_network)
	show_cards_for_current_picker()


# Callback wywoływany przez serwer po zaaplikowaniu moda (tryb sieciowy).
func _on_modifier_applied_network(_char_name: String, _mod_id: String) -> void:
	current_picker_index += 1
	show_cards_for_current_picker()


func show_cards_for_current_picker() -> void:
	if current_picker_index >= pickers.size():
		call_deferred("_go_to_main_game")
		return

	var picker: String = pickers[current_picker_index]
	picking_label.text = picker + " wybiera modyfikator!"

	var pool: Array = Global.all_modifiers.duplicate()
	pool.shuffle()
	current_cards = pool.slice(0, 3)

	_set_card_text(card1, current_cards[0])
	_set_card_text(card2, current_cards[1])
	_set_card_text(card3, current_cards[2])

	# W trybie sieciowym tylko właściciel tej postaci może kliknąć
	if Global.is_network_game:
		var can_pick = _is_my_character(picker)
		card1.disabled = not can_pick
		card2.disabled = not can_pick
		card3.disabled = not can_pick
	else:
		card1.disabled = false
		card2.disabled = false
		card3.disabled = false


func _set_card_text(card: Button, mod_id: String) -> void:
	if not Global.modifier_registry.has(mod_id):
		card.text = mod_id
		return
	var entry: Dictionary = Global.modifier_registry[mod_id]
	var emoji: String     = entry.get("emoji", "")
	var name:  String     = entry.get("name",  mod_id)
	var desc:  String     = entry.get("desc",  "")
	card.text = emoji + " " + name + "\n" + desc


func _go_to_main_game() -> void:
	if Global.is_network_game:
		if multiplayer.is_server():
			MultiplayerManager.server_change_scene("res://Scenes/main_game.tscn")
		# Klienci czekają — serwer zmieni scenę dla wszystkich
	else:
		get_tree().change_scene_to_file("res://Scenes/main_game.tscn")


func _is_my_character(char_name: String) -> bool:
	match Global.local_player_slot:
		1: return Global.player1_character == char_name
		2: return Global.player2_character == char_name
		3: return Global.player3_character == char_name
		4: return Global.player4_character == char_name
	return false


func pick(index: int) -> void:
	var picker: String = pickers[current_picker_index]
	var chosen: String = current_cards[index]

	if Global.is_network_game:
		if not _is_my_character(picker):
			return
		# Wyślij prośbę do serwera — serwer aplikuje i rozsyła do wszystkich
		MultiplayerManager.request_modifier.rpc_id(1, picker, chosen)
	else:
		# Tryb lokalny — istniejąca logika
		Global.modifiers[picker].append(chosen)
		var entry: Dictionary = Global.modifier_registry.get(chosen, {})
		var msg:   String     = entry.get("emoji", "") + " " + picker + \
								" wybrał: " + entry.get("name", chosen)
		Global.kill_feed_message.emit(msg)
		current_picker_index += 1
		show_cards_for_current_picker()


func _on_card_1_pressed() -> void: pick(0)
func _on_card_2_pressed() -> void: pick(1)
func _on_card_3_pressed() -> void: pick(2)
