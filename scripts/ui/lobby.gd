extends Control

@onready var players_label: Label  = $VBox/PlayersLabel
@onready var status_label:  Label  = $VBox/StatusLabel
@onready var start_button:  Button = $VBox/StartButton


func _ready() -> void:
	MultiplayerManager.player_joined.connect(_on_player_change)
	MultiplayerManager.player_left.connect(_on_player_change)
	MultiplayerManager.disconnected.connect(_on_disconnected)

	var is_host = multiplayer.is_server()
	start_button.visible = is_host

	if is_host:
		status_label.text = "Twój IP: " + _get_local_ip() + "\nPort: " + str(MultiplayerManager.port)
	else:
		status_label.text = "Połączono! Czekaj na hosta..."

	_refresh_player_list()


func _get_local_ip() -> String:
	for addr in IP.get_local_addresses():
		if addr.find(":") != -1:
			continue  # pomiń IPv6
		if addr.begins_with("192.168") or addr.begins_with("10.") or addr.begins_with("172."):
			return addr
	return "127.0.0.1"


func _on_player_change(_peer_id: int) -> void:
	_refresh_player_list()


func _refresh_player_list() -> void:
	var count = MultiplayerManager.connected_players.size()
	var text  = "Gracze (%d/%d):\n" % [count, MultiplayerManager.MAX_PLAYERS]
	for pid in MultiplayerManager.connected_players:
		var slot = MultiplayerManager.player_slots.get(pid, "?")
		text += "  Gracz %s — %s\n" % [str(slot), MultiplayerManager.connected_players[pid]]
	players_label.text     = text
	start_button.disabled  = count < 2


func _on_start_pressed() -> void:
	if not multiplayer.is_server():
		return
	Global.total_players = MultiplayerManager.connected_players.size()
	MultiplayerManager.sync_total_players.rpc(Global.total_players)
	await get_tree().create_timer(0.1).timeout
	MultiplayerManager.server_change_scene("res://scenes/ui/choose_character.tscn")


func _on_disconnected() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_back_pressed() -> void:
	MultiplayerManager.disconnect_network()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
