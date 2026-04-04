extends Node
# GameManager.gd v3 — anty-snowball + matchmaking stub + sygnaly

signal round_started(round_num: int)
signal round_ended(winner_id: int)
signal session_created(session_id: String)

const ANTI_SNOWBALL_TOP : int = 2

var round_number : int = 0
var scores       : Dictionary = {}
var _session_id  : String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_round() -> void:
	round_number += 1
	_apply_anti_snowball()
	emit_signal("round_started", round_number)

func _apply_anti_snowball() -> void:
	if scores.is_empty(): return
	var sorted_ids := scores.keys()
	sorted_ids.sort_custom(func(a,b): return scores[a] > scores[b])
	for i in sorted_ids.size():
		var pid : int = sorted_ids[i]
		var node := _find_player(pid)
		if node and i < ANTI_SNOWBALL_TOP:
			node.set_meta("anti_snowball", true)
			push_warning("AntiSnowball: gracz %d bez modyfikatorow" % pid)

func register_kill(killer_id: int, victim_id: int) -> void:
	scores[killer_id] = scores.get(killer_id, 0) + 1
	var alive := get_tree().get_nodes_in_group("players").filter(
		func(p): return p.get("current_hp", 0) > 0)
	if alive.size() == 1:
		emit_signal("round_ended", alive[0].get_meta("player_id", -1))

func create_session() -> void:
	_session_id = "session_%d" % Time.get_ticks_msec()
	emit_signal("session_created", _session_id)
	push_warning("WebSocket stub — session_id: " + _session_id)

func _find_player(pid: int) -> Node:
	for p in get_tree().get_nodes_in_group("players"):
		if p.get_meta("player_id",-1) == pid:
			return p
	return null
