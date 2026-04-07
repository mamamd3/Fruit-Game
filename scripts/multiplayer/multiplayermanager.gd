# =====================================================================
# MultiplayerManager — zarządzanie trybem sieciowym (ENet)
# Godot 4 — autoload
# =====================================================================

extends Node

signal connected
signal disconnected
signal message_received(message: String, sender_peer_id: int)
signal player_joined(peer_id: int)
signal player_left(peer_id: int)
signal player_spectating(peer_id: int)
signal pick_synced                                        # po syncu wyboru postaci
signal modifier_applied(char_name: String, mod_id: String)  # po syncu moda

const MAX_PLAYERS: int = 4
enum Mode { SINGLE_PLAYER, SERVER, CLIENT }

var current_mode: Mode = Mode.SINGLE_PLAYER
var peer_id: int        = 0
var multiplayer_peer: ENetMultiplayerPeer

var connected_players: Dictionary = {}  # peer_id → nazwa wyświetlana
var player_slots:      Dictionary = {}  # peer_id → slot (1..4)
var spectators:        Dictionary = {}  # peer_id → nazwa — gracze dołączający w trakcie gry

var host_address: String = "127.0.0.1"
var port:         int    = 7777


# ─── READY ────────────────────────────────────────────────────────────────────
func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


# ─── START / STOP ─────────────────────────────────────────────────────────────
func start_single_player() -> void:
	disconnect_network()
	current_mode             = Mode.SINGLE_PLAYER
	peer_id                  = 1
	connected_players        = {peer_id: "Gracz Lokalny"}
	player_slots             = {peer_id: 1}
	Global.is_network_game   = false
	Global.local_player_slot = 0
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

	peer_id                  = 1
	current_mode             = Mode.SERVER
	connected_players        = {peer_id: "Host"}
	player_slots             = {peer_id: 1}
	Global.is_network_game   = true
	Global.local_player_slot = 1

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
	Global.is_network_game = true

func disconnect_network() -> void:
	if multiplayer_peer != null:
		multiplayer_peer.close()
		multiplayer_peer = null
		multiplayer.multiplayer_peer = null

	current_mode             = Mode.SINGLE_PLAYER
	peer_id                  = 0
	connected_players.clear()
	player_slots.clear()
	spectators.clear()
	Global.is_network_game   = false
	Global.local_player_slot = 0
	disconnected.emit()


# ─── GAME FLOW — zmiana sceny na wszystkich klientach ─────────────────────────
func server_change_scene(scene_path: String) -> void:
	if multiplayer.is_server():
		_rpc_change_scene.rpc(scene_path)

@rpc("authority", "call_local", "reliable")
func _rpc_change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)


# ─── SLOT ASSIGNMENT (tylko serwer) ──────────────────────────────────────────
func _assign_slot(new_peer_id: int) -> int:
	for slot in range(1, MAX_PLAYERS + 1):
		if not player_slots.values().has(slot):
			player_slots[new_peer_id] = slot
			return slot
	return -1

func get_peer_for_slot(slot: int) -> int:
	for pid in player_slots:
		if player_slots[pid] == slot:
			return pid
	return -1

func get_character_for_peer(pid: int) -> String:
	var slot = player_slots.get(pid, -1)
	match slot:
		1: return Global.player1_character
		2: return Global.player2_character
		3: return Global.player3_character
		4: return Global.player4_character
	return ""

@rpc("authority", "call_remote", "reliable")
func _rpc_set_my_slot(slot: int) -> void:
	Global.local_player_slot = slot

@rpc("authority", "call_remote", "reliable")
func _rpc_sync_player_list(players: Dictionary, slots: Dictionary) -> void:
	connected_players = players
	player_slots      = slots

@rpc("authority", "call_remote", "reliable")
func sync_total_players(count: int) -> void:
	Global.total_players = count


