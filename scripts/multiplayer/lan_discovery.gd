# =====================================================================
# Tabliczka Znamionowa Skryptu
# Data: 2026-04-07
# Opis: LAN Beacon — rozgłaszanie i wykrywanie serwerów w sieci lokalnej
#        poprzez pakiety UDP (broadcast).
# Użycie (serwer):
#   var disc = LanDiscovery.new()
#   add_child(disc)
#   disc.start_broadcasting(7777, "Mój serwer")
# Użycie (klient):
#   var disc = LanDiscovery.new()
#   add_child(disc)
#   disc.server_found.connect(func(addr, port, name): ...)
#   disc.start_listening()
# =====================================================================

extends Node

## Emitowany gdy znaleziono serwer w sieci lokalnej.
signal server_found(address: String, port: int, server_name: String)

const BEACON_PORT:     int   = 7778          # port UDP dla beacon (inny niż port gry)
const BROADCAST_ADDR:  String = "255.255.255.255"
const BROADCAST_INTERVAL: float = 2.0        # sekundy między pakietami beacon
const MAGIC:           String = "FRUIT_GAME_BEACON"

var _udp_listener: PacketPeerUDP      = null   # tryb nasłuchu (klient)
var _beacon_timer: float              = 0.0
var _server_port:  int                = 7777
var _server_name:  String             = "Serwer"
var _broadcasting: bool               = false
var _listening:    bool               = false


## Uruchom nadawanie beacon (wywołaj na hoście gry).
func start_broadcasting(game_port: int, server_name: String = "Serwer") -> void:
	stop()
	_server_port  = game_port
	_server_name  = server_name
	_broadcasting = true
	_beacon_timer = 0.0
	print("[LanDiscovery] Rozgłaszanie na ", BROADCAST_ADDR, ":", BEACON_PORT)


## Uruchom nasłuch beacon (wywołaj na kliencie szukającym serwera).
func start_listening() -> void:
	stop()
	_udp_listener = PacketPeerUDP.new()
	var err: Error = _udp_listener.bind(BEACON_PORT)
	if err != OK:
		printerr("[LanDiscovery] Nie można nasłuchiwać na porcie ", BEACON_PORT, ": ", err)
		_udp_listener = null
		return
	_udp_listener.set_broadcast_enabled(true)
	_listening = true
	print("[LanDiscovery] Nasłuch beacon na porcie ", BEACON_PORT)


## Zatrzymaj beacon (broadcast i nasłuch).
func stop() -> void:
	_broadcasting = false
	_listening    = false
	if _udp_listener != null:
		_udp_listener.close()
		_udp_listener = null


func _process(delta: float) -> void:
	if _broadcasting:
		_beacon_timer -= delta
		if _beacon_timer <= 0.0:
			_beacon_timer = BROADCAST_INTERVAL
			_send_beacon()

	if _listening and _udp_listener != null:
		_poll_listener()


func _send_beacon() -> void:
	var sender := PacketPeerUDP.new()
	sender.set_broadcast_enabled(true)
	var err: Error = sender.set_dest_address(BROADCAST_ADDR, BEACON_PORT)
	if err != OK:
		sender.close()
		return
	var payload: String = "%s|%d|%s" % [MAGIC, _server_port, _server_name]
	sender.put_packet(payload.to_utf8_buffer())
	sender.close()


func _poll_listener() -> void:
	while _udp_listener.get_available_packet_count() > 0:
		var raw: PackedByteArray = _udp_listener.get_packet()
		var sender_ip: String    = _udp_listener.get_packet_ip()
		var text: String         = raw.get_string_from_utf8()
		var parts: Array         = text.split("|")
		if parts.size() == 3 and parts[0] == MAGIC:
			var game_port: int       = int(parts[1])
			var srv_name: String     = parts[2]
			server_found.emit(sender_ip, game_port, srv_name)
