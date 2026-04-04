extends Node
# RotManager.gd v3 — gnicie + super-rot + nagroda za walke

signal rot_updated(player_id: int, rot_progress: float)

const ROT_TICK     : float = 0.05
const ROT_THRESHOLD: float = 0.7
const SUPER_ROT_MUL: float = 3.0
const REWARD_MULT  : float = 0.5

var _rot : Dictionary = {}

func register_player(player_id: int) -> void:
	_rot[player_id] = 0.0

func tick(player_id: int) -> float:
	var current : float = _rot.get(player_id, 0.0)
	var mult    : float = SUPER_ROT_MUL if current > 0.95 else 1.0
	current += ROT_TICK * mult
	current  = minf(current, 1.0)
	_rot[player_id] = current
	emit_signal("rot_updated", player_id, current)
	return current

func reward_attack(attacker_id: int) -> void:
	if attacker_id in _rot:
		_rot[attacker_id] = maxf(0.0, _rot[attacker_id] - ROT_TICK * REWARD_MULT)

func get_rot(player_id: int) -> float:
	return _rot.get(player_id, 0.0)