# ─── CHARACTER SELECTION SYNC ─────────────────────────────────────────────────
# Klient wysyła żądanie wyboru postaci do serwera.
@rpc("any_peer", "call_local", "reliable")
func request_pick(character_name: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1  # lokalne wywołanie z serwera
	var slot = player_slots.get(sender_id, -1)
	if slot != Global.current_picking_player:
		return  # nie twoja kolej

	Global.pick_character(character_name)
	_rpc_sync_character_state.rpc(
		Global.player1_character,
		Global.player2_character,
		Global.player3_character,
		Global.player4_character,
		Global.current_picking_player
	)

	if Global.all_picked():
		await get_tree().create_timer(0.2).timeout
		Global.rpc_reset_all.rpc()
		await get_tree().create_timer(0.05).timeout
		_rpc_change_scene.rpc("res://Scenes/main_game.tscn")

# Serwer rozsyła aktualny stan wyboru postaci do wszystkich.
@rpc("authority", "call_local", "reliable")
func _rpc_sync_character_state(p1: String, p2: String, p3: String, p4: String, next_picker: int) -> void:
	Global.player1_character     = p1
	Global.player2_character     = p2
	Global.player3_character     = p3
	Global.player4_character     = p4
	Global.current_picking_player = next_picker
	var picked = [p1, p2, p3, p4].filter(func(c): return c != "")
	Global.available_characters  = Global.base_characters.keys().filter(func(c): return not picked.has(c))
	pick_synced.emit()


# ─── MODIFIER SELECTION SYNC ──────────────────────────────────────────────────
@rpc("any_peer", "call_local", "reliable")
func request_modifier(picker_char: String, mod_id: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	var my_char = get_character_for_peer(sender_id)
	if my_char != picker_char:
		return  # walidacja: tylko twoja postać

	if not Global.modifiers.has(picker_char):
		Global.modifiers[picker_char] = []
	Global.modifiers[picker_char].append(mod_id)
	_rpc_broadcast_modifier.rpc(picker_char, mod_id)

@rpc("authority", "call_local", "reliable")
func _rpc_broadcast_modifier(char_name: String, mod_id: String) -> void:
	if not Global.modifiers.has(char_name):
		Global.modifiers[char_name] = []
	if not Global.modifiers[char_name].has(mod_id):
		Global.modifiers[char_name].append(mod_id)
	modifier_applied.emit(char_name, mod_id)


# ─── GLOBAL STATE SYNC ────────────────────────────────────────────────────────
@rpc("authority", "call_local", "reliable")
func rpc_sync_round_number(n: int) -> void:
	Global.round_number = n


# ─── MESSAGING ────────────────────────────────────────────────────────────────
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


# ─── PEER CALLBACKS ───────────────────────────────────────────────────────────
func _on_peer_connected(new_peer_id: int) -> void:
	# Gra już w toku — nowy gracz zostaje obserwatorem
	if Global.game_started:
		spectators[new_peer_id] = "Obserwator %d" % new_peer_id
		_notify_player_spectating.rpc_id(new_peer_id, new_peer_id)
		player_spectating.emit(new_peer_id)
		return

	var slot = _assign_slot(new_peer_id)
	connected_players[new_peer_id] = "Gracz %d" % slot

	_rpc_set_my_slot.rpc_id(new_peer_id, slot)
	_rpc_sync_player_list.rpc(connected_players, player_slots)

	Global.total_players = connected_players.size()
	sync_total_players.rpc(Global.total_players)

	player_joined.emit(new_peer_id)

@rpc("authority", "call_remote", "reliable")
func _notify_player_spectating(spectating_peer_id: int) -> void:
	player_spectating.emit(spectating_peer_id)

## Promuje obserwatorów do aktywnych graczy na początku następnej rundy.
## Wywołuj tylko na serwerze, przed zmianą sceny.
func promote_spectators() -> void:
	if not multiplayer.is_server():
		return
	for spid in spectators.keys():
		var slot = _assign_slot(spid)
		if slot == -1:
			continue  # brak wolnych slotów
		connected_players[spid] = spectators[spid]
		_rpc_set_my_slot.rpc_id(spid, slot)
	spectators.clear()
	_rpc_sync_player_list.rpc(connected_players, player_slots)
	Global.total_players = connected_players.size()
	sync_total_players.rpc(Global.total_players)

func _on_peer_disconnected(disconnected_peer_id: int) -> void:
	if connected_players.has(disconnected_peer_id):
		connected_players.erase(disconnected_peer_id)
		player_slots.erase(disconnected_peer_id)
		player_left.emit(disconnected_peer_id)
		if multiplayer.is_server():
			Global.total_players = connected_players.size()
			sync_total_players.rpc(Global.total_players)

func _on_connection_failed() -> void:
	disconnect_network()

func _on_server_disconnected() -> void:
	disconnect_network()

func _on_connected_to_server() -> void:
	peer_id      = multiplayer.get_unique_id()
	current_mode = Mode.CLIENT
	connected_players = {peer_id: "Ty (Klient)"}
	connected.emit()
	player_joined.emit(peer_id)
