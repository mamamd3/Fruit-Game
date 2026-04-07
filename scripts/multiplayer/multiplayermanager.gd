# =====================================================================
# Tabliczka Znamionowa Skryptu
# Data: 2026-04-07
# Opis: Skrypt zarządzający trybem wieloosobowym (ENet)
# Gdzie uruchomić: Silnik Godot 4
# Docelowa maszyna: Dowolny OS / Serwer dedykowany
# Wymagane uprawnienia: Brak (standardowe prawa aplikacji)
# =====================================================================

extends Node

signal connected
signal disconnected
signal message_received(message: String, sender_peer_id: int)
signal player_joined(peer_id: int)
signal player_left(peer_id: int)
## Emitowany gdy gracz dołącza w trakcie trwającej rundy — trafia do trybu obserwatora.
signal player_spectating(peer_id: int)

const MAX_PLAYERS: int = 4
enum Mode { SINGLE_PLAYER, SERVER, CLIENT }

var current_mode: Mode = Mode.SINGLE_PLAYER
var peer_id: int = 0
var multiplayer_peer: ENetMultiplayerPeer
var connected_players: Dictionary = {}
## Gracze, którzy dołączyli w trakcie rundy i czekają jako obserwatorzy.
var spectators: Dictionary = {}

@export var host_address: String = "127.0.0.1"
@export var port: int = 7777

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func start_single_player() -> void:
	disconnect_network()
	current_mode = Mode.SINGLE_PLAYER
	peer_id = 1
	connected_players = {peer_id: "Gracz Lokalny"}
	connected.emit()
	player_joined.emit(peer_id)

func start_server() -> void:
	disconnect_network()
	multiplayer_peer = ENetMultiplayerPeer.new()
	var error: Error = multiplayer_peer.create_server(port, MAX_PLAYERS)
	if error != OK:
		printerr("Błąd przy tworzeniu serwera: ", error)
		return

	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer_peer.peer_connected.connect(_on_peer_connected)
	multiplayer_peer.peer_disconnected.connect(_on_peer_disconnected)
	
	peer_id = 1
	current_mode = Mode.SERVER
	connected_players = {peer_id: "Serwer"}
	
	connected.emit()
	player_joined.emit(peer_id)

func start_client(address: String = host_address, server_port: int = port) -> void:
	disconnect_network()
	multiplayer_peer = ENetMultiplayerPeer.new()
	var error: Error = multiplayer_peer.create_client(address, server_port)
	if error != OK:
		printerr("Błąd przy tworzeniu klienta: ", error)
		return
		
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer_peer.peer_disconnected.connect(_on_peer_disconnected)

func disconnect_network() -> void:
	if multiplayer_peer != null:
		multiplayer_peer.close()
		multiplayer_peer = null
		multiplayer.multiplayer_peer = null
		
	current_mode = Mode.SINGLE_PLAYER
	peer_id = 0
	connected_players.clear()
	spectators.clear()
	disconnected.emit()

func broadcast(message: String) -> void:
	if current_mode == Mode.SINGLE_PLAYER:
		receive_message(message)
	elif multiplayer_peer != null:
		rpc("receive_message", message)

@rpc("any_peer", "call_local", "reliable")
func receive_message(message: String) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = peer_id
	message_received.emit(message, sender_id)

func send_to_player(player_id: int, message: String) -> void:
	if multiplayer_peer != null:
		rpc_id(player_id, "receive_message", message)

func _on_peer_connected(new_peer_id: int) -> void:
	connected_players[new_peer_id] = "Gracz %d" % new_peer_id
	# Jeśli runda jest w toku, gracz trafia do trybu obserwatora do następnego rozdania.
	if Global.game_started:
		spectators[new_peer_id] = true
		player_spectating.emit(new_peer_id)
	else:
		player_joined.emit(new_peer_id)

func _on_peer_disconnected(disconnected_peer_id: int) -> void:
	if connected_players.has(disconnected_peer_id):
		connected_players.erase(disconnected_peer_id)
		player_left.emit(disconnected_peer_id)
	spectators.erase(disconnected_peer_id)

func _on_connection_failed() -> void:
	disconnect_network()

func _on_server_disconnected() -> void:
	disconnect_network()

## Zwraca true jeśli peer czeka w trybie obserwatora.
func is_spectator(check_peer_id: int) -> bool:
	return spectators.has(check_peer_id)

## Przesuwa wszystkich obserwatorów do aktywnych graczy po zakończeniu rundy.
## Wywołaj to z round_ended.gd lub main_game.gd przed nowym rozdaniem.
func promote_spectators() -> void:
	for sp_id in spectators.keys():
		spectators.erase(sp_id)
		player_joined.emit(sp_id)

func _on_connected_to_server() -> void:
	peer_id = multiplayer.get_unique_id()
	current_mode = Mode.CLIENT
	connected_players = {peer_id: "Ty (Klient)"}
	connected.emit()
