# =====================================================================
# LanDiscovery — odkrywanie serwerów Fruit Game w sieci LAN przez UDP
# Użycie:
#   start_broadcasting(port)  — serwer zaczyna rozsyłać beacony
#   stop_broadcasting()       — serwer zatrzymuje beacony
#   start_listening()         — klient zaczyna nasłuchiwać
#   stop_listening()          — klient zatrzymuje nasłuchiwanie
#   Sygnał server_found(address, port, info) — emitowany gdy odkryto serwer
# =====================================================================

extends Node

signal server_found(address: String, port: int, info: Dictionary)

const BROADCAST_PORT:     int   = 7778
const BROADCAST_INTERVAL: float = 2.0

var _broadcast_socket: PacketPeerUDP = null
var _listen_socket:    PacketPeerUDP = null
var _broadcast_timer:  float = 0.0
var _is_broadcasting:  bool  = false
var _is_listening:     bool  = false
var _game_port:        int   = 7777


# ─── BROADCASTING (serwer) ────────────────────────────────────────────────────

func start_broadcasting(game_port: int = 7777) -> void:
	_game_port = game_port
	_broadcast_socket = PacketPeerUDP.new()
	_broadcast_socket.set_broadcast_enabled(true)
	_broadcast_timer  = BROADCAST_INTERVAL  # wyślij od razu przy pierwszym _process
	_is_broadcasting  = true

func stop_broadcasting() -> void:
	_is_broadcasting = false
	if _broadcast_socket:
		_broadcast_socket.close()
		_broadcast_socket = null
	_broadcast_timer = 0.0


# ─── LISTENING (klient) ───────────────────────────────────────────────────────

func start_listening() -> void:
	_listen_socket = PacketPeerUDP.new()
	_listen_socket.set_broadcast_enabled(true)
	var err: Error = _listen_socket.bind(BROADCAST_PORT)
	if err != OK:
		printerr("LanDiscovery: nie można nasłuchiwać na porcie %d (%s)" % [BROADCAST_PORT, error_string(err)])
		_listen_socket = null
		return
	_is_listening = true

func stop_listening() -> void:
	_is_listening = false
	if _listen_socket:
		_listen_socket.close()
		_listen_socket = null


# ─── PROCESS ──────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _is_broadcasting:
		_broadcast_timer += delta
		if _broadcast_timer >= BROADCAST_INTERVAL:
			_broadcast_timer = 0.0
			_send_beacon()

	if _is_listening:
		_poll_incoming()


# ─── INTERNALS ────────────────────────────────────────────────────────────────

func _send_beacon() -> void:
	if not _broadcast_socket:
		return
	var payload: Dictionary = {"port": _game_port, "game": "FruitGame"}
	var bytes: PackedByteArray = JSON.stringify(payload).to_utf8_buffer()
	_broadcast_socket.set_dest_address("255.255.255.255", BROADCAST_PORT)
	_broadcast_socket.put_packet(bytes)

func _poll_incoming() -> void:
	if not _listen_socket:
		return
	while _listen_socket.get_available_packet_count() > 0:
		var raw: PackedByteArray = _listen_socket.get_packet()
		var sender_ip: String    = _listen_socket.get_packet_ip()
		var json_str: String     = raw.get_string_from_utf8()
		var parsed               = JSON.parse_string(json_str)
		if parsed is Dictionary and parsed.has("port"):
			server_found.emit(sender_ip, int(parsed["port"]), parsed)
